import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';
import 'package:path/path.dart' as p;

/// Project trees `clonify configure` is allowed to mutate.
const configureMutableRoots = <String>[
  'android',
  'ios',
  'macos',
  'web',
  'linux',
  'windows',
  'assets/images',
  'lib/generated',
  'lib/firebase_options.dart',
  'shorebird.yaml',
  'pubspec.yaml',
  'package_rename_config.yaml',
  'flutter_launcher_icons.yaml',
  'flutter_native_splash.yaml',
  'firebase.json',
  'clonify/last_client.txt',
  'clonify/last_config.json',
];

const checkpointSkipDirectoryNames = <String>{
  '.gradle',
  'build',
  '.cxx',
  'captures',
};

/// Thrown after a failed configure has restored the previous project files.
class ConfigureRolledBackException implements Exception {
  ConfigureRolledBackException(this.cause);

  final Object cause;

  String get message => 'Configure failed: $cause';

  @override
  String toString() =>
      '$message\nRestored previous iOS, Android, and project files.';
}

/// Snapshot of configure-owned files. Restore wipes a half-applied clone
/// (for example iOS already rewritten, Android signing then failed).
class FileTreeCheckpoint {
  FileTreeCheckpoint._(this.backupDir, this.entries);

  final Directory backupDir;
  final List<CheckpointEntry> entries;

  static FileTreeCheckpoint capture([
    Iterable<String> roots = configureMutableRoots,
  ]) {
    final backupDir = Directory.systemTemp.createTempSync(
      'clonify_checkpoint_',
    );
    final entries = <CheckpointEntry>[
      for (var index = 0; index < roots.length; index++)
        _captureRoot(backupDir, roots.elementAt(index), '$index'),
    ];
    return FileTreeCheckpoint._(backupDir, entries);
  }

  void restore() {
    for (final entry in entries) {
      _restoreRoot(entry);
    }
    discard();
  }

  void discard() {
    if (backupDir.existsSync()) {
      backupDir.deleteSync(recursive: true);
    }
  }

  static CheckpointEntry _captureRoot(
    Directory backupDir,
    String root,
    String id,
  ) {
    final type = FileSystemEntity.typeSync(root, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      return CheckpointEntry(root: root, existed: false, id: id);
    }
    final dest = p.join(backupDir.path, id, p.basename(root));
    _copyEntity(root, dest);
    return CheckpointEntry(
      root: root,
      existed: true,
      id: id,
      isDirectory: type == FileSystemEntityType.directory,
    );
  }

  void _restoreRoot(CheckpointEntry entry) {
    if (!entry.existed) {
      _deleteEntity(entry.root);
      return;
    }
    final parked = _parkSkippedDirectories(entry.root);
    _deleteEntity(entry.root);
    _copyEntity(
      p.join(backupDir.path, entry.id, p.basename(entry.root)),
      entry.root,
    );
    _unparkSkippedDirectories(entry.root, parked);
  }
}

class CheckpointEntry {
  CheckpointEntry({
    required this.root,
    required this.existed,
    required this.id,
    this.isDirectory = false,
  });

  final String root;
  final bool existed;
  final String id;
  final bool isDirectory;
}

Future<T> runConfigureTransaction<T>(Future<T> Function() body) async {
  final checkpoint = FileTreeCheckpoint.capture();
  try {
    final result = await body();
    checkpoint.discard();
    return result;
  } catch (error) {
    try {
      checkpoint.restore();
    } catch (restoreError) {
      logger.e('❌ Configure failed: $error');
      logger.e('❌ Also failed to restore previous files: $restoreError');
      rethrow;
    }
    throw ConfigureRolledBackException(error);
  }
}

void _copyEntity(String sourcePath, String destPath) {
  final type = FileSystemEntity.typeSync(sourcePath, followLinks: false);
  if (type == FileSystemEntityType.notFound) return;
  if (type == FileSystemEntityType.directory) {
    Directory(destPath).createSync(recursive: true);
    for (final child in Directory(sourcePath).listSync(followLinks: false)) {
      final name = p.basename(child.path);
      if (checkpointSkipDirectoryNames.contains(name)) continue;
      _copyEntity(child.path, p.join(destPath, name));
    }
    return;
  }
  File(destPath).parent.createSync(recursive: true);
  File(sourcePath).copySync(destPath);
}

void _deleteEntity(String path) {
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return;
  if (type == FileSystemEntityType.directory) {
    Directory(path).deleteSync(recursive: true);
    return;
  }
  File(path).deleteSync();
}

List<(String, Directory)> _parkSkippedDirectories(String root) {
  final parked = <(String, Directory)>[];
  final type = FileSystemEntity.typeSync(root, followLinks: false);
  if (type != FileSystemEntityType.directory) return parked;

  void walk(Directory dir) {
    for (final child in dir.listSync(followLinks: false).toList()) {
      if (child is! Directory) continue;
      final name = p.basename(child.path);
      if (checkpointSkipDirectoryNames.contains(name)) {
        final hold = Directory.systemTemp.createTempSync('clonify_park_');
        final moved = p.join(hold.path, name);
        child.renameSync(moved);
        parked.add((p.relative(child.path, from: root), hold));
      } else {
        walk(child);
      }
    }
  }

  walk(Directory(root));
  return parked;
}

void _unparkSkippedDirectories(String root, List<(String, Directory)> parked) {
  for (final item in parked) {
    final relative = item.$1;
    final hold = item.$2;
    final name = p.basename(relative);
    final source = Directory(p.join(hold.path, name));
    if (!source.existsSync()) continue;
    final dest = Directory(p.join(root, relative));
    dest.parent.createSync(recursive: true);
    if (dest.existsSync()) dest.deleteSync(recursive: true);
    source.renameSync(dest.path);
    hold.deleteSync(recursive: true);
  }
}
