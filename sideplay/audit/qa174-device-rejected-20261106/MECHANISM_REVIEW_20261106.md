# QA174: review of the user's wake-gate and OmniCar architecture document

Date: 2026-11-06. Scope: analysis and handoff only, NOT runtime implementation, build, deployment or device validation.
Repository: chuongnguyen89dn-ui/Duoface.
Branch: fix/qa173-logo-map-touch-recall-20261106.
Inspected source/handoff HEAD: 2336b9e8b65f87bc3c0803924cfa1429a73afaef.
Released compiled source: d8144d3c58833764fbc6a53e25044682adf852e2, version 0.0.174~mapwake1.
Existing device acceptance remains FAILED: no arbitrary-pane-touch logo recall; GOFA opens but Google Maps/Waze do not; selected apps absent outside DuoFace on CarPlay Home.

## Latest user-supplied contract, superseding previous assistant advice

The user supplied a document saying: when controls are hidden, the first touch in the owned app pane only wakes controls and MUST NOT activate the app underneath; when controls are visible, touches pass normally. The document proposes an in-path gate at the SpringBoard-owned DFSceneSurface, not a separate shield UIWindow. It also requests an in-car per-pane picker with real native CarPlay apps plus selected installed phone apps, an explicit launch/presentation transaction into the chosen pane, one geometry authority per scene, scoped lifecycle retention, and independence from manually changing Apple's CarPlay Customize settings.

This explicitly supersedes the assistant's blanket 'never consume the first tap' / passive-only wake policy and the similar sentence in the earlier QA174-DEVICE-REJECTED checkpoint. Preserve those older entries as history, NOT as current instructions. Do not silently reinterpret this as a pass-through wake request again. References to the user's 04/11 and 05/11 statements are supplied by the user here; this review does not claim independently retrieving those original conversations.

## 1. Wake contract: a confirmed mismatch in the current implementation

Source: sideplay/duoface-native-scene-host/DFNative12Chrome.m, lines 271-300. DFNativeWakeGateView.hitTest:withEvent: deliberately returns nil and comments explicitly say 'Never consume the Maps/Waze first tap'. That does NOT implement the newly restated wake-only first contact. Returning nil from this sibling gate lets routing continue; it does not reserve the first gesture for controls.

Source: the same file, logoTouchDown:/logoTouchFinished:/swapPressed: around lines 2704-2741. Existing logoWakeOnlyTap suppresses Swap for an initially hidden logo's short tap. This is a concrete existing wake-only precedent, not proof that the whole pane already follows it.

Source: sideplay/duoface-native-scene-host/DFSceneHost.m, DFSceneSurface.hitTest:withEvent: around lines 631-667. It first resolves the underlying target, logs the hit, asynchronously posts DFSceneHostDidObserveTouchNotification and returns the original target. It is an observer, not a consume-on-hidden gate. The proposed DFSceneSurface boundary is a reasonable candidate for our OWN hosted phone-app scenes, but actual remote event routing must still reach it. Native CarPlay maps currently use a DIFFERENT process/controller path, so changing only DFSceneSurface cannot automatically cover those native panes or empty-pane roots.

Source: tests/test_qa172w2_wakefix2.py, test_gate_hittest_contract around lines 53-62. Current regression expects return nil and forbids shouldConsume, touchesBegan, and return self. It protects the WRONG behavior for this user contract. A passing test here cannot be cited as evidence of correct wake semantics. Replace the behavioral specification before implementation; do not merely change assertions to accept arbitrary new text.

Proposed acceptance: hidden -> tap a functional app button -> controls show and app action count remains zero; release; second tap while visible -> exactly one app action. Also test repeated hide/wake, touch movement/cancellation, multi-touch, keyboard present, empty/loaded pane, modal/Home return and divider dragging. The wake contact must remain captured through Ended/Cancelled even though controls become visible immediately; do not forward its tail or replay it. A visible-state gesture must not be seized mid-stream if a timer expires. Do not relayout scene/keyboard or wake red border independently of logo. Red may appear only with visible logo.

Apple public semantics consulted: UIView hitTest(_:with:) and Handling touches in your view. UIKit has Began/Moved/Ended/Cancelled touch phases and a hit-tested view hierarchy. These are general UIKit facts, not proof of jailbreak remote-surface routing.

## 2. In-car roster: the document identifies a real policy difference

Source: sideplay/duoface-native-scene-host/DFAppPickerVC.m, refreshInstalledApps lines 537-598. Current QA174 builds selectedIDs, then discards every app outside selectedSet BEFORE native-map route classification. Native catalog membership is a route label here, not a union source adding eligible native apps. Thus current roster is not simply nativeCarPlay union selectedPhoneApps.

Reference: sideplay/audit/omnicar-iphone-picker-20261029/VERIFIED_ORIGINAL_IPHONE_ALLOWLIST_TO_CARPLAY_20261029.md and DUODASH_OMNICAR_COMBINED_ARCHITECTURE_RESEARCH_20261029.md. Original SCPCarSplit distinguishes native CarPlay apps and selected iPhone AppBridge apps; showPickerForSlot:, buildPickerSheetForPane:, pickerAppTapped: and openApp:slot: are separately identified. The user's requested native-category-plus-selected-bridge-category design is consistent with that separation. Selection on iPhone configures availability; selecting on the car chooses a pane target. Neither operation is automatic launch-all.

