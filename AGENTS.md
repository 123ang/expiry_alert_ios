# Expiry Alert iOS Agent Instructions

Read `MONETIZATION.md` before any pricing, paywall, StoreKit, RevenueCat,
entitlement, cloud-sync, photo-storage, notification, or family-plan work.

Hard rules:

- `MONETIZATION.md` is canonical and wins over older notes.
- Personal Lifetime is $24.99-$29.99 and unlocks local personal features only.
- Premium is $1.99/month or $14.99/year for individual cloud services.
- Family is $24.99/year, subscription only, and never Lifetime.
- Cloud sync, cloud backup, server-side APNs, cloud photos, groups, and sharing
  require an active subscription.
- Verify and enforce entitlements server-side. RevenueCat is recommended.
- Never trust a client-only plan flag for authorization.
- Do not use the deprecated USD40, USD57.92, or USD120 pricing.
- iOS monetization ships before Android billing or web checkout.
- Run `node scripts/check-calendar-notification-scheduling.mjs` after changing
  `ExpiryAlert/Services/NotificationService.swift`.
