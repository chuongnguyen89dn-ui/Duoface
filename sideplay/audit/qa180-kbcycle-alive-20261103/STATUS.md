# QA180 — keyboard-fit cycle + relay-alive markers + D-B (STATUS)

- Branch: feature/duoface-qa180-kbcycle-alive-20261103 (from QA179 tip)
- Integrated: com.duoface.jb.embedded 0.0.180~kbcycle1; host 0.1.180~kbcycle1
- Private build run: 41579486857 SUCCESS (head 57f02a72; first run 41579370429 failed step 4 on a BOOL/nil comparison in the guard split, fixed in 57f02a72)
- Archive commit: 7b940c301bbcff0d4b6c2e3b2d809e7b56c17d44
- DEB: 1,279,032 bytes, SHA256 37e9bde009f203dc22245dcc76fa73a81bbc7311c35cc193407681cc2b6889ec
- postinst/postrm md5 5d016787d5af05ce8a353942f1dfa091 / eddecdc6cbe35384fd72bf23a831d801 (byte-identical to QA177-QA179)
- CI battery: 159 tests OK across 33 modules, 0 FAIL/ERROR (qa154 4, qa155 4, qa176 7, qa177 12, qa178 10, qa179 9, qa180 8, integrated144 4)
- SILEO_PUBLISHED=false (awaiting approval); DEVICE_TESTED=false

## Scope (WORK ORDER QA180 v2 + Spec Q3 conditions)
- B (Maps + Waze fit scope): an accepted DidShow opens a fit CYCLE (token = cycle id). Evaluations at 0 (immediate), +0.3s, +0.6s, +1.2s and immediately when a Keyboard-class window becomes visible (per-cycle UIWindowDidBecomeVisible observer, removed at cycle end; the global reconcile observer is untouched). The existing QA179 evaluation path is reused. Terminal outcomes close the cycle: applied / already-fit / not-hosted / flag-off; retryable outcomes (no-kb-window, no-key-window) close it as exhausted at the +1.2s beat; DidHide cancels it. Each cycle end writes a qa180-cycle summary (outcome, reason, tries, found, foundAt ms, duration). Fit segments carry cyc/try/foundAt while a cycle is open. Kill switch KeyboardCycle180 (qa176 plist, absent = ON); OFF reproduces QA179 exactly (two beats, no observer, no extra retries).
- C (all pilot apps): relay-alive markers. R1 = first statement of the DF154 constructor (proves injection). The compound start guard is split into named conditions WITHOUT semantic change; R2 is written at each exit: guards-fail variant naming b/p/e/s/i + listen=-1, listen-failure variant (listen=0), success variant (listen=1 reg=1). Markers go DIRECTLY to the kbdiag mailbox (DF156Init, no DF156Listen / pilot channel dependency) and Chrome logs them as qa180-relay-alive. No Waze behaviour change.
- D-B: the fit evaluation logs the ORIGINAL keyboardScreenReferenceSize value read from the keyboard window (respondsToSelector + try/catch, read-only, never used for decisions) as refSize= in the qa179-kbfit segment, refWhen=pre on the immediate capture and post on later beats (the +0.3s beat is the post-fit read Spec required).
- Counting definitions (WO A.5): a "capture" is one kbdiag record of any kind; an "evaluation" is one fit run inside a DidShow capture. QA179 export: 77 captures (all Maps), 28 fit lines = 25 evaluations (applied 5, already-fit 9, no-kb-window 11) + 3 out-of-cycle restore records. QA180 acceptance counts per-CYCLE final outcomes.

## Known limits / notes
- Mailbox is latest-value: a cycle summary written immediately before its capture record can be overwritten before Chrome polls; the fit segments themselves carry cyc/try/foundAt, so cycle data remains reconstructible from qa179-kbfit lines.
- The cycle does not extend past 1.2s of scheduled beats; the visibility event can still resolve it later while the keyboard is up (observer lives until a terminal outcome or DidHide).
- DFSceneHost.m and DFHostedMapRenderSize.h untouched (test_qa180 asserts no QA180 markers; frozen digest held).

## Step-0 paperwork (parallel, read-only): readback premise — preliminary
- scene-frame-readback's "actual" is the frame read back from the remote scene's SETTINGS object after the host's commit; "target" is the host's own nativeFrame (pane-derived). DFSceneHost.m contains no 414/mainScreen reference. Preliminary reading: actual {414,736} is produced on the system/app side of the scene-settings transaction, not by the host's commit — leaning toward the UIKit/client clamp hypothesis. Full transaction trace deferred until/unless the geometry branch opens (3 conditions in LOI_HIEN_TAI).
