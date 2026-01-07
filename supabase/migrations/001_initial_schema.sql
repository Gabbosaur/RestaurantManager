-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Menu Items table
CREATE TABLE menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    name_zh TEXT,  -- nome in cinese per la cucina
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    category TEXT NOT NULL DEFAULT 'Altro',
    is_available BOOLEAN DEFAULT true,
    ingredient_key TEXT,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ingredienti chiave (per gestione disponibilità)
CREATE TABLE ingredients (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    is_available BOOLEAN DEFAULT true,
    notes TEXT
);

-- Tables table
CREATE TABLE tables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    capacity INTEGER DEFAULT 4,
    status TEXT DEFAULT 'available',
    current_order_id UUID,
    number_of_people INTEGER,
    reserved_at TIMESTAMPTZ,
    reserved_by TEXT
);

-- Orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_id TEXT,
    table_name TEXT,
    order_type TEXT DEFAULT 'table',
    number_of_people INTEGER,
    items JSONB NOT NULL DEFAULT '[]',
    status TEXT DEFAULT 'pending',
    total DECIMAL(10,2) NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inventory Items table
CREATE TABLE inventory_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 0,
    unit TEXT DEFAULT 'unità',
    min_quantity DECIMAL(10,2) DEFAULT 10,
    supplier TEXT,
    last_restocked TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- Enable Row Level Security
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Allow authenticated access" ON menu_items FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated access" ON ingredients FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated access" ON tables FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated access" ON orders FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Allow authenticated access" ON inventory_items FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory_items;

-- Restaurant settings
CREATE TABLE restaurant_settings (
    id INTEGER PRIMARY KEY DEFAULT 1,
    cover_charge DECIMAL(10,2) DEFAULT 1.50
);
INSERT INTO restaurant_settings (id, cover_charge) VALUES (1, 1.50);
ALTER TABLE restaurant_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow authenticated access" ON restaurant_settings FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Ingredienti chiave
INSERT INTO ingredients (id, name, is_available) VALUES
    ('riso', 'Riso', true),
    ('spaghetti_riso', 'Spaghetti di Riso', true),
    ('spaghetti_soia', 'Spaghetti di Soia', true),
    ('udon', 'Udon', true),
    ('ravioli', 'Ravioli', true),
    ('gnocchi_riso', 'Gnocchi di Riso', true),
    ('anatra', 'Anatra', true),
    ('pollo', 'Pollo', true),
    ('vitello', 'Vitello', true),
    ('maiale', 'Maiale', true),
    ('costine', 'Costine di Maiale', true),
    ('gamberi', 'Gamberi', true),
    ('gamberoni', 'Gamberoni', true),
    ('calamari', 'Calamari', true),
    ('pesce', 'Pesce', true),
    ('frutti_mare', 'Frutti di Mare', true),
    ('tofu', 'Tofu', true),
    ('involtini_carne', 'Involtini di Carne', true),
    ('involtini_primavera', 'Involtini Primavera', true),
    ('wanton', 'Wanton', true),
    ('granchio', 'Granchio', true);


