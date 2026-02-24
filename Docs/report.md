# Categories Screen – Backend Error Report

**Date:** February 2026  
**Issue:** Categories screen shows “Couldn’t load categories” with “Server error (500): Internal server error”.

---

## Conclusion

**This is a backend error.** The iOS app is behaving correctly. The API at `https://api.expiry-alert.link` returns **500 Internal Server Error** when the app (or Postman) calls **GET /api/categories**. The backend must be fixed so this endpoint returns **200** with `{ "categories": [ ... ] }`.

---

## What was verified

| Check | Result |
|-------|--------|
| API health | **200** – server is up |
| Login | **200** – auth works |
| GET /api/groups | **200** – groups returned |
| **GET /api/categories** (no `group_id`) | **500** – Internal server error |
| **GET /api/categories** (with `group_id`) | **500** – Internal server error |
| POST /api/categories | **201** – create works |
| Database `categories` table | All expected columns present (`section`, `sort_order`, etc.) |

So: listing categories fails; creating a category works; the database schema is complete. The bug is in the backend code that handles **GET /api/categories**.

---

## What was done on the iOS app

- **Error handling:** When GET categories fails, the app shows “Couldn’t load categories”, the server error message, and a **Retry** button instead of a blank screen.
- **Refresh:** Categories are refreshed on appear, when the Quick Setup sheet closes, and on pull-to-refresh.
- **Auth:** Token is sent correctly; 401 was resolved by using only the raw access token in Postman.

No further app changes are required for this issue.

---

## What the backend team needs to do

1. **Reproduce:** Call GET `/api/categories` with a valid `Authorization: Bearer <token>` (with or without `group_id`). The response is 500.
2. **Find the error:** Check the **API server logs** at the time of that request. The log will show the real exception (e.g. missing column, null reference, or ORM error).
3. **Fix:** Typical causes:
   - **Null `group_id`:** When the request has no `group_id`, the handler must query default categories (e.g. `WHERE group_id IS NULL`), not pass `null` into a `WHERE group_id = $1` style query.
   - **Missing column / ORM mismatch:** Align the Category model and query with the actual `categories` table (all 14 columns are present in the DB).
   - **Join or serialization:** If the handler joins to `users` or builds JSON from relations, ensure nulls are handled (e.g. optional chaining, LEFT JOIN).

After the backend returns **200** with `{ "categories": [ ... ] }` for GET /api/categories, the Categories screen will work without any further iOS changes.

---

## API endpoint test results (February 2026)

All links from `API_REFERENCE.md` that can be tested with GET + auth were called. Results:

| Endpoint | Status | Notes |
|----------|--------|--------|
| GET /health | 200 | OK |
| POST /api/auth/login | 200 | OK |
| GET /api/users/me | 200 | OK |
| GET /api/users/me/settings | 200 | OK |
| GET /api/groups | 200 | OK |
| GET /api/groups/:id | 200 | OK |
| GET /api/invitations | 200 | OK |
| GET /api/food-items?group_id=... | 200 | OK |
| GET /api/food-items/expiring?group_id=...&days=3 | 200 | OK |
| GET /api/food-items/expired?group_id=... | 200 | OK |
| GET /api/analytics/summary?group_id=... | 200 | OK |
| **GET /api/categories** | **500** | Internal server error |
| **GET /api/categories?group_id=...** | **500** | Internal server error |
| **GET /api/locations** | **500** | Internal server error |
| **GET /api/locations?group_id=...** | **500** | Internal server error |
| **GET /api/shopping-items?group_id=...** | **404** | Route not found |
| **GET /api/wish-items?group_id=...** | **404** | Route not found |

### Failing endpoints (backend fix required)

1. **GET /api/categories** (with or without `group_id`) → **500**  
   Backend crashes when listing categories. See “What the backend team needs to do” above.

2. **GET /api/locations** (with or without `group_id`) → **500**  
   Same behaviour as categories; backend likely has the same kind of bug when listing locations (e.g. null `group_id` or missing column handling).

3. **GET /api/shopping-items?group_id=...** → **404**  
   Response: `{"error":"Route not found","path":"/api/shopping-items"}`. Backend may expose this under a different path (e.g. `/api/shopping-list`); align routes with `API_REFERENCE.md` or update the docs.

4. **GET /api/wish-items?group_id=...** → **404**  
   Response: `{"error":"Route not found","path":"/api/wish-items"}`. Same as above; backend route may differ from the reference.

---

## Reference

- **API base:** `https://api.expiry-alert.link`
- **Endpoint:** GET `/api/categories` (optional query: `group_id`)
- **Expected response:** `200` with body `{ "categories": [ ... ] }`
- **Database:** `categories` table has `id`, `group_id`, `name`, `icon`, `color`, `is_default`, `created_by`, `created_at`, `updated_at`, `deleted_at`, `version`, `translation_key`, `section`, `sort_order`. Seed data and schema are in `DATABASE_SEED.md` and `seed.sql`.
