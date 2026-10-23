// Restores the already-existing original fullscreen transaction shape:
// request ID → separate native CarPlay Dock owner ACK → real host geometry,
// and rollback on failed ACK, Home, session loss, or timeout.
// No Native12 CBWindow / vendor license binary is loaded.
#import "DFDockZoomCoordinator.h"
#import "DFNative12Chrome.h"
#import <UIKit/UIKit.h>
#import <notify.h>
#import <math.h>

static NSString *const DFZCommand=@"/var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.command.plist";
static NSString *const DFZAck=@"/var/mobile/Library/Preferences/com.duoface.nativehost.dockzoom.ack.plist";
static NSString *const DFZSessionFile=@"/var/mobile/Library/Preferences/com.duoface.nativehost.touchowner.session.plist";
static const char *const DFZNotify="com.duoface.nativehost.dockzoom.command.v1";
static const char *const DFZAckNotify="com.duoface.nativehost.dockzoom.ack.v1";
static NSString *sPendingRequest,*sPendingSession,*sOwnerSession;
static __weak DFNative12Chrome *sPendingChrome;
static DFDockZoomCompletion sCompletion;
static NSUInteger sSequence,sPendingSequence,sGeneration;
static BOOL sDesired;
static int sToken=-1;
static BOOL sSubscribed;

static BOOL DFZPulseFresh(NSString *session) {
    NSDictionary *pulse=[NSDictionary dictionaryWithContentsOfFile:DFZSessionFile];
    NSNumber *stamp=pulse[@"Timestamp"];
    if(![pulse[@"Active"] isEqual:@YES] || !session ||
       ![pulse[@"Session"] isEqualToString:session] ||
       ![stamp isKindOfClass:NSNumber.class])return NO;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-stamp.doubleValue;
    return isfinite(age) && age>=0 && age<=2.5;
}
static BOOL DFZSend(NSString *session,BOOL expanded,NSString *req,
                     NSUInteger sequence) {
    if(!session || !req)return NO;
    NSDictionary *record=@{@"Version":@1,@"Operation":@"SetDockHidden",
        @"Session":session,@"RequestID":req,@"Sequence":@(sequence),
        @"Expanded":@(expanded),
        @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
    if(![record writeToFile:DFZCommand atomically:YES])return NO;
    return notify_post(DFZNotify)==0;
}
static void DFZCancelPending(void) {
    ++sGeneration;
    sPendingRequest=nil;sPendingSession=nil;sPendingChrome=nil;
    sCompletion=nil;sPendingSequence=0;
}
static void DFZComplete(BOOL success,BOOL expanded,
                        NSDictionary<NSString *,id> *receipt) {
    DFDockZoomCompletion completion=[sCompletion copy];
    DFZCancelPending();
    if(completion)completion(success,expanded,receipt?:@{});
}
static void DFZEmergencyRestore(NSString *session) {
    if(!session)return;
    // Must not report success from this fire-and-forget safety restoration.
    DFZSend(session,NO,NSUUID.UUID.UUIDString,++sSequence);
}
static void DFZConsumeAck(void) {
    if(!sPendingRequest || !sPendingSession || !sPendingChrome)return;
    NSDictionary *ack=[NSDictionary dictionaryWithContentsOfFile:DFZAck];
    id stamp=ack[@"Timestamp"],sequence=ack[@"Sequence"];
    if(![ack[@"Version"] isEqual:@1] ||
       ![ack[@"Session"] isEqualToString:sPendingSession] ||
       ![ack[@"RequestID"] isEqualToString:sPendingRequest] ||
       ![sequence isKindOfClass:NSNumber.class] ||
       [sequence unsignedIntegerValue]!=sPendingSequence ||
       ![ack[@"Expanded"] isEqual:@(sDesired)] ||
       ![stamp isKindOfClass:NSNumber.class])return;
    NSTimeInterval age=NSDate.date.timeIntervalSince1970-[stamp doubleValue];
    if(!isfinite(age) || age<0 || age>3.0)return;
    BOOL owner=[ack[@"Applied"] isEqual:@YES] &&
               [ack[@"DockOwnerVerified"] isEqual:@YES] &&
               [ack[@"DockHidden"] isEqual:@(sDesired)] &&
               [ack[@"OwnerClass"] isKindOfClass:NSString.class] &&
               [ack[@"OwnerClass"] length]>0;
    DFNative12Chrome *chrome=sPendingChrome;
    NSString *session=sPendingSession;
    BOOL desired=sDesired;
    if(!DFZPulseFresh(session)) {
        if(desired)DFZEmergencyRestore(session);
        DFZComplete(NO,desired,@{@"Reason":@"foreground-session-revoked"});
        return;
    }
    if(!owner) {
        NSLog(@"[DuoFaceDockZoom] refused owner=%@ reason=%@",
              ack[@"OwnerClass"],ack[@"Reason"]);
        DFZComplete(NO,desired,@{@"Reason":ack[@"Reason"]?:@"dock-rejected"});
        return;
    }
    CGRect bounds=CGRectFromString(ack[@"ScreenBounds"]);
    BOOL success=NO;
    if(desired) {
        // Only the active independent source-pane owner may apply geometry,
        // after the *other* process has physically hidden a measured Dock.
        success=[chrome applyHostFullscreenToScreenBoundsAfterDockAck:bounds];
        if(success)sOwnerSession=[session copy];
        else DFZEmergencyRestore(session);
    }else{
        [chrome restoreHostFullscreenGeometry];
        success=![chrome.stateSnapshot[@"HostFullscreenGeometry"] boolValue];
        if(success)sOwnerSession=nil;
    }
    if(!success) {
        DFZComplete(NO,desired,@{@"Reason":@"source-host-geometry-rejected"});
        return;
    }
    // End-to-end receipt is a result of two observed operations, not
    // a synthetic accept based on tapping the Zoom UI.
    NSDictionary *receipt=@{@"Version":@1,
        @"Session":session,@"RequestID":ack[@"RequestID"],
        @"DockOwnerVerified":@YES,@"DockHidden":@(desired),
        @"HostFullscreenGeometry":@(desired),
        @"ScreenBounds":ack[@"ScreenBounds"]?:@"",
        @"OwnerClass":ack[@"OwnerClass"]?:@"",
        @"Applied":@YES,@"Expanded":@(desired)};
    NSLog(@"[DuoFaceDockZoom] verified-two-owner-zoom=%d",desired);
    DFZComplete(YES,desired,receipt);
}
// Darwin notifications are edge-triggered and can be coalesced while a real
// Dashboard/Dock scene is transitioning. Do not confuse lost notify delivery
// with a failed Dock operation: re-read ONLY the existing atomic signed-like
// session/request/sequence ACK through DFZConsumeAck's strict verification.
// The three-second timeout and emergency restore remain authoritative.
static void DFZPollMatchingAck(NSUInteger generation) {
    if(generation!=sGeneration || !sPendingRequest)return;
    DFZConsumeAck();
    if(generation!=sGeneration || !sPendingRequest)return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(.25*NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        DFZPollMatchingAck(generation);
    });
}

