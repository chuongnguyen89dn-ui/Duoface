// Real CarPlay process DBWorkspace owner capture, read-only.
// No vendor runtime, no fake Dock, no dashboard state mutation.
#import "MTDashboardWorkspace.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <mach-o/loader.h>
static __weak id gDashboardWorkspace = nil;
static BOOL gInstalled = NO;
static BOOL gObserverArmed = NO;
static NSString *const kLog=@"/var/mobile/Library/Logs/MyTweakWorkspace.log";
static NSString *const kOwner=@"DBDashboardWorkspaceOwner";
static id (*MTOriginalWorkspaceInit)(id,SEL,id)=NULL;
static void MTWSLog(NSString *message) {
    NSString *line=[NSString stringWithFormat:@"[MyTweakWorkspace] %@\n",message];
    NSLog(@"%@",line);
    [[NSFileManager defaultManager] createDirectoryAtPath:
       [kLog stringByDeletingLastPathComponent] withIntermediateDirectories:YES
       attributes:nil error:nil];
    NSFileHandle *f=[NSFileHandle fileHandleForWritingAtPath:kLog];
    if (!f) {
        [[NSFileManager defaultManager] createFileAtPath:kLog contents:nil attributes:nil];
        f=[NSFileHandle fileHandleForWritingAtPath:kLog];
    }
    @try {
        [f seekToEndOfFile];
        [f writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        [f closeFile];
    } @catch (NSException *exception) {
        NSLog(@"[MyTweakWorkspace] log-write exception=%@",NSStringFromClass(exception.class));
    }
}
static BOOL MTIsCarPlayDashboardProcess(void) {
    return [NSProcessInfo.processInfo.processName isEqualToString:@"CarPlay"];
}
static void MTObserveWorkspace(id candidate,id owner) {
    Class cls=NSClassFromString(kOwner);
    if (!candidate || !cls)return;
    if (![owner isKindOfClass:cls])return;
    gDashboardWorkspace=candidate;  // weak; disconnect invalidates DBWorkspace
    MTWSLog([NSString stringWithFormat:@"event=dashboard-owner-captured ownerClass=%@ workspaceClass=%@",
             NSStringFromClass([owner class]),NSStringFromClass([candidate class])]);
}
static id MTWorkspaceInitCapture(id self,SEL _cmd,id owner) {
    // Preserve Apple's original initializer and its return (may differ from self).
    id result=MTOriginalWorkspaceInit ? MTOriginalWorkspaceInit(self,_cmd,owner) : nil;
    MTObserveWorkspace(result,owner);
    return result;
}
static BOOL MTInstallWorkspaceObserver(void) {
    if (gInstalled) return YES;
    Class cls=NSClassFromString(@"DBWorkspace");
    Class owner=NSClassFromString(kOwner);
    if (!cls || !owner)return NO;
    SEL selector=NSSelectorFromString(@"initWithOwner:");
    Method method=class_getInstanceMethod(cls,selector);
    if (!method || method_getNumberOfArguments(method)!=3)return NO;
    char ret[8]={0},arg[8]={0};
    method_getReturnType(method,ret,sizeof(ret));
    method_getArgumentType(method,2,arg,sizeof(arg));
    if (ret[0]!='@' || arg[0]!='@')return NO;
    IMP original=method_getImplementation(method);
    if (!original || original==(IMP)MTWorkspaceInitCapture)return NO;
    MTOriginalWorkspaceInit=(id(*)(id,SEL,id))original;
    // If inherited, install only on DBWorkspace, never on UIWindow/NSObject.
    if (!class_addMethod(cls,selector,(IMP)MTWorkspaceInitCapture,method_getTypeEncoding(method))) {
        Method own=class_getInstanceMethod(cls,selector);
        MTOriginalWorkspaceInit=(id(*)(id,SEL,id))method_setImplementation(
                           own,(IMP)MTWorkspaceInitCapture);
    }
    gInstalled=YES;
    MTWSLog(@"event=owner-hook-installed selector=initWithOwner: owner=DBDashboardWorkspaceOwner");
    return YES;
}
static void MTWorkspaceImageMapped(const struct mach_header *header) {
    (void)header;
    MTInstallWorkspaceObserver();
}
@implementation MTDashboardWorkspace
+ (id)liveDashboardWorkspace {
    return MTIsCarPlayDashboardProcess() ? gDashboardWorkspace : nil;
}
+ (void)installEarlyObserver {
    if (!MTIsCarPlayDashboardProcess())return;
    if (gObserverArmed)return;
    gObserverArmed=YES;
    MTWSLog(@"event=early-setup process=CarPlay mode=read-only");
    if (!MTInstallWorkspaceObserver()) {
        objc_addLoadImageFunc(MTWorkspaceImageMapped);
        MTWSLog(@"event=waiting-for-Dashboard-classes");
    }
}
+ (NSDictionary<NSString *,id> *)snapshot {
    if (!MTIsCarPlayDashboardProcess())
        return @{@"WorkspaceObserverProcess":NSProcessInfo.processInfo.processName,
                 @"WorkspaceCaptured":@NO};
    id workspace=gDashboardWorkspace;
    Class ownerClass=NSClassFromString(kOwner);
    NSMutableDictionary *data=[NSMutableDictionary dictionaryWithDictionary:@{
        @"WorkspaceOwnerClassPresent":@(ownerClass!=Nil),
        @"WorkspaceClassPresent":@(NSClassFromString(@"DBWorkspace")!=Nil),
        @"WorkspaceHookInstalled":@(gInstalled),
        @"WorkspaceCaptured":@(workspace!=nil),
    }];
    // Read-only optional introspection; never change CarPlay's workspace state.
    if (workspace) {
        data[@"WorkspaceRuntimeClass"]=NSStringFromClass([workspace class]);
        SEL stateSelector=NSSelectorFromString(@"state");
        if ([workspace respondsToSelector:stateSelector]) {
            @try {
                id state=((id(*)(id,SEL))objc_msgSend)(workspace,stateSelector);
                if (state) {
                    data[@"WorkspaceStateClass"]=NSStringFromClass([state class]);
                    SEL active=NSSelectorFromString(@"activeBundleIdentifier");
                    if ([state respondsToSelector:active]) {
                        id bundle=((id(*)(id,SEL))objc_msgSend)(state,active);
                        // Do not log bundle identifiers; only report whether
                        // Dashboard currently declares an active application.
                        data[@"WorkspaceHasActiveApp"]=@([bundle isKindOfClass:NSString.class] &&
                                                           [bundle length]>0);
                    }
                }
            } @catch (NSException *ex) {
                data[@"WorkspaceStateReadException"]=NSStringFromClass([ex class]);
            }
        }
    }
    return [data copy];
}
@end
