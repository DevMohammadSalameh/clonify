import 'dart:io';

import 'package:clonify/utils/shorebird_manager.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String originalDir;

  setUp(() {
    originalDir = Directory.current.path;
    tempDir = Directory.systemTemp.createTempSync('clonify_shorebird_');
    Directory.current = tempDir;
  });

  tearDown(() {
    Directory.current = originalDir;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('configureShorebirdAppId replaces existing app_id', () async {
    File(defaultShorebirdYamlPath).writeAsStringSync('''
# comment
app_id: old-id-here
auto_update: false
''');

    await configureShorebirdAppId(shorebirdAppId: 'new-app-id');

    final content = File(defaultShorebirdYamlPath).readAsStringSync();
    expect(content, contains('app_id: new-app-id'));
    expect(content, isNot(contains('old-id-here')));
    expect(content, contains('auto_update: false'));
  });

  test('configureShorebirdAppId inserts app_id when missing', () async {
    File(defaultShorebirdYamlPath).writeAsStringSync('# only a comment\n');

    await configureShorebirdAppId(shorebirdAppId: 'inserted-id');

    final content = File(defaultShorebirdYamlPath).readAsStringSync();
    expect(content.startsWith('app_id: inserted-id\n'), isTrue);
  });

  test('configureShorebirdAppId respects skip', () async {
    File(defaultShorebirdYamlPath).writeAsStringSync('app_id: keep-me\n');

    await configureShorebirdAppId(
      shorebirdAppId: 'should-not-apply',
      skip: true,
    );

    expect(
      File(defaultShorebirdYamlPath).readAsStringSync(),
      contains('app_id: keep-me'),
    );
  });

  test('resolveShorebirdAppId reads string value', () {
    expect(
      resolveShorebirdAppId({'shorebirdAppId': '  abc  '}),
      'abc',
    );
    expect(resolveShorebirdAppId({}), '');
  });

  test('readCurrentShorebirdAppId reads yaml', () {
    File(defaultShorebirdYamlPath).writeAsStringSync('app_id: xyz\n');
    expect(readCurrentShorebirdAppId(), 'xyz');
  });
}
