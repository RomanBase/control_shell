import 'dart:io';

import 'package:control_shell/shell.dart';

Future<void> buildPackages({String? project, String name = 'package', List<String> exclude = const []}) async {
  final root = projectLib(project);
  final pck = Directory(path(root.path, [name]));
  final dirs = await listDirectories(root);

  if (pck.existsSync()) {
    print('clean package: ${project ?? 'root'}');
    await pck.delete(recursive: true);
  }

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

Future<File?> buildLib({Directory? directory, String? name}) async {
  File? output;
  directory ??= projectLib();
  name ??= directory.name;

  final files = await listFiles(directory, true);
  files.removeWhere((element) => element.name == name);
  final export = buildExport(files, directory);

  final exportFile = File(path(directory.path, [name], '.dart'));

  if (!exportFile.existsSync()) {
    output = exportFile;
    await exportFile.create(recursive: true);
  }

  await exportFile.writeAsString(export, flush: true);

  print('build lib module: ${exportFile.path}');

  return output;
}

Future<List<File>> buildModuleLibs({required Directory directory, List<String> exclude = const []}) async {
  final list = <File>[];

  final dirs = await listDirectories(directory);

  for (final dir in dirs) {
    if (exclude.contains(dir.name)) {
      continue;
    }

    final file = await buildLib(directory: dir);

    if (file != null) {
      list.add(file);
    }
  }

  return list;
}

Future<List<File>> buildProjectLibs({String? project, List<String> exclude = const []}) async {
  final list = <File>[];

  final root = projectLib(project);
  final dirs = await listDirectories(root);

  for (final dir in dirs) {
    if (exclude.contains(dir.name)) {
      continue;
    }

    final file = await buildLib(directory: dir);

    if (file != null) {
      list.add(file);
    }
  }

  return list;
}
