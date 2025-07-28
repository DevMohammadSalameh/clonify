// Assets Section


import 'dart:io';

void replaceAssets(String clientId) {
  try {
    final sourceDir = Directory('./clonify/clones/$clientId/assets');
    final targetDir = Directory('./assets/images');

    if (!sourceDir.existsSync()) {
      throw FileSystemException(
          'Source Assets directory does not exist', sourceDir.path);
    }

    if (!targetDir.existsSync()) {
      throw FileSystemException(
          'Target Assets directory does not exist', targetDir.path);
    }
    final String splitBy = Platform.isWindows ? '\\' : '/';
    for (final file in sourceDir.listSync()) {
      // print('Copying ${file.path} to ${targetDir.path}');
      if (file is File) {
        final targetFile =
            File('${targetDir.path}/${file.path.split(splitBy).last}');
        file.copySync(targetFile.path);
      }
    }

    print('✅ Assets replaced successfully.');
  } catch (e) {
    print('❌ Error during asset replacement: $e');
  }
}

void createAssetsDirectory(String clientId) {
  //create assets directory for the clone
  final assetsDir = Directory('./clonify/clones/$clientId/assets');
  assetsDir.createSync(recursive: true);
  //copy the assets from the original project to the clone
  final List<String> assets = [
    'android12splashScreen.png',
    'launcherIcon.png',
    'splashScreen.png',
    'cloneLogo.png',
  ];

  final sourceDir = Directory('./assets/images');
  final targetDir = Directory('./clonify/clones/$clientId/assets');

  if (!sourceDir.existsSync()) {
    throw FileSystemException(
        'Assets directory does not exist', sourceDir.path);
  }

  targetDir.createSync(recursive: true);

  for (final asset in assets) {
    final sourceFile = File('${sourceDir.path}/$asset');
    final targetFile = File('${targetDir.path}/$asset');
    sourceFile.copySync(targetFile.path);
  }

  print(
      '[!] Dont forget to replace the assets in the clone assets with the original assets');
}
