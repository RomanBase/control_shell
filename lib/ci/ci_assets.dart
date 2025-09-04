import 'dart:io';

import 'package:control_shell/shell.dart';

Future<File> buildAssets({String folder = 'assets', String? dir, String name = 'res', List<String> exclude = const []}) async {
  final root = projectLib();
  final res = Directory(path(root.path, [dir ?? name]));

  final assetRoot = projectDir(folder);
  final dirs = await listDirectories(assetRoot);

  final assetsExport = StringBuffer();
  final export = StringBuffer();
  export.writeln('//Generated file: ${DateTime.now()}');

  export.writeln('class ${name[0].toUpperCase()}${name.substring(1)} {');

  int count = 0;
  for (final dir in dirs) {
    if (exclude.contains(dir.name) || dir.name.startsWith('.') || dir.name.startsWith('_')) {
      continue;
    }

    final files = await listFiles(dir, recursive: true);
    final assets = buildAssetList(files, dir, assetRoot.parent);

    if (assets.isNotEmpty) {
      final cName = propertyName(dir.name);
      count++;
      assetsExport.writeln('class _${cName} {');
      assetsExport.writeln('  const _${cName}._();');
      assetsExport.writeln();
      assetsExport.writeln('  String operator [](String value) => \'${folder}/${dir.name}/\${value}\';');
      assetsExport.writeln('}');
      assetsExport.writeln();

      export.writeln('  static const ${cName} = _${cName}._();');
      export.writeln(assets);
    }

    print('build assets: ${dir.path} - ${files.length}');
  }

  export.writeln('}');
  export.writeln();
  export.write(assetsExport);

  final exportFile = File(path(res.path, [name], '.dart'));
  await exportFile.create(recursive: true);
  await exportFile.writeAsString(export.toString(), flush: true);

  print('-------------- ${name} [$count]');

  return exportFile;
}

String buildAssetList(List<File> files, Directory parent, [Directory? relative]) {
  final buffer = StringBuffer();
  final offset = (relative?.path.length ?? -1) + 1;

  for (final element in files) {
    if (element.name.startsWith('.') || element.name.startsWith('_')) {
      continue;
    }

    final relativePath = element.relativePath(offset);
    final file = element.path.substring(parent.path.length + 1);
    String prefix = '';

    if (file.contains(slash)) {
      final split = file.split(slash)..removeLast();
      prefix = '${split.join('_')}_';
    }

    buffer.writeln('  static const ${propertyName(parent.name)}_$prefix${elementName(element.name)} = \'${relativePath}\';');
  }

  return buffer.toString();
}

String elementName(String value) => value.replaceAll(RegExp(r'[-#/\*+!@#$%^&()=,.]'), '_');

String propertyName(String value) {
  value = elementName(value);

  if (value.isNumeric) {
    return 'n_${value}';
  }

  if (value.isKeyword) {
    return '${value}_k';
  }

  return value;
}
