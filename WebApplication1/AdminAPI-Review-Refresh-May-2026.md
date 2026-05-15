# NaviDeals AdminAPI Review Refresh

Updated against the current repo state after the static/demo-data removal and database-backing pass.

## Summary

- The runtime admin bootstrap endpoint has been removed.
- OTP and password-reset workflows are now persisted in the database through `AuthChallenges`.
- Seed/demo helpers and hardcoded credential scripts were removed or replaced with env-driven smoke-test scripts.
- First-admin provisioning and one-time demo-data cleanup now live in the separate `WebApplication1.Tools` console project.
- Keeper review, hold, document verification, audit scheduling, loyalty, chat-thread creation, queued notifications, and custom analytics now use persisted database models instead of placeholder responses.

## Status Legend

- `resolved`: fixed in the current codebase
- `partially valid`: improved, but still worth follow-up
- `not present in this repo`: the older report referenced a different snapshot
- `new finding`: discovered during this refresh

## Corrected Findings

### Auth

- `resolved` Refresh-token validation, rotation, and logout revocation are implemented.
- `resolved` Admin/user forgot-password and OTP verification now use persisted `AuthChallenges` instead of cache-only state.
- `resolved` The admin bootstrap HTTP route and related config flags were removed.
- `resolved` Admin 2FA setup, enable, and disable endpoints are exposed and persisted.
- `not present in this repo` The older social-login findings do not apply to this snapshot.

### Users

- `resolved` `/api/v1/users` queries end-user records, not admin accounts.
- `resolved` `reset-2fa` is now a real database update and token-revocation flow.
- `resolved` Bulk user actions enforce action-specific permissions in the controller.
- `partially valid` CSV export streams in batches, but there is still no explicit hard row cap.

### Keepers / Shops / Tags / Loyalty

- `resolved` Keeper request-info, hold, verify-document, and schedule-audit paths now write persisted records.
- `resolved` `KeeperStatus` now supports `OnHold` with hold reason/until metadata.
- `resolved` Shops and tags are namespaced under `/api/v1/admin/shops` and `/api/v1/admin/tags`.
- `resolved` Shop approve, reject, verify, unverify, and status updates now operate on persisted shop records.
- `resolved` Loyalty program reads and writes use `ShopLoyaltyProgram`.

### Notifications / Chat / Analytics

- `resolved` User chat thread creation no longer returns `501`; it creates or reuses persisted `ChatThread` and `ChatMessage` rows.
- `resolved` Notification create/send flows now persist `NotificationDeliveryJob` rows and return queue-oriented status instead of implying confirmed delivery.
- `resolved` `/api/v1/admin/push` now goes through the same persisted notification flow.
- `resolved` Custom analytics reports no longer return placeholder “not implemented” payloads; they execute typed dataset queries and can export CSV.

### Tooling / Cleanup

- `resolved` `DataSeeder`, `SeedShopsClean`, `CheckUsers`, and `InspectShopsSchema` were removed from the web project.
- `resolved` `WebApplication1.Tools` now provides:
  - `create-first-admin`
  - `cleanup-demo-data`
  - `check-users`
  - `inspect-shops-schema`
- `resolved` Hardcoded admin/bootstrap credential scripts were replaced with env-driven scripts.

## New Findings

- `resolved` The previous in-repo review snapshot had become stale and still described cache-backed auth recovery plus bootstrap admin creation.
- `resolved` Generated build/log artifacts needed stronger ignore coverage; `plan_build*/` and `api.stdout.log` are now ignored in the API project.

## Remaining Follow-Up

1. Add a true delivery worker that advances queued notification jobs to `sent` or `failed`.
2. Expand audit coverage across the remaining non-auth destructive workflows not touched in this pass.
3. Continue replacing the remaining lower-priority `object` contracts outside the targeted admin/shared surfaces.