Keep installed/runnable checks, deduplication, explicit exclusions and user choice migration. Merely finding a declaration or reading CFPreferences is not evidence that the app was presented or that Home icons were published. Independent DuoFace versioned preferences are allowed; using the vendor's literal preference domain is not required and would violate project independence.

## 3. Launch/presentation: QA174 is not literally waiting passively

Correction to the document's description of CURRENT code: sideplay/native-carplay-scene-v1/DFNativeMapPaneCoordinator.m, handleAttachCommand:allowLaunch: calls beginPendingLaunch:observation:generation: when there is no matching owner and an explicit launch is allowed. That calls DFNativeMapDispatchLaunchGuarded. DFNativeMapLaunchRuntime.m creates a launch-info/event and calls dashboard handleEvent: after context/ABI checks. It is an active native launch attempt followed by observation, not only waiting for Dashboard to spontaneously show an app.

However, this remains the system-native CarPlay launch/adoption route, NOT proof of the independent SpringBoard-host presentation route requested in the supplied document. GOFA is routed to phone AppBridge; Maps/Waze are routed to native coordinator in DFCarPlayAppRoute178.h. Working GOFA does not establish native map readiness. Do not describe a picker callback fix as completion of either route or Home publication.

Future work must name the chosen route per app, its actual scene identity, responsible process and explicit request -> activation -> host mount -> input/geometry transaction. Do not remove native checks or replace all map paths indiscriminately on the assumption that 'native' automatically means wrong; compare the actual original route for that category. A shared, independently controlled UX can still use legitimate OS scene APIs. A map running inside a phone scene versus a real native navigation scene are different implementations.

## 4. Geometry: valid invariant, unproved causal claim

One authoritative geometry contract per scene/generation is appropriate. But the assertion that QA174's two writers are the established root cause of misplaced input is NOT proven by the reviewed source alone. DFSceneSurface.layoutScene/commitSceneGeometry handles hosted phone-app viewport/reference geometry; DFNativeMapPaneCoordinator.refreshAdoptedNativeMapBounds handles a native CarPlay controller and its pane. Two processes or two different view sizes do not establish competing writes to the SAME scene.

Verify scene identifier, generation, requested frame/reference size, transform and native owner before declaring a conflict. For an independently hosted SpringBoard scene, that host should own its final geometry; do not let an unrelated native coordinator write it. Per-pane zoom must map display and input coordinates consistently. Do not erase necessary UIKit viewport vs remote-content-reference conversions merely to make the source contain one setter.

## 5. Under-lock: the suggested hook already exists

The document's statement that current DuoFace only writes settings/assertions is incorrect for QA174. Source: sideplay/duoface-native-scene-host/DFSceneLifecycle.m lines 261-427. DFInstallOwnedUnderLock123 installs SBSuspendedUnderLockManager._shouldBeBackgroundUnderLockForScene:withSettings: using DFUnderLockBackground123, and DFSceneLifecycleInstall invokes it. DFInstallPostLockIntercept also installs interceptUpdateForScene:withNewSettings:. The predicate is scoped to current registered, live external hosted scenes and passes foreign scenes to the original implementation.

What remains unproved is whether those hooks install and their ownership predicates accept the relevant scene on the user's device, particularly when that scene instead belongs to the native CarPlay route. Do not add a duplicate global hook or suppress background/blanking for arbitrary apps. Screen-blank handling is a separate policy whose exact callback, process, active-session scope and restore behavior must be verified. Adding it blindly is not a demonstrated cure for the present launch/roster failures.

## 6. Keep the independent CarPlay Home requirement separate

The supplied document's four implementation points mainly describe the in-DuoFace picker and pane hosting. They do not themselves complete the earlier requirement that apps appear on CarPlay Home OUTSIDE DuoFace. The original OmniCar reference explicitly separates appBridgeApps, homeScreenShownApps/homeScreenHiddenApps and splitScreenCarPlayApps with a separate OMCHomeScreenController. Current DFHomePublisher136Core.m also has independent Home admission paths and skips records with existing native declarations. A visible card, launch request, or attached pane is not a Home icon.

Record THREE separate acceptance results: (A) app present in the on-car DuoFace picker, (B) app actually renders and accepts input in its selected pane, (C) requested real app entry appears and launches from CarPlay Home outside DuoFace. Avoid proposing changes in Apple's Customize UI as a substitute for completing the requested independent feature.

## Verified work in this review and continuation

Read live GitHub branch/handoff, in-progress runs (zero before documentation action), pinned current implementation/test ranges and original reference reports. No runtime source, DEB, Sileo, app lifecycle or device configuration changed. No app tests executed in this review. Container read-only curl of pinned public raw source failed DNS (curl: (6) Could not resolve host: raw.githubusercontent.com); live connector reads succeeded. No fresh device log was used. The known wrong passive wake contract and selected-only roster can be identified without asking for a log; runtime evidence is still needed to attribute native scene rejection or geometry competition and validate the eventual implementation.

Next implementation sequence: (1) replace the mistaken passive-only wake specification with the first-contact consume/release contract and behavioral regression; (2) verify the in-path host boundary for loaded and empty panes without shield windows; (3) align native versus selected-bridge roster; (4) trace explicit per-app activation, geometry and lifecycle ownership together; (5) implement/verify outside-DuoFace Home publication separately. Preserve GOFA, keyboard, media and divider behavior. Prior 'never consume first touch' assistant decisions are superseded; physical QA174 failures remain authoritative. The current user request asks to assess this document, so this turn does not authorize a new functional release.
