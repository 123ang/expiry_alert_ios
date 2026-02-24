# Database redesign: default categories & locations

This document describes schema changes and seed data so the app can offer **default categories** and **default locations** that users can choose from. Defaults are stored with `group_id = NULL` and `is_default = true`, and are grouped by a **section** (e.g. "Food & Drinks", "Kitchen") for display.

**To run the SQL:** Use the file **`seed.sql`** in this folder—it contains only executable SQL (no Markdown). Open or run `seed.sql` in your database client (pgAdmin, DBeaver, psql, etc.). Do not copy from the code blocks below or you may paste the Markdown fence `` ```sql `` and get a syntax error.

---

## 1. Schema changes

Add optional columns to support grouping and ordering. Run these on your backend database (adjust if your ORM manages migrations).

### Categories

```sql
-- Add section (display group) and sort_order for default categories
ALTER TABLE categories
  ADD COLUMN IF NOT EXISTS section VARCHAR(100),
  ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;

-- Optional: index for listing defaults by section/order
CREATE INDEX IF NOT EXISTS idx_categories_default_section
  ON categories (is_default, section, sort_order)
  WHERE group_id IS NULL;
```

### Locations

```sql
ALTER TABLE locations
  ADD COLUMN IF NOT EXISTS section VARCHAR(100),
  ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_locations_default_section
  ON locations (is_default, section, sort_order)
  WHERE group_id IS NULL;
