#!/usr/bin/env dart

import 'package:args/args.dart';
import 'package:clean_arch_cli/commands/generate_command.dart';
import 'package:clean_arch_cli/commands/init_command.dart';
import 'package:clean_arch_cli/commands/create_command.dart';
import 'package:mason_logger/mason_logger.dart';

void main(List<String> arguments) async {
  final logger = Logger();
  
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage help',
      negatable: false,
    )
    ..addFlag(
      'version',
      abbr: 'v',
      help: 'Show version',
      negatable: false,
    );

  final subCommands = <String, Command>{
    'init': InitCommand(logger),
    'generate': GenerateCommand(logger),
    'create': CreateCommand(logger),
  };

  for (final command in subCommands.values) {
    parser.addCommand(command.name, command.argParser);
  }

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _showUsage(parser, subCommands);
      return;
    }

    if (results['version'] as bool) {
      logger.info('Clean Architecture Code Generator CLI v1.0.0');
      return;
    }

    if (results.command == null) {
      logger.err('No command specified');
      _showUsage(parser, subCommands);
      return;
    }

    final commandName = results.command!.name;
    final command = subCommands[commandName];
    
    if (command == null) {
      logger.err('Unknown command: $commandName');
      _showUsage(parser, subCommands);
      return;
    }

    await command.run(results.command!);
  } catch (e) {
    logger.err('Error: $e');
  }
}

void _showUsage(ArgParser parser, Map<String, Command> subCommands) {
  print('Usage: clean_arch_cli <command> [options]');
  print('');
  print('Available commands:');
  for (final command in subCommands.values) {
    print('  ${command.name.padRight(12)} ${command.description}');
  }
  print('');
  print('Global options:');
  print(parser.usage);
  print('');
  print('Run "clean_arch_cli <command> --help" for more information about a command.');
}

abstract class Command {
  Command(this.logger);
  
  final Logger logger;
  
  String get name;
  String get description;
  ArgParser get argParser;
  
  Future<void> run(ArgResults results);
}
