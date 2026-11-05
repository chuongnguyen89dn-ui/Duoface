// Execute the production pointer/ancestry policy with mutable object graphs.
// These are Foundation objects, not UIKit or an on-device restoration test.
#import <Foundation/Foundation.h>
#import "../DFNativeMapRestorePolicy.h"

@interface DFRestoreViewStub : NSObject <DFNativeMapRestoreView>
@property(nonatomic,strong) id window;
@property(nonatomic,strong) id<DFNativeMapRestoreView> superview;
@end
@implementation DFRestoreViewStub
@end

@interface DFRestoreControllerStub : NSObject <DFNativeMapRestoreController>
@property(nonatomic,strong) id<DFNativeMapRestoreView> viewIfLoaded;
@property(nonatomic,strong) id<DFNativeMapRestoreController> parentViewController;
@end
@implementation DFRestoreControllerStub
@end

static NSUInteger assertionCount=0;
static void check(BOOL condition,NSString *why) {
    assertionCount++;
    if(!condition){NSLog(@"NATIVE_MAP_RESTORE_FAIL %@",why);abort();}
}

int main(void){@autoreleasepool{
    NSObject *window=[NSObject new],*otherWindow=[NSObject new];
    DFRestoreViewStub *root=[DFRestoreViewStub new];root.window=window;
    DFRestoreViewStub *container=[DFRestoreViewStub new];container.window=window;
    container.superview=root;
    DFRestoreViewStub *otherRoot=[DFRestoreViewStub new];otherRoot.window=window;
    DFRestoreControllerStub *owner=[DFRestoreControllerStub new];
    DFRestoreViewStub *ownerView=[DFRestoreViewStub new];ownerView.window=window;
    DFRestoreViewStub *assignedPane=[DFRestoreViewStub new];assignedPane.window=window;
    assignedPane.superview=root;ownerView.superview=assignedPane;
    owner.viewIfLoaded=ownerView;
    DFRestoreControllerStub *parent=[DFRestoreControllerStub new];
    DFRestoreControllerStub *ancestor=[DFRestoreControllerStub new];
    parent.viewIfLoaded=root;

    check(DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"unchanged captured parent, superview and window accepted");
    check(DFNativeMapRestoreDestinationMatches(owner,parent,root,root,window),
          @"original direct parent view is a valid destination");
    parent.parentViewController=ancestor;
    check(DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"unrelated parent ancestor does not prevent restoration");
    parent.parentViewController=nil;

    parent.viewIfLoaded=nil;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"unloaded original parent rejected without loading a view");
    parent.viewIfLoaded=otherRoot;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"replaced parent view rejected even in the original window");
    parent.viewIfLoaded=root;

    root.window=otherWindow;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"original parent moved to another window rejected");
    root.window=window;
    container.window=nil;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"detached old superview rejected");
    container.window=otherWindow;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"old superview moved to another window rejected");
    container.window=window;
    container.superview=otherRoot;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"old superview reused by another hierarchy in same window rejected");
    check(parent.viewIfLoaded==root && container.superview==otherRoot,
          @"a rejected destination leaves the object graph unchanged");
    container.superview=container;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"malformed view cycle rejected without an unbounded walk");
    container.superview=root;

    // UIKit may keep the old container in the same captured root while
    // moving it below the adopted map view: root -> pane -> owner -> old.
    container.superview=ownerView;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"old superview below the adopted owner view rejected");
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,ownerView,window),
          @"owner view itself cannot become its restoration superview");
    check(container.superview==ownerView && ownerView.superview==assignedPane &&
          assignedPane.superview==root && owner.viewIfLoaded==ownerView,
          @"rejected owner-view cycles leave the complete view graph unchanged");
    container.superview=root;
    ownerView.superview=nil;root.superview=ownerView;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"owner ancestor above the captured root also rejected");
    root.superview=nil;ownerView.superview=assignedPane;

    parent.parentViewController=owner;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"restoration below owner would create a controller cycle");
    parent.parentViewController=ancestor;ancestor.parentViewController=owner;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"indirect containment cycle rejected");
    ancestor.parentViewController=parent;
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"existing ancestor cycle rejected without an unbounded walk");
    parent.parentViewController=nil;ancestor.parentViewController=nil;
    check(!DFNativeMapRestoreDestinationMatches(parent,parent,root,container,window),
          @"controller cannot be restored into itself");

    check(!DFNativeMapRestoreDestinationMatches(nil,parent,root,container,window),
          @"missing native owner rejected");
    check(!DFNativeMapRestoreDestinationMatches(owner,nil,root,container,window),
          @"missing parent rejected");
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,nil,container,window),
          @"missing captured parent view rejected");
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,nil,window),
          @"missing old superview rejected");
    check(!DFNativeMapRestoreDestinationMatches(owner,parent,root,container,nil),
          @"missing original window rejected");
    check(DFNativeMapRestoreDestinationMatches(owner,parent,root,container,window),
          @"valid unchanged hierarchy remains usable after rejected attempts");
    NSLog(@"DF_NATIVE_MAP_RESTORE_POLICY_RUNTIME_PASS assertions=%lu",
          (unsigned long)assertionCount);
}return 0;}
