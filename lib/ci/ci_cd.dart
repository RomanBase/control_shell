import 'package:control_shell/shell.dart';

Future<void> distributeIpa(ControlShell shell, {bool dryRun = false}) async {
  final timestamp = DateTime.now();

  await buildIpa(shell);

  if (dryRun) {
    final serviceAccount = (await LocalConfig.read()).appleService;
    final service = await getAppleServiceCredentials(serviceAccount!);
    print(service);
  } else {
    await uploadIpa(shell);
  }

  timestampDuration('iOS Build Ready | ${shell.rootShell().path}', timestamp);
}

Future<void> distributeAppBundle(ControlShell shell, {String track = 'alpha', bool dryRun = false}) async {
  final timestamp = DateTime.now();

  await buildAppBundle(shell);
  await uploadAppBundle(shell);

  if (dryRun) {
    final serviceAccount = (await LocalConfig.read()).googleService;
    final service = await getGoogleServiceCredentials(serviceAccount!);
    print(service);
  } else {
    await publish(shell, track: track);
  }

  timestampDuration('Android Build Ready | ${shell.rootShell().path}', timestamp);
}
