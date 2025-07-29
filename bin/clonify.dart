import 'dart:io';

import 'package:clonify/src/clonify_core.dart';
import 'package:clonify/utils/clone_manager.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:clonify/utils/upload_manager.dart';

void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help')) {
    printUsage();
    exit(1);
  }
  final debug =
      args.contains('--verbose') ||
      args.contains('--debug') ||
      args.contains('-d') ||
      args.contains('-v');
  if (debug) {
    print('Debug mode enabled.');
  }
  final command = args.first;

  try {
    switch (command) {
      case 'create':
        await createClone();
        break;
      case 'init':
        await initClonify();
        break;
      case 'which' || 'current' || 'who':
        await getCurrentCloneConfig();
        break;

      case 'configure' || 'con' || 'config' || 'c':
        final clientId = await getClientIdFromArgsOrLast(args);

        final List<String> tempArgs = [...args, '--clientId', clientId ?? ''];

        final config = await configureApp(tempArgs);
        if (config != null) {
          await saveLastConfig(config);
        } else {
          print('❌ Error: Could not configure client "$clientId".');
        }
        break;

      case 'build' || 'b':
        final clientId = await getClientIdFromArgsOrLast(args);
        if (clientId != null) {
          await buildApps(clientId, args);
        } else {
          print(
            '❌ Error: Could not determine bundle ID for client "$clientId".',
          );
        }
        break;

      case 'clean' || 'clear':
        final clientId = await getClientIdFromArgsOrLast(args);
        if (clientId != null) {
          await cleanupPartialClone(clientId);
        } else {
          print(
            '❌ Error: Could not determine bundle ID for client "$clientId".',
          );
        }
        break;

      case 'upload' || 'up' || 'u':
        final clientId = await getClientIdFromArgsOrLast(args);

        if (clientId != null) {
          await uploadToAppStore(clientId);
        } else {
          print(
            '❌ Error: Could not determine bundle ID for client "$clientId".',
          );
        }
        break;

      case 'list' || 'ls':
        listClients();
        break;

      default:
        if (args.any(
          (arg) => arg == '--help' || arg == '-h' || arg == 'help',
        )) {
          printUsage();
        } else {
          print('❌ Unknown command: $command');
          printUsage();
        }
    }
  } catch (e) {
    print('❌ An error occurred: $e');
    exit(1);
  }
}
