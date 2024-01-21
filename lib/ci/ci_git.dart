import 'dart:io';

import 'package:control_shell/shell.dart';

void add(ControlShell shell, String path) {
  shell.runInRoot('git add $path');
}

void addFile(ControlShell shell, File file) => add(shell, file.path);

void addFiles(ControlShell shell, Iterable<File> files) => files.forEach((element) => add(shell, element.path));

extension FileGitExt on File {
  void addToGit(ControlShell shell) => addFile(shell, this);
}
