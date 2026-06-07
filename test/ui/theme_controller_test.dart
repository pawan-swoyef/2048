import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/ui/theme_controller.dart';

void main() {
  group('ThemeController', () {
    test('defaults to the free Aurora theme', () {
      final c = ThemeController();
      expect(c.current.id, 'aurora');
      expect(c.current.isPremium, isFalse);
    });

    test('a free theme is always unlocked', () {
      final c = ThemeController();
      final aurora = kThemes.firstWhere((t) => t.id == 'aurora');
      expect(c.isUnlocked(aurora), isTrue);
    });

    test('premium themes are locked until premium is unlocked', () {
      final c = ThemeController();
      final neon = kThemes.firstWhere((t) => t.id == 'neon');
      expect(c.isUnlocked(neon), isFalse);

      c.setPremiumUnlocked(true);
      expect(c.isUnlocked(neon), isTrue);
    });

    test('selecting a locked premium theme is rejected and keeps current', () {
      final c = ThemeController();
      final ok = c.select('neon');
      expect(ok, isFalse);
      expect(c.current.id, 'aurora');
    });

    test('selecting a premium theme works once premium is unlocked', () {
      final c = ThemeController();
      c.setPremiumUnlocked(true);
      final ok = c.select('gold');
      expect(ok, isTrue);
      expect(c.current.id, 'gold');
    });

    test('selecting an unknown theme id is rejected', () {
      final c = ThemeController();
      expect(c.select('does-not-exist'), isFalse);
      expect(c.current.id, 'aurora');
    });

    test('revoking premium reverts a premium selection to the free default', () {
      final c = ThemeController();
      c.setPremiumUnlocked(true);
      c.select('ocean');
      expect(c.current.id, 'ocean');

      c.setPremiumUnlocked(false);
      expect(c.current.id, 'aurora');
    });

    test('notifies listeners on a successful select', () {
      final c = ThemeController()..setPremiumUnlocked(true);
      var notified = 0;
      c.addListener(() => notified++);
      c.select('sunset');
      expect(notified, greaterThan(0));
    });

    test('persists selection and premium state via the onChanged callback', () {
      String? savedId;
      bool? savedPremium;
      final c = ThemeController(onChanged: (id, premium) {
        savedId = id;
        savedPremium = premium;
      });
      c.setPremiumUnlocked(true);
      c.select('candy');
      expect(savedId, 'candy');
      expect(savedPremium, isTrue);
    });
  });
}
