import 'package:control_shell/ci/ci_args.dart';
import 'package:control_shell/shell.dart';

Future<void> distributeIpa(
  ControlShell shell, {
  bool dryRun = false,
  Args args = const Args.empty(),
}) async {
  final timestamp = DateTime.now();

  await buildIpa(
    shell,
    args: args.build,
  );

  if (dryRun) {
    final serviceAccount = (await LocalConfig.read()).appleService;
    final service = await getAppleServiceCredentials(serviceAccount!);
    print(service);
  } else {
    await uploadIpa(
      shell,
      args: args.deploy,
    );
  }

  timestampDuration('iOS Build Ready | ${shell.rootShell().path}', timestamp);
}

Future<void> distributeAppBundle(
  ControlShell shell, {
  String track = 'alpha',
  bool dryRun = false,
  Args args = const Args.empty(),
}) async {
  final timestamp = DateTime.now();

  await buildAppBundle(
    shell,
    args: args.build,
  );

  if (dryRun) {
    final serviceAccount = (await LocalConfig.read()).googleService;
    final service = await getGoogleServiceCredentials(serviceAccount!);
    print(service);
  } else {
    await uploadAppBundle(shell);
    await publish(
      shell,
      track: track,
      args: args.deploy,
    );
  }

  timestampDuration(
      'Android Build Ready | ${shell.rootShell().path}', timestamp);
}
