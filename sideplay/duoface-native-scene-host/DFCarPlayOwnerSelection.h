// First-party native CarPlay scene selection contract.
// Unrelated CarPlay app scenes (including an official navigation app like GOFA)
// must not invalidate the uniquely visible DuoFace host. Multiple DuoFace
// controllers are ambiguous and fail closed. This never publishes app icons.
#ifndef DF_CARPLAY_OWNER_SELECTION_H
#define DF_CARPLAY_OWNER_SELECTION_H
#import <Foundation/Foundation.h>

static inline NSDictionary *DFOwnerUniqueDuoFaceCandidate(NSArray *visibleControllers) {
    NSDictionary *owner=nil;
    for(id object in visibleControllers) {
        if(![object isKindOfClass:NSDictionary.class])continue;
        NSDictionary *entry=(NSDictionary *)object;
        if(![entry[@"Bundle"] isEqual:@"com.duoface.native.scenehost"])continue;
        id sceneID=entry[@"SceneID"];
        if(![sceneID isKindOfClass:NSString.class] || [sceneID length]==0 ||
           !entry[@"Controller"])return nil;
        if(owner)return nil; // never guess between two visible DuoFace scenes
        owner=entry;
    }
    return owner;
}
#endif
