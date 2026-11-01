# Evidence correction: original CarPlayPro Speed 0.9.97 GOFA vs AudioQueue

**CONFIRMED**: The three `dlsym` names loaded at 0x393a0, 0x393b4 and 0x393c8
are **AudioQueueStart, AudioQueuePause, AudioQueueStop** respectively.
Thus the `MSHookFunction` calls at 0x393f0/0x39408/0x39420
observe AUDIO, not the GOFA speed/traffic alert data source.
These calls had been incorrectly labelled 'GOFA candidate' in an earlier
static report; the corrected label is 'AudioQueue monitoring'.

## Original exact __cstring addresses
- `0x54cf4`: `AudioQueueStart`
- `0x54d04`: `AudioQueuePause`
- `0x54d14`: `AudioQueueStop`

## Literal references to GOFA data helper/callback addresses
Detected direct ADR/ADRP+ADD patterns (not a complete Swift/ObjC xref graph).
- None matched; indirect Swift/ObjC and encoded relocations remain unexamined.

## Next forensic target
Distinguish actual GOFA Swift model hooks from unrelated audio hooks.
The real GOFA callback addresses `0x3cfb4` and `0x3d468`
invoke original `_SAGofaAlertPayload` at `0x3e93c` and
`_SAGofaSpeedPayload` at `0x3e38c`, respectively.
Their actual GOFA producer types and model schema are not yet proved.
No camera/sign/turn data should be invented on DuoFace.
