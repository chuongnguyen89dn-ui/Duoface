// Bounded first-party diagnostics. No system method hooks or exception swallowing.
#import <Foundation/Foundation.h>
#import <unistd.h>
#import <fcntl.h>
#import <stdio.h>
#import <sys/stat.h>
static inline void DFDeepTrace(NSString *area, NSString *event) {
    @try {
        static NSString *run; static dispatch_once_t once;
        dispatch_once(&once,^{run=NSUUID.UUID.UUIDString;});
        // Serialize both module writers through a shared Foundation lock.
        @synchronized(NSProcessInfo.processInfo) {
            NSString *path=@"/var/mobile/Library/Logs/DuoFaceDeepTrace.log";
            struct stat st;
            if(stat(path.fileSystemRepresentation,&st)==0 && st.st_size>2*1024*1024) {
                NSString *previous=[path stringByAppendingString:@".previous"];
                (void)rename(path.fileSystemRepresentation,previous.fileSystemRepresentation);
            }
            NSString *line=[NSString stringWithFormat:@"utc=%.6f uptime=%.6f build=0.0.73~scenecontract1 pid=%d process=%@ run=%@ main=%d area=%@ %@\n",
                NSDate.date.timeIntervalSince1970,NSProcessInfo.processInfo.systemUptime,
                getpid(),NSProcessInfo.processInfo.processName,run,NSThread.isMainThread,area,event];
            NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
            int fd=open(path.fileSystemRepresentation,O_WRONLY|O_CREAT|O_APPEND,0644);
            if(fd>=0){(void)write(fd,data.bytes,data.length);close(fd);}
        }
    } @catch(NSException *exception) { (void)exception; }
}

// Shared audit vocabulary across real SpringBoard panes, native CPWindow,
// Apple Dock owner, user commands and actual diagnostic export. Read-only:
// NEVER writes FBScene state or user files beyond our existing bounded log.
// Values are restricted to scalar metadata (no media, Apple IDs or cookies).
static inline void DFDiagnosticSnapshot(NSString *area, NSString *phase,
                                        NSDictionary<NSString *,id> *facts) {
    @try {
        static NSSet<NSString *> *approved;
        static dispatch_once_t once;
        dispatch_once(&once,^{
            approved=[NSSet setWithArray:@[@"bundle",@"phase",@"ready",@"started",
              @"stopped",@"generation",@"hosting",@"sceneMatches",@"attached",
              @"controller",@"sceneType",@"pane",@"window",@"childFrame",
              @"childBounds",@"pending",@"committed",@"requested",@"native",@"result",
              @"reason",@"zoom",@"dock",@"focus",@"ratio",@"slot",@"count",
              @"event",@"owner",@"status",@"action",@"sequence",@"screen",
              @"timer",@"source"]];
        });
        NSMutableArray<NSString *> *items=[NSMutableArray arrayWithObject:
            [NSString stringWithFormat:@"checkpoint=%@",phase?:@"unknown"]];
        NSArray *keys=[[facts allKeys] sortedArrayUsingSelector:@selector(compare:)];
        for(id key in keys) {
            if(![key isKindOfClass:NSString.class] ||
               ![approved containsObject:key])continue;
            id value=facts[key];
            if(![value isKindOfClass:NSString.class] &&
               ![value isKindOfClass:NSNumber.class])continue;
            NSString *clean=[[value description]
              stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
            clean=[clean stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
            if(clean.length>160)clean=[clean substringToIndex:160];
            [items addObject:[NSString stringWithFormat:@"%@=%@",key,clean]];
        }
        DFDeepTrace(area?:@"audit",[items componentsJoinedByString:@" "]);
    } @catch(NSException *ignored) {(void)ignored;}
}
