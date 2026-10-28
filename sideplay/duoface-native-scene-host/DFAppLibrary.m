// Independently maintained first-party DuoFace module, ported from the
// project's own prior scene-host experiments; no vendor binary or license.
#import "DFAppLibrary.h"
#import "DFAppEligibility.h"
#import "DFAppCatalogPolicy.h"

@implementation DFAppInfo
@end

@implementation DFAppLibrary

+ (NSArray<DFAppInfo *> *)installedUserApps {
    NSMutableArray<DFAppInfo *> *result = [NSMutableArray array];

    Class wsClass = NSClassFromString(@"LSApplicationWorkspace");
    if (!wsClass) {
        NSLog(@"[DuoFace] LSApplicationWorkspace not available");
        return result;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id workspace = nil;
    SEL defaultSel = NSSelectorFromString(@"defaultWorkspace");
    if ([wsClass respondsToSelector:defaultSel]) {
        workspace = [wsClass performSelector:defaultSel];
    }
    NSArray *proxies = nil;
    SEL allSel = NSSelectorFromString(@"allInstalledApplications");
    if (workspace && [workspace respondsToSelector:allSel]) {
        proxies = [workspace performSelector:allSel];
    }
#pragma clang diagnostic pop

    for (NSDictionary *record in DFCatalogRecordsFromProxies(proxies)) {
        NSString *bundleID=record[@"bundle"];
        NSString *name=record[@"name"];
        DFAppInfo *info = [[DFAppInfo alloc] init];
        info.bundleID = bundleID;
        info.displayName = name;
        [result addObject:info];
    }

    [result sortUsingComparator:^NSComparisonResult(DFAppInfo *a, DFAppInfo *b) {
        return [a.displayName localizedCaseInsensitiveCompare:b.displayName];
    }];
    return result;
}

@end
