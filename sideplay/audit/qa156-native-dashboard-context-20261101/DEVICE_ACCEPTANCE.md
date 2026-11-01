# Finite physical acceptance for nativebridge4

No hardware acceptance is recorded. User's distinct destinations remain literal: “Home CarPlay” versus “trang chọn app”. Do not collapse them into one Home label or infer a specific navigation controller from a Dock repaint.

Install only verified public0.0.156~nativebridge4 from existing source once published. Retain selected Safari and current opt-ins; refresh existing Sileo source and respring, no new source/Filza/selection-reset workaround.

1. From native app chooser open selected Safari, then press native Home. Record actual returned screen (app chooser required). Repeat from one selected third-party app. Confirm native Dock can switch app afterward.
2. Compare Calendar/Music on same screen/session. Log25 has no native app identities, so those9 unattributed Home presses cannot be used as native baseline.
3. Correlate same RequestID. On grid launch expect native-dashboard-context-verified with actual dashboard class, workspaceSame=1, externalSame=1, rootRelated=1; qa151 homeGetter=1, workspaceSame=1, showingAppGetter=1. From chooser, qa152 native-chooser-ready is correct and must not issue unnecessary official deactivation. From native-app Dock context, matching actual scene+workspace may produce native-workspace-deactivate-request then once-only resume.
4. Exact source Home cleanup now clears owned Dock ID and outside-app displayState1; no late prior app state restoration. Existing native new-owner guard must preserve a newly switched native app. Log line for restore alone is not proof of destination or pixels.

If context refusal persists, inspect exact anchor/dashboard/workspace/external/parent relation; do not guess a different workspace or force an unsupported selector. If verified context succeeds but wrong destination persists, recover actual native Home callback/navigation state before further behavioral change. No original callback suppression or speculative delay.
