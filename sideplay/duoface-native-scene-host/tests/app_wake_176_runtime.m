// Executable synthetic QA176 A1 dispatch contract. It does NOT prove HID or
// that FBScene.identifier equals UIKit UISceneSession.persistentIdentifier on car.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <unistd.h>
#include <stdio.h>
static NSDictionary *snapshot,*pulse;
static NSUInteger wakes;
static NSTimeInterval fakeNow;
static BOOL transportOK=YES,localKeyboardVisible=NO;
static UIWindow *keyboardWindow;
static BOOL DF177AppTouchEnabled(void){return YES;}
static BOOL DF177AppTouchNoteBegan(NSString *bundle,BOOL reserved){
    (void)bundle;
    if(!transportOK || !reserved)return NO;
    wakes++;return YES;
}
static BOOL DF177IsKeyboardWindow(id window){return window==keyboardWindow;}
static BOOL DF177KbComputeVisible(void){return localKeyboardVisible;}
static NSDictionary *readRecord(NSString *path){
    return [path containsString:@"wake-state"]?snapshot:pulse;
}
#define DF176_WAKE_READ_RECORD(path) readRecord(path)
#define DF176_WAKE_NOW() fakeNow
#define DF177_APP_SIDE_SENDER 1
#import "../DFAppWakeGate176.h"
static void check(BOOL ok,const char *reason){
    if(!ok){fprintf(stderr,"QA176_A1_FAIL %s\n",reason);abort();}
}
static UIWindow *windowWithScene(NSString *identifier){
    UIWindow *window=[[UIWindow alloc] initWithFrame:CGRectMake(0,0,640,360)];
    UISceneSession *session=[UISceneSession new];
    session.persistentIdentifier=identifier;
    UIWindowScene *scene=[UIWindowScene new];scene.session=session;
    window.windowScene=scene;return window;
}
static UITouch *touchInWindow(UIWindow *window){
    UITouch *touch=[UITouch new];touch.window=window;return touch;
}
static UIEvent *event(UITouch *touch,UITouchPhase phase){
    touch.phase=phase;
    UIEvent *event=[UIEvent new];event.type=UIEventTypeTouches;
    event.allTouches=[NSSet setWithObject:touch];return event;
}
static void state(BOOL hidden,BOOL validPID,BOOL known,BOOL visible,
                  NSString *sessionID,NSString *sceneID){
    pulse=@{@"Version":@1,@"Active":@YES,
        @"Session":@"01234567-89AB-CDEF-0123-456789ABCDEF",
        @"Timestamp":@(NSDate.date.timeIntervalSince1970)};
    snapshot=@{@"Version":@2,@"Session":sessionID?:pulse[@"Session"],
        @"Eligible":@YES,@"Processes":@{@"test.app":@(validPID?getpid():getpid()+1)},
        @"Scenes":@{@"test.app":sceneID?:@"bridge.SCENE"},
        @"KeyboardKnown":@(known),@"KeyboardVisible":@(visible),
        @"Until":@(fakeNow+(hidden?-1:10)),@"Timestamp":@(fakeNow)};
}
static void forwarded(NSString *reason,UITouch *touch){
    check(!DF176ConsumeWakeEvent(event(touch,UITouchPhaseBegan),@"test.app"),
          reason.UTF8String);
    check(!DF176ConsumeWakeEvent(event(touch,UITouchPhaseEnded),@"test.app"),
          "forwarded end");
}
int main(void){@autoreleasepool{
    fakeNow=NSDate.date.timeIntervalSince1970;
    UIWindow *host=windowWithScene(@"bridge.SCENE");
    UIWindow *phone=windowWithScene(@"phone.SCENE");
    keyboardWindow=windowWithScene(@"bridge.SCENE");
    UITouch *t=touchInWindow(host);
    state(YES,NO,YES,NO,nil,nil);forwarded(@"foreign pid",t);
    state(YES,YES,YES,NO,nil,nil);
    NSMutableDictionary *bad=[snapshot mutableCopy];
    bad[@"Timestamp"]=@(fakeNow-2);snapshot=bad;
    forwarded(@"stale snapshot",t);
    state(YES,YES,YES,NO,NSUUID.UUID.UUIDString,nil);
    forwarded(@"foreign session",t);
    state(YES,YES,NO,NO,nil,nil);forwarded(@"unknown keyboard",t);
    state(YES,YES,YES,YES,nil,nil);forwarded(@"host keyboard visible",t);
    state(YES,YES,YES,NO,nil,@"wrong.SCENE");
    forwarded(@"stale scene",t);
    state(YES,YES,YES,NO,nil,nil);
    forwarded(@"phone scene",touchInWindow(phone));
    forwarded(@"keyboard window",touchInWindow(keyboardWindow));
    localKeyboardVisible=YES;
    forwarded(@"local keyboard visible",t);
    localKeyboardVisible=NO;
    transportOK=NO;
    forwarded(@"mailbox/notify failure must fail open",t);
    transportOK=YES;
    state(NO,YES,YES,NO,nil,nil);
    forwarded(@"controls visible",t);
    state(YES,YES,YES,NO,nil,nil);
    // A forwarded gesture began while visible; hiding Chrome must not
    // steal subsequent moved/tail events.
    check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseBegan),@"test.app"),
          "visible gesture forwarded");
    state(YES,YES,YES,NO,nil,nil);
    check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseMoved),@"test.app"),
          "visible gesture tail");
    check(!DF176ConsumeWakeEvent(event(t,UITouchPhaseEnded),@"test.app"),
          "visible gesture end");
    // Three independent hidden -> first consumed -> second forwarded cycles.
    for(int i=0;i<3;i++){
        fakeNow+=5;
        state(YES,YES,YES,NO,nil,nil);
        UITouch *first=touchInWindow(host);
        check(DF176ConsumeWakeEvent(event(first,UITouchPhaseBegan),@"test.app"),
              "first hidden contact consumed");
        check(wakes==(NSUInteger)(i+1),"one wake per hidden cycle");
        UITouch *second=touchInWindow(host);
        first.phase=UITouchPhaseStationary;second.phase=UITouchPhaseBegan;
        UIEvent *multi=[UIEvent new];multi.type=UIEventTypeTouches;
        multi.allTouches=[NSSet setWithObjects:first,second,nil];
        check(DF176ConsumeWakeEvent(multi,@"test.app"),"same-scene multitouch consumed");
        check(wakes==(NSUInteger)(i+1),"second finger not new wake");
        check(DF176ConsumeWakeEvent(event(second,UITouchPhaseEnded),@"test.app"),
              "second finger tail consumed");
        state(NO,YES,YES,NO,nil,nil);
        check(DF176ConsumeWakeEvent(event(first,UITouchPhaseCancelled),@"test.app"),
              "reserved gesture cancel consumed even after wake");
        forwarded(@"next visible contact forwarded",touchInWindow(host));
    }
    fakeNow+=5;
    state(YES,YES,YES,NO,nil,nil);
    UITouch *owned=touchInWindow(host);
    check(DF176ConsumeWakeEvent(event(owned,UITouchPhaseBegan),@"test.app"),
          "owned contact captured");
    UITouch *foreign=touchInWindow(phone);
    owned.phase=UITouchPhaseStationary;foreign.phase=UITouchPhaseBegan;
    UIEvent *mixed=[UIEvent new];mixed.type=UIEventTypeTouches;
    mixed.allTouches=[NSSet setWithObjects:owned,foreign,nil];
    check(!DF176ConsumeWakeEvent(mixed,@"test.app"),
          "foreign joining an active capture must fail open");
    check(!DF176ConsumeWakeEvent(event(foreign,UITouchPhaseEnded),@"test.app"),
          "foreign tail forwarded");
    check(!DF176ConsumeWakeEvent(event(owned,UITouchPhaseEnded),@"test.app"),
          "reclassified owned tail forwarded");
    check(wakes==4,"exact wake count");
    NSLog(@"QA176_A1_APP_WAKE_MODEL_PASS cycles=3 failures=1 mixed=1");
    return 0;
}}
