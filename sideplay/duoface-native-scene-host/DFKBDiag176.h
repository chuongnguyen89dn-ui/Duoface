// QA176: hosted-app keyboard diagnostics (LOG ONLY, no behaviour change).
// The app-side relay (DF154GeneralAppStateRelay) writes one bounded
// record per keyboard appearance into a fixed DF156 mailbox and posts a
// Darwin wakeup; SpringBoard (Chrome) reads the record and logs it
// together with its own host-surface frames and the external display
// size, so one exported log block can separate the hypotheses:
// frame overflowing the bottom / clipped by an ancestor / wrong
// keyplane / phantom hardware keyboard. Behind its own flag in the
// qa176 plist; absent = ON for this diagnostic round.
#ifndef DF_KBDIAG_176_H
#define DF_KBDIAG_176_H
#import <Foundation/Foundation.h>

static NSString *const DF176KBDiagPrefsPath =
    @"/var/mobile/Library/Preferences/com.duoface.nativehost.qa176.plist";
static const char *const DF176KBDiagWakeName = "com.duoface.kbdiag176.wake";
static const char *const DF176KBDiagMailboxName = "com.duoface.ipc.v176.kbdiag";

static inline BOOL DF176KBDiagEnabled(void) {
    NSDictionary *p = [NSDictionary dictionaryWithContentsOfFile:DF176KBDiagPrefsPath];
    id v = [p isKindOfClass:NSDictionary.class] ? p[@"KeyboardDiag176"] : nil;
    return v ? [v boolValue] : YES;
}
#endif
