import 'package:control_shell/shell.dart';

Future<void> distributeIpa(ControlShell shell) async {
  final timestamp = DateTime.now();

  await buildIpa(shell);
  await uploadIpa(shell);

  timestampDuration('iOS Build Ready | ${shell.rootShell().path}', timestamp);
}

Future<void> distributeAppBundle(ControlShell shell, [String track = 'alpha']) async {
  final timestamp = DateTime.now();

  await buildAppBundle(shell);
  await uploadAppBundle(shell);
  await publish(shell, track: track);

  timestampDuration('Android Build Ready | ${shell.rootShell().path}', timestamp);
}
