// ignore_for_file: avoid_print

import 'dart:io';

import 'clonify_helpers.dart';

import 'dart:convert';

Future<void> createFirebaseProject({
  required String clientId,
  required String packageName,
  required String firebaseProjectId,
}) async {
  try {
    // Step 1: Get the logged-in user
    logger.i('🔍 Checking logged-in Firebase user...');
    final userResult = await Process.run('firebase', ['login:list', '--json']);
    if (userResult.exitCode != 0) {
      throw Exception('❌ Failed to retrieve Firebase user info.');
    }

    final userData = jsonDecode(userResult.stdout) as Map<String, dynamic>;
    if (userData['status'] != 'success' ||
        (userData['result'] as List).isEmpty) {
      throw Exception('❌ No user is logged in to Firebase CLI.');
    }

    final loggedInUser = userData['result'][0]['user'] as Map<String, dynamic>;
    final userEmail = loggedInUser['email'];
    logger.i('👤 Logged in as: $userEmail');

    // Step 2: Get the list of Firebase projects
    logger.i('🔍 Fetching the list of Firebase projects...');
    final projectsResult = await Process.run('firebase', [
      'projects:list',
      '--json',
    ]);
    if (projectsResult.exitCode != 0) {
      throw Exception('❌ Failed to retrieve the list of Firebase projects.');
    }

    final projectsJson =
        jsonDecode(projectsResult.stdout) as Map<String, dynamic>;
    final projectsData = projectsJson['results'] as List<dynamic>?;

    if (projectsData == null || projectsData.isEmpty) {
      logger.i('📋 No existing Firebase projects found.');
    } else {
      logger.i('📋 Current Firebase projects:');
      for (final project in projectsData) {
        logger.i(
          '   - ${project['projectId']} (${project['displayName']}) by ${project['projectOwner'] ?? 'Unknown'}',
        );
      }
    }

    // Step 3: Check if a project with the same ID exists
    final existingProject = projectsData?.firstWhere(
      (project) => project['projectId'] == firebaseProjectId,
      orElse: () => null,
    );

    if (existingProject != null) {
      // Prompt user to decide whether to use the existing project
      logger.i(
        '⚠️ A project with the ID "$firebaseProjectId" already exists (Display Name: ${existingProject['displayName']}).',
      );
      final choice = prompt('Do you want to use this existing project? (y/n):');

      if (choice.toLowerCase() == 'y') {
        logger.i('✅ Using existing project: $firebaseProjectId');
        return;
      } else {
        logger.i(
          '🔄 You chose not to use the existing project. Please provide a new project ID.',
        );
        final newProjectId = prompt(
          'Enter a new Firebase Project ID (e.g., my-new-project):',
        );
        if (newProjectId.isEmpty) {
          throw Exception('❌ Project ID cannot be empty.');
        }
        firebaseProjectId = newProjectId;
      }
    }

    // Step 4: Create a new Firebase project
    final displayName = '${toTitleCase(clientId)}-HR-Flutter';
    logger.i('🚀 Creating Firebase project: $firebaseProjectId...');
    await runCommand(
      'firebase',
      ['projects:create', '--display-name', displayName, firebaseProjectId],
      successMessage:
          '✅ Firebase project created successfully: $firebaseProjectId',
    );
  } catch (e) {
    logger.e('❌ Error during Firebase project creation: $e');
  }
}

Future<void> addFirebaseToApp({
  required String firebaseProjectId,
  required String packageName,
  bool? skip,
}) async {
  final firebaseJsonPath = clonifySettings.firebaseSettingsFilePath;

  try {
    // Step 1: Parse the firebase.json file
    logger.i('🔍 Checking for firebase.json in the project root...');
    final firebaseJsonFile = File(firebaseJsonPath);
    if (!firebaseJsonFile.existsSync()) {
      logger.e('❌ No firebase.json file found in the project root.');
      logger.i('  Please run "firebase init" to add Firebase to your app.');
      return;
    }

    final firebaseJsonContent =
        jsonDecode(firebaseJsonFile.readAsStringSync()) as Map<String, dynamic>;

    // Step 2: Check if the project ID matches
    final flutterPlatforms = firebaseJsonContent['flutter']?['platforms'];
    if (flutterPlatforms == null) {
      logger.e('❌ No platforms found in firebase.json.');
      logger.i('  Please run "firebase init" to add Firebase to your app.');
      return;
    }

    bool projectIdMatches = false;

    for (final platform in flutterPlatforms.entries) {
      final platformData = platform.value as Map<String, dynamic>;
      if (platformData['default']?['projectId'] == firebaseProjectId) {
        projectIdMatches = true;
        logger.i(
          '✅ Firebase project ID matches for platform: ${platform.key} (${platformData['default']?['projectId']})',
        );
      }
    }

    if (projectIdMatches) {
      if (skip == false) {
        final userChoice = prompt(
          'Firebase project ID matches the current configuration. Do you want to re-run the command anyway? (y/n):',
        );
        if (userChoice.toLowerCase() != 'y') {
          logger.i('>>| Skipping Firebase configuration...');
          return;
        }
      } else {
        logger.i(
          '✅ Firebase project ID matches the current configuration.\n>>| Skipping Firebase configuration...',
        );
        return;
      }
    } else {
      logger.e(
        '❌ Firebase project ID does not match any configuration in firebase.json.',
      );
      if (skip == false) {
        final userChoice = prompt(
          'Do you want to proceed with Firebase configuration for project ID: $firebaseProjectId? (y/n):',
        );
        if (userChoice.toLowerCase() != 'y') {
          logger.i('🚀 Skipping Firebase configuration...');
          return;
        }
      } else {
        logger.i(
          '>>| Proceeding with Firebase configuration for project ID: $firebaseProjectId...',
        );
      }
    }

    // Step 3: Activate Flutterfire CLI
    logger.i('🛠 Activating Flutterfire CLI...');
    await runCommand('dart', [
      'pub',
      'global',
      'activate',
      'flutterfire_cli',
    ], successMessage: '✅ Flutterfire CLI activated successfully.');

    // Step 4: Add Firebase to Android and iOS
    logger.i('🛠 Adding Firebase to your Flutter app...');
    await runCommand(
      'flutterfire',
      [
        'configure',
        '--project',
        firebaseProjectId,
        '-y',
        '--platforms=android,ios',
        '-i',
        packageName,
        '-a',
        packageName,
      ],
      successMessage: '✅ Firebase added successfully to your Flutter app.',
    );

    logger.i("[!] Don't forget to upload the APNs key to Firebase Console [!]");
  } catch (e) {
    logger.e('❌ Error during Firebase setup: $e');
  }
}
