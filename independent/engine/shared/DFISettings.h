#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <notify.h>
#define DFIDomain @"com.duoface.independent"
#define DFIChanged "com.duoface.independent.preferences"
static inline id DFIPref(NSString *key) { CFPreferencesAppSynchronize((__bridge CFStringRef)DFIDomain); return CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key,(__bridge CFStringRef)DFIDomain)); }
static inline void DFISetPref(NSString *key,id value) { CFPreferencesSetAppValue((__bridge CFStringRef)key,(__bridge CFPropertyListRef)value,(__bridge CFStringRef)DFIDomain);CFPreferencesAppSynchronize((__bridge CFStringRef)DFIDomain);notify_post(DFIChanged); }
static inline BOOL DFIEnabled(void) { id v=DFIPref(@"enabled");return v && [v boolValue]; }
static inline NSString *DFIT(NSString *vi,NSString *en) {return [DFIPref(@"language") isEqual:@"en"]?en:vi;}
static inline CGFloat DFIFontSize(void) { NSInteger n=[DFIPref(@"textSize") integerValue];return n==2?17:(n==1?15:13); }
@interface DFISettingsController : UITableViewController
@end
