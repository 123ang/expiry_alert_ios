# Expiry Alert API Reference

**Base URL (production):** `https://api.expiry-alert.link`  
**Base path:** All API routes are under `/api/...`

- **Web app:** `https://expiry-alert.link` (served by nginx from web-app build)
- **API:** `https://api.expiry-alert.link` (proxies to backend on `localhost:3006`)
- **Uploaded images:** `https://api.expiry-alert.link/uploads/<filename>`

---

## Authentication

- **Login/Register/Refresh:** No `Authorization` header.
- **All other routes:** Send `Authorization: Bearer <access_token>`.

Access token expires in ~15 minutes; use refresh token to get a new access token.

---

## Health Check (no auth)

| Method | URL | Function |
|--------|-----|----------|
| GET | `https://api.expiry-alert.link/health` | Server health check. Returns `{ status, timestamp, environment }`. |

---

## 1. Auth — `/api/auth`

| Method | Full URL | Function |
|--------|----------|----------|
| POST | `https://api.expiry-alert.link/api/auth/register` | Register new user. Body: `{ email, password, full_name?, device_info }`. Returns `{ message, user, tokens, device }`. |
| POST | `https://api.expiry-alert.link/api/auth/login` | Login. Body: `{ email, password, device_info }`. Returns `{ message, user, tokens, device }`. |
| POST | `https://api.expiry-alert.link/api/auth/refresh` | Refresh access token. Body: `{ refreshToken }`. Uses refresh-token auth. Returns `{ message, tokens }`. |
| POST | `https://api.expiry-alert.link/api/auth/logout` | Logout (invalidate refresh token for this device). Requires Bearer token. Returns `{ message }`. |

**device_info:** `{ device_uuid, device_name?, device_type?, platform }` (e.g. `"ios"`, `"android"`).

---

## 2. Users — `/api/users` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| GET | `https://api.expiry-alert.link/api/users/me` | Get current user profile. Returns `{ user }`. |
| PATCH | `https://api.expiry-alert.link/api/users/me` | Update profile. Body: `{ full_name?, language_preference?, ... }`. Returns `{ message, user }`. |
| GET | `https://api.expiry-alert.link/api/users/me/settings` | Get user settings. Returns `{ settings }`. |
| PATCH | `https://api.expiry-alert.link/api/users/me/settings` | Update settings. Body: e.g. `{ theme?, notification_time?, expiring_soon_days?, expiring_today_alerts?, expired_alerts? }`. Returns `{ message, settings }`. |

---

## 3. Groups — `/api/groups` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| POST | `https://api.expiry-alert.link/api/groups` | Create group. Body: `{ name, description? }`. Returns `{ message, group }`. |
| GET | `https://api.expiry-alert.link/api/groups` | List user's groups. Returns `{ groups }`. |
| GET | `https://api.expiry-alert.link/api/groups/:id` | Get group by ID. Returns `{ group }`. |
| PATCH | `https://api.expiry-alert.link/api/groups/:id` | Update group. Body: `{ name?, description? }`. Returns `{ message, group }`. |
| DELETE | `https://api.expiry-alert.link/api/groups/:id` | Delete group. Returns `{ message }`. |
| GET | `https://api.expiry-alert.link/api/groups/:id/members` | List group members. Returns `{ members }`. |
| DELETE | `https://api.expiry-alert.link/api/groups/:id/members/:memberId` | Remove member. Returns `{ message }`. |
| PATCH | `https://api.expiry-alert.link/api/groups/:id/members/:memberId` | Update member role. Body: `{ role }` (`owner` \| `admin` \| `member`). Returns `{ message }`. |

---

## 4. Invitations — `/api/invitations` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| POST | `https://api.expiry-alert.link/api/invitations/send` | Send invitation. Body: `{ group_id, email }`. Returns `{ message, invitation }`. |
| GET | `https://api.expiry-alert.link/api/invitations` | Get current user's pending invitations. Returns `{ invitations }`. |
| POST | `https://api.expiry-alert.link/api/invitations/join` | Join group by invite code. Body: `{ invite_code }`. Returns `{ message }`. |
| POST | `https://api.expiry-alert.link/api/invitations/:id/accept` | Accept invitation. Returns `{ message }`. |
| POST | `https://api.expiry-alert.link/api/invitations/:id/decline` | Decline invitation. Returns `{ message }`. |
| GET | `https://api.expiry-alert.link/api/invitations/verify/:code` | Verify invite code (e.g. for join page). Returns invite/group info. |

