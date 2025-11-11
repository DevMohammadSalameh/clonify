import 'color_model.dart';
import 'gradient_color_model.dart';

/// Represents the complete configuration for a Flutter project clone.
///
/// This model contains all the necessary information to configure a white-labeled
/// version of a Flutter application, including branding, colors, package details,
/// and server endpoints.
///
/// Example:
/// ```dart
/// final config = CloneConfigModel.fromJson({
///   'appName': 'MyApp',
///   'clientId': 'client-123',
///   'packageName': 'com.example.myapp',
///   'primaryColor': '#FF5733',
///   'baseUrl': 'https://api.example.com',
///   'version': '1.0.0+1'
/// });
/// ```
class CloneConfigModel {
  /// The display name of the application.
  String? appName;

  /// Unique identifier for this client configuration.
  String? clientId;

  /// The primary color for the app theme in hex format.
  String? primaryColor;

  /// The Android/iOS package name (e.g., 'com.example.app').
  String? packageName;

  /// List of additional color configurations for the application.
  List<ColorModel>? colors;

  /// List of gradient color configurations for the application.
  List<GradientColorModel>? gradientsColors;

  /// The base URL for API endpoints.
  String? baseUrl;

  /// The version string in format 'major.minor.patch+build' (e.g., '1.0.0+1').
  late String version;

  /// Validates if the configuration has the minimum required fields.
  ///
  /// Returns true if both [appName] and [packageName] are non-empty strings.
  bool get isValid =>
      (appName?.isNotEmpty ?? false) && (packageName?.isNotEmpty ?? false);

  /// Creates a [CloneConfigModel] instance from a JSON object.
  ///
  /// Parses the provided JSON and populates all configuration fields.
  /// If 'version' is not provided, defaults to '1.0.0+1'.
  ///
  /// Example:
  /// ```dart
  /// final json = {
  ///   'appName': 'MyApp',
  ///   'clientId': 'client-123',
  ///   'packageName': 'com.example.myapp'
  /// };
  /// final config = CloneConfigModel.fromJson(json);
  /// ```
  CloneConfigModel.fromJson(dynamic json) {
    clientId = json['clientId'];
    appName = json['appName'];
    primaryColor = json['primaryColor'];
    packageName = json['packageName'];
    baseUrl = json['baseUrl'];
    version = json['version'] ?? '1.0.0+1';
    if (json['colors'] != null) {
      colors = [];
      json['colors'].forEach((v) {
        colors?.add(ColorModel.fromJson(v));
      });
    }
    if (json['linearGradients'] != null) {
      gradientsColors = [];
      json['linearGradients'].forEach((v) {
        gradientsColors?.add(GradientColorModel.fromJson(v));
      });
    }
  }
}
