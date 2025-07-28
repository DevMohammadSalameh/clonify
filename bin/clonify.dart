import 'dart:io';
import 'dart:convert';

import 'package:clonify/utils/clone_manager.dart';
import 'package:clonify/utils/clonify_helpers.dart';
import 'package:clonify/utils/upload_manager.dart';

const lastClientFilePath = './clonify/last_client.txt';
const lastConfigFilePath = './clonify/last_config.json';

Future<void> saveLastClientId(String clientId) async {
  final file = File(lastClientFilePath);
  await file.writeAsString(clientId);
}

Future<String?> getLastClientId() async {
  final file = File(lastClientFilePath);
  if (file.existsSync()) {
    return file.readAsStringSync();
  }
  return null;
}

Future<void> saveLastConfig(Map<String, dynamic> config) async {
  final file = File(lastConfigFilePath);
  await file.writeAsString(jsonEncode(config));
}

Future<Map<String, dynamic>?> getLastConfig() async {
  final file = File(lastConfigFilePath);
  if (file.existsSync()) {
    return jsonDecode(await file.readAsString());
  }
  return null;
}

Future<String?> getClientIdFromArgsOrLast(List<String> args) async {
  String? clientId =
      getArgumentValue(args, '--clientId') ??
      getArgumentValue(args, '-id') ??
      getArgumentValue(args, '--clientId');
  if (getArgumentValue(args, '--clientId') != null) {
    // I added this case because i have typed it wrong multiple times
    print(
      ' [!] Typo in argument name. Use "--clientId" instead of "--clientId" next time.',
    );
  }

  if (clientId == null) {
    final lastConfig = await getLastConfig();
    if (lastConfig != null) {
      clientId = lastConfig['clientId'];
      final answer = prompt(
        'No client ID provided. Use last configured client ID "$clientId"? (y/n):',
      );
      if (answer.toLowerCase() != 'y') {
        throw Exception('Client ID is required.');
      }
    } else {
      throw Exception(
        'No client ID provided and no last configured client found.',
      );
    }
  }
  return clientId;
}

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
