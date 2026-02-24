# Backend & Database Changes

This document describes all database and API changes required for the Expiry Alert iOS app.

**Contents:**
- **Part A:** Category and Location Customization (edit/remove only for user-added items)
- **Part B:** Shopping List & Wishlist (schema, endpoints, and logic)

---

# Part A: Category and Location Customization

The app shows **edit** and **remove** only for **user-added (customization)** categories and locations. Fixed/seed categories and locations must not expose edit or remove.

---

## A.1. Database: Categories Table

Add a new column to the **categories** table:

| Column            | Type    | Default | Description |
|-------------------|---------|---------|-------------|
| `is_customization` | BOOLEAN | `false` | `true` when the category was created by a user via "Add Category"; `false` for all seed/default categories. |

- **Migration:** Add the column with default `false` so existing rows (seed categories) are non-customization.
- **New rows from POST `/api/categories`:** Set `is_customization = true`.
- **Seed/default categories:** Ensure they are created/updated with `is_customization = false`.

---

## A.2. API: Category Object

Include `is_customization` in every category payload.

**Category object** (add this field):

- `is_customization` (boolean, optional in JSON): `true` = user-added category (show edit/remove); `false` or omitted = fixed category (no edit/remove).

**Endpoints to update:**

- **GET** `/api/categories` — Each object in `{ categories }` must include `is_customization`.
- **GET** `/api/categories/:id` — The `{ category }` object must include `is_customization`.
- **POST** `/api/categories` — When creating a category, set `is_customization = true` in the database. The returned `{ category }` must include `is_customization: true`.
- **PATCH** `/api/categories/:id` — Response `{ category }` should include `is_customization` (for consistency).

---

## A.3. Categories Behaviour Summary

| Source of category        | `is_customization` | App shows Edit/Remove |
|---------------------------|--------------------|------------------------|
| Seed/default categories   | `false`            | No                     |
| User creates via "Add Category" (POST) | `true`  | Yes                    |

---

## A.4. Optional: Backend Enforcement (Categories)

- **PATCH** `/api/categories/:id` — Only allow updates for categories with `is_customization = true`; return 403 or 400 for others.
- **DELETE** `/api/categories/:id` — Only allow deletion for categories with `is_customization = true`; return 403 or 400 for others.

---

## A.5. Reference: Category Object (after changes)

- `id`
- `group_id` (optional)
- `name`
- `icon` (optional)
- `color` (optional)
- `translation_key` (optional)
- `is_default` (optional)
- **`is_customization`** (optional, boolean) — **NEW**
- `section` (optional)
- `sort_order` (optional)
- `created_at` (optional)
- `updated_at` (optional)

---

## A.6. Database: Locations Table

Add a new column to the **locations** table:

| Column            | Type    | Default | Description |
|-------------------|---------|---------|-------------|
| `is_customization` | BOOLEAN | `false` | `true` when the location was created by a user via "Add Location"; `false` for all seed/default locations. |

- **Migration:** Add the column with default `false` so existing rows (seed locations) are non-customization.
- **New rows from POST `/api/locations`:** Set `is_customization = true`.
- **Seed/default locations:** Ensure they are created/updated with `is_customization = false`.

---

## A.7. API: Location Object

Include `is_customization` in every location payload.

**Location object** (add this field):

- `is_customization` (boolean, optional in JSON): `true` = user-added location (show edit/remove); `false` or omitted = fixed location (no edit/remove).

**Endpoints to update:**

- **GET** `/api/locations` — Each object in `{ locations }` must include `is_customization`.
- **GET** `/api/locations/:id` — The `{ location }` object must include `is_customization`.
- **POST** `/api/locations` — When creating a location, set `is_customization = true` in the database. The returned `{ location }` must include `is_customization: true`.
- **PATCH** `/api/locations/:id` — Response `{ location }` should include `is_customization` (for consistency).

---

## A.8. Locations Behaviour Summary

| Source of location        | `is_customization` | App shows Edit/Remove |
|---------------------------|--------------------|------------------------|
| Seed/default locations    | `false`            | No                     |
| User creates via "Add Location" (POST) | `true`  | Yes                    |

---

## A.9. Optional: Backend Enforcement (Locations)

- **PATCH** `/api/locations/:id` — Only allow updates for locations with `is_customization = true`; return 403 or 400 for others.
- **DELETE** `/api/locations/:id` — Only allow deletion for locations with `is_customization = true`; return 403 or 400 for others.

---

## A.10. Reference: Location Object (after changes)

