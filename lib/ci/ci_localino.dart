import 'dart:convert';
import 'dart:io';

import 'package:control_cli/shell.dart';

Future<void> runLocalinoBuilder(ControlShell shell, [String setup = 'assets/localization/setup.json', List<String>? modules]) async {
  await shell.runInRoot('dart run localino_builder');

  modules ??= shell.modules;

  if (modules.isEmpty) {
    return;
  }

  final localino = jsonDecode(await File(setup).readAsString());
  final asset = localino['asset'] as String;
  final files = <String>['setup', ...localino['locales'].keys];

  for (final module in shell.modules) {
    print('copy localization data to module: $module');

    for (final file in files) {
      final filePath = asset.replaceFirst('{locale}', file);
      await shell.runInRoot('${cmd.copy} ${path(null, [filePath])} ${path(module, [filePath])}');
    }
  }
}
