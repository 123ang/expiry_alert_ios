# Expiry Alert Monetization Plan (Canonical)

**Status:** Approved strategy, aligned 2026-06-13.
**Audience:** Every developer or AI assistant working on Expiry Alert.
**Tie-breaker:** If another file conflicts with this one, this file wins.

This document supersedes the old `USD 120/yr`, `USD 40/yr`, and `$57.92/yr`
figures. Do not restore or reuse those prices.

## 1. Product Principle

- Free Local remains useful forever and keeps pantry data on the device.
- A one-time Lifetime purchase may unlock local personal features with near-zero
  ongoing server cost.
- Any feature that continuously uses the backend, cloud storage, APNs, sync, or
  household sharing requires an active subscription.
- Family/group access is never sold as Lifetime.

## 2. Approved Tiers And Prices

| Entitlement | Store price | Billing | Core purpose |
|---|---:|---|---|
| `free_local` | $0 | Free | Private single-device tracking |
| `personal_lifetime` | $24.99-$29.99 | One-time | Personal local features forever |
| `premium` | $1.99/month | Subscription | Individual cloud services |
| `premium` | $14.99/year | Subscription | Recommended individual cloud plan |
| `family` | $24.99/year | Subscription only | Shared household cloud plan, up to 6 members |

The paywall should recommend Premium Annual. Monthly remains available as a
lower-commitment option. An introductory Premium Annual offer of $9.99 for the
first year is allowed.

Do not create a Family Lifetime product. Do not include cloud services in
Personal Lifetime.

### Regional Premium Annual price points

Use explicit App Store price points instead of simple currency conversion:

- Malaysia: approximately RM29.90/year.
- Thailand: approximately THB249/year.
- Japan: approximately JPY1,500-JPY2,000/year.

Choose Family and Lifetime regional price points in App Store Connect before
launch. Do not reintroduce the old RM59/RM149 roadmap prices without a new,
explicit pricing decision.

## 3. Feature Entitlement Matrix

| Feature | Free Local | Personal Lifetime | Premium subscription | Family subscription |
|---|---|---|---|---|
| Local item tracking | Limited to about 30-50 items | Unlimited | Unlimited | Unlimited |
| Themes and languages | Included | Included | Included | Included |
| Device-scheduled local notifications | Included | Included | Included | Included |
| Local export/import | Included | Included | Included | Included |
| Personal photos | Limited, compressed, local | Higher capped local allowance | Cloud allowance | Shared cloud allowance |
| Analytics and advanced stats | Basic | Personal local stats | Full | Full household stats |
| Server-side APNs notifications | No | No | Yes | Yes |
| Cloud backup and restore | No | No | Yes | Yes |
| Sync across a user's devices | No | No | Yes | Yes |
| Household groups and invitations | No | No | No | Yes |
| Shared photos and member attribution | No | No | No | Yes |

Important wording:

- "Local notifications" means notifications scheduled by the app on the device.
- "Server-side push" means APNs/backend delivery and is subscription-only.
- "Lifetime" means personal local features, not lifetime cloud access.

## 4. Entitlement Architecture (Non-Negotiable)

1. iOS payment uses Apple In-App Purchase with StoreKit 2. Expiry Alert never
   processes card details directly.
2. RevenueCat is the recommended purchase/receipt layer. Its current public
   pricing starts free for up to $2,500 in monthly tracked revenue, then charges
   1% of tracked revenue.
3. RevenueCat webhooks or App Store validation update the PostgreSQL backend.
   Add a server-owned entitlement/subscription model with fields equivalent to:
   `plan`, `product_id`, `status`, `expires_at`, `original_transaction_id`, and
   `provider`.
4. Clients ask the API for their effective entitlement. Never trust a locally
   edited plan flag.
5. The backend must enforce cloud sync, groups, shared photos, APNs, and other
   server features. Hiding a button in the app is not authorization.
6. Lifetime purchases still need server-side verification so Restore Purchases
   and device changes work, even though Lifetime does not unlock cloud data.
7. The paywall must provide Restore Purchases and subscription management.

## 5. Platform Sequencing

1. Native iOS ships monetization first and is the flagship paid client.
2. The Expo app remains the future Android client. Before release, replace its
   mock IAP service with RevenueCat and migrate legacy `free | family` plan types
   to the canonical entitlement model.
3. The web app remains marketing/landing-first. Do not build Stripe checkout or
   promise web billing until iOS monetization has traction and a separate
   decision approves it.

## 6. Blocking Work Before Charging

- [x] Fix `ExpiryAlert/Services/NotificationService.swift`: expiry alerts now
  use calendar-based `UNCalendarNotificationTrigger` scheduling. Verification
  guard: `node scripts/check-calendar-notification-scheduling.mjs`.
- [ ] Add server-side APNs for Premium and Family.
- [ ] Add backend entitlement/subscription tables and RevenueCat webhook
  verification.
- [ ] Build the SwiftUI paywall for Free, Personal Lifetime, Premium, and Family.
- [ ] Add Restore Purchases and Manage Subscription flows.
- [ ] Enroll in Apple's App Store Small Business Program.
- [ ] Publish the privacy policy and complete App Privacy disclosures.
- [ ] Define photo compression and storage caps for every tier before enabling
  cloud photo uploads.

## 7. Economics And Cost Controls

- The VPS is mostly a fixed cost; cloud storage and shared photos are the more
  important variable costs.
- Compress photos, define quotas, and monitor storage instead of promising
  unlimited cloud storage.
- Personal Lifetime is sustainable because it excludes recurring cloud
  services.
- Premium and Family subscriptions fund APNs, backups, sync, shared data, and
  ongoing operations.
- Apple currently offers qualifying developers a reduced 15% commission through
  the App Store Small Business Program.

## 8. Official References

- RevenueCat pricing: https://www.revenuecat.com/pricing/
- Apple Small Business Program:
  https://developer.apple.com/app-store/small-business-program/
- Apple App Review Guidelines:
  https://developer.apple.com/app-store/review/guidelines/