---

## 5. Food Items — `/api/food-items` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| POST | `https://api.expiry-alert.link/api/food-items` | Create food item. Body: `group_id`, `name`, `quantity?`, `unit?`, `category_id?`, `location_id?`, `expiry_date?`, `purchase_date?`, `notes?`, `image_url?`, `brand?`, etc. Returns `{ message, item }`. |
| GET | `https://api.expiry-alert.link/api/food-items?group_id=...` | List food items. Query: `group_id` (required), `category_id?`, `location_id?`, `is_consumed?`, `status?`. Returns `{ items }`. |
| GET | `https://api.expiry-alert.link/api/food-items/expiring?group_id=...&days=3` | Items expiring within `days` (default 3). Returns `{ items }`. |
| GET | `https://api.expiry-alert.link/api/food-items/expired?group_id=...` | Expired items. Returns `{ items }`. |
| GET | `https://api.expiry-alert.link/api/food-items/:id` | Get one food item. Returns `{ item }`. |
| PATCH | `https://api.expiry-alert.link/api/food-items/:id` | Update food item. Body: any updatable fields. Returns `{ message, item }`. |
| DELETE | `https://api.expiry-alert.link/api/food-items/:id` | Delete food item. Returns `{ message }`. |
| POST | `https://api.expiry-alert.link/api/food-items/:id/events` | Log event (used/throw/expired etc.). Body: `{ event_type, quantity_affected, disposal_reason? }`. Returns `{ message, event }`. |
| GET | `https://api.expiry-alert.link/api/food-items/:id/events` | Get event history for item. Returns `{ events }`. |

**event_type:** `used_completely` \| `used_partially` \| `thrown_away` \| `gifted` \| `expired_unused`.

---

## 6. Categories — `/api/categories` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| GET | `https://api.expiry-alert.link/api/categories?group_id=...` | List categories. Query: `group_id` (optional). Returns `{ categories }`. |
| GET | `https://api.expiry-alert.link/api/categories/:id` | Get category by ID. Returns `{ category }`. |
| POST | `https://api.expiry-alert.link/api/categories` | Create category. Body: `{ group_id, name, icon?, color? }`. Returns `{ message, category }`. |
| PATCH | `https://api.expiry-alert.link/api/categories/:id` | Update category. Body: `{ name?, icon?, color? }`. Returns `{ message, category }`. |
| DELETE | `https://api.expiry-alert.link/api/categories/:id` | Delete category. Returns `{ message }`. |

**Category object:** `id`, `group_id?`, `name`, `icon?`, `color?`, `translation_key?`, `is_default?`, `section?`, `sort_order?`, `created_at?`, `updated_at?`. For default (seed) categories, `section` groups display (e.g. `"Food & Drinks"`, `"Health"`) and `sort_order` defines order within section.

---

## 7. Locations — `/api/locations` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| GET | `https://api.expiry-alert.link/api/locations?group_id=...` | List locations. Query: `group_id` (optional). Returns `{ locations }`. |
| GET | `https://api.expiry-alert.link/api/locations/:id` | Get location by ID. Returns `{ location }`. |
| POST | `https://api.expiry-alert.link/api/locations` | Create location. Body: `{ group_id, name, icon? }`. Returns `{ message, location }`. |
| PATCH | `https://api.expiry-alert.link/api/locations/:id` | Update location. Body: `{ name?, icon? }`. Returns `{ message, location }`. |
| DELETE | `https://api.expiry-alert.link/api/locations/:id` | Delete location. Returns `{ message }`. |

**Location object:** `id`, `group_id?`, `name`, `icon?`, `translation_key?`, `is_default?`, `section?`, `sort_order?`, `created_at?`, `updated_at?`. For default (seed) locations, `section` groups display (e.g. `"Kitchen"`, `"Home Storage"`) and `sort_order` defines order within section.

---

