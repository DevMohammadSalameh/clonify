import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/android_signing_manager.dart';
import 'package:clonify/utils/background_geolocation_license_manager.dart';
import 'package:clonify/utils/clone_configure_validator.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  late Directory tempDir;
  late String originalDir;

  setUp(() {
    originalDir = Directory.current.path;
    tempDir = Directory.systemTemp.createTempSync('clonify_configure_');
    Directory.current = tempDir;
  });

  tearDown(() {
    Directory.current = originalDir;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('assertBackgroundGeolocationLicenses', () {
    test('skips when licenses are not used', () {
      expect(
        () => assertBackgroundGeolocationLicenses({'packageName': 'com.app'}),
        returnsNormally,
      );
    });

    test('throws when iOS license key is missing', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app',
          backgroundGeolocationLicenseAndroidKey: fakeJwt(
            os: 'android',
            appId: 'com.app',
          ),
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('backgroundGeolocationLicenseIos is not set'),
          ),
        ),
      );
    });

    test('throws when iOS license is blank', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app',
          backgroundGeolocationLicenseAndroidKey: fakeJwt(
            os: 'android',
            appId: 'com.app',
          ),
          backgroundGeolocationLicenseIosKey: '   ',
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('backgroundGeolocationLicenseIos is not set'),
          ),
        ),
      );
    });

    test('throws when Android license is missing', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app',
          backgroundGeolocationLicenseIosKey: fakeJwt(
            os: 'ios',
            appId: 'com.app',
          ),
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('backgroundGeolocationLicenseAndroid is not set'),
          ),
        ),
      );
    });

    test('throws when Android license is blank', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app',
          backgroundGeolocationLicenseAndroidKey: '   ',
          backgroundGeolocationLicenseIosKey: fakeJwt(
            os: 'ios',
            appId: 'com.app',
          ),
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('backgroundGeolocationLicenseAndroid is not set'),
          ),
        ),
      );
    });

    test('throws when both license keys are omitted', () {
      writeNativeLicenseSlots();
      expect(
        () => assertBackgroundGeolocationLicenses({'packageName': 'com.app'}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('backgroundGeolocationLicenseAndroid is not set'),
          ),
        ),
      );
    });

    test('throws when packageName is omitted while licenses are set', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          backgroundGeolocationLicenseAndroidKey: fakeJwt(
            os: 'android',
            appId: 'com.app',
          ),
          backgroundGeolocationLicenseIosKey: fakeJwt(
            os: 'ios',
            appId: 'com.app',
          ),
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('packageName is not set'),
          ),
        ),
      );
    });

    test('throws when JWT payload is missing os', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app',
          backgroundGeolocationLicenseAndroidKey: fakeJwt(
            os: 'android',
            appId: 'com.app',
          ),
          backgroundGeolocationLicenseIosKey: fakeJwtPayload({
            'app_id': 'com.app',
          }),
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('must be "ios"'),
          ),
        ),
      );
    });

    test('throws when JWT payload is missing app_id', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app',
          backgroundGeolocationLicenseAndroidKey: fakeJwt(
            os: 'android',
            appId: 'com.app',
          ),
          backgroundGeolocationLicenseIosKey: fakeJwtPayload({'os': 'ios'}),
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('must match packageName'),
          ),
        ),
      );
    });

    test('throws when the JWT is invalid', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app',
          backgroundGeolocationLicenseAndroidKey: fakeJwt(
            os: 'android',
            appId: 'com.app',
          ),
          backgroundGeolocationLicenseIosKey: 'not-a-jwt',
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('is not a valid JWT'),
          ),
        ),
      );
    });

    test('throws when the iOS JWT is an Android key', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app',
          backgroundGeolocationLicenseAndroidKey: fakeJwt(
            os: 'android',
            appId: 'com.app',
          ),
          backgroundGeolocationLicenseIosKey: fakeJwt(
            os: 'android',
            appId: 'com.app',
          ),
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('must be "ios"'),
          ),
        ),
      );
    });

    test('throws when JWT app_id does not match packageName', () {
      expect(
        () => assertBackgroundGeolocationLicenses({
          'packageName': 'com.app.staff',
          backgroundGeolocationLicenseAndroidKey: fakeJwt(
            os: 'android',
            appId: 'com.app.staff',
          ),
          backgroundGeolocationLicenseIosKey: fakeJwt(
            os: 'ios',
            appId: 'com.app.client',
          ),
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('must match packageName'),
          ),
        ),
      );
    });

    test('accepts matching Android and iOS JWTs', () {
      expect(
        () => assertBackgroundGeolocationLicenses(validLicensedConfig()),
        returnsNormally,
      );
    });

    test('requires licenses when native slots already exist', () {
      writeNativeLicenseSlots();
      expect(
        () => assertBackgroundGeolocationLicenses({'packageName': 'com.app'}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('backgroundGeolocationLicenseAndroid is not set'),
          ),
        ),
      );
    });
  });

  group('assertCloneAssetFiles', () {
    test('throws when the clone assets directory is missing', () {
      expect(
        () => assertCloneAssetFiles('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('Clone assets directory does not exist'),
          ),
        ),
      );
    });

    test('throws when each branding key is omitted', () {
      writeCloneAssets();
      for (final field in requiredCloneAssetFields) {
        final config = validLicensedConfig()..remove(field);
        expect(
          () => assertCloneAssetFiles('client_a', config),
          throwsA(
            isA<CustomException>().having(
              (error) => error.message,
              'message',
              contains('"$field" is not set'),
            ),
          ),
          reason: 'expected configure to fail when $field is omitted',
        );
      }
    });

    test('throws when each branding key is blank', () {
      writeCloneAssets();
      for (final field in requiredCloneAssetFields) {
        final config = validLicensedConfig()..[field] = '   ';
        expect(
          () => assertCloneAssetFiles('client_a', config),
          throwsA(
            isA<CustomException>().having(
              (error) => error.message,
              'message',
              contains('"$field" is not set'),
            ),
          ),
          reason: 'expected configure to fail when $field is blank',
        );
      }
    });

    test('throws when splash.png is missing', () {
      writeCloneAssets(writeSplash: false);
      expect(
        () => assertCloneAssetFiles('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('splashScreen'),
          ),
        ),
      );
    });

    test('throws when icon.png is missing', () {
      writeCloneAssets(writeIcon: false);
      expect(
        () => assertCloneAssetFiles('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('launcherIcon'),
          ),
        ),
      );
    });

    test('throws when logo.png is missing', () {
      writeCloneAssets(writeLogo: false);
      expect(
        () => assertCloneAssetFiles('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('logo'),
          ),
        ),
      );
    });

    test('throws when icon.png is empty', () {
      writeCloneAssets(emptyIcon: true);
      expect(
        () => assertCloneAssetFiles('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('empty'),
          ),
        ),
      );
    });

    test('throws when logo.png is not a PNG', () {
      writeCloneAssets(invalidLogo: true);
      expect(
        () => assertCloneAssetFiles('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('is not a PNG'),
          ),
        ),
      );
    });

    test('accepts a complete clone assets directory', () {
      writeCloneAssets();
      expect(
        () => assertCloneAssetFiles('client_a', validLicensedConfig()),
        returnsNormally,
      );
    });
  });

  group('assertNotificationSource', () {
    test('skips when notificationIcon is not configured', () {
      expect(
        () => assertNotificationSource('client_a', {'packageName': 'com.app'}),
        returnsNormally,
      );
    });

    test('throws when notificationIcon is blank', () {
      writeCloneAssets();
      expect(
        () => assertNotificationSource('client_a', {
          ...validLicensedConfig(),
          'notificationIcon': '   ',
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('notificationIcon'),
          ),
        ),
      );
    });

    test('throws when notificationIcon is set but the file is missing', () {
      writeCloneAssets(writeNotification: false);
      expect(
        () => assertNotificationSource('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('notificationIcon'),
          ),
        ),
      );
    });

    test('accepts a configured notification icon', () {
      writeCloneAssets();
      expect(
        () => assertNotificationSource('client_a', validLicensedConfig()),
        returnsNormally,
      );
    });
  });

  group('assertConfigureFinished', () {
    test('throws when generated splash was not copied to assets/images', () {
      writeCloneAssets();
      writeGeneratedCheckout(writeSplash: false);
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('splashScreen'),
          ),
        ),
      );
    });

    test('throws when clone_configs.dart was not generated', () {
      writeCloneAssets();
      writeGeneratedCheckout(writeCloneConfigs: false);
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('clone_configs.dart was not generated'),
          ),
        ),
      );
    });

    test('throws when generated images directory is missing', () {
      writeCloneAssets();
      writeGeneratedCheckout();
      Directory('assets/images').deleteSync(recursive: true);
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('Generated images directory does not exist'),
          ),
        ),
      );
    });

    test('throws when generated icon was not copied', () {
      writeCloneAssets();
      writeGeneratedCheckout(writeIcon: false);
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('launcherIcon'),
          ),
        ),
      );
    });

    test('throws when generated logo was not copied', () {
      writeCloneAssets();
      writeGeneratedCheckout(writeLogo: false);
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('logo'),
          ),
        ),
      );
    });

    test(
      'throws when AndroidManifest does not contain the Android license',
      () {
        writeCloneAssets();
        writeGeneratedCheckout(writeAndroidLicense: false);
        expect(
          () => assertConfigureFinished('client_a', validLicensedConfig()),
          throwsA(
            isA<CustomException>().having(
              (error) => error.message,
              'message',
              contains('backgroundGeolocationLicenseAndroid'),
            ),
          ),
        );
      },
    );

    test('throws when Info.plist does not contain the iOS license', () {
      writeCloneAssets();
      writeGeneratedCheckout(writeIosLicense: false);
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('TSLocationManagerLicense'),
          ),
        ),
      );
    });

    test('throws when a notification drawable is missing', () {
      writeCloneAssets();
      writeGeneratedCheckout(writeXxxhdpiNotification: false);
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('notificationIcon'),
          ),
        ),
      );
    });

    test('accepts a finished configure checkout', () {
      writeCloneAssets();
      writeGeneratedCheckout();
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        returnsNormally,
      );
    });

    test('throws when clone signing files were not copied to android/', () {
      writeCloneAssets();
      writeGeneratedCheckout();
      writeCloneSigningSource();
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('androidKeystore'),
          ),
        ),
      );
    });

    test('accepts copied Android signing outputs', () {
      writeCloneAssets();
      writeGeneratedCheckout();
      writeCloneSigningSource();
      writeAndroidSigningOutputs();
      expect(
        () => assertConfigureFinished('client_a', validLicensedConfig()),
        returnsNormally,
      );
    });
  });

  group('assertAndroidSigningSource', () {
    test('skips when signing is not used', () {
      expect(() => assertAndroidSigningSource('client_a', {}), returnsNormally);
    });

    test('throws when androidKeystore key is blank', () {
      expect(
        () => assertAndroidSigningSource('client_a', {
          androidKeystoreConfigKey: '   ',
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('androidKeystore'),
          ),
        ),
      );
    });

    test('throws when androidKeystore file is missing', () {
      expect(
        () => assertAndroidSigningSource('client_a', {
          androidKeystoreConfigKey: 'upload-keystore.jks',
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('Missing androidKeystore'),
          ),
        ),
      );
    });

    test('throws when androidKeyProperties key is blank', () {
      expect(
        () => assertAndroidSigningSource('client_a', {
          androidKeyPropertiesConfigKey: '   ',
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('androidKeyProperties'),
          ),
        ),
      );
    });

    test('throws when signing files exist but Gradle is missing', () {
      writeCloneSigningSource();
      Directory('android/app').createSync(recursive: true);
      expect(
        () => assertAndroidSigningSource('client_a', {}),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('build.gradle'),
          ),
        ),
      );
    });
  });

  group('assertConfigureReady omitted keys', () {
    test('fails when any required branding or license key is omitted', () {
      writeCloneAssets();
      const requiredKeys = [
        'launcherIcon',
        'splashScreen',
        'logo',
        'packageName',
        backgroundGeolocationLicenseAndroidKey,
        backgroundGeolocationLicenseIosKey,
      ];
      for (final field in requiredKeys) {
        final config = validLicensedConfig()..remove(field);
        expect(
          () => assertConfigureReady('client_a', config),
          throwsA(isA<CustomException>()),
          reason: 'expected configure to fail when $field is omitted',
        );
      }
    });

    test('fails when any required branding or license key is blank', () {
      writeCloneAssets();
      const requiredKeys = [
        'launcherIcon',
        'splashScreen',
        'logo',
        'packageName',
        backgroundGeolocationLicenseAndroidKey,
        backgroundGeolocationLicenseIosKey,
      ];
      for (final field in requiredKeys) {
        final config = validLicensedConfig()..[field] = '';
        expect(
          () => assertConfigureReady('client_a', config),
          throwsA(isA<CustomException>()),
          reason: 'expected configure to fail when $field is blank',
        );
      }
    });
  });
}

