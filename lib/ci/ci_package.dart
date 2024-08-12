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
    final files = await listFiles(dir, recursive: true, exclude: exclude);
    final export = buildExport(files, root);

    final exportFile = File(path(pck.path, [dir.name], '.dart'));
    await exportFile.create(recursive: true);
    await exportFile.writeAsString(export, flush: true);

    print('build package: ${exportFile.path}');
  }
  print('-------------- ${pck.path} [$count]');
}

Future<List<File>> buildLib({Directory? directory, String? name, bool provider = false, List<String> exclude = const [], String suffix = '_provider'}) async {
  final list = <File>[];

  directory ??= projectLib();
  name ??= directory.name;

  final files = await listFiles(directory, recursive: true, exclude: exclude);
  files.removeWhere((element) => element.name == name || element.name == '$name$suffix');
  final export = buildExport(files, directory, provider ? name : null, suffix);

  final exportFile = File(path(directory.path, [name], '.dart'));

  if (provider) {
    final providerFile = File(path(directory.path, [name], '$suffix.dart'));

    if (!await providerFile.exists()) {
      list.add(providerFile);

      await providerFile.create(recursive: true);
      await providerFile.writeAsString('import \'$name.dart\';', flush: true);
    }
  }

  if (!exportFile.existsSync()) {
    list.add(exportFile);

    await exportFile.create(recursive: true);
  }

  await exportFile.writeAsString(export, flush: true);

  print('build lib module: ${exportFile.path}');

  return list;
}

Future<List<File>> buildModuleLibs({required Directory directory, List<String> exclude = const [], bool provider = false, String suffix = '_provider'}) async {
  final list = <File>[];

  final dirs = await listDirectories(directory);

  for (final dir in dirs) {
    if (exclude.contains(dir.name)) {
      continue;
    }

    final files = await buildLib(
      directory: dir,
      provider: provider,
      suffix: suffix,
      exclude: exclude,
    );

    if (files.isNotEmpty) {
      list.addAll(files);
    }
  }

  return list;
}

Future<List<File>> buildProjectLibs({String? project, List<String> exclude = const [], bool provider = false, String suffix = '_provider'}) async {
  final list = <File>[];

  final root = projectLib(project);
  final dirs = await listDirectories(root);

  for (final dir in dirs) {
    if (exclude.contains(dir.name)) {
      continue;
    }

    final files = await buildLib(
      directory: dir,
      provider: provider,
      suffix: suffix,
      exclude: exclude,
    );

    if (files.isNotEmpty) {
      list.addAll(files);
    }
  }

  return list;
}

String buildExport(List<File> files, [Directory? relative, String? library, String suffix = '_provider']) {
  final buffer = StringBuffer();
  final offset = (relative?.path.length ?? -1) + 1;

  if (library != null) {
    buffer.writeln('export \'$library$suffix.dart\';');
  }

  files.forEach((element) {
    buffer.writeln('export \'${element.relativePath(offset)}\';');
  });

  return buffer.toString();
}
