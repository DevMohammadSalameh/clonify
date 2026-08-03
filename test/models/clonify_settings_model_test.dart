import 'package:clonify/models/clonify_settings_model.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  group('ClonifySettings.fromYaml', () {
    test('parses minimal valid settings', () {
      final yaml =
          loadYaml('''
firebase:
  enabled: false
  settings_file: ""
fastlane:
  enabled: false
  settings_file: ""
company_name: "Acme"
default_color: "#FFFFFF"
''')
              as YamlMap;

      final settings = ClonifySettings.fromYaml(yaml);
      expect(settings.companyName, 'Acme');
      expect(settings.defaultColor, '#FFFFFF');
      expect(settings.firebaseEnabled, isFalse);
      expect(settings.fastlaneEnabled, isFalse);
    });

    test('parses shorebird enabled flag when present', () {
      final yaml =
          loadYaml('''
firebase:
  enabled: true
  settings_file: "./firebase.json"
fastlane:
  enabled: false
  settings_file: ""
shorebird:
  enabled: true
company_name: "Acme"
default_color: "#112233"
''')
              as YamlMap;

      final settings = ClonifySettings.fromYaml(yaml);
      expect(settings.firebaseEnabled, isTrue);
      expect(settings.shorebirdEnabled, isTrue);
      expect(settings.firebaseSettingsFilePath, contains('firebase.json'));
    });

    test('defaults shorebird to disabled when missing', () {
      final yaml =
          loadYaml('''
firebase:
  enabled: false
  settings_file: ""
fastlane:
  enabled: false
  settings_file: ""
company_name: "Acme"
default_color: "#FFFFFF"
''')
              as YamlMap;

      final settings = ClonifySettings.fromYaml(yaml);
      expect(settings.shorebirdEnabled, isFalse);
    });
  });
}
