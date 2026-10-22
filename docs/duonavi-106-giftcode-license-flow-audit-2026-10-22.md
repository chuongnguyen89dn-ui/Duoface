# DuoNavi 1.0.6 — giftcode redemption and 30-day license flow (static audit)

Date: 2026-10-22 (Asia/Ho_Chi_Minh). Project: DuoFace reference research. Read-only inspection; no live phone/backend session, no license edits or redemption requests.

## Sources

- Two conversation-uploaded packages: `com.duonavi.app_1.0.6_iphoneos-arm64.deb` (SHA-256 `8a6457f8c8c7dc78e984b49bbcfa22b382952d785132601e15f2b8da33bed375`) and its ` 2.deb` counterpart (SHA-256 `5a5e27d8f81e035e594644e18dd0b4b0676d081a8b7b4836e131b662d12968c7`).
- Both unpack to 50 data files; 49 match byte-for-byte. Their `DuoNaviUI` binaries match SHA-256 (`b13485b21aaca9a2bcd2de7bd41c2c15ae7094c138caac088eff6bf05a82cafe`) and `DuoNaviDashboard.dylib` binaries match SHA-256 (`63f742d486da2dd59abb290de5d8892bf2ebf0acf443ef1eb44234e7b38e0d51`). The different data file is the tweak's bundle filter plist, unrelated to license state.
- Relevant history: repository `tiep tuc du an.md`, 2026-10-12/13: preexisting per-device runtime files `com.duonavi.license.data` (observed 1020 B) and `com.duonavi.sync.plist` under `/var/mobile/Library/Preferences/`; older experimental duration cache values are *not* current-device server expiry.

## User observation to investigate

User reports that a 30-day promotional activation code was entered today and the application displayed 30 days of use. This is a user observation, not a server transaction independently verified in this audit. The specific code is intentionally omitted from this public report.

## Static evidence — Objective-C ARM64 disassembly of 1.0.6 DuoNaviUI

| Stage | Verified code evidence |
|---|---|
| UI button | `CBSubscriptionViewController -giftcodeRedeemCellDidTapRedeem:` IMP `0x10001fe94` dispatches `-redeemGiftCodeTapped` |
| Prepare redemption | `-redeemGiftCodeTapped` IMP `0x1000200e8`: reads giftcode input, trims whitespace/newlines, invokes `uppercaseString`, obtains `CBLicenseSyncManager deviceHardwareHashHex`, checks a 64-character identifier |
| Send to backend | Builds a JSON dictionary with keys `code` and `hw_hash`, obtains `resolvedBackendBaseURL`, invokes `CBHttpClient postJSON:toURL:timeout:customHeaders:completion:` (10-second timeout). Exact giftcode endpoint is not proven from plaintext strings. |
| Response | Completion callback parses JSON dictionary, reads numeric response key `code` and checks `200` (`0xc8`); reads `payload_base64` |
| Cryptographic license | Base64-decodes payload and calls `CBLicenseSyncManager installAndVerifyLicensePayload:errorMsg:` (`0x1000a4998`), which checks payload length `0x3fc` = 1,020 bytes and runs further validation logic |
| Expiry/tier update | Callback reads `actual_expire_at` and calls `setActualLicenseExpirationTimestamp:` (around `0x100020b28`); reads `tier`/`plan_tier` and calls `setActualLicenseTierName:` (around `0x100020d00`) |
| Sync and UI | Uses notification/reload and `forceSyncWithCompletion:`; checks `isLicenseCurrentlyValid`. JSON fields `code_applied` and `duration_days` are used in displayed success messaging. |
| Persistence and calculation | `CBLicenseSyncManager` exposes `actualLicenseExpirationTimestamp` (IMP `0x1000b1128`, reads `actualExpireTimestamp` in local dictionary and may fall back to data-file header) and `remainingLicenseSeconds` (IMP `0x10007b714`). |

Source locations: both binaries are embedded in the DEB at `var/jb/Applications/DuoNaviUI.app/DuoNaviUI` and `var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib`. These offsets are *arm64 Mach-O virtual addresses for this binary*, not file byte offsets or runtime ASLR-adjusted addresses.

## Conclusions and limits

1. The literal 30-day promotional code is **not** present in any of the 50 extracted files of either DEB as ASCII uppercase, lowercase, or UTF-16LE; no embedded per-device redemption result was found. This does not rule out an obfuscated code, but the observed `code` + `hw_hash` network workflow strongly supports server-side redemption.
2. Unlike the free-trial eligibility UI (`is_trial_eligible`, `%ld-day free trial`), a typed activation/gift code is sent through the **giftcode redemption** path. Its resulting **duration** comes from a response field (`duration_days`) and/or the expiry timestamp provided by the backend, not from a fixed 30-day constant proven in these DEBs.
3. If a full 30×24-hour period started on 2026-10-22, its theoretical end date is **2026-11-21 at the same local clock time** (2,592,000 seconds later). Actual expiration could differ because the server may anchor to activation, an existing subscription, or its own policy. Do not present that estimate as a confirmed server expiry.
4. Neither extracted DEB bundles `com.duonavi.license.data` nor `com.duonavi.sync.plist`. These are runtime/device-side paths documented in prior project history. Even if two DEBs are identical in license code, each device may have different locally stored/verified entitlements.
5. Do **not** equate changing `leaseSeconds`, `status` or a `sync.plist` display with authorization. Prior history shows an experimental 39-day install worked on one already authorized device but did not activate another; cryptographic verification is present.

## Next non-destructive proof (authorized device)

- View DuoNavi `Subscription & License` → `Device ID`, `License Status`, `License Duration`, `Server Expiry` on each phone; capture the numeric expiry and duration (redact full device IDs and gift codes).
- Check local `/var/mobile/Library/Preferences/com.duonavi.sync.plist` (if present) with Filza for `actualExpireTimestamp`, `expiresAt`, `leaseSeconds`, `lastSyncTimestamp`; interpret only as cached values, not a server authority proof.
- Check existence/size (not secret contents) of `/var/mobile/Library/Preferences/com.duonavi.license.data` and compare device state, not package archives.
- No backend redemption request was made, and no device-side or CarPlay verification was performed.
