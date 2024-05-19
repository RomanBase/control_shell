import 'dart:io';

final slash = onPlatform(win: () => '\\', mac: () => '\/');

T onPlatform<T>({required T Function() win, required T Function() mac}) => Platform.isWindows ? win() : mac();

extension StringExt on String {
  bool get isNumeric {
    RegExp _numeric = RegExp(r'^-?[0-9]+$');
    return _numeric.hasMatch(this);
  }

  bool get isKeyword => _platform_keywords.contains(this);
}

//https://dart.dev/language/keywords
const _platform_keywords = [
  'assert',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'do',
  'else',
  'enum',
  'extends',
  'false',
  'final',
  'finally',
  'for',
  'if',
  'in',
  'is',
  'new',
  'null',
  'rethrow',
  'return',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'try',
  'var',
  'void',
  'with',
  'while',
];