```

**API:** Ensure GET `/api/categories` and GET `/api/locations` return `section` and `sort_order` in each object when present. The iOS app will use them to group and order defaults.

---

## 2. Seed data

Run the seed script **after** the schema changes. Defaults use `group_id = NULL` and `is_default = true`. Replace `NOW()` with your DB’s current-timestamp function if needed (e.g. `CURRENT_TIMESTAMP`).

### PostgreSQL: seed default categories

```sql
INSERT INTO categories (id, group_id, name, icon, color, is_default, section, sort_order, created_at, updated_at) VALUES
-- Food & Drinks
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
-- Health
(gen_random_uuid(), NULL, 'Medicine', '💊', NULL, true, 'Health', 20, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Supplements / Vitamins', '💉', NULL, true, 'Health', 21, NOW(), NOW()),
(gen_random_uuid(), NULL, 'First Aid', '🩹', NULL, true, 'Health', 22, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Medical Devices (e.g., test strips)', '🩺', NULL, true, 'Health', 23, NOW(), NOW()),
-- Personal Care
(gen_random_uuid(), NULL, 'Skincare', '🧴', NULL, true, 'Personal Care', 30, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Makeup', '💄', NULL, true, 'Personal Care', 31, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Hair Care', '💇', NULL, true, 'Personal Care', 32, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Body Care', '🧼', NULL, true, 'Personal Care', 33, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Perfume', '🌸', NULL, true, 'Personal Care', 34, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Hygiene Products', '🪥', NULL, true, 'Personal Care', 35, NOW(), NOW()),
-- Home
(gen_random_uuid(), NULL, 'Cleaning Supplies', '🧹', NULL, true, 'Home', 40, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Laundry', '🧺', NULL, true, 'Home', 41, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Kitchen Supplies (wrap, foil)', '📦', NULL, true, 'Home', 42, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Batteries', '🔋', NULL, true, 'Home', 43, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Light Bulbs', '💡', NULL, true, 'Home', 44, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Filters (water/air)', '💨', NULL, true, 'Home', 45, NOW(), NOW()),
-- Documents
(gen_random_uuid(), NULL, 'Passport', '🛂', NULL, true, 'Documents', 50, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Visa / Residence Card', '📇', NULL, true, 'Documents', 51, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Driver License', '🪪', NULL, true, 'Documents', 52, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Insurance', '📋', NULL, true, 'Documents', 53, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Contracts', '📄', NULL, true, 'Documents', 54, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Bills / Receipts', '🧾', NULL, true, 'Documents', 55, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Warranty', '📑', NULL, true, 'Documents', 56, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Certificates', '📜', NULL, true, 'Documents', 57, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Membership / Subscriptions', '🎫', NULL, true, 'Documents', 58, NOW(), NOW()),
-- Pets
(gen_random_uuid(), NULL, 'Pet Food', '🐕', NULL, true, 'Pets', 60, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Pet Medicine', '💊', NULL, true, 'Pets', 61, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Pet Supplies', '🦴', NULL, true, 'Pets', 62, NOW(), NOW()),
-- Others
(gen_random_uuid(), NULL, 'Electronics / Gadgets', '📱', NULL, true, 'Others', 70, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Stationery', '✏️', NULL, true, 'Others', 71, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Miscellaneous', '📦', NULL, true, 'Others', 72, NOW(), NOW())
ON CONFLICT DO NOTHING;
```

*(Remove `ON CONFLICT DO NOTHING` if your table has no unique constraint on (name, group_id); otherwise add a unique constraint or use a different conflict strategy.)*

### PostgreSQL: seed default locations

```sql
INSERT INTO locations (id, group_id, name, icon, is_default, section, sort_order, created_at, updated_at) VALUES
-- Kitchen
(gen_random_uuid(), NULL, 'Fridge (Top)', '🧊', true, 'Kitchen', 1, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Fridge (Middle)', '🧊', true, 'Kitchen', 2, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Fridge (Bottom)', '🧊', true, 'Kitchen', 3, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Fridge Door', '🚪', true, 'Kitchen', 4, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Freezer', '❄️', true, 'Kitchen', 5, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Pantry', '🗄️', true, 'Kitchen', 6, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Cabinet', '📦', true, 'Kitchen', 7, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Drawer', '🗃️', true, 'Kitchen', 8, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Counter / Shelf', '🪑', true, 'Kitchen', 9, NOW(), NOW()),
-- Home Storage
(gen_random_uuid(), NULL, 'Storage Box', '📦', true, 'Home Storage', 10, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Cardboard Box', '📦', true, 'Home Storage', 11, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Closet / Wardrobe', '👔', true, 'Home Storage', 12, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Under Bed', '🛏️', true, 'Home Storage', 13, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Storage Room', '🚪', true, 'Home Storage', 14, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Garage', '🚗', true, 'Home Storage', 15, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Balcony Storage', '🏠', true, 'Home Storage', 16, NOW(), NOW()),
-- Bathroom
(gen_random_uuid(), NULL, 'Bathroom Cabinet', '🪞', true, 'Bathroom', 20, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Sink Drawer', '🚰', true, 'Bathroom', 21, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Shower Shelf', '🚿', true, 'Bathroom', 22, NOW(), NOW()),
-- Office
(gen_random_uuid(), NULL, 'Desk Drawer', '🪑', true, 'Office', 30, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Bookshelf', '📚', true, 'Office', 31, NOW(), NOW()),
(gen_random_uuid(), NULL, 'File Organizer', '📁', true, 'Office', 32, NOW(), NOW()),
-- Travel
(gen_random_uuid(), NULL, 'Backpack', '🎒', true, 'Travel', 40, NOW(), NOW()),
(gen_random_uuid(), NULL, 'Suitcase', '🧳', true, 'Travel', 41, NOW(), NOW())
ON CONFLICT DO NOTHING;
```

---

## 3. Backend API behavior

- **GET /api/categories**  
  When `group_id` is omitted (or null), include default categories (`group_id IS NULL`, `is_default = true`) and return them with `section` and `sort_order`. Optionally merge with group-specific categories; the app already merges and sorts.

- **GET /api/locations**  
  Same for default locations.

- **POST /api/categories** and **POST /api/locations**  
  For user-created rows, `group_id` is set and `is_default` is false; `section`/`sort_order` can be null.

---

## 4. Idempotency

If you need to re-run the seed without duplicates:

- Ensure there is a unique constraint, e.g. `UNIQUE (name, COALESCE(group_id, '00000000-0000-0000-0000-000000000000'))` for defaults, or use a deterministic seed (e.g. fixed UUIDs per name) and `ON CONFLICT (id) DO UPDATE SET ...`.
- Or clear default rows first: `DELETE FROM categories WHERE group_id IS NULL AND is_default = true;` (and same for locations) before re-inserting.

---

## 5. iOS app

The iOS app has been updated to:

- Decode optional `section` and `sort_order` on `Category` and `Location`.
- When listing categories/locations (e.g. in Settings or in the Add Item picker), group by `section` when present and sort by `sort_order`, then by name, so the seeded defaults appear in the intended order and under the right headings.

After the backend has the new columns and seed data, and returns `section` and `sort_order` in the API responses, the app will show the default categories and locations grouped by section.
