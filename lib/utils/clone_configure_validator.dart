import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clonify/constants.dart';
import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/android_signing_manager.dart';
import 'package:clonify/utils/background_geolocation_license_manager.dart';
import 'package:clonify/utils/notification_icon_manager.dart';
import 'package:path/path.dart' as p;

const pngMagicBytes = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

String? trimmedConfigString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

bool projectHasBackgroundGeolocationSlots() {
  final manifest = File(Constants.androidMainManifestFilePath);
  final plist = File(Constants.iosInfoPlistFilePath);
  final hasAndroidSlot =
      manifest.existsSync() &&
      manifest.readAsStringSync().contains(androidLicenseMetaName);
  final hasIosSlot =
      plist.existsSync() &&
      plist.readAsStringSync().contains(iosLicensePlistKey);
  return hasAndroidSlot || hasIosSlot;
}

bool licensesAreRequired(Map<String, dynamic> configJson) {
  return configJson.containsKey(backgroundGeolocationLicenseAndroidKey) ||
      configJson.containsKey(backgroundGeolocationLicenseIosKey) ||
      projectHasBackgroundGeolocationSlots();
}

bool notificationIconIsRequired(Map<String, dynamic> configJson) {
  return trimmedConfigString(configJson[notificationIconConfigKey]) != null ||
      configJson.containsKey(notificationIconConfigKey);
}

void assertConfigureReady(String clientId, Map<String, dynamic> configJson) {
  assertCloneAssetFiles(clientId, configJson);
  assertBackgroundGeolocationLicenses(configJson);
  assertNotificationSource(clientId, configJson);
  assertAndroidSigningSource(clientId, configJson);
}

void assertConfigureFinished(String clientId, Map<String, dynamic> configJson) {
  assertGeneratedImageFiles(configJson);
  assertGeneratedCloneConfigsFile();
  assertNativeLicensesApplied(configJson);
  assertNotificationOutputs(clientId, configJson);
  assertAndroidSigningOutputs(clientId, configJson);
}

const requiredCloneAssetFields = ['launcherIcon', 'splashScreen', 'logo'];

void assertCloneAssetFiles(String clientId, Map<String, dynamic> configJson) {
  final assetsDir = Directory(p.join('clonify', 'clones', clientId, 'assets'));
  if (!assetsDir.existsSync()) {
    throw CustomException(
      'Clone assets directory does not exist: ${assetsDir.path}',
    );
  }

  for (final field in requiredCloneAssetFields) {
    final fileName = trimmedConfigString(configJson[field]);
    if (fileName == null) {
      throw CustomException('Clone config "$field" is not set');
    }
    assertPngFile(p.join(assetsDir.path, fileName), field);
  }
}

void assertBackgroundGeolocationLicenses(Map<String, dynamic> configJson) {
  if (!licensesAreRequired(configJson)) return;

  final packageName = trimmedConfigString(configJson['packageName']);
  final androidLicense = trimmedConfigString(
    configJson[backgroundGeolocationLicenseAndroidKey],
  );
  final iosLicense = trimmedConfigString(
    configJson[backgroundGeolocationLicenseIosKey],
  );

  if (packageName == null) {
    throw CustomException('packageName is not set');
  }
  if (androidLicense == null) {
    throw CustomException('backgroundGeolocationLicenseAndroid is not set');
  }
  if (iosLicense == null) {
    throw CustomException('backgroundGeolocationLicenseIos is not set');
  }

  assertLicenseJwt(
    license: androidLicense,
    field: backgroundGeolocationLicenseAndroidKey,
    expectedOs: 'android',
    expectedPackageName: packageName,
  );
  assertLicenseJwt(
    license: iosLicense,
    field: backgroundGeolocationLicenseIosKey,
    expectedOs: 'ios',
    expectedPackageName: packageName,
  );
}

