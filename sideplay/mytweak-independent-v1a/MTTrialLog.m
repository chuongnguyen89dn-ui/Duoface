#import "MTTrialLog.h"
#import <fcntl.h>
#import <unistd.h>
static NSString *const MTLogPath=@"/var/mobile/Library/Logs/MyTweakV1BC.log";
NSString *MTTrialConfigurationPath(void) {
    return @"/var/mobile/Library/Preferences/com.duoface.mytweak.v1bc.plist";
}
void MTTrialLog(NSString *event, NSString *detail) {
    NSString *line=[NSString stringWithFormat:@"[MyTweakV1BC] event=%@ %@",event ?: @"-",detail ?: @""];
    NSLog(@"%@",line);
    @synchronized([NSFileManager defaultManager]) {
        // Preserve a simple Filza-readable log; failure also appears in NSLog.
        [[NSFileManager defaultManager] createDirectoryAtPath:[MTLogPath stringByDeletingLastPathComponent]
                                   withIntermediateDirectories:YES attributes:nil error:nil];
        int fd=open(MTLogPath.UTF8String,O_WRONLY|O_APPEND|O_CREAT,0644);
        if (fd<0) return;
        NSData *data=[[line stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding];
        (void)write(fd,data.bytes,data.length);
        close(fd);
    }
}
