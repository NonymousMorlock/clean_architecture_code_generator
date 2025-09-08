
import 'clean_arch_cli.dart';

export 'package:args/args.dart';
export 'package:mason_logger/mason_logger.dart';

abstract class Command {
  Command(this.logger);
  
  final Logger logger;
  
  String get name;
  String get description;
  ArgParser get argParser;
  
  Future<void> run(ArgResults results);
}
