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
    final assets = buildAssetList(files, assetRoot.parent);

    if (assets.isNotEmpty) {
      count++;
      assetsExport.writeln('class _${dir.name} {');
      assetsExport.writeln('  const _${dir.name}._();');
      assetsExport.writeln();
      assetsExport.writeln('  String operator[](String value) => \'${folder}/${dir.name}/\${value}\';');
      assetsExport.writeln();
      assetsExport.writeln(assets);
      assetsExport.write('}');

      export.writeln('  static const ${dir.name} = _${dir.name}._();');
    }

    print('build assets: ${dir.path} - ${files.length}');
  }

  export.writeln('}');
  export.writeln();
  export.writeln(assetsExport);

  final exportFile = File(path(res.path, [name], '.dart'));
  await exportFile.create(recursive: true);
  await exportFile.writeAsString(export.toString(), flush: true);

  print('-------------- ${name} [$count]');

  return exportFile;
}
