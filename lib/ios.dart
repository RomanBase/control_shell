import 'dart:convert';
import 'dart:io';

import 'package:control_shell/shell.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

import 'config.dart';

const _buildDir = 'build/ios';

Future<void> buildIpa(ControlShell shell) async {
  final buildNumber = (await LocalConfig.read()).buildNumber;

  await shell.run('flutter build ipa --build-number $buildNumber');
}

Future<void> uploadIpa(ControlShell shell, {String? serviceAccount, String dir = '$_buildDir/ipa'}) async {
  serviceAccount ??= (await LocalConfig.read()).appleService;

  if (serviceAccount == null) {
    throw 'Missing service account credentials';
  }

  final config = await _getConfig(serviceAccount);
  final plist = await XmlDocument.parse(await File(path(shell.rootShell().path, [dir, 'DistributionSummary.plist'])).readAsString());
  final name = plist.xpath('plist/dict/key').first.children.first;

  await shell.run('xcrun altool --upload-app --type ios -f "$dir/$name" ${config.appleKey != null ? '--apiKey ${config.appleKey}' : '-u ${config.appleId}'} ${config.appleIssuer != null ? '--apiIssuer ${config.appleIssuer}' : '-p ${config.applePassword}'}');
}

Future<void> buildArchive(ControlShell shell) async {
  await shell.module('ios').run('xcodebuild -sdk iphoneos -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath ..$_buildDir/archive/Runner.xcarchive archive');
}

Future<void> exportArchiveOptions(ControlShell shell) async {
  throw ('TODO');
}

Future<void> exportArchive(ControlShell shell) async {
  await shell.module('ios').run('xcodebuild -exportArchive -archivePath ..$_buildDir/archive/Runner.xcarchive -exportPath ..$_buildDir/Runner.ipa -exportOptionsPlist ExportOptions.plist');
}

Future<AppleServiceCredentials> _getConfig(String serviceAccount) async {
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
}
