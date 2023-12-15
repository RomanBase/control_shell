import 'dart:io';

import 'package:control_cli/shell.dart';

Future<void> buildPackage({String? project, String name = 'package', List<String> exclude = const []}) async {
  final root = projectLib(project);
  final pck = Directory(path(root.path, [name]));
  final dirs = await listDirectories(root);

  if (pck.existsSync()) {
    await pck.delete(recursive: true);
  }

  print('clean package: ${project ?? 'root'}');
  int count = 0;
  for (final dir in dirs) {
    if (dir.path == pck.path || exclude.contains(dir.name)) {
      continue;
    }

    count++;
    final files = await listFiles(dir, true);
    final export = buildExport(files, root);

    final exportFile = File(path(pck.path, [dir.name], '.dart'));
    await exportFile.create(recursive: true);
    await exportFile.writeAsString(export, flush: true);

    print('build package: ${exportFile.path}');
  }
  print('-------------- ${pck.path} [$count]');
}
