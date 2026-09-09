import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';
import 'package:path/path.dart' as p;

/// Local files `clonify configure` may change. On failure these are restored
/// so the project looks like the switch never ran.
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
  '.firebaserc',
  'clonify',
];

const checkpointSkipDirectoryNames = <String>{
  '.gradle',
  'build',
  '.cxx',
  'captures',
  // Flutter regenerates this; it also contains package symlinks that
  // File.copySync cannot copy when they point at directories.
  'ephemeral',
};

/// Thrown after a failed configure has restored the previous project files.
class ConfigureRolledBackException implements Exception {
  ConfigureRolledBackException(this.cause, {this.restoreError});

  final Object cause;
  final Object? restoreError;

  String get message {
    if (restoreError == null) return 'Configure failed: $cause';
    return 'Configure failed: $cause\nAlso failed to restore previous files: $restoreError';
  }

  @override
  String toString() {
    if (restoreError == null) {
      return '$message\nRestored previous iOS, Android, and project files.';
    }
    return message;
  }
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
    Object? firstError;
    StackTrace? firstStack;
    for (final entry in entries) {
      try {
        _restoreRoot(entry);
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    try {
      discard();
    } catch (_) {
      // Backup leftover in temp is safer than aborting a restored project.
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStack!);
    }
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
    final backupPath = p.join(backupDir.path, entry.id, p.basename(entry.root));
    if (_isMissing(backupPath)) {
      throw StateError('Checkpoint backup missing for ${entry.root}');
    }

    final absoluteRoot = p.normalize(p.absolute(entry.root));
    final staged = '$absoluteRoot.clonify_restore_${entry.id}';
    _deleteEntity(staged);
    _copyEntity(backupPath, staged);

    final parked = _parkSkippedDirectories(entry.root);
    var restored = false;
    try {
      _deleteEntity(entry.root);
      _renameEntity(staged, entry.root);
      restored = true;
    } catch (error) {
      if (_isMissing(entry.root) && !_isMissing(staged)) {
        _copyEntity(staged, entry.root);
        restored = !_isMissing(entry.root);
      }
      if (!restored) rethrow;
    } finally {
      _unparkSkippedDirectories(entry.root, parked);
      _deleteEntity(staged);
    }
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
      throw ConfigureRolledBackException(error, restoreError: restoreError);
    }
    throw ConfigureRolledBackException(error);
  }
}

void _copyEntity(String sourcePath, String destPath) {
  final type = FileSystemEntity.typeSync(sourcePath, followLinks: false);
  if (type == FileSystemEntityType.notFound) return;
  if (type == FileSystemEntityType.link) {
    File(destPath).parent.createSync(recursive: true);
    final existing = FileSystemEntity.typeSync(destPath, followLinks: false);
    if (existing != FileSystemEntityType.notFound) {
      _deleteEntity(destPath);
    }
    Link(destPath).createSync(Link(sourcePath).targetSync());
    return;
  }
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
  if (type == FileSystemEntityType.link) {
    Link(path).deleteSync();
    return;
  }
  File(path).deleteSync();
}

void _renameEntity(String sourcePath, String destPath) {
  final type = FileSystemEntity.typeSync(sourcePath, followLinks: false);
  if (type == FileSystemEntityType.notFound) return;
  File(destPath).parent.createSync(recursive: true);
  if (type == FileSystemEntityType.directory) {
    Directory(sourcePath).renameSync(destPath);
    return;
  }
  if (type == FileSystemEntityType.link) {
    Link(sourcePath).renameSync(destPath);
    return;
  }
  File(sourcePath).renameSync(destPath);
}

bool _isMissing(String path) {
  return FileSystemEntity.typeSync(path, followLinks: false) ==
      FileSystemEntityType.notFound;
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
