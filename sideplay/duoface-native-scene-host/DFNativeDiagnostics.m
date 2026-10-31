#import "DFNativeDiagnostics.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <math.h>

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
    [summary appendString:@"Audit schema: 3; exporter build 0.0.90~nativegetters1; runtime process build is in timestamped traces.\n"];
    NSArray<NSString *> *ownLogs=@[
      @"/var/mobile/Library/Logs/DuoFaceSceneHost.log",
      @"/var/mobile/Library/Logs/DuoFaceTouchOwner.log",
      @"/var/mobile/Library/Logs/DuoFaceDockOwner.log",
      @"/var/mobile/Library/Logs/DuoFaceHomeCatalogABI.log",
      @"/var/mobile/Library/Logs/DuoFaceHomePublisher136.log",
      @"/var/mobile/Library/Logs/DuoFaceHomeAdmission137.log",
      @"/var/mobile/Library/Logs/DuoFaceHomeAdmission140.log",
      @"/var/mobile/Library/Logs/DuoFaceHomeAdmission141.log",
      @"/var/mobile/Library/Logs/DuoFaceHomeLaunch142.log",
      @"/var/mobile/Library/Logs/DuoFaceHomeLaunch143.log",
      @"/var/mobile/Library/Logs/DuoFaceStandalone144.log",
      @"/var/mobile/Library/Logs/DuoFaceNativeSceneJoin.log",
      @"/var/mobile/Library/Logs/DuoFaceCarPlayOwnerSnapshot.log",
      @"/var/mobile/Library/Logs/DuoFaceNativeMapPane.log",
      @"/var/mobile/Library/Logs/DuoFaceDisconnectClose.log",
      @"/var/mobile/Library/Logs/DuoFaceFatalException.log"];
    for(NSString *process in @[@"DuoFaceNativeHost",@"SpringBoard",@"CarPlayApp",@"CarPlay",@"Dashboard"]){
        NSString *name=[NSString stringWithFormat:@"DuoFaceGeometry119-%@.jsonl",process];
        NSString *path=[@"/var/mobile/Library/Logs" stringByAppendingPathComponent:name];
        [summary appendFormat:@"\n=== %@ (last 256 KiB; read-only geometry, no physical PASS) ===\n%@\n",
            name,[self tailAtPath:path maxBytes:256*1024]];
    }
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

    // Separate standalone Home owner: diagnostic only, no one-time request UUIDs.
    NSDictionary *soloConsent=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-optin.plist"];
    NSDictionary *soloLease=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-sb-lease.plist"];
    NSDictionary *soloResult=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.standalone144-result.plist"];
    NSNumber *leaseStamp=soloLease[@"Timestamp"],*resultStamp=soloResult[@"Timestamp"];
    NSTimeInterval soloLeaseAge=[leaseStamp isKindOfClass:NSNumber.class]?
      NSDate.date.timeIntervalSince1970-leaseStamp.doubleValue:INFINITY;
    NSTimeInterval resultAge=[resultStamp isKindOfClass:NSNumber.class]?
      NSDate.date.timeIntervalSince1970-resultStamp.doubleValue:INFINITY;
    [summary appendFormat:@"\nStandalone Home: enabled=%@ receiverAlive=%@ age=%.2fs outcome=%@ reason=%@ resultAge=%.2fs bundle=%@; display/touch UNVERIFIED\n",
      [soloConsent[@"StandaloneHomeDirect"] boolValue]?@"YES":@"NO",
      [soloLease[@"Alive"] boolValue]?@"YES":@"NO",soloLeaseAge,
      [soloResult[@"Outcome"] isKindOfClass:NSString.class]?soloResult[@"Outcome"]:@"none",
      [soloResult[@"Reason"] isKindOfClass:NSString.class]?soloResult[@"Reason"]:@"none",
      resultAge,[soloResult[@"BundleID"] isKindOfClass:NSString.class]?soloResult[@"BundleID"]:@"unknown"];

    // Native Maps is owned by CarPlayApp, not SpringBoard. Include its
    // acknowledged attach result and measured PHYSICAL panes so a human can
    // distinguish a controller attach from real map tiles/navigation.
    // Strip request IDs/session UUIDs. Never claim rendering from these.
    NSDictionary *mapAck=[NSDictionary dictionaryWithContentsOfFile:
       @"/var/mobile/Library/Preferences/com.duoface.nativehost.map-pane.ack.v1.plist"];
    NSDictionary *physical=[NSDictionary dictionaryWithContentsOfFile:
       @"/var/mobile/Library/Preferences/com.duoface.nativehost.physical-panes.v1.plist"];
    NSNumber *mapStamp=mapAck[@"Timestamp"];
    double mapAge=[mapStamp isKindOfClass:NSNumber.class]?
       NSDate.date.timeIntervalSince1970-mapStamp.doubleValue:INFINITY;
    [summary appendFormat:
      @"\nNative Map ACK: applied=%@ attached=%@ reason=%@ owner=%@ age=%.2fs\n",
      [mapAck[@"Applied"] boolValue]?@"YES":@"NO",
      [mapAck[@"PaneAttached"] boolValue]?@"YES":@"NO",
      [mapAck[@"Reason"] isKindOfClass:NSString.class]?mapAck[@"Reason"]:@"none",
      [mapAck[@"OwnerProcess"] isKindOfClass:NSString.class]?mapAck[@"OwnerProcess"]:@"unknown",
      mapAge];
    NSArray *physicalFrames=physical[@"Windows"];
    if([physicalFrames isKindOfClass:NSArray.class]){
      NSNumber *physicalStamp=physical[@"Timestamp"];
      NSTimeInterval age=[physicalStamp isKindOfClass:NSNumber.class]?
         NSDate.date.timeIntervalSince1970-physicalStamp.doubleValue:INFINITY;
      [summary appendFormat:@"Native Maps physical frame readback: count=%lu age=%.2fs\n",
         (unsigned long)physicalFrames.count,age];
      for(id item in physicalFrames){
        if(![item isKindOfClass:NSDictionary.class])continue;
        [summary appendFormat:@"  physical=%@ visual=%@ external=%@ visible=%@ app=%@ frame=%@\n",
          item[@"PhysicalSlot"]?:@"?", item[@"VisualSlot"]?:@"?",
          item[@"OnExternalScreen"]?:@"?", item[@"WindowVisible"]?:@"?",
          item[@"HasLiveApp"]?:@"?", item[@"Frame"]?:@"?"];
      }
    }
    [summary appendString:@"Native Maps pixels and actual route continuation require CarPlay on-device visual QA; never inferred from ACK.\n"];
    // Report both independent persistence owners without exporting session IDs
    // or PIDs. Normal app slots and the adopted native CarPlay Maps scene differ.
    NSDictionary *workspace=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.workspace.v1.plist"];
    NSArray *slots=workspace[@"PhysicalBundles"];
    if([slots isKindOfClass:NSArray.class] && slots.count==4){
      for(NSUInteger i=0;i<4;i++) {
        NSString *selected=[slots[i] isKindOfClass:NSString.class]?slots[i]:@"";
        [summary appendFormat:@"Remembered app slot %lu: %@\n",
             (unsigned long)i,selected.length?selected:@"empty"];
      }
    }else [summary appendString:@"Remembered app slots: unavailable/invalid\n"];
    NSDictionary *nativeChoice=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-map-choice.v1.plist"];
    NSDictionary *nativeLease=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.native-map-lease.v1.plist"];
    NSNumber *leaseTimestamp=nativeLease[@"Timestamp"];
    NSTimeInterval leaseAge=[leaseTimestamp isKindOfClass:NSNumber.class]?
      NSDate.date.timeIntervalSince1970-leaseTimestamp.doubleValue:INFINITY;
    NSString *nativeBid=[nativeLease[@"BundleID"] isKindOfClass:NSString.class]?
      nativeLease[@"BundleID"]:@"unverified";
    [summary appendFormat:
       @"Native map chosen physical slot: %@; last verified owner bundle: %@; lease age: %.2fs (must match current session)\n",
       nativeChoice[@"Slot"]?:@"none",nativeBid,leaseAge];
    NSDictionary *closeSetting=[NSDictionary dictionaryWithContentsOfFile:
      @"/var/mobile/Library/Preferences/com.duoface.nativehost.disconnect-close.v1.plist"];
    [summary appendFormat:@"Physical unplug app close enabled: %@ (default OFF)\n",
      [closeSetting[@"CloseOnPhysicalDisconnect"] boolValue]?@"YES":@"NO"];
    NSDictionary *closeState=[NSDictionary dictionaryWithContentsOfFile:
       @"/var/mobile/Library/Preferences/com.duoface.nativehost.disconnect-close.ack.v1.plist"];
    NSNumber *closeTime=closeState[@"Timestamp"];
    NSTimeInterval closeAge=[closeTime isKindOfClass:NSNumber.class]?
       NSDate.date.timeIntervalSince1970-closeTime.doubleValue:INFINITY;
    [summary appendFormat:
      @"Disconnect close (10s opt-in): status=%@ attempted=%@ verified=%@ age=%.2fs (process exit requires PID check; never an ACK alone)\\n",
      closeState[@"Status"]?:@"not-observed",closeState[@"Attempted"]?:@0,
      closeState[@"VerifiedExited"]?:@0,closeAge];
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
