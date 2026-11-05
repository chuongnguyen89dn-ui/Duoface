// Read-only restoration destination checks using public UIKit getter semantics.
// Foundation protocols keep the exact pointer/ancestry policy executable in CI;
// the harness does not emulate or prove a live UIKit containment transaction.
#ifndef DF_NATIVE_MAP_RESTORE_POLICY_H
#define DF_NATIVE_MAP_RESTORE_POLICY_H
#import <Foundation/Foundation.h>

@protocol DFNativeMapRestoreView <NSObject>
- (id)window;
- (id<DFNativeMapRestoreView>)superview;
@end

@protocol DFNativeMapRestoreController <NSObject>
- (id<DFNativeMapRestoreView>)viewIfLoaded;
- (id<DFNativeMapRestoreController>)parentViewController;
@end

NS_INLINE BOOL DFNativeMapRestoreDestinationMatches(
    id<DFNativeMapRestoreController> owner,
    id<DFNativeMapRestoreController> parent,
    id<DFNativeMapRestoreView> capturedParentView,
    id<DFNativeMapRestoreView> oldSuperview, id window) {
    if(!owner || !parent || !capturedParentView || !oldSuperview || !window ||
       parent.viewIfLoaded!=capturedParentView ||
       capturedParentView.window!=window || oldSuperview.window!=window)return NO;

    // A retained superview can remain in the window after UIKit moves it to
    // another controller. Require the original view relationship as well.
    NSHashTable *seen=[NSHashTable hashTableWithOptions:
        NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality];
    id<DFNativeMapRestoreView> ownerView=owner.viewIfLoaded;
    BOOL descendant=NO;
    for(id<DFNativeMapRestoreView> view=oldSuperview;view;view=view.superview) {
        // Restoring into our own view or any of its descendants would insert
        // an ancestor into itself. Check above the captured root as well.
        if(view==ownerView)return NO;
        if(view==capturedParentView)descendant=YES;
        if([seen containsObject:view])return NO;
        [seen addObject:view];
    }
    if(!descendant)return NO;

    // The old parent may itself have been reparented while the map was away.
    // Never create a controller cycle, including through an indirect parent.
    [seen removeAllObjects];
    for(id<DFNativeMapRestoreController> cursor=parent;cursor;
        cursor=cursor.parentViewController) {
        if(cursor==owner || [seen containsObject:cursor])return NO;
        [seen addObject:cursor];
    }
    return YES;
}
#endif