-- Menu completo Xin Xing 新星 (con nomi cinesi)
INSERT INTO menu_items (name, name_zh, price, category, ingredient_key) VALUES
    -- ANTIPASTI
    ('01. Antipasto Misto', '什锦拼盘', 5.00, 'Antipasti', NULL),
    ('02. Involtino di Carne', '肉卷', 2.50, 'Antipasti', 'involtini_carne'),
    ('03. Involtino di Primavera', '春卷', 1.00, 'Antipasti', 'involtini_primavera'),
    ('04. Toast di Gamberi', '虾多士', 2.50, 'Antipasti', 'gamberi'),
    ('05. Nuvolette di Gamberi', '虾片', 1.50, 'Antipasti', NULL),
    ('06. Insalata Agropiccante', '酸辣沙拉', 4.00, 'Antipasti', NULL),
    ('07. Insalata di Mare', '海鲜沙拉', 6.50, 'Antipasti', 'frutti_mare'),
    ('08. Insalata di Alghe', '海带沙拉', 5.00, 'Antipasti', NULL),
    ('09. Focaccia Farcita Cinese', '中式馅饼', 2.00, 'Antipasti', NULL),
    -- ZUPPE
    ('10. Zuppa di Mais e Pollo', '玉米鸡汤', 3.00, 'Zuppe', 'pollo'),
    ('11. Zuppa di Wanton', '馄饨汤', 3.00, 'Zuppe', 'wanton'),
    ('12. Zuppa Pechinese Agropiccante', '酸辣汤', 3.00, 'Zuppe', NULL),
    ('13. Zuppa di Granchio con Asparagi', '蟹肉芦笋汤', 3.00, 'Zuppe', 'granchio'),
    ('14. Zuppa ai Frutti di Mare', '海鲜汤', 3.50, 'Zuppe', 'frutti_mare'),
    -- PRIMI - RISO
    ('21. Riso "Xin Xing"', '新星炒饭', 6.00, 'Primi - Riso', 'riso'),
    ('22. Riso Bianco con Uova e Pomodori', '番茄蛋炒饭', 5.00, 'Primi - Riso', 'riso'),
    ('23. Riso Bianco, Pancetta e Melanzane', '培根茄子饭', 7.00, 'Primi - Riso', 'riso'),
    ('24. Riso alla Cantonese', '扬州炒饭', 3.50, 'Primi - Riso', 'riso'),
    ('25. Riso Bianco con Curry e Verdure', '咖喱蔬菜饭', 7.00, 'Primi - Riso', 'riso'),
    ('26. Riso Bianco con Curry e Pollo', '咖喱鸡饭', 10.00, 'Primi - Riso', 'riso'),
    ('27. Riso Piccante con Gamberi e Cipolle', '辣虾洋葱饭', 4.50, 'Primi - Riso', 'riso'),
    ('28. Riso all''Ananas', '菠萝炒饭', 5.00, 'Primi - Riso', 'riso'),
    ('29. Riso all''Ananas con Gamberi', '菠萝虾仁饭', 7.50, 'Primi - Riso', 'riso'),
    ('30. Riso con Verdure', '蔬菜炒饭', 4.00, 'Primi - Riso', 'riso'),
    ('31. Riso con Gamberi', '虾仁炒饭', 4.50, 'Primi - Riso', 'riso'),
    -- PRIMI - SPAGHETTI
    ('32. Spaghetti di Riso ai Frutti di Mare', '海鲜炒米粉', 6.50, 'Primi - Spaghetti', 'spaghetti_riso'),
    ('33. Spaghetti di Riso Agropiccante', '酸辣米粉', 6.00, 'Primi - Spaghetti', 'spaghetti_riso'),
    ('34. Spaghetti di Riso con Verdure', '蔬菜炒米粉', 4.00, 'Primi - Spaghetti', 'spaghetti_riso'),
    ('35. Spaghetti di Riso, Curry e Verdure', '咖喱蔬菜米粉', 8.00, 'Primi - Spaghetti', 'spaghetti_riso'),
    ('36. Spaghetti di Soia con Maiale', '猪肉炒面', 4.50, 'Primi - Spaghetti', 'spaghetti_soia'),
    ('37. Spaghetti di Soia alla Piastra', '铁板炒面', 7.00, 'Primi - Spaghetti', 'spaghetti_soia'),
    ('38. Spaghetti di Soia al Curry', '咖喱炒面', 5.00, 'Primi - Spaghetti', 'spaghetti_soia'),
    ('39. Spaghetti Udon in Salsa di Soia', '酱油乌冬面', 5.00, 'Primi - Spaghetti', 'udon'),
    ('40. Ramen con Costine', '排骨拉面', 7.50, 'Primi - Spaghetti', 'costine'),
    -- PRIMI - RAVIOLI
    ('41. Ravioli di Carne Brasati', '红烧饺子', 5.00, 'Primi - Ravioli', 'ravioli'),
    ('42. Ravioli al Vapore', '蒸饺', 4.00, 'Primi - Ravioli', 'ravioli'),
    ('43. Gnocchi di Riso', '年糕', 4.00, 'Primi - Ravioli', 'gnocchi_riso'),
    ('44. Gnocchi di Riso con Carne o Gamberi', '肉/虾年糕', 5.00, 'Primi - Ravioli', 'gnocchi_riso'),
    ('45. Spaghetti di Grano con Verdure', '蔬菜炒面', 4.50, 'Primi - Ravioli', NULL),
    -- SECONDI - ANATRA
    ('46. Anatra alla Piastra', '铁板鸭', 8.00, 'Secondi - Anatra', 'anatra'),
    ('47. Anatra al Limone', '柠檬鸭', 7.00, 'Secondi - Anatra', 'anatra'),
    ('48. Anatra Arrosto', '烤鸭', 6.00, 'Secondi - Anatra', 'anatra'),
    ('49. Anatra con Funghi e Bambù', '香菇笋鸭', 7.00, 'Secondi - Anatra', 'anatra'),
    -- SECONDI - POLLO
    ('50. Pollo alle Mandorle', '杏仁鸡', 5.50, 'Secondi - Pollo', 'pollo'),
    ('51. Pollo al Curry', '咖喱鸡', 5.00, 'Secondi - Pollo', 'pollo'),
    ('52. Pollo al Limone', '柠檬鸡', 6.00, 'Secondi - Pollo', 'pollo'),
    ('53. Pollo Kon-Pao Piccante', '宫保鸡丁', 5.50, 'Secondi - Pollo', 'pollo'),
    ('54. Pollo con Asparagi al Latte', '奶油芦笋鸡', 6.50, 'Secondi - Pollo', 'pollo'),
    ('55. Pollo in Salsa di Soia', '酱油鸡', 5.00, 'Secondi - Pollo', 'pollo'),
    ('56. Spiedini di Pollo', '鸡肉串', 5.00, 'Secondi - Pollo', 'pollo'),
    -- SECONDI - VITELLO
    ('57. Vitello con Funghi e Bambù', '香菇笋牛肉', 7.00, 'Secondi - Vitello', 'vitello'),
    ('58. Vitello alla Piastra', '铁板牛肉', 7.00, 'Secondi - Vitello', 'vitello'),
    ('59. Vitello con Cipolle', '洋葱牛肉', 7.00, 'Secondi - Vitello', 'vitello'),
    -- SECONDI - MAIALE
    ('60. Maiale con Verdure', '蔬菜猪肉', 6.00, 'Secondi - Maiale', 'maiale'),
    ('61. Maiale con Funghi Neri', '木耳猪肉', 6.00, 'Secondi - Maiale', 'maiale'),
    ('62. Maiale in Salsa Piccante', '辣猪肉', 5.00, 'Secondi - Maiale', 'maiale'),
    ('63. Maiale in Agrodolce', '糖醋猪肉', 6.00, 'Secondi - Maiale', 'maiale'),
    ('64. Costine di Maiale Fritte', '炸排骨', 6.50, 'Secondi - Maiale', 'costine'),
    -- SECONDI - GAMBERI
    ('65. Gamberi Fritti all''Imperiale', '皇家炸虾', 7.00, 'Secondi - Gamberi', 'gamberi'),
    ('66. Gamberi alla Piastra', '铁板虾', 9.00, 'Secondi - Gamberi', 'gamberi'),
    ('67. Gamberi al Limone', '柠檬虾', 6.50, 'Secondi - Gamberi', 'gamberi'),
    ('68. Gamberi in Agrodolce', '糖醋虾', 6.00, 'Secondi - Gamberi', 'gamberi'),
    ('69. Gamberi in Salsa Piccante', '辣虾', 7.00, 'Secondi - Gamberi', 'gamberi'),
    ('70. Gamberoni allo Spiedo', '烤大虾', 10.00, 'Secondi - Gamberi', 'gamberoni'),
    ('71. Gamberoni alla Piastra', '铁板大虾', 12.00, 'Secondi - Gamberi', 'gamberoni'),
    -- SECONDI - PESCE
    ('72. Calamari con Gamberi e Funghi', '鱿鱼虾仁香菇', 7.00, 'Secondi - Pesce', 'calamari'),
    ('73. Calamari Fritti', '炸鱿鱼', 7.00, 'Secondi - Pesce', 'calamari'),
    ('74. Filetto di Pesce con Funghi e Bambù', '香菇笋鱼片', 7.00, 'Secondi - Pesce', 'pesce'),
    ('75. Filetto di Pesce Fritto', '炸鱼片', 7.00, 'Secondi - Pesce', 'pesce'),
    ('76. Pesce Intero al Vapore', '清蒸全鱼', 11.00, 'Secondi - Pesce', 'pesce'),
    ('77. Pesce Intero Stufato in Salsa di Soia', '红烧全鱼', 11.00, 'Secondi - Pesce', 'pesce'),
    ('78. Frutti di Mare alla Piastra', '铁板海鲜', 12.00, 'Secondi - Pesce', 'frutti_mare'),
    -- CONTORNI
    ('81. Verdura Mista Saltata', '炒杂菜', 3.00, 'Contorni', NULL),
    ('82. Funghi e Bambù Saltati', '炒香菇笋', 4.00, 'Contorni', NULL),
    ('83. Riso Bianco al Vapore', '白饭', 2.00, 'Contorni', 'riso'),
    ('84. Pane Cinese al Vapore o Fritto', '馒头', 1.00, 'Contorni', NULL),
    ('85. Patatine Fritte', '薯条', 3.00, 'Contorni', NULL),
    ('86. Insalata Mista', '沙拉', 3.00, 'Contorni', NULL),
    ('87. Germogli di Soia', '炒豆芽', 4.00, 'Contorni', NULL),
    ('88. Tofu in Salsa Piccante', '麻辣豆腐', 5.00, 'Contorni', 'tofu'),
    ('89. Tofu in Salsa d''Ostrica', '蚝油豆腐', 5.00, 'Contorni', 'tofu'),
    ('90. Tofu con Verdure', '蔬菜豆腐', 5.00, 'Contorni', 'tofu'),
    -- DOLCI
    ('91. Frutta Cinese', '中式水果', 3.00, 'Dolci', NULL),
    ('92. Frutta Fresca Caramellata', '拔丝水果', 4.00, 'Dolci', NULL),
    ('93. Frutta Fresca Fritta', '炸水果', 4.00, 'Dolci', NULL),
    ('94. Gelato Fritto', '炸冰淇淋', 3.00, 'Dolci', NULL),
    ('95. Gelato Misto', '什锦冰淇淋', 4.00, 'Dolci', NULL),
    ('96. Tartufo Bianco o Nero', '松露冰淇淋', 4.00, 'Dolci', NULL),
    ('97. Crème Caramel', '焦糖布丁', 2.50, 'Dolci', NULL),
    ('98. Dolce "Xin Xing"', '新星甜点', 4.00, 'Dolci', NULL),
    -- BEVANDE - VINI
    ('Vino Sfuso 0,50L', '散装酒', 5.00, 'Bevande - Vini', NULL),
    ('Vermentino', '维蒙蒂诺', 16.00, 'Bevande - Vini', NULL),
    ('Pigato', '皮加托', 25.00, 'Bevande - Vini', NULL),
    ('Pinot Grigio', '灰皮诺', 10.00, 'Bevande - Vini', NULL),
    ('Vino Bianco', '白葡萄酒', 9.00, 'Bevande - Vini', NULL),
    ('Vino Rosato', '桃红酒', 8.00, 'Bevande - Vini', NULL),
    ('Vino Rosso', '红葡萄酒', 10.00, 'Bevande - Vini', NULL),
    ('Chardonnay Frizzante', '霞多丽起泡', 10.00, 'Bevande - Vini', NULL),
    -- BEVANDE - BIRRE
    ('Birra Cinese 64cl', '青岛啤酒', 5.00, 'Bevande - Birre', NULL),
    ('Birra Heineken 66cl', '喜力大', 6.00, 'Bevande - Birre', NULL),
    ('Birra Heineken 33cl', '喜力小', 4.00, 'Bevande - Birre', NULL),
    -- BEVANDE - ANALCOLICHE
    ('Acqua Naturale o Frizzante 1L', '矿泉水大', 3.50, 'Bevande - Analcoliche', NULL),
    ('Acqua Naturale o Frizzante 0,5L', '矿泉水小', 2.50, 'Bevande - Analcoliche', NULL),
    ('Coca-Cola / Fanta / Sprite 500ml', '可乐/芬达/雪碧', 3.50, 'Bevande - Analcoliche', NULL),
    ('Estathé Limone o Pesca 330ml', '冰茶', 3.00, 'Bevande - Analcoliche', NULL),
    ('Tè Cinese Caldo', '中国热茶', 3.50, 'Bevande - Analcoliche', NULL),
    -- BEVANDE - ALTRO
    ('Sakè', '清酒', 3.00, 'Bevande - Altro', NULL),
    ('Liquore', '利口酒', 2.50, 'Bevande - Altro', NULL),
    ('Cappuccino', '卡布奇诺', 2.50, 'Bevande - Altro', NULL),
    ('Caffè', '咖啡', 1.50, 'Bevande - Altro', NULL);

-- Tavoli (13 interni + 3 esterni)
INSERT INTO tables (name, capacity) VALUES
    ('T1', 4), ('T2', 4), ('T3', 4), ('T4', 4), ('T5', 4), ('T6', 4), ('T7', 4), ('T8', 4),
    ('T9', 6), ('T10', 6), ('T11', 6), ('T12', 4), ('T13', 4),
    ('E1', 4), ('E2', 4), ('E3', 4);
