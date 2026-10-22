# Native12 0xaf01c → DuoFace DFSceneHost.stop — exact teardown order (read-only finding)

## Source identity (no vendor runtime imported)
- Original Native12 DEB SHA256 `2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad`, original `DuoFaceDashboard.dylib` SHA256 `9e02a4bcee98fb703777122c67286158d9ca9cfa3088887b5ca280c580a695ea`.
- Verified original 111 ARM64 instructions at `sideplay/audit/native12-continuation-4888299/gallery-media-imp/ORIGINAL_LAYOUT_IMP_INSTRUCTIONS.json`, function `CBBridgedUIAppView.dismiss` @ `0xaf01c..0xaf1d8`.
- Original class ivar metadata `dismiss-ivar-owner/ORIGINAL_DISMISS_IVAR_OWNER.json` CI39739371586 resolves x23 owner `_appViewController` type `SBAppViewController` offset24; x20 owner `_wrapperView` type `UIView` offset32. Verified selector pointer `dismiss-selref/ORIGINAL_DISMISS_SHARED_SELECTOR.json` is `removeFromSuperview`, NOT fabricated `invalidate` (CI39738620890).
- This is **STATIC FUNCTION ORDER**, not proof that iPhone/CarPlay has no ExitSafeMode or that matching order solves crashes.

## Exact first party comparable calls

| Native12 verified PC | Actual original receiver/action | New first-party `DFSceneHost.m` `DFSceneSurface.stop` before correction |
|---|---|---|
| `af040`, `af054` | CBBridgedUIAppView.setInvalidated:YES / setHosting:NO | No equivalent **bridge instance** exists; do not call on SBAppViewController |
| `af09c`, `af0ac` | SBAppViewController beginAppearanceTransition:NO then endAppearanceTransition | yes (inside `self.started` guarded branch) |
| `af0d8` | SBAppViewController setRequestedMode:0 (conditional signature guard) | yes (DFHostInt guarded) |
| `af0fc` | appController.view **removeFromSuperview**, shared selref 0x37db28 | yes, but **after** willMove in independent code |
| `af130` | appController **willMoveToParentViewController:nil** (conditional guard) | yes, but **before** removeFromSuperview in independent code |
| `af158` | appController removeFromParentViewController (if responds) | yes |
| `af180` | appController invalidate (if responds) | yes |
| `af1a4` | `_wrapperView.removeFromSuperview`, not child invalidate | first-party `DFSceneSurface` wrapper removed via `[self removeFromSuperview]` after child invalidation (different own UIView), do not double-remove original ivar |

**Identified precise ordering mismatch:** Independent code currently executes `willMove...` **before** `appController.view removeFromSuperview` although original Native12 does **remove view before willMove**. A one-line reorder of those calls (in the source-owned `DFSceneSurface.stop` only), retaining branch guard, scene invalidation order, and no new setters, is a testable independent compatibility change. Do not infer that it fixes ExitSafeMode without device log.

**User's invariants:** original Native12 only (not DuoNavi original104); preserve 9 presets, per-pane focus, split drag, swap, menu/App/Style/Close, older signed packages and public Sileo .31. Do not add license code or auto release.

**Follow-up gate:** preserve isolated .44 signed candidate from 39741037084 before any additional nativehost source push (the smoke workflow uses cancel-in-progress); once archived, implement reorder under bumped isolated package version, add a static regression test binding PCs and call sequence, and verify new CI. Do not claim device PASS.
