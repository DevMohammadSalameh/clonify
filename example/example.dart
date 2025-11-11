/// Example demonstrating programmatic usage of Clonify models.
///
/// This example shows how to work with Clonify's data models
/// programmatically, which can be useful for testing or building
/// custom tooling on top of Clonify.
library;

import 'package:clonify/models/color_model.dart';
import 'package:clonify/models/gradient_color_model.dart';
import 'package:clonify/models/config_model.dart';
import 'package:clonify/models/custom_field_model.dart';

void main() {
  print('=== Clonify Models Example ===\n');

  // Example 1: Working with ColorModel
  print('1. Creating a ColorModel:');
  final primaryColor = ColorModel(color: '#2196F3', name: 'Primary');
  print('   Color: ${primaryColor.color}');
  print('   Name: ${primaryColor.name}\n');

  // Example 2: Creating ColorModel from JSON
  print('2. ColorModel from JSON:');
  final colorJson = {'color': '#FF5733', 'name': 'Accent'};
  final accentColor = ColorModel.fromJson(colorJson);
  print('   Color: ${accentColor.color}');
  print('   Name: ${accentColor.name}\n');

  // Example 3: Working with GradientColorModel
  print('3. Creating a GradientColorModel:');
  final gradientJson = {
    'name': 'Sunset Gradient',
    'colors': ['#FF5733', '#FFC300', '#FF5733'],
    'begin': 'topLeft',
    'end': 'bottomRight',
  };
  final gradient = GradientColorModel.fromJson(gradientJson);
  print('   Name: ${gradient.name}');
  print('   Colors: ${gradient.colors}');
  print('   Begin: ${gradient.begin}');
  print('   End: ${gradient.end}\n');

  // Example 4: Working with CustomField
  print('4. Creating CustomField:');
  final customField = CustomField(name: 'apiTimeout', type: 'int');
  print('   Name: ${customField.name}');
  print('   Type: ${customField.type}');
  print('   Valid: ${customField.isValidType()}\n');

  // Example 5: CustomField from JSON
  print('5. CustomField from JSON:');
  final fieldJson = {'name': 'enableDarkMode', 'type': 'bool'};
  final darkModeField = CustomField.fromJson(fieldJson);
  print('   Name: ${darkModeField.name}');
  print('   Type: ${darkModeField.type}');
  print('   JSON: ${darkModeField.toJson()}\n');

  // Example 6: Working with CloneConfigModel
  print('6. Creating complete CloneConfigModel:');
  final configJson = {
    'clientId': 'client-abc',
    'appName': 'Client ABC App',
    'packageName': 'com.example.clientabc',
    'primaryColor': '#2196F3',
    'baseUrl': 'https://api.clientabc.com',
    'version': '1.0.0+1',
    'colors': [
      {'color': '#2196F3', 'name': 'Primary'},
      {'color': '#FF5733', 'name': 'Secondary'},
    ],
    'linearGradients': [
      {
        'name': 'Primary Gradient',
        'colors': ['#2196F3', '#1976D2'],
        'begin': 'topCenter',
        'end': 'bottomCenter',
      },
    ],
  };

  final config = CloneConfigModel.fromJson(configJson);
  print('   Client ID: ${config.clientId}');
  print('   App Name: ${config.appName}');
  print('   Package: ${config.packageName}');
  print('   Primary Color: ${config.primaryColor}');
  print('   Base URL: ${config.baseUrl}');
  print('   Version: ${config.version}');
  print('   Valid: ${config.isValid}');
  print('   Colors count: ${config.colors?.length ?? 0}');
  print('   Gradients count: ${config.gradientsColors?.length ?? 0}\n');

  // Example 7: Validating config
  print('7. Validating configurations:');
  final validConfig = CloneConfigModel.fromJson({
    'appName': 'Valid App',
    'packageName': 'com.example.valid',
  });
  print('   Valid config: ${validConfig.isValid}');

  final invalidConfig = CloneConfigModel.fromJson({
    'appName': '',
    'packageName': '',
  });
  print('   Invalid config: ${invalidConfig.isValid}\n');

  // Example 8: Working with multiple colors
  print('8. Managing multiple colors:');
  final colorList = [
    ColorModel(color: '#2196F3', name: 'Primary'),
    ColorModel(color: '#FF5733', name: 'Secondary'),
    ColorModel(color: '#4CAF50', name: 'Success'),
    ColorModel(color: '#F44336', name: 'Error'),
  ];

  print('   Colors in palette:');
  for (final color in colorList) {
    print('     - ${color.name}: ${color.color}');
  }
  print('');

  // Example 9: Multiple gradients
  print('9. Managing multiple gradients:');
  final gradientList = [
    GradientColorModel.fromJson({
      'name': 'Ocean',
      'colors': ['#667eea', '#764ba2'],
      'begin': 'topLeft',
      'end': 'bottomRight',
    }),
    GradientColorModel.fromJson({
      'name': 'Sunset',
      'colors': ['#FF5733', '#FFC300'],
      'begin': 'topCenter',
      'end': 'bottomCenter',
    }),
  ];

  print('   Gradients in collection:');
  for (final grad in gradientList) {
    print('     - ${grad.name}: ${grad.colors?.length} colors');
    print('       Direction: ${grad.begin} → ${grad.end}');
  }
  print('');

  // Example 10: Custom fields validation
  print('10. Custom fields type validation:');
  final validTypes = ['string', 'int', 'bool', 'double'];
  final invalidType = 'array';

  for (final type in validTypes) {
    final field = CustomField(name: 'test', type: type);
    print('     $type: ${field.isValidType()}');
  }

  final invalidField = CustomField(name: 'test', type: invalidType);
  print('     $invalidType: ${invalidField.isValidType()}\n');

  print('=== Example Complete ===');
}
