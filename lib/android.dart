import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:control_shell/shell.dart';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';

import 'config.dart';

///
/// https://developers.google.com/android-publisher
///

String get _path => path('build', ['app', 'outputs', 'bundle', 'release', 'app-release.aab']);

Future<void> buildAppBundle(ControlShell shell) async {
  final buildNumber = (await LocalConfig.read()).buildNumber;

  await shell.run('flutter build appbundle --build-number $buildNumber');
}

Future<Client> _client(String serviceAccount) async => clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(await File.fromUri(Uri.file(serviceAccount)).readAsString()),
      [AndroidPublisherApi.androidpublisherScope],
    );

Future<EditsResource> _edits(String serviceAccount) async {
  return AndroidPublisherApi(await _client(serviceAccount)).edits;
}

Future<Map<String, dynamic>> uploadAppBundle(ControlShell shell, {String? serviceAccount, String? packageName}) async {
  packageName ??= await _packageNameFromArchive(shell);
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
Future<Map<String, dynamic>> publish(ControlShell shell, {String? serviceAccount, String? packageName, String track = 'alpha'}) async {
  packageName ??= await _packageNameFromArchive(shell);
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

Future<String> _packageNameFromArchive(ControlShell shell) async {
  final bytes = File(path(shell.rootShell().path, [_path])).readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes);
  final manifest = archive.firstWhere((value) => value.name.endsWith('AndroidManifest.xml'));
  final content = String.fromCharCodes(manifest.content);

  //just quickly read package name - we don't need to decompress manifest.
  final declaration = LineSplitter.split(content).elementAt(4);

  return declaration.split('"')[0];
}
