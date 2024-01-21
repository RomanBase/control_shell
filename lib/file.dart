import 'dart:async';
import 'dart:io';

import 'platform.dart';

String path(String? root, List<String> path, [String? extension]) {
  root ??= '';

  final output = root + (root.isEmpty || root.endsWith(slash) ? '' : slash) + path.join(slash) + (extension ?? '');

  return onPlatform(win: () => output, mac: () => output.replaceAll('/', slash));
}

Directory projectDir([String? name]) {
  final root = File('').absolute.parent.path;

  if (name == null || name.isEmpty) {
    return Directory(path(root, []));
  }

  return Directory(path(root, [name]));
}

Directory projectLib([String? name]) {
  final root = File('').absolute.parent.path;

  if (name == null || name.isEmpty) {
    return Directory(path(root, ['lib']));
  }

  return Directory(path(root, [name, 'lib']));
}

Directory libDirectory(String name) {
  final root = projectLib().path;

  return Directory(path(root, [name]));
}

File projectFile(String name) {
  final root = File('').absolute.parent.path;

  return File(path(root, [name]));
}

Future<List<Directory>> listDirectories(Directory parent) async {
  final completer = Completer();
  final list = <Directory>[];

  parent.list(recursive: false).listen((event) {
    if (event is Directory) {
      list.add(event);
    }
  }, onDone: () {
    completer.complete();
  });

  await completer.future;

  return list;
}

Future<List<File>> listFiles(Directory parent, [bool recursive = false]) async {
  final completer = Completer();
  final list = <File>[];

  parent.list(recursive: recursive).listen((event) {
    if (event is File) {
      list.add(event);
    }
  }, onDone: () {
    completer.complete();
  });

  await completer.future;

  list.sort((a, b) => a.path.compareTo(b.path));

  return list;
}

String buildExport(List<File> files, [Directory? relative]) {
  final buffer = StringBuffer();
  final offset = (relative?.path.length ?? -1) + 1;

  files.forEach((element) {
    buffer.writeln('export \'${element.relativePath(offset)}\';');
  });

  return buffer.toString();
}

String buildAssetList(List<File> files, [Directory? relative]) {
  final buffer = StringBuffer();
  final offset = (relative?.path.length ?? -1) + 1;

  files.forEach((element) {
    buffer.writeln('  final ${element.name} = \'${element.relativePath(offset)}\';');
  });

  return buffer.toString();
}

extension DirectoryExtension on Directory {
  String get name => this.path.substring(this.path.lastIndexOf(slash) + 1);
}

extension FileExtension on File {
  String get name => this.path.substring(this.path.lastIndexOf(slash) + 1).split('.').first;

  String relativePath(int offset) => this.path.substring(offset).replaceAll('\\', '\/');
}