void assertLicenseJwt({
  required String license,
  required String field,
  required String expectedOs,
  required String? expectedPackageName,
}) {
  final payload = decodeJwtPayload(license);
  if (payload == null) {
    throw CustomException('$field is not a valid JWT');
  }
  final os = payload['os']?.toString();
  final appId = payload['app_id']?.toString();
  if (os != expectedOs) {
    throw CustomException('$field os "$os" must be "$expectedOs"');
  }
  if (expectedPackageName != null && appId != expectedPackageName) {
    throw CustomException(
      '$field app_id "$appId" must match packageName "$expectedPackageName"',
    );
  }
}

void assertNotificationSource(
  String clientId,
  Map<String, dynamic> configJson,
) {
  if (!notificationIconIsRequired(configJson)) return;
  final fileName = trimmedConfigString(configJson[notificationIconConfigKey]);
  if (configJson.containsKey(notificationIconConfigKey) && fileName == null) {
    throw CustomException('Clone config "notificationIcon" is not set');
  }
  assertPngFile(
    p.join(
      'clonify',
      'clones',
      clientId,
      'assets',
      fileName ?? defaultNotificationIconFileName,
    ),
    notificationIconConfigKey,
  );
}

void assertGeneratedImageFiles(Map<String, dynamic> configJson) {
  final imagesDir = Directory('assets/images');
  if (!imagesDir.existsSync()) {
    throw CustomException(
      'Generated images directory does not exist: ${imagesDir.path}',
    );
  }

  for (final field in requiredCloneAssetFields) {
    final fileName = trimmedConfigString(configJson[field]);
    if (fileName == null) {
      throw CustomException('Clone config "$field" is not set');
    }
    assertPngFile(p.join(imagesDir.path, fileName), field);
  }

  if (notificationIconIsRequired(configJson)) {
    final fileName =
        trimmedConfigString(configJson[notificationIconConfigKey]) ??
        defaultNotificationIconFileName;
    assertPngFile(p.join(imagesDir.path, fileName), notificationIconConfigKey);
  }
}

void assertGeneratedCloneConfigsFile() {
  final file = File('lib/generated/clone_configs.dart');
  if (!file.existsSync() || file.lengthSync() == 0) {
    throw CustomException(
      'clone_configs.dart was not generated at ${file.path}',
    );
  }
}

void assertNativeLicensesApplied(Map<String, dynamic> configJson) {
  if (!licensesAreRequired(configJson)) return;

  final androidLicense = trimmedConfigString(
    configJson[backgroundGeolocationLicenseAndroidKey],
  );
  final iosLicense = trimmedConfigString(
    configJson[backgroundGeolocationLicenseIosKey],
  );

  final manifest = File(Constants.androidMainManifestFilePath);
  if (!manifest.existsSync()) {
    throw CustomException(
      'AndroidManifest.xml not found; cannot apply backgroundGeolocationLicenseAndroid',
    );
  }
  if (androidLicense != null &&
      !manifest.readAsStringSync().contains(androidLicense)) {
    throw CustomException(
      'AndroidManifest.xml does not contain backgroundGeolocationLicenseAndroid',
    );
  }

  final plist = File(Constants.iosInfoPlistFilePath);
  if (!plist.existsSync()) {
    throw CustomException(
      'Info.plist not found; cannot apply backgroundGeolocationLicenseIos',
    );
  }
  final plistText = plist.readAsStringSync();
  if (!plistText.contains(iosLicensePlistKey)) {
    throw CustomException('Info.plist is missing $iosLicensePlistKey');
  }
  if (iosLicense != null && !plistText.contains(iosLicense)) {
    throw CustomException(
      'Info.plist $iosLicensePlistKey does not match backgroundGeolocationLicenseIos',
    );
  }
}

void assertNotificationOutputs(
  String clientId,
  Map<String, dynamic> configJson,
) {
  if (!notificationIconIsRequired(configJson)) return;

  final resRoot = Directory(p.join(Constants.androidMainDirPath, 'res'));
  if (!resRoot.existsSync()) {
    throw CustomException(
      'Android res directory not found; notification icon was not generated',
    );
  }

  for (final dirName in androidNotificationDrawableDirs) {
    assertPngFile(
      p.join(resRoot.path, dirName, androidNotificationIconFileName),
      notificationIconConfigKey,
    );
  }
}

