# Voice linkage audit — native 1.0.4 (2026-10-13)

Command: `llvm-objdump --macho --objc-meta-data /mnt/data/duoface_fullaudit/up/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib`; output `/mnt/data/duoface_voice_objc_full.txt`.

The voice implementation is **compiled into the native Dashboard Mach-O**, not a directory of standalone files. Confirmed Objective-C class metadata and methods:

| Class | Representative methods |
|---|---|
| `CBVoiceSessionManager` | `sharedInstance`, `toggleSession`, `startSession`, `setState:`, `announceErrorAndReset` |
| `CBVoiceAudioCapture` | `startRecording:`, `stopRecording`, `setMode:` |
| `CBVoiceAudioPlayer` | `appendAudioData:`, `playWithCompletion:`, `stopAndClear` |
| `CBVoiceSTTAppleOnDeviceProvider` | `startSessionWithInputFormat:error:`, `consumeAudioBuffer:`, `stopSession` |
| `CBVoiceSTTCloudStreamingProvider` | `startSessionWithInputFormat:error:`, `consumeAudioBuffer:`, `stopSession` |
| `CBVoiceDirectiveDispatcher` | `registerHandler:`, `dispatchDirective:completion:` |
| `CBVoiceSceneDispatcher` | `dispatchAppWithBundleID:launchURL:targetSlot:completion:` |
| `CBAIBubbleView` | `setupAuraPulse`, `setupCoreBubble`, `setupBrandingIcon` |
| `CBAppLaunchDirectiveHandler` | `canHandleDirective:`, `executeDirective:completion:` |

The `CBAIBubbleView` appears as a typed Objective-C property in the native Dashboard's other class metadata; this is a direct in-binary linkage, not a standalone asset. Voice uses Speech/AVFoundation/AudioToolbox frameworks (confirmed previously). Therefore adding audio and OldABI files to v12 is not enough. To preserve v12 native Dashboard while adding native 1.0.4 voice, need a separately compiled, linked compatible module or carefully validated binary integration; blindly adding second Dashboard creates duplicate UI/classes. This is an observed technical dependency, not conjecture. No DEB built.
