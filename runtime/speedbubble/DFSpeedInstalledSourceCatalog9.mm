// Native SpringBoard read-only installed-source inventory; no Waze/GOFA/VietMap code loaded.
#import "DFSpeedInstalledSourceCatalog9.h"
#import <objc/runtime.h>
#include <string.h>

NSString *DFSpeedBundleForSource(NSInteger source) {
    switch(source) {
        case 2:return @"com.waze.iphone";
        case 3:return @"vn.vietmap.live";
        case 4:return @"com.lumi.GOFA";
        default:return nil;
    }
}
NSString *DFSpeedNameForSource(NSInteger source) {
    switch(source) {
        case 2:return @"Waze";
        case 3:return @"VietMap Live";
        case 4:return @"GOFA";
        default:return @"Chưa chọn";
    }
}
BOOL DFSpeedSourceInstalled(NSInteger source) {
    NSString *bundle=DFSpeedBundleForSource(source);
    if(!bundle)return NO;
    @try {
        // Uses private LaunchServices via runtime checks (no unverified headers).
        // SpringBoard typically loads these classes, but fail CLOSED if absent.
        Class proxy=NSClassFromString(@"LSApplicationProxy");
        SEL selector=NSSelectorFromString(@"applicationProxyForIdentifier:");
        if(proxy && [proxy respondsToSelector:selector]) {
            Method method=class_getClassMethod(proxy,selector);
            const char *enc=method?method_getTypeEncoding(method):NULL;
            // Object return with 1 object argument, never cast an unknown ABI.
            if(enc && enc[0]=='@') {
                NSMethodSignature *sig=[NSMethodSignature signatureWithObjCTypes:enc];
                if(sig.numberOfArguments==3 &&
                   strcmp([sig getArgumentTypeAtIndex:2],"@")==0) {
                    id (*call)(id,SEL,id)=(id (*)(id,SEL))[proxy methodForSelector:selector];
                    id item=call(proxy,selector,bundle);
                    // Unknown/missing proxy must NOT be mistaken for installed.
                    if(item && ![item isKindOfClass:NSNull.class]) {
                        SEL idSel=NSSelectorFromString(@"bundleIdentifier");
                        if([item respondsToSelector:idSel]) {
                            NSString *(*get)(id,SEL)=(NSString *(*)(id,SEL))[item methodForSelector:idSel];
                            NSString *name=get(item,idSel);
                            return [name isKindOfClass:NSString.class] && [name isEqualToString:bundle];
                        }
                    }
                }
            }
        }
    } @catch (__unused NSException *error) {}
    return NO;
}
NSArray<NSNumber *> *DFSpeedInstalledSupportedSources(void) {
    NSMutableArray<NSNumber *> *result=[NSMutableArray arrayWithCapacity:3];
    for(NSNumber *source in @[@2,@3,@4])
        if(DFSpeedSourceInstalled(source.integerValue)) [result addObject:source];
    return [result copy];
}
