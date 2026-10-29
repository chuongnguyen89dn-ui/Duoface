// Source-owned executable Foundation regression; never touches real preferences.
#import <Foundation/Foundation.h>
#import <unistd.h>
#import "DFAppHabits.h"
static void ensure(BOOL ok,NSString *reason) {
 if(!ok){NSLog(@"APP_HABITS_FAIL %@",reason);abort();}
}
int main(void) {
 @autoreleasepool {
    NSString *directory=[NSTemporaryDirectory() stringByAppendingPathComponent:
         [NSString stringWithFormat:@"duoface-habits-%d-%@",getpid(),NSUUID.UUID.UUIDString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *prefs=[directory stringByAppendingPathComponent:@"choices.plist"];
    NSString *history=[directory stringByAppendingPathComponent:@"usage.plist"];
    NSDictionary *initial=DFReadAppChoicesAtPath(prefs);
    ensure([initial[@"DefaultBundleID"] isEqual:@""] &&
        [initial[@"PinnedBundleIDs"] count]==0,@"missing prefs empty");
    ensure(!DFWriteAppChoicesAtPath(@"com.apple.springboard",@[],prefs),
        @"invalid default rejected");
    ensure(DFWriteAppChoicesAtPath(@"com.google.ios.youtube",
          @[@"com.apple.Maps",@"com.google.ios.youtube",@"com.apple.Maps"],prefs),
          @"save default and pins");
    NSDictionary *saved=DFReadAppChoicesAtPath(prefs);
    ensure([saved[@"DefaultBundleID"] isEqual:@"com.google.ios.youtube"] &&
      [saved[@"PinnedBundleIDs"] isEqualToArray:@[@"com.apple.Maps",@"com.google.ios.youtube"]],
      @"dedup and readback");
    NSArray *installed=@[@"com.example.other",@"com.apple.Maps",
                          @"com.google.ios.youtube",@"com.example.news"];
    NSArray *ordered=DFRankAppIDsByHabits(installed,saved,@{});
    ensure([ordered isEqualToArray:@[@"com.google.ios.youtube",@"com.apple.Maps",
           @"com.example.other",@"com.example.news"]],@"default and pinned rank");
    ensure(DFRecordReadyAppHabitAtPath(@"com.example.news",history),@"usage count first");
    ensure(DFRecordReadyAppHabitAtPath(@"com.example.news",history),@"usage count second");
    ensure(DFRecordReadyAppHabitAtPath(@"com.example.other",history),@"usage count other");
    NSDictionary *counts=DFReadAppHabitCountsAtPath(history);
    ensure([counts[@"com.example.news"] integerValue]==2,@"counts persisted");
    ensure(!DFRecordReadyAppHabitAtPath(@"com.apple.springboard",history),
           @"service excluded");
    NSArray *habits=DFRankAppIDsByHabits(installed,DFEmptyAppChoices(),counts);
    ensure([habits isEqualToArray:@[@"com.example.news",@"com.example.other",
            @"com.apple.Maps",@"com.google.ios.youtube"]],@"usage priority deterministic");
    ensure(![habits containsObject:@"com.example.uninstalled"],@"no invented installed app");
    [@{@"Version":@9,@"DefaultBundleID":@"com.google.ios.youtube",
       @"PinnedBundleIDs":@[]} writeToFile:prefs atomically:YES];
    ensure([DFReadAppChoicesAtPath(prefs)[@"DefaultBundleID"] isEqual:@""],
         @"invalid file fail closed");
    [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
    NSLog(@"APP_HABITS_RUNTIME_PASS");
 }
 return 0;
}
