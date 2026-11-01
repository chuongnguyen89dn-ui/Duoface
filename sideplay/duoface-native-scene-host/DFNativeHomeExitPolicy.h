// Original bridgeDidDeactivate clears active bundle and sends inApp:NO;
// setHomeButtonInApp computes !inApp => displayState1. No guessed enum values.
#ifndef DF_NATIVE_HOME_EXIT_POLICY_H
#define DF_NATIVE_HOME_EXIT_POLICY_H
static inline BOOL DFNativeHomeChooserExit(NSString *reason) {
 return [reason isEqualToString:@"native-home-stop"] ||
        [reason isEqualToString:@"native-Home-exit"];
}
static inline NSString *DFNativeHomeRestoredBundle(NSString *reason,NSString *previous) {
 return DFNativeHomeChooserExit(reason)?nil:previous;
}
static inline NSUInteger DFNativeHomeRestoredState(NSString *reason,NSUInteger previous) {
 return DFNativeHomeChooserExit(reason)?1:previous;
}
#endif
