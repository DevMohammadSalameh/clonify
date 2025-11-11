/// Represents a gradient color configuration for Flutter LinearGradient widgets.
///
/// This model stores gradient properties including color stops, alignment positions,
/// and optional transform values for creating linear gradients in the application.
///
/// Example:
/// ```dart
/// final gradient = GradientColorModel.fromJson({
///   'name': 'Primary Gradient',
///   'colors': ['#FF5733', '#FFC300'],
///   'begin': 'topLeft',
///   'end': 'bottomRight'
/// });
/// ```
class GradientColorModel {
  /// An optional name to identify this gradient (e.g., 'Primary Gradient').
  String? name;

  /// List of color values in hex format that form the gradient stops.
  List<String>? colors;

  /// The starting alignment point for the gradient (e.g., 'topLeft', 'centerLeft').
  String? begin;

  /// The ending alignment point for the gradient (e.g., 'bottomRight', 'centerRight').
  String? end;

  /// Optional gradient transform value for additional gradient effects.
  String? transform;

  /// Creates a [GradientColorModel] instance from a JSON map.
  ///
  /// The JSON map should contain 'name', 'colors' (as a list), 'begin', 'end',
  /// and optionally 'transform' keys.
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'name': 'Sunset',
  ///   'colors': ['#FF5733', '#FFC300', '#FF5733'],
  ///   'begin': 'topCenter',
  ///   'end': 'bottomCenter'
  /// };
  /// final gradient = GradientColorModel.fromJson(json);
  /// ```
  GradientColorModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    if (json['colors'] != null) {
      colors = [];
      json['colors'].forEach((v) {
        colors?.add(v);
      });
    }
    begin = json['begin'];
    end = json['end'];
    transform = json['transform'];
  }
}
