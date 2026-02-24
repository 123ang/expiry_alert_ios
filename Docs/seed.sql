-- ============================================================
-- RUN THE ENTIRE FILE FROM TOP TO BOTTOM (or run Part 1 first,
-- then Part 2). If you get "column section does not exist", run
-- Part 1 below to add the columns, then run the INSERTs.
-- ============================================================

-- PART 1: Add columns (safe to run even if they already exist)
-- ============================================================

-- Categories: section, sort_order
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'categories' AND column_name = 'section') THEN
    ALTER TABLE categories ADD COLUMN section VARCHAR(100);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'categories' AND column_name = 'sort_order') THEN
    ALTER TABLE categories ADD COLUMN sort_order INT DEFAULT 0;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_categories_default_section
  ON categories (is_default, section, sort_order)
  WHERE group_id IS NULL;

-- Locations: section, sort_order
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'locations' AND column_name = 'section') THEN
    ALTER TABLE locations ADD COLUMN section VARCHAR(100);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'locations' AND column_name = 'sort_order') THEN
    ALTER TABLE locations ADD COLUMN sort_order INT DEFAULT 0;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_locations_default_section
  ON locations (is_default, section, sort_order)
  WHERE group_id IS NULL;

-- ============================================================
-- 3. Seed default categories
-- ============================================================
INSERT INTO categories (id, group_id, name, icon, color, is_default, section, sort_order, created_at, updated_at) VALUES
(gen_random_uuid(), NULL, 'Fresh Food', '🥬', NULL, true, 'Food & Drinks', 1, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Cooked Food / Leftovers', '🍱', NULL, true, 'Food & Drinks', 2, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Snacks', '🍪', NULL, true, 'Food & Drinks', 3, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Drinks', '🥤', NULL, true, 'Food & Drinks', 4, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Frozen Food', '🧊', NULL, true, 'Food & Drinks', 5, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Dairy', '🥛', NULL, true, 'Food & Drinks', 6, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Meat / Seafood', '🥩', NULL, true, 'Food & Drinks', 7, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Fruits', '🍎', NULL, true, 'Food & Drinks', 8, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Vegetables', '🥕', NULL, true, 'Food & Drinks', 9, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Bread / Bakery', '🍞', NULL, true, 'Food & Drinks', 10, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Condiments & Sauces', '🫙', NULL, true, 'Food & Drinks', 11, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Spices & Seasoning', '🧂', NULL, true, 'Food & Drinks', 12, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Canned / Packaged Food', '🥫', NULL, true, 'Food & Drinks', 13, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Baby Food', '🍼', NULL, true, 'Food & Drinks', 14, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Medicine', '💊', NULL, true, 'Health', 20, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Supplements / Vitamins', '💉', NULL, true, 'Health', 21, NOW(), NOW()),
(gen_random_uuid(), NULL, 'First Aid', '🩹', NULL, true, 'Health', 22, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Medical Devices (e.g., test strips)', '🩺', NULL, true, 'Health', 23, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Skincare', '🧴', NULL, true, 'Personal Care', 30, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Makeup', '💄', NULL, true, 'Personal Care', 31, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Hair Care', '💇', NULL, true, 'Personal Care', 32, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Body Care', '🧼', NULL, true, 'Personal Care', 33, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Perfume', '🌸', NULL, true, 'Personal Care', 34, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Hygiene Products', '🪥', NULL, true, 'Personal Care', 35, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Cleaning Supplies', '🧹', NULL, true, 'Home', 40, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Laundry', '🧺', NULL, true, 'Home', 41, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Kitchen Supplies (wrap, foil)', '📦', NULL, true, 'Home', 42, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Batteries', '🔋', NULL, true, 'Home', 43, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Light Bulbs', '💡', NULL, true, 'Home', 44, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Filters (water/air)', '💨', NULL, true, 'Home', 45, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Passport', '🛂', NULL, true, 'Documents', 50, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Visa / Residence Card', '📇', NULL, true, 'Documents', 51, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Driver License', '🪪', NULL, true, 'Documents', 52, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Insurance', '📋', NULL, true, 'Documents', 53, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Contracts', '📄', NULL, true, 'Documents', 54, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Bills / Receipts', '🧾', NULL, true, 'Documents', 55, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Warranty', '📑', NULL, true, 'Documents', 56, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Certificates', '📜', NULL, true, 'Documents', 57, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Membership / Subscriptions', '🎫', NULL, true, 'Documents', 58, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Pet Food', '🐕', NULL, true, 'Pets', 60, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Pet Medicine', '💊', NULL, true, 'Pets', 61, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Pet Supplies', '🦴', NULL, true, 'Pets', 62, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Electronics / Gadgets', '📱', NULL, true, 'Others', 70, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Stationery', '✏️', NULL, true, 'Others', 71, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Miscellaneous', '📦', NULL, true, 'Others', 72, NOW(), NOW());

-- ============================================================
-- 4. Seed default locations
-- ============================================================
INSERT INTO locations (id, group_id, name, icon, is_default, section, sort_order, created_at, updated_at) VALUES
(gen_random_uuid(), NULL, 'Fridge (Top)', '🧊', true, 'Kitchen', 1, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Fridge (Middle)', '🧊', true, 'Kitchen', 2, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Fridge (Bottom)', '🧊', true, 'Kitchen', 3, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Fridge Door', '🚪', true, 'Kitchen', 4, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Freezer', '❄️', true, 'Kitchen', 5, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Pantry', '🗄️', true, 'Kitchen', 6, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Cabinet', '📦', true, 'Kitchen', 7, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Drawer', '🗃️', true, 'Kitchen', 8, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Counter / Shelf', '🪑', true, 'Kitchen', 9, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Storage Box', '📦', true, 'Home Storage', 10, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Cardboard Box', '📦', true, 'Home Storage', 11, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Closet / Wardrobe', '👔', true, 'Home Storage', 12, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Under Bed', '🛏️', true, 'Home Storage', 13, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Storage Room', '🚪', true, 'Home Storage', 14, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Garage', '🚗', true, 'Home Storage', 15, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Balcony Storage', '🏠', true, 'Home Storage', 16, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Bathroom Cabinet', '🪞', true, 'Bathroom', 20, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Sink Drawer', '🚰', true, 'Bathroom', 21, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Shower Shelf', '🚿', true, 'Bathroom', 22, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Desk Drawer', '🪑', true, 'Office', 30, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Bookshelf', '📚', true, 'Office', 31, NOW(), NOW()),
(gen_random_uuid(), NULL, 'File Organizer', '📁', true, 'Office', 32, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Backpack', '🎒', true, 'Travel', 40, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Suitcase', '🧳', true, 'Travel', 41, NOW(), NOW());
