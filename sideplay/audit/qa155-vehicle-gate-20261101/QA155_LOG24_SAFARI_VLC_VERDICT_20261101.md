# QA155 user test triage — Log24 (Safari missing, VLC reported tested) — 2026-11-01

## User report vs verified input

**Latest user report:** “Đưa safari lên carplay ko đc. Đã test vlc. Check log đi.” User confirms Safari cannot be added to CarPlay and has tested VLC; user has **not** reported VLC pass/fail details here. Do not infer VLC success/failure.

**Latest accessible raw on-device export checked:** `chuongnguyen89dn-ui/Duoface`, `main:sideplay/log/DuoFaceAudit 24.txt`, upload commit `2a5d39d8f3de874d42192894868caa61941e25b1` (“Add files via upload” 2026-10-31 23:58:00 UTC), Git blob **`1f21a2095bdcd735e3c24fa7df0ef122d58cb629`**, **5,083,061 bytes**. Export header `Date: 2026-10-31 23:56:59 +0000` (=2026-11-01 **06:56:59 Asia/Ho_Chi_Minh**), iOS 16.7.16. **This is Log24, not a new Log25.** GitHub `main/sideplay/log` inspection found no more recent numbered export. Log 24 has 5,082,901 decoded characters.

**Important exporter limitation:** `Audit schema: 3; exporter build 0.0.90~nativegetters1` is a known hard-coded export label, NOT independent proof of the installed QA version. The installed QA155 package was verified on Pages, not verified installed on this particular iPhone by this export.

## Deterministic log24 counts, verified from text

Scoped to real session events `[DFStandalone144] time >= 1793490600` (2026-10-31 23:50:00 UTC; avoid mixing retained historical sessions):
- `standalone-requested-not-yet-ready` **11**: Facebook **5**, TikTok `com.ss.iphone.ugc.Ame` **1**, YouTube **3**, ChatGPT **1**, Gemini **1**.
- `qa149-manager-live-scene-owned` **7**, `scene-hosted-render-and-touch-unverified` **7**, `qa147-native-dock-active` **7**. These are code-side state markers, NOT evidence Dock icons, scene pixels or full touches were correct on physical CarPlay.
- `qa154-general-app-restore` **6**, `stopped` **7**.
- **4** explicit `stage=failed` with **`Scene attach exception: bogus reference size`**: YouTube **2**, ChatGPT **1**, Gemini **1**. Same request each has `mount-reentrancy-terminal` and `no-valid-standalone-owner`; indicates an actual unresolved attach branch, not a VLC diagnosis.
- `qa155-app-side-ack` **0** across entire Log24. The file has **0 exact `org.videolan.vlc-ios`**, **0 exact `com.apple.mobilesafari`**, **0 standalone launch of VLC or Safari**, even though it mentions a SocialSafariSpringBoard dylib in ABI probing, which is NOT Safari app launch.
- Thus **Log24 cannot diagnose whether VLC received the QA155 app-side lease**: no VLC request/RequestID to correlate. Either the physical test is after the latest exported window, or the selection is not reaching the standalone handler; the log alone cannot choose between those possibilities.
- For 7 requests with `qa147-native-dock-active`, runtime state says “active”; the user previously reported physical Dock mismatch. Do not assume these events prove the visual Dock or native Home semantics.

Representative exact events:
```text
[DFStandalone144] time=1793490648.254 process=SpringBoard stage=qa149-manager-live-scene-owned req=B1E77DA8-C5D7-4E9D-B850-2CDFC2FBA171 bid=com.facebook.Facebook generation=2 window={{0, 0}, {595, 331.33333333333331}}
[DFStandalone144] time=1793490648.272 process=CarPlay stage=qa147-native-dock-active bid=com.facebook.Facebook req=B1E77DA8-C5D7-4E9D-B850-2CDFC2FBA171 homeCaptured=1
[DFStandalone144] time=1793490743.945 process=SpringBoard stage=failed bid=com.google.ios.youtube req=F5F96F33-EB54-4E39-93FB-D820BC8E2CC4 Scene attach exception: bogus reference size
```

## Safari is provably excluded by deployed source; package filter misleading

Exact **signed QA155 source** `6e4dba0a03b20d787ed70760b7b1d5bbbcbc71ee`, verified same blob as current feature branch:
- `sideplay/duoface-native-scene-host/DFHomeStandalone144.m:47-51`: `DF144Allowed(bid)` requires `DFIsRecommendedAppID(bid)`; at `:163-166` rejected icon invokes original CarPlay handler without issuing DuoFace standalone request or logging a rejection reason.
- `sideplay/duoface-native-scene-host/DFEnabledAppsPolicy.h:50-54`: `DFIsRecommendedAppID` requires `![bundleID hasPrefix:@"com.apple."]`. Safari's app id is `com.apple.mobilesafari`, so `DF144Allowed` **always rejects Safari regardless of the user's enabled-app setting**. This is a confirmed source-level reason Safari does not enter DuoFace standalone Home path.
- `sideplay/duoface-native-scene-host/DFAppEligibility.h` *does* allow explicit `com.apple.mobilesafari` as user-facing app, so the distinct `DFIsRecommendedAppID` check is the blocking gate. `DF155GeneralAppStateRelay.plist` *also* includes Safari in injection filter, but this only makes an app-side receiver eligible; it does NOT add Safari to CarPlay Home nor override the earlier rejecting gate.
- `DF155PilotAppScope.h` permits Safari and VLC in narrow relay. Sender admission and receiver filter are inconsistent for Safari. **Confirmed architectural configuration mistake; no on-device Safari error trace needed to prove this guard**. Changing it needs a narrowly scoped, original-mechanism-compatible Safari launch/CarPlay eligibility solution; removing all Apple restrictions indiscriminately is unsafe. No code change committed in this triage.

## Exact next evidence/action (no speculative QA build)

1. User's reported Safari failure is already explained **for the standalone intercept path** by the contradictory filter. Do not ask the user to rerun Safari merely to prove this code path is closed. A Safari app-side plist filter alone can never create the required standalone launch.
2. Need the **actual VLC session export after VLC test**: use existing iPhone DuoFace button `Xuất log / lỗi CarPlay` then upload/store next numbered `DuoFaceAudit 25.txt` in `Duoface/main/sideplay/log/` (do not overwrite Log24); or identify an already existing subsequent export if uploaded elsewhere. Require exact `org.videolan.vlc-ios` / same RequestID and `qa155-app-side-ack` phase before concluding relay transport works or fails. The app-side ACK may be absent because no VLC request, not necessarily broken transport.
3. Once a real request is present, compare `standalone-requested-not-yet-ready` → `qa149-manager-live-scene-owned` → `qa155-app-side-ack` phase → `qa147-native-dock-active` → exit/restore and user-observed Home/Dock/touch. Also track actual error `bogus reference size` separately. No new DEB/package/Sileo change based solely on Log24.

**Tool validation:** GitHub `fetch_blob` decoded exact Log24 text (not just search snippets); JavaScript in `functions.exec` filtered `[DFStandalone144]` + numeric timestamp, counted stages/bundle IDs, exact searched markers. Source fetched using `mcp__GitHub__fetch_file` at both build SHA and current feature branch; required files had matching blob SHA. No physical phone access, no build/test/deploy in this investigation.
