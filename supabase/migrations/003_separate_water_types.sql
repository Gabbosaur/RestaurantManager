-- Separa le acque in naturale e frizzante (richiesta mamma)

-- Rimuovi le vecchie voci acqua combinate
DELETE FROM menu_items WHERE name LIKE 'Acqua Naturale o Frizzante%';

-- Inserisci le nuove voci separate
INSERT INTO menu_items (name, name_zh, price, category, ingredient_key) VALUES
    ('Acqua Naturale 1L', '矿泉水大', 3.50, 'Bevande - Analcoliche', NULL),
    ('Acqua Naturale 0,5L', '矿泉水小', 2.50, 'Bevande - Analcoliche', NULL),
    ('Acqua Frizzante 1L', '气泡水大', 3.50, 'Bevande - Analcoliche', NULL),
    ('Acqua Frizzante 0,5L', '气泡水小', 2.50, 'Bevande - Analcoliche', NULL);
