import 'dart:io';

import 'package:ci/ci.dart' as ci;
import 'package:control_shell/ci/ci_package.dart' as pck;
import 'package:control_shell/ci/ci_git.dart' as git;
import 'package:control_shell/shell.dart';

const _app = ['app'];
const _libs = ['core', 'presentation'];
const _modular = ['modules', 'platforms'];

void main(List<String> args) async {
  await ci.runAsync(
    'directory libs',
    (shell) => pck.buildProjectLibs(
      exclude: [
        ..._app,
        ..._libs,
        ..._modular,
      ],
      provider: false,
    ).then((value) => git.addFiles(shell, value)),
  );

  for (final lib in _libs) {
    await ci.runAsync(
      '$lib lib',
      (shell) => pck
          .buildLib(
            directory: libDirectory(lib),
            provider: true,
          )
          .then((value) => git.addFiles(shell, value)),
    );
  }

  for (final module in _modular) {
    await ci.runAsync(
      '$module libs',
      (shell) => pck
          .buildModuleLibs(
            directory: libDirectory(module),
            provider: true,
          )
          .then((value) => git.addFiles(shell, value)),
    );
  }
}

void buildPck(Directory directory) {
  Directory dir = _parent(directory, 'lib');

  print(dir.name);

  if (_modular.contains(dir.name)) {
    if (!_modular.contains(directory.name)) {
      dir = _parent(directory, dir.name);
    } else {
      return;
    }
  }

  if (dir.name == 'lib' || dir.name == 'app') {
    return;
  }

  ci.runAsync(
    '${dir.name} lib',
    (shell) => pck
        .buildLib(
          directory: dir,
          provider: _libs.contains(dir.name) || _modular.contains(dir.name),
        )
        .then((value) => value.forEach((element) => element.addToGit(shell))),
  );
}

Directory _parent(Directory dir, String name) {
  if (dir.name == name) {
    return dir;
  }

  if (dir.parent.name == name) {
    return dir;
  }

  return _parent(dir.parent, name);
}
