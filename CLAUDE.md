# Expiry Alert iOS

Native SwiftUI app for the Expiry Alert product, backed by the live Express/PostgreSQL API at `https://api.expiry-alert.link`.

## Rules

- **Monetization/pricing/IAP work:** follow `MONETIZATION.md` (canonical,
  approved 2026-06-13). If another note conflicts, `MONETIZATION.md` wins.
- Approved products: Free Local, $24.99-$29.99 Personal Lifetime, $1.99/month
  Premium, $14.99/year Premium, and $24.99/year Family.
- Personal Lifetime is local-only. It never includes cloud sync, cloud backup,
  server-side APNs, cloud photos, household groups, or sharing.
- Premium and Family are subscriptions because they consume recurring server
  resources. Family is annual subscription only and is never Lifetime.
- Entitlements are verified and enforced server-side, with RevenueCat
  recommended. Never authorize paid features from a client-only plan flag.
- Any `$120/yr`, `$40/yr`, or `$57.92/yr` figures found in older notes or the Expo app's mock IAP service are deprecated.
- Known blocking bug before any paid release: `ExpiryAlert/Services/NotificationService.swift` schedules all notifications with `timeInterval: 1` (fires immediately) instead of on expiry dates.
- Auth tokens belong in Keychain (already implemented in `APIService.swift`) — keep it that way.

## Related codebases

- Expo/React Native client (future Android): `../food_expiry_app/FoodExpiryApp`
- Backend + legacy web app: `../food_expiry_app`
