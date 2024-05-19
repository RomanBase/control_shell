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
    if (exclude.contains(dir.name)) {
      continue;
    }

    final files = await listFiles(dir, true);
    final assets = buildAssetList(files, dir, assetRoot.parent);

    if (assets.isNotEmpty) {
      count++;
      assetsExport.writeln('class _${dir.name} {');
      assetsExport.writeln('  const _${dir.name}._();');
      assetsExport.writeln();
      assetsExport.writeln('  String operator [](String value) => \'${folder}/${dir.name}/\${value}\';');
      assetsExport.writeln();
      assetsExport.write(assets);
      assetsExport.writeln('}');
      assetsExport.writeln();

      export.writeln('  static const ${dir.name} = _${dir.name}._();');
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

  files.forEach((element) {
    final relativePath = element.relativePath(offset);
    final file = element.path.substring(parent.path.length + 1);
    String prefix = '';

    if (file.contains(slash)) {
      final split = file.split(slash)..removeLast();
      prefix = '${split.join('_')}_';
    }

    buffer.writeln('  final $prefix${propertyName(element.name)} = \'${relativePath}\';');
  });

  return buffer.toString();
}

String propertyName(String value) {
  if (value.isNumeric) {
    return 'n_${value}';
  }

  if (value.isKeyword) {
    return '${value}_k';
  }

  return value;
}
