/// Model representing a custom configuration field for clone configurations.
///
/// This model allows users to define additional fields beyond the standard
/// configuration options. Custom fields can be used to store client-specific
/// data or feature flags.
///
/// Supported types: 'string', 'int', 'bool', 'double'
///
/// Example:
/// ```dart
/// final customField = CustomField(
///   name: 'apiTimeout',
///   type: 'int'
/// );
/// ```
class CustomField {
  /// The name of the custom field (e.g., 'apiTimeout', 'enableFeatureX').
  final String name;

  /// The data type of the field. Supported values: 'string', 'int', 'bool', 'double'.
  final String type;

  /// Creates a new [CustomField] instance.
  ///
  /// Both [name] and [type] are required parameters.
  CustomField({required this.name, required this.type});

  /// Creates a [CustomField] instance from a JSON map.
  ///
  /// The JSON map should contain 'name' and 'type' keys.
  ///
  /// Example:
  /// ```dart
  /// final json = {'name': 'apiTimeout', 'type': 'int'};
  /// final field = CustomField.fromJson(json);
  /// ```
  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  /// Converts this [CustomField] to a JSON map.
  ///
  /// Returns a map with 'name' and 'type' keys.
  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type};
  }

  /// Creates a [CustomField] instance from a YAML map.
  ///
  /// The YAML map should contain 'name' and 'type' keys.
  ///
  /// Example:
  /// ```dart
  /// final yaml = {'name': 'enableDarkMode', 'type': 'bool'};
  /// final field = CustomField.fromYaml(yaml);
  /// ```
  factory CustomField.fromYaml(Map<dynamic, dynamic> yaml) {
    return CustomField(
      name: yaml['name'] as String,
      type: yaml['type'] as String,
    );
  }

  /// Validates if the [type] is one of the supported types.
  ///
  /// Returns true if the type is 'string', 'int', 'bool', or 'double'.
  bool isValidType() {
    return ['string', 'int', 'bool', 'double'].contains(type);
  }
}
