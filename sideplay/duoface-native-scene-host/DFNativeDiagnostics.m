#import "DFNativeDiagnostics.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

@implementation DFNativeDiagnostics
+ (NSString *)tailAtPath:(NSString *)path maxBytes:(NSUInteger)limit {
    NSFileHandle *handle=[NSFileHandle fileHandleForReadingAtPath:path];
    if(!handle)return @"[không đọc được hoặc file chưa tồn tại]";
    @try {
        unsigned long long length=[handle seekToEndOfFile];
        if(length>limit)[handle seekToFileOffset:length-limit];
        else [handle seekToFileOffset:0];
        NSData *bytes=[handle readDataToEndOfFile];
        [handle closeFile];
        NSString *value=[[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding];
        return value?:@"[không giải mã được UTF-8]";
    }@catch(NSException *ex){
        [handle closeFile];
        return [NSString stringWithFormat:@"[lỗi đọc: %@]",ex.name];
    }
}
+ (NSArray<NSURL *> *)prepareShareFiles {
    NSFileManager *fm=NSFileManager.defaultManager;
    NSString *base=[NSTemporaryDirectory() stringByAppendingPathComponent:
             [NSString stringWithFormat:@"DuoFaceAudit-%lld",(long long)NSDate.date.timeIntervalSince1970]];
    NSError *error=nil;
    if(![fm createDirectoryAtPath:base withIntermediateDirectories:YES
                          attributes:@{NSFileProtectionKey:NSFileProtectionCompleteUnlessOpen}
                               error:&error])return @[];

    // The shared DuoFaceDeepTrace log has tagged coverage for native
    // CPWindow, SpringBoard hosted app scenes, media reference ABI, App/Style,
    // Logo/Ratio/Swap/Zoom, Dock ACK, Close, Home and disconnect.
    // No background upload: manual iPhone export only. A successful trace
    // checkpoint NEVER means the video rendered or SpringBoard cannot crash.
    // Capture only DuoFace-owned logs plus at most three recent system-host
    // crashes. Do not collect arbitrary apps' reports or device identifiers.
    NSMutableString *summary=[NSMutableString stringWithFormat:
         @"DuoFace CarPlay / media scene diagnostic (manual export)\n"
          @"Date: %@\niOS: %@\nApp: %@\n"
          @"This file contains technical diagnostics; share only with a trusted recipient.\n",
         NSDate.date.description,UIDevice.currentDevice.systemVersion,
         NSBundle.mainBundle.bundleIdentifier?:@"unknown"];
    [summary appendString:@"Audit schema: 3; exporter build 0.0.79~nativeocclusion1; runtime process build is in timestamped traces.\n"];
    NSArray<NSString *> *ownLogs=@[
      @"/var/mobile/Library/Logs/DuoFaceSceneHost.log",
      @"/var/mobile/Library/Logs/DuoFaceTouchOwner.log",
      @"/var/mobile/Library/Logs/DuoFaceDockOwner.log",
      @"/var/mobile/Library/Logs/DuoFaceNativeSceneJoin.log",
      @"/var/mobile/Library/Logs/DuoFaceFatalException.log"];
    for(NSString *p in ownLogs){
        [summary appendFormat:@"\n=== %@ (last 256 KiB) ===\n%@\n",
           p.lastPathComponent,[self tailAtPath:p maxBytes:256*1024]];
    }
    for(NSString *name in @[@"DuoFaceDeepTrace.log.previous",@"DuoFaceDeepTrace.log"]){
        NSString *trace=[@"/var/mobile/Library/Logs" stringByAppendingPathComponent:name];
        [summary appendFormat:@"\n=== %@ (last 2 MiB; timestamped diagnostic build) ===\n%@\n",name,[self tailAtPath:trace maxBytes:2*1024*1024]];
    }
    NSString *session=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
    NSDictionary *sessionValue=[NSDictionary dictionaryWithContentsOfFile:session];
    [summary appendFormat:@"\nSession active: %@; heartbeat age seconds: ",
       [sessionValue[@"Active"] boolValue]?@"YES":@"NO"];
    NSNumber *stamp=sessionValue[@"Timestamp"];
    if([stamp isKindOfClass:NSNumber.class])
       [summary appendFormat:@"%.2f\n",NSDate.date.timeIntervalSince1970-stamp.doubleValue];
    else [summary appendString:@"unknown\n"];

    NSMutableArray<NSDictionary *> *found=[NSMutableArray new];
    NSMutableSet<NSString *> *seen=[NSMutableSet new];
    NSArray<NSString *> *crashDirs=@[
       @"/var/mobile/Library/Logs/CrashReporter",
       @"/var/mobile/Library/Logs/CrashReporter/DiagnosticLogs",
       @"/var/mobile/Library/Logs/CrashReporter/Retired",
       @"/var/mobile/Library/Logs/DiagnosticReports",
       @"/var/root/Library/Logs/CrashReporter"];
    for(NSString *dir in crashDirs){
       for(NSString *name in [fm contentsOfDirectoryAtPath:dir error:nil]?:@[]){
           NSString *lower=name.lowercaseString;
           BOOL relevant=[lower hasPrefix:@"springboard"]||[lower hasPrefix:@"carplay"];
           if(!relevant || (!([lower hasSuffix:@".ips"]||[lower hasSuffix:@".crash"])))continue;
           NSString *path=[dir stringByAppendingPathComponent:name];
           if([seen containsObject:path])continue;
           [seen addObject:path];
           NSDictionary *attributes=[fm attributesOfItemAtPath:path error:nil];
           if(![attributes[NSFileType] isEqual:NSFileTypeRegular])continue;
           unsigned long long size=[attributes[NSFileSize] unsignedLongLongValue];
           NSDate *modified=attributes[NSFileModificationDate];
           if(size==0 || size>8*1024*1024 || ![modified isKindOfClass:NSDate.class])continue;
           NSTimeInterval age=[NSDate.date timeIntervalSinceDate:modified];
           if(age< -120 || age>30*24*3600)continue;
           [found addObject:@{@"path":path,@"date":modified,@"size":@(size)}];
       }
    }
    [found sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){
        return [b[@"date"] compare:a[@"date"]];
    }];
    NSMutableArray<NSURL *> *files=[NSMutableArray new];
    NSUInteger copies=MIN((NSUInteger)3,found.count);
    for(NSUInteger i=0;i<copies;i++){
        NSDictionary *report=found[i];
        NSString *source=report[@"path"];
        NSString *destination=[base stringByAppendingPathComponent:
               [NSString stringWithFormat:@"Crash-%lu-%@",(unsigned long)i,source.lastPathComponent]];
        NSError *copyError=nil;
        if([fm copyItemAtPath:source toPath:destination error:&copyError]){
            [files addObject:[NSURL fileURLWithPath:destination]];
            [summary appendFormat:@"Crash included: %@ (%@ bytes)\n",
               source.lastPathComponent,report[@"size"]];
        }else [summary appendFormat:@"Crash unreadable: %@ (%@)\n",
                       source.lastPathComponent,copyError.localizedDescription?:@"unknown"];
    }
    if(!copies)[summary appendString:
                 @"No readable recent SpringBoard/CarPlay .ips or .crash found. Check access rights or occurrence date.\n"];
    NSString *path=[base stringByAppendingPathComponent:@"DuoFaceAudit.txt"];
    if(![summary writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error])return @[];
    [files insertObject:[NSURL fileURLWithPath:path] atIndex:0];
    return files;
}
@end
