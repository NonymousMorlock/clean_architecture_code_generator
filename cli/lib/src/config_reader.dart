import 'dart:io';
import 'package:yaml/yaml.dart';

/// A lightweight utility to read configuration from clean_arch_config.yaml.
class ConfigReader {
  /// Reads the multi_file_output: enabled setting from the config file.
  static bool isMultiFileEnabled(String projectPath) {
    try {
      final configFile = File('$projectPath/clean_arch_config.yaml');
      if (!configFile.existsSync()) {
        return false;
      }

      final yamlString = configFile.readAsStringSync();
      final yamlMap = loadYaml(yamlString) as Map?;
      if (yamlMap == null) return false;

      final multiFileOutput = yamlMap['multi_file_output'] as Map?;
      if (multiFileOutput == null) return false;

      return multiFileOutput['enabled'] == true;
    } on Exception catch (_) {
      return false;
    }
  }
}
