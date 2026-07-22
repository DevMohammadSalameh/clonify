import 'dart:io';

import 'package:clonify/utils/shorebird_manager.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late File shorebirdFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('clonify_shorebird_');
    shorebirdFile = File('${tempDir.path}/shorebird.yaml');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('configureShorebirdAppId replaces existing app_id', () async {
    shorebirdFile.writeAsStringSync('''
# comment
app_id: old-id-here
auto_update: false
''');

    await configureShorebirdAppId(
      shorebirdAppId: 'new-app-id',
      settingsFilePath: shorebirdFile.path,
    );

    final content = shorebirdFile.readAsStringSync();
    expect(content, contains('app_id: new-app-id'));
    expect(content, isNot(contains('old-id-here')));
    expect(content, contains('auto_update: false'));
  });

  test('configureShorebirdAppId inserts app_id when missing', () async {
    shorebirdFile.writeAsStringSync('# only a comment\n');

    await configureShorebirdAppId(
      shorebirdAppId: 'inserted-id',
      settingsFilePath: shorebirdFile.path,
    );

    final content = shorebirdFile.readAsStringSync();
    expect(content.startsWith('app_id: inserted-id\n'), isTrue);
  });

  test('configureShorebirdAppId respects skip', () async {
    shorebirdFile.writeAsStringSync('app_id: keep-me\n');

    await configureShorebirdAppId(
      shorebirdAppId: 'should-not-apply',
      settingsFilePath: shorebirdFile.path,
      skip: true,
    );

    expect(shorebirdFile.readAsStringSync(), contains('app_id: keep-me'));
  });

  test('resolveShorebirdAppId reads string value', () {
    expect(
      resolveShorebirdAppId({'shorebirdAppId': '  abc  '}),
      'abc',
    );
    expect(resolveShorebirdAppId({}), '');
  });
}
