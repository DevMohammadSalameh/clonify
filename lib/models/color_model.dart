/// Represents a color configuration for a Flutter project clone.
///
/// This model stores a color value (in hex format) and an optional name
/// for organizing and referencing colors throughout the application.
///
/// Example:
/// ```dart
/// final primaryColor = ColorModel(
///   color: '#FF5733',
///   name: 'Primary'
/// );
/// ```
class ColorModel {
  /// The color value in hex format (e.g., '#FF5733').
  final String? color;

  /// An optional name to identify this color (e.g., 'Primary', 'Secondary').
  final String? name;

  /// Creates a new [ColorModel] instance.
  ///
  /// Both [color] and [name] parameters are required but nullable.
  ColorModel({required this.color, required this.name});

  /// Creates a [ColorModel] instance from a JSON map.
  ///
  /// The JSON map should contain 'color' and 'name' keys.
  ///
  /// Example:
  /// ```dart
  /// final json = {'color': '#FF5733', 'name': 'Primary'};
  /// final colorModel = ColorModel.fromJson(json);
  /// ```
  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(color: json['color'], name: json['name']);
  }
}
