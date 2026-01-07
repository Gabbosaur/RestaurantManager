/// Ordine delle categorie del menu (dall'antipasto al dolce)
const List<String> menuCategoryOrder = [
  'Antipasti',
  'Zuppe',
  'Primi - Riso',
  'Primi - Spaghetti',
  'Primi - Ravioli',
  'Secondi - Anatra',
  'Secondi - Pollo',
  'Secondi - Vitello',
  'Secondi - Maiale',
  'Secondi - Gamberi',
  'Secondi - Pesce',
  'Contorni',
  'Dolci',
  'Bevande - Vini',
  'Bevande - Birre',
  'Bevande - Analcoliche',
  'Bevande - Altro',
  'Altro', // fallback per categorie non definite
];

/// Ordina le categorie secondo l'ordine del menu
List<String> sortCategories(Iterable<String> categories) {
  final list = categories.toList();
  list.sort((a, b) {
    final indexA = menuCategoryOrder.indexOf(a);
    final indexB = menuCategoryOrder.indexOf(b);
    // Se non trovato, metti alla fine
    final orderA = indexA == -1 ? 999 : indexA;
    final orderB = indexB == -1 ? 999 : indexB;
    return orderA.compareTo(orderB);
  });
  return list;
}
