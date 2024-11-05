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

Future<List<File>> listFiles(Directory parent, {bool recursive = false, List<String> exclude = const []}) async {
  final completer = Completer();
  final list = <File>[];

  parent.list(recursive: recursive).listen((event) {
    if (event is File && !exclude.any((value) => event.name == value || _hasMatch(value, event.path))) {
      list.add(event);
    }
  }, onDone: () {
    completer.complete();
  });

  await completer.future;

  list.sort((a, b) => a.path.compareTo(b.path));

  return list;
}

Directory parentDir(Directory dir, String name) {
  if (dir.name == name) {
    return dir;
  }

  if (dir.parent.name == name) {
    return dir;
  }

  return parentDir(dir.parent, name);
}

extension DirectoryExtension on Directory {
  String get name => this.path.substring(this.path.lastIndexOf(slash) + 1);
}

extension FileExtension on File {
  String get name => this.path.substring(this.path.lastIndexOf(slash) + 1).split('.').first;

  String relativePath(int offset) => this.path.substring(offset).replaceAll('\\', '\/');
}

bool _hasMatch(String regex, String value) => _isRegex(regex) && RegExp(regex).hasMatch(value);

bool _isRegex(String value) => ['^', '*', '|', '{', '}', '[', ']', '<', '>', '+', '-', '=', '\$', '?', '!'].any((c) => value.contains(c));