- `id`
- `group_id` (optional)
- `name`
- `icon` (optional)
- `translation_key` (optional)
- `is_default` (optional)
- **`is_customization`** (optional, boolean) — **NEW**
- `section` (optional)
- `sort_order` (optional)
- `created_at` (optional)
- `updated_at` (optional)

---

**Part A summary:** Add `is_customization` to categories and locations (default `false`), set to `true` on POST create, return in all GET/POST/PATCH responses. Optionally restrict PATCH/DELETE to customization rows only.

---

# Part B: Shopping List & Wishlist

Database schema and API requirements for the Shopping List and Wishlist features. Implement these so the app can sync and persist shopping and wishlist data.

---

## B.1. Database: Shopping List Table

The **shopping_items** table (or equivalent) should support at least the following. If the table already exists, add the new columns via migration.

| Column               | Type         | Default   | Description |
|----------------------|--------------|-----------|-------------|
| `id`                 | UUID / string| —         | Primary key. |
| `group_id`           | UUID / string| —         | FK to groups. Required. |
| `created_by`         | UUID / string| NULL      | User who created. |
| `name`               | VARCHAR      | —         | Item name. Required. |
| `quantity`           | INT          | 1         | Quantity (app sends 1). |
| `unit`               | VARCHAR      | NULL      | Optional. |
| **`where_to_buy`**   | VARCHAR      | NULL      | **NEW.** Store or place (optional). |
| `category_id`        | UUID / string| NULL      | **FK to system categories table.** Required in app; recommend NOT NULL. |
| `is_purchased`       | BOOLEAN      | false     | Checkbox “bought” state. |
| `purchased_at`       | TIMESTAMP    | NULL      | Set when `is_purchased` becomes true; clear when false. |
| `purchased_by`       | UUID / string| NULL      | Optional. |
| **`moved_to_inventory`** | BOOLEAN   | false     | **NEW.** True after user taps “Add to Inventory” and creates an inventory item. |
| **`inventory_item_id`** | UUID / string | NULL   | **NEW.** ID of the food/inventory item created from this shopping item. |
| `notes`              | TEXT         | NULL      | Optional. |
| `created_at`         | TIMESTAMP    | —         | Set on insert. |
| `updated_at`         | TIMESTAMP    | —         | Set on insert/update. |

### Rules

- When **`is_purchased`** is toggled **false → true**: set **`purchased_at` = now**.
- When **`is_purchased`** is toggled **true → false**: set **`purchased_at` = NULL**, and reset **`moved_to_inventory` = false** and **`inventory_item_id` = NULL**.
- **`category_id`** must reference the existing **categories** table (system categories used elsewhere in the app).

---

## B.2. Database: Wishlist Table

The **wish_items** table (or equivalent) should support:

| Column       | Type         | Default | Description |
|--------------|--------------|---------|-------------|
| `id`         | UUID / string| —       | Primary key. |
| `group_id`   | UUID / string| —       | FK to groups. Required. |
| `created_by` | UUID / string| NULL    | Optional. |
| `name`       | VARCHAR      | —       | Item name. Required. |
| `notes`      | TEXT         | NULL    | Optional. |
| `price`      | DECIMAL      | NULL    | Optional. |
| **`currency_code`** | VARCHAR(3) | NULL | **Optional.** ISO currency code (e.g. USD, EUR). |
| **`rating`** | INT          | 3       | **Desire level 1–5.** “How much I want it.” Must be between 1 and 5 (enforce in API/DB). |
| `image_url`  | VARCHAR      | NULL    | Optional. |
| `created_at` | TIMESTAMP    | —       | Set on insert. |
| `updated_at` | TIMESTAMP    | —       | Set on insert/update. |

### Validation

- **`rating`** (desire level): must be in range **1–5**. Reject with 400 if out of range.

---

## B.3. API: Shopping List Endpoints

Base path assumed: **`/api/shopping-items`** (or your existing prefix).

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET    | `/shopping-items?group_id=:id&include_purchased=true\|false` | List items. **include_purchased=true** must return bought items as well (app uses this for “Add to Inventory”). |
| GET    | `/shopping-items/:id` | Single item. |
| POST   | `/shopping-items` | Create. Body below. |
| PATCH  | `/shopping-items/:id` | Update (e.g. toggle bought, set moved_to_inventory). |
| POST   | `/shopping-items/:id/toggle` | Toggle `is_purchased`; set/clear `purchased_at` (and clear `moved_to_inventory` / `inventory_item_id` when toggling to false). |
| DELETE | `/shopping-items/:id` | Delete item. |
| POST   | `/shopping-items/clear-purchased` | Delete all items where `is_purchased = true` for the given group. Body: `{ "group_id": "..." }`. |

