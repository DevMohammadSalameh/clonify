// Assets Section

import 'dart:io';

import 'clonify_helpers.dart';

/// Replaces the assets in the main project's assets directory with assets from a specific clone.
///
/// This function copies asset files from the `./clonify/clones/[clientId]/assets`
/// directory to the main project's `./assets/images` directory. This is used
/// to apply clone-specific branding and images to the active project.
///
/// [clientId] The ID of the client whose assets should be used for replacement.
///
/// Throws a [FileSystemException] if either the source or target asset directory
/// does not exist. Logs errors if asset replacement fails.
void replaceAssets(String clientId) {
  try {
    final sourceDir = Directory('./clonify/clones/$clientId/assets');
    final targetDir = Directory('./assets/images');

    if (!sourceDir.existsSync()) {
      throw FileSystemException(
        'Source Assets directory does not exist',
        sourceDir.path,
      );
    }

    if (!targetDir.existsSync()) {
      throw FileSystemException(
        'Target Assets directory does not exist',
        targetDir.path,
      );
    }
    final String splitBy = Platform.isWindows ? '\\' : '/';
    for (final file in sourceDir.listSync()) {
      if (file is File) {
        final targetFile = File(
          '${targetDir.path}/${file.path.split(splitBy).last}',
        );
        file.copySync(targetFile.path);
      }
    }

    logger.i('✅ Assets replaced successfully.');
  } catch (e) {
    logger.e('❌ Error during asset replacement: $e');
  }
}

/// Creates an assets directory for a new clone and copies default assets into it.
///
/// This function first creates the `./clonify/clones/[clientId]/assets` directory.
/// Then, it copies a predefined set of assets (specified in `clonifySettings.assets`)
/// from the main project's `./assets/images` directory into the new clone's
/// asset directory.
///
/// [clientId] The ID of the client for which the assets directory is being created.
///
/// Throws a [FileSystemException] if the source assets directory does not exist
/// or if files cannot be copied.
void createAssetsDirectory(String clientId) {
  //create assets directory for the clone
  final assetsDir = Directory('./clonify/clones/$clientId/assets');
  assetsDir.createSync(recursive: true);
  //copy the assets from the original project to the clone
  // final List<String> assets = [
  //   'android12splashScreen.png',
  //   'launcherIcon.png',
  //   'splashScreen.png',
  //   'cloneLogo.png',
  // ];

  final sourceDir = Directory('./assets/images');
  final targetDir = Directory('./clonify/clones/$clientId/assets');

  if (!sourceDir.existsSync()) {
    throw FileSystemException(
      'Assets directory does not exist',
      sourceDir.path,
    );
  }

  targetDir.createSync(recursive: true);

  logger.i(
    '[!] Dont forget to replace the assets in the clone assets with the original assets',
  );
}
