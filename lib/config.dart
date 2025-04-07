import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

File get _file => File.fromUri(Uri.file('local_config.yaml'));

class LocalConfig {
  final YamlMap _data;

  int? _buildNumber;

  int get buildNumber => _buildNumber ?? _data['build'] ?? 1;

  String? _version;

  String get version => _version ?? _data['version'] ?? '0.0.1';

  String? get appleService => _data['apple'];

  String? get googleService => _data['google'];

  LocalConfig._(this._data);

  static Future<LocalConfig> read() async {
    if (await _file.exists()) {
      final data = await _file.readAsString();

      return LocalConfig._(loadYaml(data));
    }

    return LocalConfig._(YamlMap());
  }

  Future<int> incrementBuildNumber([int? base, int? step]) async {
    if (base != null && base > buildNumber) {
      _buildNumber = base;
    } else {
      _buildNumber = buildNumber;
    }

    _buildNumber = buildNumber + (step ?? 1);

    await _save();

    print('Next Build Number: $buildNumber');

    return buildNumber;
  }

  Future<String> incrementBuildName({String? override, int major = 0, int minor = 0, int patch = 0}) async {
    if (override != null) {
      _version = version;
    } else {
      final parts = version.split('.').map((e) => int.parse(e)).toList();
      final digits = List.generate(3, (i) => parts.length > i ? parts[i] : 0);
      digits[0] += major;
      digits[1] += minor;
      digits[2] += patch;

      _version = digits.join('.');
    }

    await _save();
    print('Next Build Name: $version');

    return version;
  }

  Future<void> _save() async {
    await _file.writeAsString(YamlWriter().write({
      ..._data.value,
      'version': _version,
      'build': _buildNumber,
    }));
  }

  @override
  String toString() => _data.toString();
}
