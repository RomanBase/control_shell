import 'dart:io';
import 'package:control_shell/shell.dart';
import 'package:yaml/yaml.dart';

import 'config.dart';

Future<Pubspec> pubspec(ControlShell shell) async {
  return Pubspec._(loadYaml(await File(path(shell.rootShell().path, ['pubspec.yaml'])).readAsString()));
}

class Pubspec {
  final dynamic _data;

  Pubspec._(this._data);

  String get version => _data['version'].toString().split('+')[0];

  int get build => int.tryParse(_data['version'].toString().split('+')[1]) ?? 1;

  Future<int> incrementBuildNumber([int? step]) async {
    print('Base Build Number: $build');
    return (await LocalConfig.read()).incrementBuildNumber(build, step);
  }
}
