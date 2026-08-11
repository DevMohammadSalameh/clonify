import 'dart:io';

import 'package:clonify/custom_exceptions.dart';
import 'package:clonify/utils/notification_icon_manager.dart';
import 'package:test/test.dart';

import '../silence_logs.dart';

void main() {
  silenceClonifyLogsForTests();

  group('notificationColorHexFromPrimary', () {
    test('parses 0xAARRGGBB', () {
      expect(notificationColorHexFromPrimary('0xFFFF7300'), '#FF7300');
    });

    test('parses #RRGGBB', () {
      expect(notificationColorHexFromPrimary('#FF7300'), '#FF7300');
    });

    test('parses RRGGBB', () {
      expect(notificationColorHexFromPrimary('ff7300'), '#FF7300');
    });

    test('returns null for invalid values', () {
      expect(notificationColorHexFromPrimary(''), isNull);
      expect(notificationColorHexFromPrimary('red'), isNull);
      expect(notificationColorHexFromPrimary('0x12'), isNull);
    });
  });

  group('resolveBackgroundNotificationColor', () {
    test('prefers backgroundNotificationColor over primaryColor', () {
      expect(
        resolveBackgroundNotificationColor({
          'primaryColor': '0xFFFF7300',
          'backgroundNotificationColor': '0xFF0066FF',
        }),
        '0xFF0066FF',
      );
    });

    test('falls back to primaryColor', () {
      expect(
        resolveBackgroundNotificationColor({'primaryColor': '0xFFFF7300'}),
        '0xFFFF7300',
      );
    });
  });

  group('notificationColorArgbLiteral', () {
    test('returns Dart Color literal', () {
      expect(notificationColorArgbLiteral('0xFFFF7300'), '0xFFFF7300');
      expect(notificationColorArgbLiteral('#0066FF'), '0xFF0066FF');
    });
  });

  group('applyAndroidNotificationIcon', () {
    late Directory tempDir;
    late String originalDir;

    setUp(() {
      originalDir = Directory.current.path;
      tempDir = Directory.systemTemp.createTempSync('clonify_notif_');
      Directory.current = tempDir;
    });

    tearDown(() {
      Directory.current = originalDir;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('throws when notificationIcon is configured but missing', () async {
      expect(
        () => applyAndroidNotificationIcon('client_a', {
          notificationIconConfigKey: 'ic_notification.png',
        }),
        throwsA(
          isA<CustomException>().having(
            (error) => error.message,
            'message',
            contains('Missing notificationIcon'),
          ),
        ),
      );
    });

    test('skips when notificationIcon is not configured', () async {
      await applyAndroidNotificationIcon('client_a', {});
    });
  });
}
