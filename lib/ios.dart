import 'dart:convert';
import 'dart:io';

import 'package:control_shell/shell.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

const _buildDir = 'build/ios';

Future<void> buildIpa(
  ControlShell shell, {
  List<String> args = const [],
}) async {
  final config = await LocalConfig.read();
  final buildNumber = config.buildNumber;
  final buildName = config.version;

  final cmd = 'flutter build ipa --build-name $buildName --build-number $buildNumber ${args.join(' ')}';
  await shell.run(cmd);
}

Future<void> buildIOS(ControlShell shell) async {
  final config = await LocalConfig.read();
  final buildNumber = config.buildNumber;
  final buildName = config.version;

  await shell.run('flutter build ios --build-name $buildName --build-number $buildNumber');
}

Future<void> buildArchive(ControlShell shell) async {
  await shell.module('ios').run('xcodebuild -sdk iphoneos -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath ..$_buildDir/archive/Runner.xcarchive archive');
}

Future<void> exportArchive(ControlShell shell) async {
  await shell.module('ios').run('xcodebuild -exportArchive -archivePath ..$_buildDir/archive/Runner.xcarchive -exportPath ..$_buildDir/Runner.ipa -exportOptionsPlist ExportOptions.plist');
}

Future<void> uploadIpa(
  ControlShell shell, {
  String? serviceAccount,
  String dir = '$_buildDir/ipa',
  List<String> args = const [],
}) async {
  serviceAccount ??= (await LocalConfig.read()).appleService;

  if (serviceAccount == null) {
    throw 'Missing service account credentials';
  }

  final config = await getAppleServiceCredentials(serviceAccount);
  final plist = await XmlDocument.parse(await File(path(shell.rootShell().path, [dir, 'DistributionSummary.plist'])).readAsString());
  final name = plist.xpath('plist/dict/key').first.children.first;

  final cmd = 'xcrun altool --upload-app --type ios -f "$dir/$name" ${config.appleKey != null ? '--apiKey ${config.appleKey}' : '-u ${config.appleId}'} ${config.appleIssuer != null ? '--apiIssuer ${config.appleIssuer}' : '-p ${config.applePassword}'} ${args.join(' ')}';
  await shell.run(cmd);
}

Future<AppleServiceCredentials> getAppleServiceCredentials(String serviceAccount) async {
  final json = await File.fromUri(Uri.file(serviceAccount)).readAsString();

  return AppleServiceCredentials(jsonDecode(json));
}

class AppleServiceCredentials {
  final Map<String, dynamic> _data;

  String? get appleId => _data['id'];

  String? get applePassword => _data['password'];

  String? get appleKey => _data['key'];

  String? get appleIssuer => _data['issuer'];

  AppleServiceCredentials(this._data);

  @override
  String toString() => _data.toString();
}
