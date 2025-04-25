import 'package:control_shell/shell.dart';

Future<void> distributeIpa(
  ControlShell shell, {
  bool dryRun = false,
  List<String> buildArgs = const [],
  List<String> deployArgs = const [],
}) async {
  final timestamp = DateTime.now();

  await buildIpa(shell, args: buildArgs);

  if (dryRun) {
    final serviceAccount = (await LocalConfig.read()).appleService;
    final service = await getAppleServiceCredentials(serviceAccount!);
    print(service);
  } else {
    await uploadIpa(shell, args: deployArgs);
  }

  timestampDuration('iOS Build Ready | ${shell.rootShell().path}', timestamp);
}

Future<void> distributeAppBundle(
  ControlShell shell, {
  String track = 'alpha',
  bool dryRun = false,
  List<String> buildArgs = const [],
}) async {
  final timestamp = DateTime.now();

  await buildAppBundle(shell, args: buildArgs);

  if (dryRun) {
    final serviceAccount = (await LocalConfig.read()).googleService;
    final service = await getGoogleServiceCredentials(serviceAccount!);
    print(service);
  } else {
    await uploadAppBundle(shell);
    await publish(shell, track: track);
  }

  timestampDuration('Android Build Ready | ${shell.rootShell().path}', timestamp);
}
