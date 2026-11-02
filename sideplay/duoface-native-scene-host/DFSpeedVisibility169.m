// First-party shared preference. Never reuse CarPlayPro preferences.
#import "DFSpeedVisibility169.h"
#import <notify.h>
static NSString *const DF169VisibilityPath=
  @"/var/mobile/Library/Preferences/com.duoface.speedhud.visibility.v1.plist";
static const char *DF169VisibilityNotify="com.duoface.speedhud.visibility.v1.changed";
BOOL DF169SpeedBubbleEnabled(void) {
    NSDictionary *state=[NSDictionary dictionaryWithContentsOfFile:DF169VisibilityPath];
    if(![state isKindOfClass:NSDictionary.class])return YES; // upgrade retains current behavior
    id v=state[@"Enabled"];
    return [v isKindOfClass:NSNumber.class] ? [v boolValue] : YES;
}
NSString *DF169SpeedBubbleChangeNotification(void) {
    return @(DF169VisibilityNotify);
}
BOOL DF169SetSpeedBubbleEnabled(BOOL enabled) {
    // Explicit action only. Persist before notifying other owners. If the
    // system restricts writes, do not falsely announce a successful change.
    NSDictionary *old=[NSDictionary dictionaryWithContentsOfFile:DF169VisibilityPath]?:@{};
    NSMutableDictionary *new=[old mutableCopy];
    new[@"Version"]=@1;
    new[@"Enabled"]=@(enabled);
    if(![new writeToFile:DF169VisibilityPath atomically:YES]) {
        NSLog(@"[DuoFaceSpeed8] QA169 visibility persistence FAILED");
        return NO;
    }
    notify_post(DF169VisibilityNotify);
    return YES;
}
