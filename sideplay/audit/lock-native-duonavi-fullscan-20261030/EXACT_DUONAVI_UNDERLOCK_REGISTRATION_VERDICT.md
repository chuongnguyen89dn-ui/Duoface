# Exact original DuoNavi signed under-lock hook registration vs Native12

This audit reads only original Mach-O + ARM64 argument setup and validates
its own implementation against the 11 previously proven Native12 registered
class/selector pairs before interpreting DuoNavi.

## Trust boundaries
- Full original signed dylib SHA256 verified; FAT arm64 slice SHA separately recorded.
- Imported MSHookMessageEx located using Mach-O LC_DYSYMTAB indirect symbols.
- Class and selector recovered by direct ARM64 ADR/SEL-ref register provenance.
- A decoded registration implies attempted hook installation, not successful
runtime invocation on iOS16, and is not proof of physical Play fixes.

## Native12 self-test
- Exact registration fixture: 11 matched to 11 preverified methods
- Imported hook calls scanned: 240

## DuoNavi signed binary
- Full original SHA: 44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15
- Arm64 slice SHA: 012c3fa0c0b4c32363d09af24bbc890d9baf61e51788d8f086836f6829a5922d
- Imported MSHookMessageEx direct callsites: 259
- Calls with both resolved class+selector: 169
- Confirmed SBSuspendedUnderLockManager registration calls: 3

- 0x2ecf80: `SBSuspendedUnderLockManager interceptUpdateForScene:withNewSettings:`; replacement 0x2ed954, previous IMP storage 0x3adfd0
- 0x2ecfa0: `SBSuspendedUnderLockManager _shouldBeBackgroundUnderLockForScene:withSettings:`; replacement 0x2eda64, previous IMP storage 0x3adfd8
- 0x2ecfc0: `SBSuspendedUnderLockManager shouldBeUnderLockForScene:`; replacement 0x2edb7c, previous IMP storage 0x3adfe0

## Caution
If DuoNavi 0 under-lock methods decoded, inspect unresolved hooks/other dispatch before concluding not registered.
