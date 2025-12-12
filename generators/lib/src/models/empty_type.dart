import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';

/// {@template empty_type_doc}
/// A default implementation of [DartType] for representing an empty
/// or non-existent type.
///
/// This is used to provide a non-null [DartType] when a real one
/// is not available, for example in the `Param.empty()` constructor.
/// {@endtemplate}
class EmptyType implements DartType {
  /// {@macro empty_type_doc}
  const EmptyType();
  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return null as R;
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    return null as R;
  }

  @override
  InstantiatedTypeAliasElement? get alias => null;

  @override
  InterfaceType? asInstanceOf(InterfaceElement element) {
    return null;
  }

  @override
  Element? get element => null;

  @override
  Element? get element2 => null;

  @override
  DartType get extensionTypeErasure => this;

  @override
  String getDisplayString({required bool withNullability}) {
    return '';
  }

  @override
  bool get isBottom => false;

  @override
  bool get isDartAsyncFuture => false;

  @override
  bool get isDartAsyncFutureOr => false;

  @override
  bool get isDartAsyncStream => false;

  @override
  bool get isDartCoreBool => false;

  @override
  bool get isDartCoreDouble => false;

  @override
  bool get isDartCoreEnum => false;

  @override
  bool get isDartCoreFunction => false;

  @override
  bool get isDartCoreInt => false;

  @override
  bool get isDartCoreIterable => false;

  @override
  bool get isDartCoreList => false;

  @override
  bool get isDartCoreMap => false;

  @override
  bool get isDartCoreNull => false;

  @override
  bool get isDartCoreNum => false;

  @override
  bool get isDartCoreObject => false;

  @override
  bool get isDartCoreRecord => false;

  @override
  bool get isDartCoreSet => false;

  @override
  bool get isDartCoreString => false;

  @override
  bool get isDartCoreSymbol => false;

  @override
  bool get isDartCoreType => false;

  @override
  bool get isDynamic => false;

  @override
  bool get isVoid => false;

  @override
  String? get name => '';

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.none;

  @override
  DartType resolveToBound(DartType objectType) {
    return this;
  }
}
