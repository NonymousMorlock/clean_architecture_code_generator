import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:annotations/annotations.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:generators/core/config/generator_config.dart';
import 'package:generators/core/extensions/class_builder_extensions.dart';
import 'package:generators/core/extensions/i_function_extensions.dart';
import 'package:generators/core/extensions/param_extensions.dart';
import 'package:generators/core/extensions/string_extensions.dart';
import 'package:generators/core/services/feature_file_writer.dart';
import 'package:generators/core/utils/utils.dart';
import 'package:generators/src/models/function.dart';
import 'package:generators/src/models/param.dart';
import 'package:generators/src/visitors/repo_visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Generator for creating use case classes from repository annotations.
///
/// Processes classes annotated with `@UsecaseGenAnnotation` and generates
/// use case classes for each repository method.
class UsecaseGenerator extends GeneratorForAnnotation<UsecaseGenAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = RepoVisitor();
    element.visitChildren(visitor);

    // Load config to check if multi-file output is enabled
    final config = GeneratorConfig.fromFile('clean_arch_config.yaml');
    final writer = FeatureFileWriter(config: config, buildStep: buildStep);
    final featureName = writer.extractFeatureName(repoName: visitor.className);

    if (writer.isMultiFileEnabled && featureName != null) {
      return _generateMultiFile(
        visitor: visitor,
        writer: writer,
        featureName: featureName,
      );
    }

    // Default behavior: generate all usecases to .g.dart
    return writer.resolveGeneratedCode(
      library: _generateLibraryForSingleFileOutput(visitor: visitor),
    );
  }

  String _generateMultiFile({
    required RepoVisitor visitor,
    required FeatureFileWriter writer,
    required String featureName,
  }) {
    final results = <String>[];

    // Generate each usecase in its own file
    for (final method in visitor.methods) {
      final usecasePath = writer.getUsecasePath(featureName, method.name);

      // Generate usecase code
      final usecaseClass = usecase(
        visitor: visitor,
        method: method,
      );

      // Generate complete file with imports
      final (:imports, :importComments) = writer.generateSmartUsecaseImports(
        featureName: featureName,
        methodName: method.name,
        candidates: Utils.discoverMethodEntities(method),
        hasCustomParams: method.params != null && method.params!.length > 1,
      );

      final completeFile = writer.resolveGeneratedCode(
        library: Library((library) {
          library
            ..body.addAll([
              usecaseClass,
              if (_usecaseNeedsCustomParams(method))
                _buildCustomParam(
                  paramClassName: _getCustomParamsClassName(method),
                  params: method.params,
                ),
            ])
            ..comments.addAll(importComments)
            ..directives.addAll(imports.map(Directive.import));
        }),
      );

      // Write to the usecase file
      try {
        writer.writeToFile(usecasePath, completeFile);
        results.add('// Usecase ${method.name} written to: $usecasePath');
      } on Exception catch (e) {
        stderr.writeln('Warning: Could not write to $usecasePath: $e');
        results.add('// Error writing usecase ${method.name}: $e');
      }
    }

    // Return markers for the .g.dart file
    return '${results.join('\n')}\n';
  }

  // if function params is greater than 1, then create
  // params class else just use it

  /// Generates a use case class for a repository method.
  ///
  /// Creates a use case class following the clean architecture pattern
  /// with call method and parameter handling.
  Class usecase({
    required RepoVisitor visitor,
    required IFunction method,
  }) {
    final repoName = visitor.className;
    final className = method.name.pascalCase;

    final needsCustomParams = _usecaseNeedsCustomParams(method);

    final paramType = needsCustomParams
        ? _getCustomParamsClassName(method)
        : method.hasParams
        ? method.params!.first.type
        : null;

    final returnType = method.returnType.rightType;
    final isStream = method.rawType.isDartAsyncStream;
    final usecaseTypePrefix = isStream ? 'Stream' : '';
    final usecaseTypeSymbol = method.hasParams
        ? '${usecaseTypePrefix}UsecaseWithParams'
        : '${usecaseTypePrefix}UsecaseWithoutParams';
    return Class((classBuilder) {
      classBuilder
        ..name = className
        ..implements.add(
          TypeReference((ref) {
            ref
              ..symbol = usecaseTypeSymbol
              ..types.addAll([
                Reference(returnType),
                if (method.hasParams) Reference(paramType),
              ]);
          }),
        )
        ..constructors.add(
          Constructor((constructor) {
            constructor
              ..constant = true
              ..requiredParameters.add(
                Parameter((param) {
                  param
                    ..toThis = true
                    ..name = '_repo';
                }),
              );
          }),
        )
        ..fields.add(
          Field((field) {
            field
              ..name = '_repo'
              ..modifier = FieldModifier.final$
              ..type = Reference(repoName);
          }),
        )
        ..methods.add(
          _buildCallMethod(
            needsCustomParams: needsCustomParams,
            method: method,
            className: className,
            paramType: paramType,
          ),
        );
    });
  }

  /// Generates the call method body for the use case.
  ///
  /// Handles parameter passing to the repository method.
  Method _buildCallMethod({
    required bool needsCustomParams,
    required IFunction method,
    required String className,
    String? paramType,
  }) {
    late Expression methodBody;
    // TODO(TestCandidate): Test with () - empty and ({oneNamed}) and
    //  (onePositional)
    if (!needsCustomParams) {
      // In the case of not needing custom params, we will pass to the
      // argument a "params" param because we know that the `usecase` contract
      // states that the `call` method's parameter shall always called
      // `params`.
      // repo => (User user): usecase call(User params) => _repo.x(params)
      // repo => ({required User user}): usecase call(User params) =>
      // _repo.x(user: params)
      final (:positional, :named) = method.extractArgs(
        transformer: (param) => 'params',
      );
      methodBody = refer(
        '_repo',
      ).property(method.name).call(positional, named).returned;
    } else {
      // TODO(TestCandidate): Test with (positional, {namedNullable, named})
      //  to see whether the repo will get called in the same order as such:
      //  (params.positional, namedNullable: params.namedNullable, named:
      //  params.named)
      final (:positional, :named) = method.extractArgs(
        transformer: (param) => 'params.${param.name}',
      );
      methodBody = refer(
        '_repo',
      ).property(method.name).call(positional, named).returned;
    }

    return Method((methodBuilder) {
      methodBuilder
        ..annotations.add(const Reference('override'))
        ..returns = TypeReference((ref) {
          final isStream = method.rawType.isDartAsyncStream;
          ref
            ..symbol = 'Result${isStream ? 'Stream' : 'Future'}'
            ..types.add(Reference(method.returnType.rightType));
        })
        ..name = 'call'
        ..body = Block((block) => block.addExpression(methodBody));

      if (paramType != null) {
        methodBuilder.requiredParameters.add(
          Parameter(
            (param) => param
              ..type = Reference(paramType)
              ..name = 'params',
          ),
        );
      }
    });
  }

  /// Generates a custom parameter class for use cases with multiple parameters.
  ///
  /// Creates an Equatable class to hold multiple parameters.
  Class _buildCustomParam({
    required String paramClassName,
    required List<Param>? params,
  }) {
    params ??= [];
    return Class((classBuilder) {
      classBuilder
        ..name = paramClassName
        ..extend = const Reference('Equatable')
        ..constructors.addAll([
          Constructor((constructor) {
            constructor
              ..constant = true
              ..optionalParameters.addAll(
                params!.map(
                  (param) => Parameter((paramBuilder) {
                    paramBuilder
                      ..required = true
                      ..toThis = true
                      ..named = true
                      ..name = param.name;
                  }),
                ),
              );
          }),
          Constructor((constructor) {
            constructor
              ..name = 'empty'
              ..constant = params!.every((param) => param.type.isConstValue)
              ..initializers.add(
                refer('this').call(
                  [],
                  {
                    for (final param in params)
                      param.name: param.fallbackValue(),
                  },
                ).code,
              );
          }),
        ])
        ..fields.addAll(
          params!.map((param) {
            return Field((field) {
              field
                ..name = param.name
                ..type = Reference(param.type)
                ..modifier = FieldModifier.final$;
            });
          }),
        )
        ..addEquatableProps(params: params);
    });
  }

  bool _usecaseNeedsCustomParams(IFunction method) {
    return method.params != null && method.params!.length > 1;
  }

  String _getCustomParamsClassName(IFunction method) {
    return '${method.name.pascalCase}Params';
  }

  Library _generateLibraryForSingleFileOutput({required RepoVisitor visitor}) {
    final libraryBody = <Class>[];
    for (final method in visitor.methods) {
      libraryBody.addAll([
        usecase(
          visitor: visitor,
          method: method,
        ),
        _buildCustomParam(
          paramClassName: _getCustomParamsClassName(method),
          params: method.params,
        ),
      ]);
    }
    return Library((library) {
      library.body.addAll(libraryBody);
    });
  }
}
