part of '../../package_rename_plus.dart';

void _setIOSConfigurations(dynamic iosConfig) {
  try {
    if (iosConfig == null) return;
    if (iosConfig is! Map) throw _PackageRenameErrors.invalidIOSConfig;

    final iosConfigMap = Map<String, dynamic>.from(iosConfig);

    _setIOSDisplayName(iosConfigMap[_appNameKey]);
    _setIOSBundleName(iosConfigMap[_bundleNameKey]);
    _setIOSPackageName(
      oldPackageName: iosConfigMap[_overrideOldPackageKey],
      packageName: iosConfigMap[_packageNameKey],
    );
  } on _PackageRenameException catch (e) {
    PackageRenamePlusLogger.error('${e.message}ERR Code: ${e.code}');
    PackageRenamePlusLogger.error('Skipping iOS configuration!!!');
  } catch (e) {
    PackageRenamePlusLogger.warning(e.toString());
    PackageRenamePlusLogger.error('ERR Code: 255');
    PackageRenamePlusLogger.error('Skipping iOS configuration!!!');
  } finally {
    if (iosConfig != null) PackageRenamePlusLogger.warning(_majorTaskDoneLine);
  }
}

void _setIOSDisplayName(dynamic appName) {
  try {
    if (appName == null) return;
    if (appName is! String) throw _PackageRenameErrors.invalidAppName;

    final iosInfoPlistFile = File(_iosInfoPlistFilePath);
    if (!iosInfoPlistFile.existsSync()) {
      throw _PackageRenameErrors.iosInfoPlistNotFound;
    }

    final iosInfoPlistString = iosInfoPlistFile.readAsStringSync();
    final newDisplayNameIOSInfoPlistString = iosInfoPlistString.replaceAll(
      RegExp(r'<key>CFBundleDisplayName</key>\s*<string>(.*?)</string>'),
      '<key>CFBundleDisplayName</key>\n\t<string>$appName</string>',
    );

    iosInfoPlistFile.writeAsStringSync(newDisplayNameIOSInfoPlistString);

    final iosProjectFile = File(_iosProjectFilePath);
    if (iosProjectFile.existsSync()) {
      final iosProjectString = iosProjectFile.readAsStringSync();
      final updatedProjectString = iosProjectString.replaceAll(
        RegExp(r'INFOPLIST_KEY_CFBundleDisplayName = ".*?";'),
        'INFOPLIST_KEY_CFBundleDisplayName = "$appName";',
      );
      iosProjectFile.writeAsStringSync(updatedProjectString);
      PackageRenamePlusLogger.info(
        'iOS display name set to: `$appName` (project.pbxproj)',
      );
    }

    PackageRenamePlusLogger.info(
        'iOS display name set to: `$appName` (Info.plist)');
  } on _PackageRenameException catch (e) {
    PackageRenamePlusLogger.error('${e.message}ERR Code: ${e.code}');
    PackageRenamePlusLogger.error('iOS Display Name change failed!!!');
  } catch (e) {
    PackageRenamePlusLogger.warning(e.toString());
    PackageRenamePlusLogger.error('ERR Code: 255');
    PackageRenamePlusLogger.error('iOS Display Name change failed!!!');
  } finally {
    if (appName != null) PackageRenamePlusLogger.warning(_minorTaskDoneLine);
  }
}

void _setIOSBundleName(dynamic bundleName) {
  try {
    if (bundleName == null) return;
    if (bundleName is! String) throw _PackageRenameErrors.invalidBundleName;

    if (bundleName.length > 15) {
      PackageRenamePlusLogger.warning(
        'Bundle name is too long. Maximum length should be 15 characters.',
      );
    }

    final iosInfoPlistFile = File(_iosInfoPlistFilePath);
    if (!iosInfoPlistFile.existsSync()) {
      throw _PackageRenameErrors.iosInfoPlistNotFound;
    }

    final iosInfoPlistString = iosInfoPlistFile.readAsStringSync();
    final newBundleNameIOSInfoPlistString = iosInfoPlistString.replaceAll(
      RegExp(r'<key>CFBundleName</key>\s*<string>(.*?)</string>'),
      '<key>CFBundleName</key>\n\t<string>$bundleName</string>',
    );

    iosInfoPlistFile.writeAsStringSync(newBundleNameIOSInfoPlistString);

    PackageRenamePlusLogger.info(
        'iOS bundle name set to: `$bundleName` (Info.plist)');
  } on _PackageRenameException catch (e) {
    PackageRenamePlusLogger.error('${e.message}ERR Code: ${e.code}');
    PackageRenamePlusLogger.error('iOS Bundle Name change failed!!!');
  } catch (e) {
    PackageRenamePlusLogger.warning(e.toString());
    PackageRenamePlusLogger.error('ERR Code: 255');
    PackageRenamePlusLogger.error('iOS Bundle Name change failed!!!');
  } finally {
    if (bundleName != null) PackageRenamePlusLogger.warning(_minorTaskDoneLine);
  }
}

void _setIOSPackageName({
  dynamic oldPackageName,
  dynamic packageName,
}) {
  try {
    if (packageName == null) return;
    if (packageName is! String) throw _PackageRenameErrors.invalidPackageName;

    final iosProjectFile = File(_iosProjectFilePath);
    if (!iosProjectFile.existsSync()) {
      throw _PackageRenameErrors.iosProjectFileNotFound;
    }

    final iosProjectString = iosProjectFile.readAsStringSync();
    final escapedOldPackageName = oldPackageName is String
        ? RegExp.escape(oldPackageName)
        : r'[^;\s]+';
    final newBundleIDIOSProjectString = iosProjectString
        .replaceAll(
      RegExp(
        'PRODUCT_BUNDLE_IDENTIFIER = $escapedOldPackageName(?<!\\.RunnerTests);',
      ),
      'PRODUCT_BUNDLE_IDENTIFIER = $packageName;',
    )
        .replaceAllMapped(
      RegExp(
        'PRODUCT_BUNDLE_IDENTIFIER = $escapedOldPackageName\\.([A-Za-z0-9.-_]+);',
      ),
      (match) {
        final extensionName = match.group(1);
        final isContains = packageName.contains(extensionName.toString());
        if (isContains) {
          return 'PRODUCT_BUNDLE_IDENTIFIER = $packageName;';
        } else {
          return 'PRODUCT_BUNDLE_IDENTIFIER = $packageName.$extensionName;';
        }
      },
    );

    iosProjectFile.writeAsStringSync(newBundleIDIOSProjectString);

    PackageRenamePlusLogger.info(
        'iOS bundle identifier set to: `$packageName` (project.pbxproj)');
  } on _PackageRenameException catch (e) {
    PackageRenamePlusLogger.error('${e.message}ERR Code: ${e.code}');
    PackageRenamePlusLogger.error('iOS Bundle Identifier change failed!!!');
  } catch (e) {
    PackageRenamePlusLogger.warning(e.toString());
    PackageRenamePlusLogger.error('ERR Code: 255');
    PackageRenamePlusLogger.error('iOS Bundle Identifier change failed!!!');
  } finally {
    if (packageName != null) {
      PackageRenamePlusLogger.warning(_minorTaskDoneLine);
    }
  }
}
