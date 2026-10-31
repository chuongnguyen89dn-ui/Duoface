# Independent bridge lifecycle boundaries — design, not shipped code

Evidence basis: the three original route audits dated2026-10-31. This specifies relationships for independently written DuoFace code; it does not copy vendor implementation or authorize claiming scene readiness from a manager response.

| Phase | Required evidence before publishing | Permitted result / next phase |
|---|---|---|
| Request accepted | Enabled bundle, exact live CarPlay display/session, fresh matching request, owned generation, no competing DuoFace split owner | Preparing; supersede only the previously owned standalone transaction |
| Native preparation | Resolve current native foreground state; perform supported native workspace close with an explicitly bounded continuation; prepare phone-app eviction | HostStarting; duplicate completion executes once |
| HostStarting | Valid native display/window and frame, owned app/controller, correct lifecycle flags and initial reference size order, native host start returns without failure, owned window becomes visible | ManagerActive response carrying real bundle and generation; no claim of pixels/touch or PID ownership |
| ManagerActive | Consumer matches current request/bundle/display/generation and verifies the native owner is still current | Update actual native Dock history/active/refresh and Home in-app state; retain restore ownership |
| Scene observed | Actual host window, handle/scene generation and live-host capabilities match; PID independently verified when available | Update separate scene/PID status. Missing observation must not silently become an artificial ready response |
| App state applied | Independently scoped app-side consumer receives own session state, applies owned window layout and reports actual readback; handle initial/active recovery and delayed windows | Track separately from host observation and pixel/touch verification |
| Native Dock/Home action | User input belongs to actual native owner; distinguish bridged target from native target and pending transaction | Bridged Dock tap enters manager request; native switch restores/releases only old owned state; Home uses complete exit transaction and native semantics |
| Stop/replacement/disconnect | Revoke matching generation; dismiss owned host; app-side restore; destroy owned windows; publish inactive; restore only Dock/Home state still owned by this transaction | Idle, or prepare replacement. PID-dependent termination requires separate real PID/provenance validation |

Race requirements:

- Any asynchronous continuation rechecks generation, bundle, display and owner. A callback from an old request cannot activate, stop or overwrite a newer request.
- A failure or synchronous completion during view attachment is terminal for that launch phase. Returning from addSubview cannot blindly write an earlier pending state.
- Manager pending expiry and hosted-app lifetime are distinct. Expiry must have an explicit result/recovery policy; it must not accidentally masquerade as a physical Home press.
- Scene-ready retries may only report the original truthfully verified condition and same live scene generation. A late PID query is not authority to promote an obsolete result.
- Full-root geometry and window level must be implemented with pass-through hit testing and correct coordinates as one change; native Dock input and original layout remain acceptance requirements.
- Candidate reuse requires both app identity and usable native window/host; stale same-bundle selection must recover rather than return a stale object.

Before implementing, instrument exact startup operation on exception and each ready rejection predicate. Acceptance requires physical tests for Home/app chooser, native app switch, bridged Dock tap, repeated taps, cancellation/replacement, delayed PID, app-side restoration, reconnect, orientation, touch and original split behavior. This checkpoint reports none of those tests as completed.
