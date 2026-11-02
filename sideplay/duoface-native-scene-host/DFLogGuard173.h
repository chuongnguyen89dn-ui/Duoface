// QA173: bounded, de-duplicated appends for DuoFace per-module log files.
// Identical consecutive lines are suppressed for 5s; files rotate to a
// single .old backup past 256 KiB so logging can never grow without
// bound (the 2026-11-02 system report showed ~1,073 MB written in ~6h).
#import <Foundation/Foundation.h>
#import <fcntl.h>
#import <unistd.h>
#import <sys/stat.h>
static inline void DFLogWriteCapped173(NSString *path, NSString *line) {
    @synchronized([NSProcessInfo processInfo]) {
        static NSMutableDictionary<NSString *, NSString *> *lastLines;
        static NSMutableDictionary<NSString *, NSNumber *> *lastTimes;
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            lastLines = [NSMutableDictionary dictionary];
            lastTimes = [NSMutableDictionary dictionary];
        });
        NSTimeInterval now = [NSProcessInfo processInfo].systemUptime;
        NSString *prev = lastLines[path];
        NSNumber *prevAt = lastTimes[path];
        if (prev && prevAt && [prev isEqualToString:line] &&
            now - prevAt.doubleValue < 5.0) return;
        lastLines[path] = [line copy];
        lastTimes[path] = @(now);
        const char *cpath = path.fileSystemRepresentation;
        struct stat st;
        if (stat(cpath, &st) == 0 && st.st_size > 256 * 1024) {
            NSString *old = [path stringByAppendingString:@".old"];
            (void)rename(cpath, old.fileSystemRepresentation);
        }
        int fd = open(cpath, O_WRONLY | O_APPEND | O_CREAT, 0644);
        if (fd >= 0) {
            NSData *d = [[line stringByAppendingString:@"\n"]
                dataUsingEncoding:NSUTF8StringEncoding];
            (void)write(fd, d.bytes, d.length);
            close(fd);
        }
    }
}
