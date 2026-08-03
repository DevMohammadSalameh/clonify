import 'package:clonify/utils/notification_icon_manager.dart';
import 'package:test/test.dart';

void main() {
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
}