### Create (POST) – example body

```json
{
  "group_id": "uuid",
  "name": "Milk",
  "quantity": 1,
  "category_id": "uuid-of-category",
  "where_to_buy": "Supermarket X"
}
```

- **category_id** is required (app validates).
- **where_to_buy** is optional.

### Update (PATCH) – example (mark moved to inventory)

```json
{
  "moved_to_inventory": true,
  "inventory_item_id": "uuid-of-created-food-item"
}
```

### Response – shopping item object

Include at least: `id`, `group_id`, `name`, `quantity`, `category_id`, **`where_to_buy`**, `is_purchased`, `purchased_at`, **`moved_to_inventory`**, **`inventory_item_id`**, `notes`, `created_at`, `updated_at`.

**iOS app note (where_to_buy):** The app sends `where_to_buy` on create and PATCH and displays it on the shopping list. If the create or GET response omits `where_to_buy`, the app uses a client-side merge so the value still appears right after adding; for it to persist after refresh/reload, the backend must persist `where_to_buy` and include it in create and GET responses.

---

## B.4. API: Wishlist Endpoints

Base path: **`/api/wish-items`**.

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET    | `/wish-items?group_id=:id` | List wish items. |
| GET    | `/wish-items/:id` | Single item. |
| POST   | `/wish-items` | Create. Body below. |
| PATCH  | `/wish-items/:id` | Update (name, price, rating/desire level, notes). |
| DELETE | `/wish-items/:id` | Delete item. |

### Create (POST) – example body

```json
{
  "group_id": "uuid",
  "name": "Wireless earbuds",
  "price": 49.99,
  "currency_code": "USD",
  "rating": 5
}
```

- **rating** = desire level 1–5. Validate 1 ≤ rating ≤ 5; return 400 if out of range.
- **currency_code** = optional ISO code (USD, EUR, GBP, JPY, etc.). App lets user pick from a list of currencies.

### Update (PATCH) – example

```json
{
  "name": "Updated name",
  "price": 39.99,
  "currency_code": "EUR",
  "rating": 4
}
```

### Response – wish item object

Include: `id`, `group_id`, `name`, `notes`, `price`, **`currency_code`** (optional), **`rating`** (1–5), `image_url`, `created_at`, `updated_at`.

---

## B.5. Logic Summary (Shopping & Wishlist)

| Feature | Rule |
|--------|------|
| Shopping: toggle bought | On **true**: set `purchased_at` = now. On **false**: clear `purchased_at`, set `moved_to_inventory` = false, `inventory_item_id` = null. |
| Shopping: Add to Inventory | App creates a food/inventory item, then PATCHes shopping item with `moved_to_inventory` = true and `inventory_item_id` = new food item id. |
| Wishlist: desire level | Stored as **rating**; must be 1–5. Validate on POST/PATCH. |

---

## B.6. Example Request/Response (Shopping Item)

**POST /shopping-items**

Request:

```json
{
  "group_id": "abc-123",
  "name": "Bread",
  "quantity": 1,
  "category_id": "cat-456",
  "where_to_buy": "Local store"
}
```

Response (201):

```json
{
  "message": "Created",
  "item": {
    "id": "item-789",
    "group_id": "abc-123",
    "name": "Bread",
    "quantity": 1,
    "category_id": "cat-456",
    "where_to_buy": "Local store",
    "is_purchased": false,
    "purchased_at": null,
    "moved_to_inventory": false,
    "inventory_item_id": null,
    "created_at": "2025-02-14T12:00:00Z",
    "updated_at": "2025-02-14T12:00:00Z"
  }
}
```

---

## B.7. Example Request/Response (Wish Item)

**POST /wish-items**

Request:

```json
{
  "group_id": "abc-123",
  "name": "Noise cancelling headphones",
  "price": 199.99,
  "rating": 5
}
```

Response (201):

```json
{
  "message": "Created",
  "item": {
    "id": "wish-789",
    "group_id": "abc-123",
    "name": "Noise cancelling headphones",
    "price": 199.99,
    "rating": 5,
    "created_at": "2025-02-14T12:00:00Z",
    "updated_at": "2025-02-14T12:00:00Z"
  }
}
```

---

**Part B summary:** Add `where_to_buy`, `moved_to_inventory`, and `inventory_item_id` to shopping_items; support `include_purchased` on GET; enforce wishlist `rating` 1–5. The iOS app uses these for the redesigned Shopping List and Wishlist (modals, category picker, “Add to Inventory,” desire level 1–5).
