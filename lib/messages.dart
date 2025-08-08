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
  static String failedToParseClonifySettings(Object error) =>
      '❌ Failed to parse clonify_settings.yaml: $error';
  static String clonifySettingsDoesNotContainAValidMap =
      '❌ clonify_settings.yaml does not contain a valid map.';
  static String missingRequiredField(String field) =>
      '❌ Missing required field: $field';
  //'❌ Field "$field" has invalid type ${rawSettings[field].runtimeType}. Expected ${requiredFields[field]}.'

  static String fieldHasInvalidType(
    String field,
    Type runtimeType,
    Type? expectedType,
  ) =>
      '❌ Field "$field" has invalid type [$runtimeType]. Expected $expectedType';
}
