-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Menu Items table
CREATE TABLE menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    category TEXT NOT NULL DEFAULT 'Altro',
    is_available BOOLEAN DEFAULT true,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tables table (with position for floor plan)
CREATE TABLE tables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    capacity INTEGER DEFAULT 4,
    status TEXT DEFAULT 'available',
    shape TEXT DEFAULT 'square',
    pos_x DECIMAL(5,2) DEFAULT 0,
    pos_y DECIMAL(5,2) DEFAULT 0,
    width DECIMAL(5,2) DEFAULT 12,
    height DECIMAL(5,2) DEFAULT 12,
    current_order_id UUID,
    reserved_at TIMESTAMPTZ,
    reserved_by TEXT
);

-- Orders table
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_id TEXT,
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
ALTER TABLE tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- Policies (allow authenticated users full access)
CREATE POLICY "Allow authenticated access" ON menu_items
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated access" ON tables
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated access" ON orders
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Allow authenticated access" ON inventory_items
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Enable realtime for orders and inventory
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE inventory_items;

-- Sample menu for Xin Xing (Chinese restaurant)
INSERT INTO menu_items (name, description, price, category) VALUES
    -- Antipasti
    ('Involtini Primavera (4pz)', 'Croccanti involtini vegetariani', 5.50, 'Antipasti'),
    ('Ravioli al Vapore (6pz)', 'Ravioli di carne al vapore', 6.50, 'Antipasti'),
    ('Ravioli alla Piastra (6pz)', 'Ravioli di carne alla piastra', 6.50, 'Antipasti'),
    ('Wonton Fritti (6pz)', 'Ravioli fritti con carne', 5.50, 'Antipasti'),
    ('Edamame', 'Fagioli di soia con sale', 4.50, 'Antipasti'),
    
    -- Zuppe
    ('Zuppa di Wonton', 'Brodo con ravioli di carne', 5.00, 'Zuppe'),
    ('Zuppa Agro-Piccante', 'Zuppa tradizionale piccante', 5.50, 'Zuppe'),
    ('Zuppa di Mais e Pollo', 'Crema di mais con pollo', 5.00, 'Zuppe'),
    
    -- Riso
    ('Riso alla Cantonese', 'Riso saltato con uova, piselli e prosciutto', 7.00, 'Riso'),
    ('Riso con Gamberi', 'Riso saltato con gamberi e verdure', 8.50, 'Riso'),
    ('Riso con Pollo', 'Riso saltato con pollo e verdure', 7.50, 'Riso'),
    
    -- Noodles
    ('Spaghetti di Riso con Manzo', 'Noodles saltati con manzo e verdure', 9.00, 'Noodles'),
    ('Spaghetti di Soia con Gamberi', 'Noodles saltati con gamberi', 9.50, 'Noodles'),
    ('Lo Mein con Pollo', 'Noodles morbidi con pollo', 8.50, 'Noodles'),
    
    -- Pollo
    ('Pollo alle Mandorle', 'Pollo croccante con mandorle', 9.50, 'Pollo'),
    ('Pollo Kung Pao', 'Pollo piccante con arachidi', 9.50, 'Pollo'),
    ('Pollo in Salsa Agrodolce', 'Pollo fritto con salsa agrodolce', 9.00, 'Pollo'),
    ('Pollo con Bambù e Funghi', 'Pollo saltato con verdure', 9.00, 'Pollo'),
    
    -- Manzo
    ('Manzo con Peperoni', 'Manzo saltato con peperoni', 10.50, 'Manzo'),
    ('Manzo in Salsa di Ostriche', 'Manzo con salsa di ostriche', 10.50, 'Manzo'),
    ('Manzo Szechuan', 'Manzo piccante stile Sichuan', 11.00, 'Manzo'),
    
    -- Gamberi
    ('Gamberi con Verdure', 'Gamberi saltati con verdure miste', 11.00, 'Gamberi'),
    ('Gamberi al Curry', 'Gamberi in salsa curry', 11.50, 'Gamberi'),
    ('Gamberi Fritti', 'Gamberi in pastella croccante', 10.50, 'Gamberi'),
    
    -- Anatra
    ('Anatra alla Pechinese', 'Mezza anatra con pancake e salsa', 18.00, 'Anatra'),
    ('Anatra con Bambù', 'Anatra saltata con bambù', 12.00, 'Anatra'),
    
    -- Verdure
    ('Verdure Miste Saltate', 'Verdure di stagione saltate', 7.00, 'Verdure'),
    ('Tofu con Verdure', 'Tofu saltato con verdure', 7.50, 'Verdure'),
    ('Melanzane in Salsa Piccante', 'Melanzane stile Sichuan', 8.00, 'Verdure'),
    
    -- Bevande
    ('Tè Cinese', 'Tè verde o gelsomino', 2.50, 'Bevande'),
    ('Birra Tsingtao', 'Birra cinese 33cl', 4.00, 'Bevande'),
    ('Coca Cola / Fanta / Sprite', 'Lattina 33cl', 2.50, 'Bevande'),
    ('Acqua', 'Naturale o frizzante 50cl', 2.00, 'Bevande'),
    
    -- Dolci
    ('Gelato Fritto', 'Gelato in pastella croccante', 5.00, 'Dolci'),
    ('Banana Fritta', 'Banana caramellata', 4.50, 'Dolci'),
    ('Lychee', 'Frutta esotica', 4.00, 'Dolci');

