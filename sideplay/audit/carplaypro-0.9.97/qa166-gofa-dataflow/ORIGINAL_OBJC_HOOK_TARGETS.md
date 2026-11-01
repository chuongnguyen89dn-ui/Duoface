# Original CarPlayPro Speed hook targets: source-by-source

**Static binary only**. Exact class/selector pointer resolution may be absent
for chained fixups or Swift fields. Nearby class lookups are not ABI proof.
No private GOFA values nor license data are read or generated.

- Original MSHookMessageEx callsites: 23
- Original MSHookFunction callsites: 9
- Raw pointer references to exported GOFA callbacks: 2

## Hook registrations with recovered selector and exact callback address
- `0xab58` (`0xa988`) _MSHookMessageEx replacementCandidate=`0x3298c` candidateClass=`FlutterMethodChannel`
- `0x17c98` (`0x17ac4`) _MSHookMessageEx replacementCandidate=`0x348b0` candidateClass=`FlutterMethodChannel`
- `0x2f83c` (`0x2f798`) _MSHookMessageEx selector=`setRootViewController:` (original_authenticated_objc_selref) replacementCandidate=`0x309b4` candidateClass=`UIWindow`
- `0x2f85c` (`0x2f798`) _MSHookMessageEx selector=`setWindowScene:` (original_authenticated_objc_selref) replacementCandidate=`0x30a7c` candidateClass=`UIWindow`
- `0x2f9ec` (`0x2f798`) _MSHookMessageEx selector=`init` (prior_objc_selref_through_register) replacementCandidate=`0x38a98` candidateClass=`CommonLib.LocationManager`, `_TtC9CommonLib15LocationManager`
- `0x2fa14` (`0x2f798`) _MSHookMessageEx selector=`didBecomeActive` (preceding_NSSelectorFromString_cfstring) replacementCandidate=`0x38b00` candidateClass=`CommonLib.LocationManager`, `_TtC9CommonLib15LocationManager`
- `0x2fa3c` (`0x2f798`) _MSHookMessageEx selector=`willResignActive` (preceding_NSSelectorFromString_cfstring) replacementCandidate=`0x38b70` candidateClass=`CommonLib.LocationManager`, `_TtC9CommonLib15LocationManager`
- `0x2fae4` (`0x2f798`) _MSHookMessageEx replacementCandidate=`0x37f28` candidateClass=`CPNavigationSession`
- `0x2fb00` (`0x2f798`) _MSHookMessageEx replacementCandidate=`0x37fec` candidateClass=`CPNavigationSession`
- `0x2fb20` (`0x2f798`) _MSHookMessageEx selector=`cancelTrip` (original_authenticated_objc_selref) replacementCandidate=`0x3813c` candidateClass=`CPNavigationSession`
- `0x2fb40` (`0x2f798`) _MSHookMessageEx selector=`finishTrip` (original_authenticated_objc_selref) replacementCandidate=`0x38190` candidateClass=`CPNavigationSession`
- `0x2fb60` (`0x2f798`) _MSHookMessageEx selector=`pauseTripForReason:description:` (original_authenticated_objc_selref) replacementCandidate=`0x381e4` candidateClass=`CPNavigationSession`
- `0x30178` (`0x2f798`) _MSHookMessageEx replacementCandidate=`0x38c18`
- `0x30210` (`0x2f798`) _MSHookMessageEx replacementCandidate=`0x38d6c` candidateClass=`_TtC9CommonLib11AudioDevice`
- `0x3022c` (`0x2f798`) _MSHookMessageEx replacementCandidate=`0x38de8` candidateClass=`_TtC9CommonLib11AudioDevice`
- `0x3028c` (`0x2f798`) _MSHookFunction replacementCandidate=`0x3aab0` candidateClass=`_TtC9CommonLib11AudioDevice`
- `0x303d8` (`0x2f798`) _MSHookFunction
- `0x30710` (`0x2f798`) _MSHookFunction replacementCandidate=`0x3a904`
- `0x30840` (`0x2f798`) _MSHookFunction replacementCandidate=`0x3ad20`
- `0x3086c` (`0x2f798`) _MSHookFunction replacementCandidate=`0x40558`
- `0x308e4` (`0x2f798`) _MSHookFunction replacementCandidate=`0x40738`
- `0x311f4` (`0x30f40`) _MSHookMessageEx
- `0x3716c` (`0x36f64`) _MSHookMessageEx selector=`objectForInfoDictionaryKey:` (prior_objc_selref_through_register) replacementCandidate=`0x375ec`
- `0x371b0` (`0x36f64`) _MSHookMessageEx selector=`infoDictionary` (prior_objc_selref_through_register) replacementCandidate=`0x37700`
- `0x37354` (`0x3728c`) _MSHookMessageEx replacementCandidate=`0x37a20` candidateClass=`FBSApplicationInfo`, `FBApplicationInfo`, `LSApplicationRecord`
- `0x373cc` (`0x3728c`) _MSHookMessageEx replacementCandidate=`0x37b64` candidateClass=`FBSApplicationInfo`, `FBApplicationInfo`, `LSApplicationRecord`
- `0x37488` (`0x3728c`) _MSHookMessageEx replacementCandidate=`0x37ca8`
- `0x390a4` (`0x38f60`) _MSHookMessageEx selector=`setActive:withOptions:error:` (prior_objc_selref_through_register) replacementCandidate=`0x39b54`
- `0x39188` (`0x38f60`) _MSHookMessageEx selector=`setCategory:mode:options:error:` (prior_objc_selref_through_register) replacementCandidate=`0x3a08c`
- `0x393f0` (`0x38f60`) _MSHookFunction replacementCandidate=`0x39630`
- `0x39408` (`0x38f60`) _MSHookFunction replacementCandidate=`0x39970`
- `0x39420` (`0x38f60`) _MSHookFunction replacementCandidate=`0x399b4`

## Explicit source-specific evidence gates
The probe is NOT a GOFA speed-limit, camera, or turn decoder.
Any selector/class must be validated in the running GOFA process.
Do not use unverified method signatures, offsets or synthetic alerts.
