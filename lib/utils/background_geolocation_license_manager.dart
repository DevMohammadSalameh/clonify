import 'dart:io';

import 'package:clonify/constants.dart';
import 'package:clonify/utils/clonify_helpers.dart';

const backgroundGeolocationLicenseAndroidKey =
    'backgroundGeolocationLicenseAndroid';
const backgroundGeolocationLicenseIosKey = 'backgroundGeolocationLicenseIos';

const androidLicenseMetaName = 'com.transistorsoft.locationmanager.license';
const iosLicensePlistKey = 'TSLocationManagerLicense';

/// Writes flutter_background_geolocation JWT licenses into native project files
/// when present on the active clone config.
///
/// Android → `android/app/src/main/AndroidManifest.xml`
/// iOS → `ios/Runner/Info.plist`
Future<void> applyBackgroundGeolocationLicenses(
  Map<String, dynamic> configJson,
) async {
  final androidLicense =
      (configJson[backgroundGeolocationLicenseAndroidKey] as String?)?.trim();
  final iosLicense = (configJson[backgroundGeolocationLicenseIosKey] as String?)
      ?.trim();

  if ((androidLicense == null || androidLicense.isEmpty) &&
      (iosLicense == null || iosLicense.isEmpty)) {
    return;
  }

  if (androidLicense != null && androidLicense.isNotEmpty) {
    await applyAndroidBackgroundGeolocationLicense(androidLicense);
  }
  if (iosLicense != null && iosLicense.isNotEmpty) {
    await applyIosBackgroundGeolocationLicense(iosLicense);
  }
}

Future<void> applyAndroidBackgroundGeolocationLicense(String license) async {
  final file = File(Constants.androidMainManifestFilePath);
  if (!file.existsSync()) {
    logger.w(
      '⚠️  ${Constants.androidMainManifestFilePath} not found; skipped BG Geo Android license.',
    );
    return;
  }

  var content = await file.readAsString();
  final metaRegex = RegExp(
    r'<meta-data\s+android:name="com\.transistorsoft\.locationmanager\.license"[^/]*/>',
    multiLine: true,
  );
  final metaBlock =
      '''
        <meta-data
            android:name="$androidLicenseMetaName"
            android:value="$license" />''';

  if (metaRegex.hasMatch(content)) {
    content = content.replaceFirst(metaRegex, metaBlock.trim());
  } else if (content.contains('</application>')) {
    content = content.replaceFirst(
      '</application>',
      '$metaBlock\n    </application>',
    );
  } else {
    logger.w('⚠️  Could not locate </application> in AndroidManifest.xml');
    return;
  }

  await file.writeAsString(content);
  logger.i('✅ Background Geolocation Android license applied');
}

Future<void> applyIosBackgroundGeolocationLicense(String license) async {
  final file = File(Constants.iosInfoPlistFilePath);
  if (!file.existsSync()) {
    logger.w(
      '⚠️  ${Constants.iosInfoPlistFilePath} not found; skipped BG Geo iOS license.',
    );
    return;
  }

  var content = await file.readAsString();
  final keyRegex = RegExp(
    r'<key>TSLocationManagerLicense</key>\s*<string>[^<]*</string>',
    multiLine: true,
  );
  final keyBlock =
      '<key>$iosLicensePlistKey</key>\n\t\t<string>$license</string>';

  if (keyRegex.hasMatch(content)) {
    content = content.replaceFirst(keyRegex, keyBlock);
  } else if (content.contains('</dict>')) {
    content = content.replaceFirst('</dict>', '\t\t$keyBlock\n\t</dict>');
  } else {
    logger.w('⚠️  Could not locate </dict> in Info.plist');
    return;
  }

  await file.writeAsString(content);
  logger.i('✅ Background Geolocation iOS license applied');
}
