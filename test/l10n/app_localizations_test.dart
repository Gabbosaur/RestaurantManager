import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/l10n/app_localizations.dart';
import 'package:restaurant_app/core/l10n/language_provider.dart';

void main() {
  group('AppLocalizations', () {
    test('Italian translations work', () {
      final l10n = AppLocalizations(AppLanguage.italian);
      expect(l10n.orders, 'Ordini');
      expect(l10n.tables, 'Tavoli');
      expect(l10n.kitchen, 'Cucina');
      expect(l10n.menu, 'Menu');
    });

    test('English translations work', () {
      final l10n = AppLocalizations(AppLanguage.english);
      expect(l10n.orders, 'Orders');
      expect(l10n.tables, 'Tables');
      expect(l10n.kitchen, 'Kitchen');
      expect(l10n.menu, 'Menu');
    });

    test('Chinese translations work', () {
      final l10n = AppLocalizations(AppLanguage.chinese);
      expect(l10n.orders, '订单');
      expect(l10n.tables, '餐桌');
      expect(l10n.kitchen, '厨房');
      expect(l10n.menu, '菜单');
    });

    test('minutesAgo formats correctly in Italian', () {
      final l10n = AppLocalizations(AppLanguage.italian);
      expect(l10n.minutesAgo(5), '5 min fa');
      expect(l10n.minutesAgo(1), '1 min fa');
    });

    test('minutesAgo formats correctly in Chinese', () {
      final l10n = AppLocalizations(AppLanguage.chinese);
      expect(l10n.minutesAgo(5), '5 分钟前');
    });
  });
}