void assertAndroidSigningSource(
  String clientId,
  Map<String, dynamic> configJson,
) {
  if (!androidSigningIsRequired(clientId, configJson)) return;

  if (configJson.containsKey(androidKeystoreConfigKey) &&
      trimmedConfigString(configJson[androidKeystoreConfigKey]) == null) {
    throw CustomException('Clone config "androidKeystore" is not set');
  }
  if (configJson.containsKey(androidKeyPropertiesConfigKey) &&
      trimmedConfigString(configJson[androidKeyPropertiesConfigKey]) == null) {
    throw CustomException('Clone config "androidKeyProperties" is not set');
  }

  final sourceDir = cloneAndroidSigningDir(clientId);
  final keystorePath = p.join(
    sourceDir,
    resolveAndroidKeystoreFileName(configJson),
  );
  final propertiesPath = p.join(
    sourceDir,
    resolveAndroidKeyPropertiesFileName(configJson),
  );

  assertAndroidKeystoreFile(keystorePath, androidKeystoreConfigKey);
  assertAndroidKeyPropertiesFile(propertiesPath, androidKeyPropertiesConfigKey);
}

void assertAndroidSigningOutputs(
  String clientId,
  Map<String, dynamic> configJson,
) {
  if (!androidSigningIsRequired(clientId, configJson)) return;

  final keystoreName = resolveAndroidKeystoreFileName(configJson);
  assertAndroidKeystoreFile(
    p.join(Constants.androidDirPath, keystoreName),
    androidKeystoreConfigKey,
  );
  assertAndroidKeyPropertiesFile(
    Constants.androidKeyPropertiesFilePath,
    androidKeyPropertiesConfigKey,
  );

  final properties = parseAndroidKeyProperties(
    File(Constants.androidKeyPropertiesFilePath).readAsStringSync(),
  );
  final storeFile = properties[androidKeyPropertiesStoreFileKey]?.trim();
  if (storeFile != keystoreName) {
    throw CustomException(
      '${Constants.androidKeyPropertiesFilePath} storeFile "$storeFile" must be "$keystoreName"',
    );
  }
}

void assertAndroidKeystoreFile(String path, String field) {
  final file = File(path);
  if (!file.existsSync()) {
    throw CustomException('Missing $field at $path');
  }
  assertAndroidKeystoreBytes(file.readAsBytesSync(), path);
}

void assertAndroidKeyPropertiesFile(String path, String field) {
  final file = File(path);
  if (!file.existsSync()) {
    throw CustomException('Missing $field at $path');
  }
  if (file.lengthSync() == 0) {
    throw CustomException('$field at $path is empty');
  }
  assertAndroidKeyPropertiesComplete(
    parseAndroidKeyProperties(file.readAsStringSync()),
    path,
  );
}

void assertPngFile(String path, String field) {
  final file = File(path);
  if (!file.existsSync()) {
    throw CustomException('Missing $field at $path');
  }
  final bytes = file.readAsBytesSync();
  if (bytes.isEmpty) {
    throw CustomException('Generated $field at $path is empty');
  }
  if (!hasPngSignature(bytes)) {
    throw CustomException('Generated $field at $path is not a PNG');
  }
}

Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    var normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
    final remainder = normalized.length % 4;
    if (remainder > 0) {
      normalized = normalized.padRight(
        normalized.length + (4 - remainder),
        '=',
      );
    }
    final decoded = jsonDecode(utf8.decode(base64.decode(normalized)));
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  } catch (_) {
    return null;
  }
}

bool hasPngSignature(Uint8List bytes) {
  if (bytes.length < pngMagicBytes.length) return false;
  for (var i = 0; i < pngMagicBytes.length; i++) {
    if (bytes[i] != pngMagicBytes[i]) return false;
  }
  return true;
}
