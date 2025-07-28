import 'dart:convert';
import 'dart:io';

import 'package:clonify/utils/clonify_helpers.dart';

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
  final file = File('./clonify/last_config.json');
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
