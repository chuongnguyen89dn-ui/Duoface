// DuoFace-owned, system-preserving CarPlay Home roster input policy.
// This computes identities only; it DOES NOT register CarPlay icons or launch apps.
// Native CarPlay membership is Apple's authority and is never rewritten here.
#ifndef DF_CARPLAY_HOME_CATALOG_POLICY_H
#define DF_CARPLAY_HOME_CATALOG_POLICY_H
#import <Foundation/Foundation.h>
#import "DFEnabledAppsPolicy.h"

// For a native CarPlay roster, preserve the system's incoming identities as-is.
// Only *installed AND explicitly enabled* nonnative apps may be added.
// No legacy "missing preferences means allow everything" fallback.
NS_INLINE NSArray<NSString *> *DFHomeBridgeBundleIDs(
    NSArray<NSString *> *installed,
    NSArray<NSString *> *enabled,
    NSArray<NSString *> *nativeHomeBundleIDs) {
    if (![installed isKindOfClass:NSArray.class] ||
        ![enabled isKindOfClass:NSArray.class] ||
        ![nativeHomeBundleIDs isKindOfClass:NSArray.class]) return @[];
    NSMutableSet<NSString *> *native = [NSMutableSet set];
    for (id entry in nativeHomeBundleIDs)
        if ([entry isKindOfClass:NSString.class] && [entry length])
            [native addObject:entry];
    NSMutableSet<NSString *> *installedIDs = [NSMutableSet set];
    for (id entry in installed)
        if ([entry isKindOfClass:NSString.class] && [entry length])
            [installedIDs addObject:entry];
    NSMutableOrderedSet<NSString *> *bridged = [NSMutableOrderedSet orderedSet];
    for (id entry in enabled) {
        if (![entry isKindOfClass:NSString.class] ||
            !DFPickerAllowsApp(entry,enabled) ||
            ![installedIDs containsObject:entry] ||
            [native containsObject:entry]) continue;
        [bridged addObject:entry];
    }
    return bridged.array;
}

// Identity-level expected Home catalog; the actual native Home implementation
// must keep Apple's existing objects and their metadata, NEVER reconstruct
// native CARApplicationInfo/DBApplicationInfo from this string list.
NS_INLINE NSArray<NSString *> *DFHomeExpectedBundleIDs(
    NSArray<NSString *> *nativeHomeBundleIDs,
    NSArray<NSString *> *installed,
    NSArray<NSString *> *enabled) {
    if (![nativeHomeBundleIDs isKindOfClass:NSArray.class]) return @[];
    NSMutableOrderedSet<NSString *> *result = [NSMutableOrderedSet orderedSet];
    for (id entry in nativeHomeBundleIDs)
        if ([entry isKindOfClass:NSString.class] && [entry length])
            [result addObject:entry];
    for (NSString *entry in DFHomeBridgeBundleIDs(installed,enabled,
                                                  nativeHomeBundleIDs))
        [result addObject:entry];
    return result.array;
}
#endif