-- Sample tables for Xin Xing (~30 seats)
-- Layout: entrance at bottom, kitchen at top
INSERT INTO tables (name, capacity, shape, pos_x, pos_y, width, height) VALUES
    -- Left side (along wall)
    ('T1', 4, 'square', 5, 10, 12, 12),
    ('T2', 4, 'square', 5, 28, 12, 12),
    ('T3', 4, 'square', 5, 46, 12, 12),
    ('T4', 2, 'square', 5, 64, 10, 10),
    
    -- Center
    ('T5', 6, 'rectangle', 25, 15, 18, 12),
    ('T6', 6, 'rectangle', 25, 35, 18, 12),
    ('T7', 4, 'round', 28, 58, 12, 12),
    
    -- Right side (along window)
    ('T8', 2, 'square', 55, 10, 10, 10),
    ('T9', 2, 'square', 55, 26, 10, 10),
    ('T10', 4, 'square', 55, 44, 12, 12),
    ('T11', 2, 'square', 55, 64, 10, 10);

-- Sample inventory for Chinese restaurant
INSERT INTO inventory_items (name, quantity, unit, min_quantity, supplier) VALUES
    ('Riso Jasmine', 50, 'kg', 15, 'Asia Market'),
    ('Salsa di Soia', 10, 'litri', 3, 'Asia Market'),
    ('Olio di Sesamo', 5, 'litri', 2, 'Asia Market'),
    ('Noodles di Riso', 20, 'kg', 5, 'Asia Market'),
    ('Noodles di Soia', 15, 'kg', 5, 'Asia Market'),
    ('Gamberi Surgelati', 8, 'kg', 3, 'Ittica Ligure'),
    ('Petto di Pollo', 12, 'kg', 4, 'Macelleria Rossi'),
    ('Manzo', 8, 'kg', 3, 'Macelleria Rossi'),
    ('Anatra', 6, 'pz', 2, 'Macelleria Rossi'),
    ('Verdure Miste', 15, 'kg', 5, 'Ortofrutta Imperia'),
    ('Germogli di Soia', 5, 'kg', 2, 'Asia Market'),
    ('Bambù in Scatola', 20, 'pz', 8, 'Asia Market'),
    ('Funghi Shiitake', 3, 'kg', 1, 'Asia Market'),
    ('Tofu', 10, 'pz', 4, 'Asia Market'),
    ('Birra Tsingtao', 48, 'pz', 24, 'Bevande Liguria'),
    ('Tè Verde', 2, 'kg', 0.5, 'Asia Market');
