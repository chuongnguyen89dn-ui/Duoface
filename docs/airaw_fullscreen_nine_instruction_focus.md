# Nine-instruction focused trace: Airaw fullscreen candidates

Input: user-supplied Airaw 1.7.1k arm64 dylib; disassembly at `/mnt/data/airaw_full_disasm.txt`. No broader file scan.

## Entry candidate, 0x45d20–0x45d88

- `0x45d20`: returns immediately if second argument is null.
- `0x45d40`: `setIsFull:YES` on object at `[x20+0x20]`.
- `0x45d48–0x45d54`: `view` -> `frame` -> `setSavedRect:`, storing the original frame on that object.
- `0x45d58–0x45d6c`: passes `UIEdgeInsetsZero` to a method on the **second argument** (x19), not necessarily the saved-frame view.
- `0x45d74–0x45d88`: class method `setDefaultAppChromeHidden:YES`.

## Exit candidate, 0x45b50–0x45bf8

- `0x45b6c–0x45b90`: obtains `[object+0x20].view`, applies `CGAffineTransformIdentity` using `setTransform:`.
- `0x45b94–0x45bc4`: reads `savedRect` and restores it using `setFrame:` on the view.
- `0x45bc8–0x45bd8`: class method `setDefaultAppChromeHidden:NO`.
- `0x45bdc–0x45be0`: invokes an additional selector on `[object+0x20]`, not yet decoded.

## Callsite check

Exact direct `bl` and `b` references to `0x45d20` and `0x45b50` in the available disassembly: **zero**. This suggests (but does not prove) indirect callbacks, blocks or dynamically registered methods. Locating these callbacks in method/block metadata is required to establish that they are the requested whole-host fullscreen rather than another chrome state transition.

**Do not** claim a working fullscreen toggle or build a production v12 DEB from this evidence alone. No modification to original v12.
