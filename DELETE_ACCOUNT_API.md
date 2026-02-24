# Delete Account API – Backend Implementation

This document describes the **account deletion** endpoint required for the MyExpiryAlert iOS app (App Store Guideline 5.1.1(v)). The app already calls this endpoint from **Settings → Account → Delete account** after a double confirmation; the backend must implement it.

---

## Endpoint

| Method | Path (relative to `/api`) | Auth |
|--------|----------------------------|------|
| **DELETE** | `/auth/me` | Required (Bearer token) |

**Full URL (production):** `DELETE https://api.expiry-alert.link/api/auth/me`

The iOS app sends:

- **Headers:** `Authorization: Bearer <access_token>`
- **Body:** none (empty body)

You may alternatively expose **DELETE /api/users/me** and have the iOS app call that; the behaviour described below is the same.

---

## Expected behaviour

1. **Authenticate** the request (same as other protected routes). If missing or invalid token, return `401 Unauthorized`.
2. **Resolve the current user** from the JWT (e.g. `req.user.id`).
3. **Permanently delete** the user and all data associated with that user. This must be a **full deletion**, not a soft delete or “deactivate”, to satisfy App Store requirements.

Suggested scope of deletion (adjust to your schema):

- **users** – delete the row for this user.
- **refresh_tokens** (or equivalent) – delete all tokens for this user (all devices).
- **group_memberships** – delete all memberships for this user.
- **invitations** – delete invitations sent by this user and/or pending invitations for this user.
- **groups** – for groups where this user is the only owner, either:
  - delete the group and its related data (food_items, categories, locations, shopping_items, etc.), or
  - transfer ownership if you support it, then delete the user’s membership.
- **food_items**, **categories**, **locations**, **shopping_items**, **wishlist_items**, etc. – delete or reassign according to your business rules (e.g. delete all items in groups owned by this user when you delete those groups).

4. **Response:**
   - **Success:** `204 No Content` (no body), or `200 OK` with e.g. `{ "message": "Account deleted" }`.
   - **Error:** `4xx`/`5xx` with a clear message (e.g. `{ "error": "..." }`). The app will show the error to the user.

---

## Example implementation sketch (Node/Express)

```js
// DELETE /api/auth/me (or DELETE /api/users/me)
router.delete('/me', authMiddleware, async (req, res) => {
  const userId = req.user.id;

  await db.transaction(async (tx) => {
    // 1. Delete or handle groups owned by this user
    // 2. Delete group_memberships for this user
    // 3. Delete invitations involving this user
    // 4. Delete refresh_tokens for this user
    // 5. Delete the user row
    // ... (order may depend on foreign keys)
  });

  return res.status(204).send();
});
```

Use a **transaction** so that a failure partway through does not leave the account half-deleted.

---

## App Store compliance

- The app **must** offer account deletion when it supports account creation (Guideline 5.1.1(v)).
- “Temporarily deactivate” or “disable” is **not** sufficient; deletion must be **permanent**.
- The iOS app already provides:
  - A clear “Delete account” entry in Settings → Account.
  - A **double confirmation** (two alerts) before calling this API.
  - Error handling and a loading state.

Once this endpoint is implemented and returns success for a valid authenticated request, the app will clear the local session and return the user to the login screen.

---

## Summary

| Item | Detail |
|------|--------|
| Method | `DELETE` |
| Path | `/api/auth/me` (or `/api/users/me`) |
| Auth | Bearer token required |
| Body | None |
| Success | `204 No Content` or `200` with message |
| Side effect | Permanently delete the user and associated data |
