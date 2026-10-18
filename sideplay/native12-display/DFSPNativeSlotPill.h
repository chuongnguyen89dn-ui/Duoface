#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
/* Independent implementation of the verified Native12 CBSlotPillView contract.
   This is DuoFace-owned UI; SidePlay only provides the hosted app/scene. */
@interface DFSPNativeSlotPill : UIVisualEffectView
@property(nonatomic,readonly) NSInteger slot;
@property(nonatomic,readonly) BOOL slotFocused;
@property(nonatomic,readonly) BOOL compact;
@property(nonatomic,readonly) BOOL allowsExpand;
- (instancetype)initWithSlot:(NSInteger)slot target:(id)target
                  menuAction:(SEL)menuAction expandAction:(SEL)expandAction
               restoreAction:(SEL)restoreAction;
- (void)configureFocused:(BOOL)focused compact:(BOOL)compact
             allowsExpand:(BOOL)allowsExpand;
- (CGSize)nativeSize;
@end
NS_ASSUME_NONNULL_END
