import 'package:process_run/shell.dart';

export 'cmd.dart';
export 'platform.dart';
export 'file.dart';

ControlShell root({String? path, List<String> modules = const []}) => ControlShell._(path == null ? Shell() : Shell().cd(path), modules);

class ControlShell {
  final Shell _shell;

  final List<String> modules;

  const ControlShell._(this._shell, this.modules);

  ControlShell module(String name) => ControlShell._(moduleShell(name), []);

  Shell rootShell() => _shell;

  Shell moduleShell(String name) => _shell.cd(name);

  Future _proceedModules(Future Function(Shell sh) func) async {
    for (var value in modules) {
      await func.call(moduleShell(value));
    }
  }

  Future call(String script) => run(script);

  Future run(String script, {bool root = true, bool modules = true}) async {
    if (root) {
      await rootShell().run(script);
    }

    if (modules) {
      await _proceedModules((sh) => sh.run(script));
    }
  }

  Future runInRoot(String script) => run(script, root: true, modules: false);

  Future runInModules(String script) => run(script, root: false, modules: true);

  void runSync(dynamic parent, void Function() action) {
    print('CI $parent --- START');
    action();
    print('CI $parent --- END');
  }

  Future<void> runAsync(dynamic parent, Future<void> Function() action) async {
    final timestamp = DateTime.now();
    print('CI $parent --- START');
    await action();
    final duration = DateTime.now().difference(timestamp);
    final inSec = duration.inSeconds > 0;
    print('CI $parent --- END | ${inSec ? duration.inSeconds : duration.inMilliseconds} ${inSec ? 'sec' : 'ms'}');
  }
}