Map<String, dynamic> validLicensedConfig() {
  return {
    'clientId': 'client_a',
    'packageName': 'com.app',
    'launcherIcon': 'icon.png',
    'splashScreen': 'splash.png',
    'logo': 'logo.png',
    'notificationIcon': 'ic_notification.png',
    backgroundGeolocationLicenseAndroidKey: fakeJwt(
      os: 'android',
      appId: 'com.app',
    ),
    backgroundGeolocationLicenseIosKey: fakeJwt(os: 'ios', appId: 'com.app'),
  };
}

String fakeJwt({required String os, required String appId}) {
  return fakeJwtPayload({'os': os, 'app_id': appId});
}

String fakeJwtPayload(Map<String, dynamic> payload) {
  final header = base64Url
      .encode(utf8.encode('{"alg":"none"}'))
      .replaceAll('=', '');
  final body = base64Url
      .encode(utf8.encode(jsonEncode(payload)))
      .replaceAll('=', '');
  return '$header.$body.sig';
}

Uint8List pngBytes() {
  return Uint8List.fromList(const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ]);
}

void writePng(String path, {bool empty = false, bool invalid = false}) {
  File(path).createSync(recursive: true);
  if (empty) {
    File(path).writeAsBytesSync(const []);
    return;
  }
  if (invalid) {
    File(path).writeAsStringSync('not a png');
    return;
  }
  File(path).writeAsBytesSync(pngBytes());
}

