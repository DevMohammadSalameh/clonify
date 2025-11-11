import 'package:clonify/constants.dart';

/// User-facing messages and error strings for the Clonify CLI tool.
///
/// This class provides static methods and constants for generating
/// consistent, user-friendly messages throughout the application.
abstract class Messages {
  static const String toolDescription =
      'A CLI tool that helps you manage your flutter project clones.';
  static String useLastClientIdMessage(String lastClientId) =>
      'Use last client ID "$lastClientId"? (y/n):';
  static String clientIdRequired = 'Client ID is required.';
  static String clientIdRequiredForBuilding =
      'Client ID is required for building apps.';

  static String failedToUploadClone(String clientId, Object error) =>
      'Failed to upload the clone for client ID "$clientId": $error';
  static String clonifySettingsFileNotFound =
      '❌  clonify_settings.yaml not found. Please run "clonify init".';
  static String failedToReadOrParseClonifySettings(Object error) =>
      '❌ Failed to read or parse clonify_settings.yaml: $error';
  static String clonifySettingsDoesNotContainAValidMap =
      '❌ clonify_settings.yaml does not contain a valid map.';
  static String missingRequiredField(String field) =>
      '❌ Missing required field: $field';
  static String fieldHasInvalidType(
    String field,
    Type runtimeType,
    Type? expectedType,
  ) =>
      '❌ Field "$field" has invalid type [$runtimeType]. Expected $expectedType';

  static String configNotFoundForClientId(String clientId) =>
      '❌ Config file not found for client ID: $clientId';

  static String failedToReadOrParseConfigFile(
    String configFilePath,
    Object e,
  ) => '❌ Failed to read or parse $configFilePath: $e';

  static String failedToReadOrParsePubspecFile(Object e) =>
      '❌ Failed to read or parse ${Constants.pubspecFilePath}: $e';

  static String pleaseVerifyBundleIdAndAppNameInXcodeProject =
      '❌ Please verify the Bundle ID and App Name in the Xcode project.';
}
