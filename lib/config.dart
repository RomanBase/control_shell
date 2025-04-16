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

  String? get env => _data['env'];

  String? get appleService => _envPath('apple');

  String? get googleService => _envPath('google');

  LocalConfig._(this._data);

  static Future<bool> check() async {
    final config = await LocalConfig.read();

    if (config.appleService == null) {
      throw 'Missing Apple service credentials';
    }

    if (config.googleService == null) {
      throw 'Missing Google service credentials';
    }

    final apple = await File.fromUri(Uri.file(config.appleService!)).readAsString();
    final google = await File.fromUri(Uri.file(config.googleService!)).readAsString();

    return apple.isNotEmpty && google.isNotEmpty;
  }

  static Future<LocalConfig> read() async {
    if (await _file.exists()) {
      final data = await _file.readAsString();

      return LocalConfig._(loadYaml(data));
    }

    return LocalConfig._(YamlMap());
  }

  String? _envPath(String service) {
    if (!_data.containsKey(service)) {
      return null;
    }

    if (_data.containsKey('env')) {
      return '$env/${_data[service]}';
    }

    return _data[service];
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

  Future<String> incrementBuildName({String? base, String? override, int major = 0, int minor = 0, int patch = 0}) async {
    if (override != null) {
      _version = version;
    } else {
      final versions = [base ?? '0.0.0', version];
      versions.sort();
      _version = versions.last;

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
      'version': version,
      'build': buildNumber,
    }));
  }

  @override
  String toString() => _data.toString();
}
