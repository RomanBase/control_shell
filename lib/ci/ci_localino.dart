import 'dart:convert';
import 'dart:io';

import 'package:control_shell/shell.dart';

Future<List<File>> fetchLocalizations(ControlShell shell, {String setup = 'assets/localization/setup.json', List<String>? modules, String? access, String? space, String? project}) async {
  final list = <File>[];

  if (access == null || space == null || project == null) {
    try {
      final localino = jsonDecode(await projectFile(setup).readAsString());
      access ??= localino['access'];
      space ??= localino['space'];
      project ??= localino['project'];
    } catch (err) {
      print('NOT FOUND: $setup not found');
    }
  }

  final args = (access == null || space == null || project == null) ? '' : ' -u $access -sp $space:$project';
  await shell.runInRoot('dart run localino_builder$args');

  final localino = jsonDecode(await projectFile(setup).readAsString());
  final asset = localino['asset'] as String;
  final files = <String>['setup', ...localino['locales'].keys].map((e) => asset.replaceFirst('{locale}', e));

  files.forEach((element) {
    list.add(projectFile(element));
  });

  modules ??= shell.modules;

  if (modules.isEmpty) {
    return list;
  }

  for (final module in shell.modules) {
    print('copy localization data to module: $module');

    for (final file in files) {
      list.add(File(path(module, [file])));
      await shell.runInRoot('${cmd.copy} ${path(null, [file])} ${path(module, [file])}');
    }
  }

  return list;
}

Future<File> buildResourceProvider({String? dir, String name = 'localize', String setup = 'assets/localization/setup.json'}) async {
  final root = projectLib();
  final res = Directory(path(root.path, [dir ?? name]));

  final localino = jsonDecode(await projectFile(setup).readAsString());
  final locale = localino['locales'].keys.first;
  final data = jsonDecode(await projectFile(localino['asset'].replaceFirst('{locale}', locale)).readAsString()) as Map;

  final className = '${name[0].toUpperCase()}${name.substring(1)}';
  final classKeyName = '${className}Key';

  final export = StringBuffer();
  export.writeln('import \'package:localino/localino.dart\';');
  export.writeln();
  export.writeln('//Generated file: ${DateTime.now()}');
  export.writeln('//Localino: https://localino.app/#/project/${localino['space']}/${localino['project']}');

  export.writeln('class $classKeyName {');
  export.writeln('  $classKeyName._();');
  export.writeln();

  int count = 0;
  for (final item in data.entries) {
    count++;

    export.writeln('  static const ${item.key} = \'${item.key}\';');
  }

  export.writeln('}');
  export.writeln();
  export.writeln('class $className {');
  export.writeln('  Localize._();');
  export.writeln();
  export.writeln('  static Localino get _instance => LocalinoProvider.instance;');
  export.writeln();
  export.writeln('  static String i(String key) => _instance.localize(key);');
  export.writeln();

  for (final item in data.entries) {
    if (item.value is String) {
      final args = _getArgsFromString(item.value);
      if (args.length == 0) {
        export.writeln('  static String get ${item.key} => _instance.localize(${classKeyName}.${item.key});');
      } else {
        print(args);
        export.writeln('  static String ${item.key}({${args.map((e) => 'dynamic $e').join(', ')}}) => _instance.localizeFormat(${classKeyName}.${item.key}, {${args.map((e) => '\'$e\': $e').join(', ')}});');
      }
    } else if (item.value is Map) {
      if ((item.value as Map).keys.every((element) => int.tryParse('$element') != null)) {
        final args = _getArgs(item.value);
        final argsProperty = args.isEmpty ? '' : ', {${args.map((e) => 'dynamic $e').join(', ')}}';
        final argsValues = args.isEmpty ? '' : ', {${args.map((e) => '\'$e\': $e').join(', ')}}';
        export.writeln('  static String ${item.key}(int plural$argsProperty) => _instance.localizePlural(${classKeyName}.${item.key}, plural$argsValues);');
      } else {
        export.writeln('  static String ${item.key}(String value) => _instance.localizeValue(${classKeyName}.${item.key}, value);');
      }
    } else if (item.value is List) {
      export.writeln('  static Iterable<String> get ${item.key} => _instance.localizeList(${classKeyName}.${item.key});');
    }
  }

  export.writeln('}');

  final exportFile = File(path(res.path, [name], '.dart'));
  await exportFile.create(recursive: true);
  await exportFile.writeAsString(export.toString(), flush: true);

  print('-------------- ${name} [$count]');

  return exportFile;
}

Iterable<String> _getArgs(dynamic value) {
  if (value is Map) {
    value = value.values;
  }

  if (value is Iterable) {
    return value.map((e) => _getArgsFromString(e)).fold([], (a, b) => [...a, ...b]);
  }

  return _getArgsFromString(value);
}

Iterable<String> _getArgsFromString(String value) => RegExp(r'{\w+}').allMatches(value).map((e) => e.group(0)).map((e) => e!.substring(1, e.length - 1));
