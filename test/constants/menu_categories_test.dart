import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/core/constants/menu_categories.dart';

void main() {
  group('Menu Categories', () {
    test('menuCategoryOrder contains expected categories', () {
      expect(menuCategoryOrder, contains('Antipasti'));
      expect(menuCategoryOrder, contains('Primi - Riso'));
      expect(menuCategoryOrder, contains('Secondi - Pollo'));
      expect(menuCategoryOrder, contains('Bevande - Analcoliche'));
      expect(menuCategoryOrder, contains('Dolci'));
    });

    test('sortCategories puts categories in correct order', () {
      final unsorted = ['Bevande - Vini', 'Antipasti', 'Dolci', 'Primi - Riso'];
      final sorted = sortCategories(unsorted);
      
      // Antipasti should come before Primi - Riso
      expect(sorted.indexOf('Antipasti'), lessThan(sorted.indexOf('Primi - Riso')));
      // Primi - Riso should come before Dolci
      expect(sorted.indexOf('Primi - Riso'), lessThan(sorted.indexOf('Dolci')));
    });

    test('sortCategories handles unknown categories', () {
      final withUnknown = ['Antipasti', 'Categoria Sconosciuta'];
      final sorted = sortCategories(withUnknown);
      
      // Unknown category should be at the end
      expect(sorted.last, 'Categoria Sconosciuta');
    });
  });
}