void writeCloneAssets({
  bool writeIcon = true,
  bool writeLogo = true,
  bool writeSplash = true,
  bool writeNotification = true,
  bool emptyIcon = false,
  bool invalidLogo = false,
}) {
  final assets = Directory('clonify/clones/client_a/assets')
    ..createSync(recursive: true);
  if (writeIcon) writePng('${assets.path}/icon.png', empty: emptyIcon);
  if (writeLogo) writePng('${assets.path}/logo.png', invalid: invalidLogo);
  if (writeSplash) writePng('${assets.path}/splash.png');
  if (writeNotification) writePng('${assets.path}/ic_notification.png');
}

void writeNativeLicenseSlots() {
  File('android/app/src/main/AndroidManifest.xml')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '<manifest><application><meta-data android:name="com.transistorsoft.locationmanager.license" android:value="old" /></application></manifest>',
    );
  File('ios/Runner/Info.plist')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '<plist><dict><key>TSLocationManagerLicense</key><string>old</string></dict></plist>',
    );
}

void writeGeneratedCheckout({
  bool writeIcon = true,
  bool writeLogo = true,
  bool writeSplash = true,
  bool writeCloneConfigs = true,
  bool writeAndroidLicense = true,
  bool writeIosLicense = true,
  bool writeXxxhdpiNotification = true,
}) {
  final config = validLicensedConfig();
  Directory('assets/images').createSync(recursive: true);
  if (writeIcon) writePng('assets/images/icon.png');
  if (writeLogo) writePng('assets/images/logo.png');
  if (writeSplash) writePng('assets/images/splash.png');
  writePng('assets/images/ic_notification.png');

  if (writeCloneConfigs) {
    File('lib/generated/clone_configs.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('abstract class CloneConfigs {}');
  }

  final androidValue = writeAndroidLicense
      ? config[backgroundGeolocationLicenseAndroidKey]
      : 'missing';
  File('android/app/src/main/AndroidManifest.xml')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '<manifest><application><meta-data android:name="com.transistorsoft.locationmanager.license" android:value="$androidValue" /></application></manifest>',
    );

  final iosBody = writeIosLicense
      ? '<key>TSLocationManagerLicense</key><string>${config[backgroundGeolocationLicenseIosKey]}</string>'
      : '<key>CFBundleName</key><string>App</string>';
  File('ios/Runner/Info.plist')
    ..createSync(recursive: true)
    ..writeAsStringSync('<plist><dict>$iosBody</dict></plist>');

  for (final dirName in [
    'drawable',
    'drawable-mdpi',
    'drawable-hdpi',
    'drawable-xhdpi',
    'drawable-xxhdpi',
    if (writeXxxhdpiNotification) 'drawable-xxxhdpi',
  ]) {
    writePng('android/app/src/main/res/$dirName/ic_notification.png');
  }
}

void writeCloneSigningSource() {
  Directory('clonify/clones/client_a/android').createSync(recursive: true);
  File(
    'clonify/clones/client_a/android/upload-keystore.jks',
  ).writeAsBytesSync(Uint8List.fromList(const [0xFE, 0xED, 0xFE, 0xED, 0x00]));
  File('clonify/clones/client_a/android/key.properties').writeAsStringSync(
    'storePassword=store-secret\nkeyPassword=key-secret\nkeyAlias=upload\nstoreFile=upload-keystore.jks\n',
  );
}

void writeAndroidSigningOutputs() {
  Directory('android').createSync(recursive: true);
  File(
    'android/upload-keystore.jks',
  ).writeAsBytesSync(Uint8List.fromList(const [0xFE, 0xED, 0xFE, 0xED, 0x00]));
  File('android/key.properties').writeAsStringSync(
    'storePassword=store-secret\nkeyPassword=key-secret\nkeyAlias=upload\nstoreFile=upload-keystore.jks\n',
  );
}
