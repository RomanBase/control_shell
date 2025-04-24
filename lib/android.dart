import 'dart:io';

import 'package:control_shell/shell.dart';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:xml/xml.dart';

///
/// https://developers.google.com/android-publisher
///

String get _path =>
    path('build', ['app', 'outputs', 'bundle', 'release', 'app-release.aab']);

Future<void> buildAppBundle(
  ControlShell shell, {
  Map<String, String> args = const <String, String>{},
}) async {
  final config = await LocalConfig.read();
  final buildNumber = config.buildNumber;
  final buildName = config.version;

  await shell.run(
      'flutter build appbundle --build-name $buildName --build-number $buildNumber ${args.isNotEmpty ? args.entries.map((e) => '--${e.key} ${e.value}').join(' ') : ''}');
}

Future<Client> _client(String serviceAccount) async => clientViaServiceAccount(
      await getGoogleServiceCredentials(serviceAccount),
      [AndroidPublisherApi.androidpublisherScope],
    );

Future<EditsResource> _edits(String serviceAccount) async {
  return AndroidPublisherApi(await _client(serviceAccount)).edits;
}

Future<Map<String, dynamic>> uploadAppBundle(ControlShell shell,
    {String? serviceAccount, String? packageName}) async {
  packageName ??= await packageNameFromArchive(shell);
  serviceAccount ??= (await LocalConfig.read()).googleService;

  if (serviceAccount == null) {
    throw 'Missing service account credentials';
  }

  print('Uploading Bundle: $packageName');

  final edit = await _edits(serviceAccount);
  final editId = await edit.insert(AppEdit(), packageName);

  var bundle = File(path(shell.rootShell().path, [_path]));
  var media = Media(bundle.openRead(), bundle.lengthSync());

  await edit.bundles.upload(
    packageName,
    editId.id!,
    uploadMedia: media,
  );

  final result = await edit.commit(packageName, editId.id!);
  print(result.toJson());

  return result.toJson();
}

//https://developers.google.com/android-publisher/tracks#ff-track-name
Future<Map<String, dynamic>> publish(
  ControlShell shell, {
  String? serviceAccount,
  String? packageName,
  String track = 'alpha',
  Map<String, String> args = const <String, String>{},
}) async {
  packageName ??= await packageNameFromArchive(shell);
  final buildNumber = (await LocalConfig.read()).buildNumber;
  serviceAccount ??= (await LocalConfig.read()).googleService;

  if (serviceAccount == null) {
    throw 'Missing service account credentials';
  }

  print('Publishing Bundle: $packageName To: $track');

  final edit = await _edits(serviceAccount);
  final editId = await edit.insert(AppEdit(), packageName);

  await edit.tracks.update(
    Track(releases: [
      TrackRelease(
        name: buildNumber.toString(),
        versionCodes: [buildNumber.toString()],
        status: 'completed',
      ),
    ]),
    packageName,
    editId.id!,
    track,
  );

  final result = await edit.commit(packageName, editId.id!);
  print(result.toJson());

  return result.toJson();
}

Future<ServiceAccountCredentials> getGoogleServiceCredentials(
    String serviceAccount) async {
  final json = await File.fromUri(Uri.file(serviceAccount)).readAsString();

  return ServiceAccountCredentials.fromJson(json);
}

Future<XmlDocument> manifestFromArchive(String dir,
    {String abb = 'app-release.aab',
    String bundletool = 'bundletool.jar'}) async {
  final aabPath = '$dir/$abb';

  final result = await Process.run(
      'java', ['-jar', bundletool, 'dump', 'manifest', '--bundle=$aabPath']);

  if (result.stderr != null) {
    print(result.stderr);
  }

  return XmlDocument.parse(result.stdout);
}

Future<String> packageNameFromArchive(ControlShell shell,
    {String? dir,
    String abb = 'app-release.aab',
    String bundletool = 'bundletool.jar'}) async {
  dir ??= path(shell.rootShell().path, [
    path('build', ['app', 'outputs', 'bundle', 'release'])
  ]);

  final xml = await manifestFromArchive(dir, abb: abb, bundletool: bundletool);

  try {
    final package = xml.getElement('manifest')!.getAttribute('package')!;

    return package;
  } catch (err) {
    print(xml);
    throw err;
  }
}
