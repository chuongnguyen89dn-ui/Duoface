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
            NSString *line=[NSString stringWithFormat:@"utc=%.6f uptime=%.6f build=0.0.62~rawgrip1 pid=%d process=%@ run=%@ main=%d area=%@ %@\n",
                NSDate.date.timeIntervalSince1970,NSProcessInfo.processInfo.systemUptime,
                getpid(),NSProcessInfo.processInfo.processName,run,NSThread.isMainThread,area,event];
            NSData *data=[line dataUsingEncoding:NSUTF8StringEncoding];
            int fd=open(path.fileSystemRepresentation,O_WRONLY|O_CREAT|O_APPEND,0644);
            if(fd>=0){(void)write(fd,data.bytes,data.length);close(fd);}
        }
    } @catch(NSException *exception) { (void)exception; }
}
