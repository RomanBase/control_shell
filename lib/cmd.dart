import 'platform.dart';

typedef cmd = _Cmd;

class _Cmd {
  static final ls = onPlatform(win: () => 'dir', mac: () => 'ls');
  static final copy = onPlatform(win: () => 'copy', mac: () => 'cp');
  static final clean = 'flutter clean';
  static final pub_get = 'flutter pub get';
  static final pub_upgrade = 'flutter pub upgrade';
  static final publish_library = 'echo "y" | flutter pub publish';

  static final analyze = 'dart analyze .';
  static final format = 'dart format .';

  static final build_runner = ' dart run build_runner build';
}
