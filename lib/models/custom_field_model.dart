/// Model representing a custom configuration field
class CustomField {
  final String name;
  final String type; // 'string', 'int', 'bool', 'double'

  CustomField({
    required this.name,
    required this.type,
  });

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
    };
  }

  factory CustomField.fromYaml(Map<dynamic, dynamic> yaml) {
    return CustomField(
      name: yaml['name'] as String,
      type: yaml['type'] as String,
    );
  }

  /// Validate if the type is supported
  bool isValidType() {
    return ['string', 'int', 'bool', 'double'].contains(type);
  }
}