static void DFZEnsureListener(void) {
    if(sSubscribed)return;
    int result=notify_register_dispatch(DFZAckNotify,&sToken,
                   dispatch_get_main_queue(),^(int t){(void)t;DFZConsumeAck();});
    sSubscribed=(result==0);
}
void DFDockZoomToggle(DFNative12Chrome *chrome, NSString *session,
                      DFDockZoomCompletion completion) {
    if(!NSThread.isMainThread || !chrome || !session ||
       !DFZPulseFresh(session) || sPendingRequest) {
        if(completion)completion(NO,NO,@{@"Reason":@"owner-or-session-not-ready"});
        return;
    }
    DFZEnsureListener();
    if(!sSubscribed){
        if(completion)completion(NO,NO,@{@"Reason":@"native-dock-ack-listener-unavailable"});
        return;
    }
    BOOL expanded=[chrome.stateSnapshot[@"HostFullscreenGeometry"] boolValue];
    if(expanded && ![sOwnerSession isEqualToString:session]){
        if(completion)completion(NO,NO,@{@"Reason":@"fullscreen-owner-session-mismatch"});
        return;
    }
    sPendingRequest=NSUUID.UUID.UUIDString;
    sPendingSession=[session copy];sPendingChrome=chrome;
    sCompletion=[completion copy];sDesired=!expanded;
    sPendingSequence=++sSequence;
    NSUInteger generation=++sGeneration;
    if(!DFZSend(session,sDesired,sPendingRequest,sPendingSequence)) {
        DFZComplete(NO,sDesired,@{@"Reason":@"dock-command-not-delivered"});
        return;
    }
    // A successful file ACK must not be discarded only because notify_post
    // was delayed/coalesced; this polls, it never synthesizes any ACK.
    DFZPollMatchingAck(generation);
    // Preserve the previous DuoFace 3-second host ACK budget (Oct 14).
    // The fresh foreground heartbeat and exact request ID still gate success.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(3.0*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{
        if(generation!=sGeneration || !sPendingRequest)return;
        // A native Dock receiver may have hidden its view but its ACK could
        // have been lost: ALWAYS request restore, never mark success.
        if(sDesired)DFZEmergencyRestore(sPendingSession);
        DFZComplete(NO,sDesired,@{@"Reason":@"real-dock-ack-timeout"});
    });
}
void DFDockZoomDetach(DFNative12Chrome *chrome, NSString *session) {
    if(!NSThread.isMainThread)return;
    if(sPendingRequest) {
        NSString *pending=sPendingSession;
        BOOL wasEntering=sDesired;
        DFZCancelPending();
        if(wasEntering)DFZEmergencyRestore(pending);
    }
    if(chrome && [chrome.stateSnapshot[@"HostFullscreenGeometry"] boolValue])
        [chrome restoreHostFullscreenGeometry];
    if(sOwnerSession){
        DFZEmergencyRestore(sOwnerSession);
        sOwnerSession=nil;
    }else if(session) {
        // Receiver watchdog also restores on stale heartbeat.
        DFZEmergencyRestore(session);
    }
}
