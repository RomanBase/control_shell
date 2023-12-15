import 'dart:io';

final slash = onPlatform(win: () => '\\', mac: () => '\/');

T onPlatform<T>({required T Function() win, required T Function() mac}) => Platform.isWindows ? win() : mac();