## 8. Shopping Items — `/api/shopping-items` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| GET | `https://api.expiry-alert.link/api/shopping-items?group_id=...&include_purchased=false` | List shopping items. Returns `{ items }`. |
| GET | `https://api.expiry-alert.link/api/shopping-items/:id` | Get one shopping item. Returns `{ item }`. |
| POST | `https://api.expiry-alert.link/api/shopping-items` | Create. Body: `{ group_id, name, quantity?, unit?, category_id?, notes? }`. Returns `{ item }`. |
| PATCH | `https://api.expiry-alert.link/api/shopping-items/:id` | Update. Body: `{ name?, quantity?, unit?, category_id?, is_purchased?, notes? }`. Returns `{ item }`. |
| DELETE | `https://api.expiry-alert.link/api/shopping-items/:id` | Delete. Returns 204. |
| POST | `https://api.expiry-alert.link/api/shopping-items/:id/toggle` | Toggle purchase status. Returns `{ item }`. |
| POST | `https://api.expiry-alert.link/api/shopping-items/clear-purchased` | Clear purchased items. Body: `{ group_id }`. Returns `{ deleted_count }`. |

---

## 9. Wish Items — `/api/wish-items` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| GET | `https://api.expiry-alert.link/api/wish-items?group_id=...` | List wish items. Returns `{ items }`. |
| GET | `https://api.expiry-alert.link/api/wish-items/:id` | Get one wish item. Returns `{ item }`. |
| POST | `https://api.expiry-alert.link/api/wish-items` | Create. Body: `{ group_id, name, notes? }`. Returns `{ item }`. |
| PATCH | `https://api.expiry-alert.link/api/wish-items/:id` | Update. Body: `{ name?, notes? }`. Returns `{ item }`. |
| DELETE | `https://api.expiry-alert.link/api/wish-items/:id` | Delete. Returns 204. |

---

## 10. Upload — `/api/upload` (auth required)

| Method | Full URL | Function |
|--------|----------|----------|
| POST | `https://api.expiry-alert.link/api/upload/image` | Upload image. `multipart/form-data`, field name `image`. Max 10MB. Allowed: JPEG, PNG, GIF, WebP. Returns `{ message, file: { id, filename, path, url, size, mimetype } }`. Use `file.url` for food item `image_url`. |
| DELETE | `https://api.expiry-alert.link/api/upload/image/:filename` | Delete image by filename. Returns `{ message }`. |

**Image URL for display:** `https://api.expiry-alert.link/uploads/<filename>` (nginx serves from backend `uploads/` folder).

---

## 11. Analytics — `/api/analytics` (auth required)

All analytics routes require query `group_id`.

| Method | Full URL | Function |
|--------|----------|----------|
| GET | `https://api.expiry-alert.link/api/analytics/summary?group_id=...&start_date?&end_date?&months=3` | Waste summary. Returns `{ summary }`. |
| GET | `https://api.expiry-alert.link/api/analytics/category-breakdown?group_id=...&start_date?&end_date?` | Waste by category. Returns `{ breakdown }`. |
| GET | `https://api.expiry-alert.link/api/analytics/location-breakdown?group_id=...&start_date?&end_date?` | Waste by location. Returns `{ breakdown }`. |
| GET | `https://api.expiry-alert.link/api/analytics/monthly-trends?group_id=...&months=12` | Monthly trends. Returns `{ trends }`. |
| GET | `https://api.expiry-alert.link/api/analytics/most-wasted?group_id=...&limit=10` | Most wasted items. Returns `{ items }`. |
| GET | `https://api.expiry-alert.link/api/analytics/disposal-reasons?group_id=...` | Disposal reasons breakdown. Returns `{ reasons }`. |
| GET | `https://api.expiry-alert.link/api/analytics/expiry-patterns?group_id=...` | Expiry patterns. Returns `{ patterns }`. |
| GET | `https://api.expiry-alert.link/api/analytics/comprehensive?group_id=...&months=3` | All analytics in one call. Returns `{ analytics }`. |

---

## Quick reference: base URLs

| Purpose | URL |
|--------|-----|
| API base | `https://api.expiry-alert.link` |
| API prefix | `https://api.expiry-alert.link/api` |
| Health | `https://api.expiry-alert.link/health` |
| Uploaded images | `https://api.expiry-alert.link/uploads/<filename>` |
| Web app | `https://expiry-alert.link` |

Use **HTTPS** in production. For local dev, backend runs on `PORT` (e.g. 3000 or 3006); nginx proxies production traffic to `localhost:3006`.
