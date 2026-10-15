// Visual-only: preserve native controls, callbacks, gestures and loading animation.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <dispatch/dispatch.h>
#import <string.h>
#include "DuoFaceBorderRunner.m"
typedef void (*DFHookFn)(Class, SEL, IMP, IMP *);
static NSString * const kAssets = @"/var/jb/Library/Application Support/DuoFace/";
static char kOverlayKey;
static char kVisualOnlyKey;
static IMP oldButtonSetBackgroundColor, oldLayerSetBorderWidth, oldLayerSetBorderColor;
static BOOL visualSetterHooksInstalled;
static void DFSetButtonBackgroundColor(UIButton *button, SEL cmd, UIColor *color) {
    if (objc_getAssociatedObject(button, &kVisualOnlyKey)) color = [UIColor clearColor];
    ((void (*)(id, SEL, id))oldButtonSetBackgroundColor)(button, cmd, color);
}
static void DFSetLayerBorderWidth(CALayer *layer, SEL cmd, CGFloat width) {
    if (objc_getAssociatedObject(layer, &kVisualOnlyKey)) width = 0;
    ((void (*)(id, SEL, CGFloat))oldLayerSetBorderWidth)(layer, cmd, width);
}
static void DFSetLayerBorderColor(CALayer *layer, SEL cmd, CGColorRef color) {
    if (objc_getAssociatedObject(layer, &kVisualOnlyKey)) color = [UIColor clearColor].CGColor;
    ((void (*)(id, SEL, CGColorRef))oldLayerSetBorderColor)(layer, cmd, color);
}

static IMP oldPillLayout, oldDividerLayout, oldSplashLayout;
static BOOL pillInstalled, dividerInstalled, splashInstalled;
static BOOL pickerLogged, fullscreenLogged, swapLogged, splashLogged;

static UIImage *DFImage(NSString *name) {
    static NSMutableDictionary *cache;
    if (!cache) cache = [[NSMutableDictionary alloc] init];
    UIImage *image = [cache objectForKey:name];
    if (!image) {
        image = [UIImage imageWithContentsOfFile:[kAssets stringByAppendingString:name]];
        if (image) [cache setObject:image forKey:name];
    }
    return image;
}
// Ivar names/types verified in actual ObjC metadata; never hard-code offsets.
static id DFObjectIvar(id object, const char *name) {
    Ivar ivar = class_getInstanceVariable([object class], name);
    const char *type = ivar ? ivar_getTypeEncoding(ivar) : NULL;
    return type && type[0] == '@' ? object_getIvar(object, ivar) : nil;
}
static BOOL DFApplyButton(id value, NSString *asset, BOOL round) {
    if (![value isKindOfClass:[UIButton class]]) return NO;
    UIButton *button = (UIButton *)value;
    UIImage *image = DFImage(asset);
    if (!image) return NO;
    UIImageView *overlay = objc_getAssociatedObject(button, &kOverlayKey);
    if (!overlay) {
        overlay = [[UIImageView alloc] initWithFrame:button.bounds];
        overlay.userInteractionEnabled = NO;
        overlay.isAccessibilityElement = NO;
        overlay.contentMode = UIViewContentModeScaleAspectFit;
        overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [button addSubview:overlay];
        objc_setAssociatedObject(button, &kOverlayKey, overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [overlay release];
    }
    overlay.frame = button.bounds;
    overlay.image = image;
    overlay.clipsToBounds = round;
    overlay.layer.cornerRadius = round ? MIN(button.bounds.size.width, button.bounds.size.height)/2.0 : 0;
    // Keep the working DuoFace overlay, but suppress only native button artwork.
    // Do not remove UIButton, its handlers, gesture recognizers or unrelated layers.
    objc_setAssociatedObject(button, &kVisualOnlyKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button.layer, &kVisualOnlyKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    button.imageView.hidden = YES;
    for (NSUInteger state = 0; state < 16; state++) {
        UIControlState controlState = (UIControlState)state;
        if ([button backgroundImageForState:controlState])
            [button setBackgroundImage:nil forState:controlState];
    }
    button.backgroundColor = [UIColor clearColor];
    // Remove native badge chrome, but preserve UIButton and its blink transform.
    // This intentionally leaves the parent layer's transform/animations intact.
    button.layer.borderWidth = 0.0;
    button.layer.borderColor = [UIColor clearColor].CGColor;
    button.layer.shadowOpacity = 0.0f;
    button.layer.shadowRadius = 0.0f;
    button.layer.shadowColor = [UIColor clearColor].CGColor;
    button.layer.shadowOffset = CGSizeZero;
    [button bringSubviewToFront:overlay];
    return YES;
}
// The source-only feature uses native UIButton and Objective-C callbacks.
#include "DFDividerLogoGrip.inc"

static void DFPillLayout(UIView *self, SEL cmd) {
    ((void(*)(id,SEL))oldPillLayout)(self, cmd);
    if (DFApplyButton(DFObjectIvar(self, "_dotsButton"), @"VisualAssets/duoface-picker.png", NO)) {
        id dots = DFObjectIvar(self, "_dotViews");
        if ([dots isKindOfClass:[NSArray class]])
            for (id dot in dots)
                if ([dot isKindOfClass:[UIView class]]) [(UIView *)dot setHidden:YES];
        if (!pickerLogged) { NSLog(@"[DuoFaceVisual12] picker applied; dots hidden"); pickerLogged=YES; }
    }
    BOOL expand = DFApplyButton(DFObjectIvar(self, "_expandButton"), @"VisualAssets/duoface-fullscreen.png", NO);
    BOOL restore = DFApplyButton(DFObjectIvar(self, "_restoreButton"), @"VisualAssets/duoface-fullscreen.png", NO);
    if ((expand || restore) && !fullscreenLogged) {
        NSLog(@"[DuoFaceVisual12] fullscreen/restore applied; actions unchanged"); fullscreenLogged=YES;
    }
}
static void DFDividerLayout(UIView *self, SEL cmd) {
    ((void(*)(id,SEL))oldDividerLayout)(self, cmd);
    // Retain the moved BUTTON's hitbox as well as its overlay across layouts.
    if (DFGripHooksInstalled && DFLogoRestorePositionBeforeLayout(self))
        ((void (*)(id, SEL))objc_msgSend)(self, @selector(updateGripLayout));
    id buttons = DFObjectIvar(self, "_moveButtons");
    if (![buttons isKindOfClass:[NSArray class]]) return;
    for (id button in buttons) {
        if (DFGripHooksInstalled) DFLogoSetNativeHoldThreshold((UIButton *)button);
        if (DFApplyButton(button, @"VisualAssets/duoface-swap.png", YES) && !swapLogged) {
            NSLog(@"[DuoFaceVisual12] divider native tap preserved; hold=0.30s logo position only; split-pan outside unchanged");
            swapLogged=YES;
        }
    }
}
static void DFSplashLayout(UIView *self, SEL cmd) {
    ((void(*)(id,SEL))oldSplashLayout)(self, cmd);
    id value = DFObjectIvar(self, "_logoImageView");
    if (![value isKindOfClass:[UIImageView class]]) return;
    UIImageView *logo = (UIImageView *)value;
    NSString *asset = logo.bounds.size.height > logo.bounds.size.width
        ? @"duoface-logo-vert.png" : @"duoface-logo.png";
    UIImage *image = DFImage(asset);
    if (!image) return;
    logo.image = image;
    logo.contentMode = UIViewContentModeScaleAspectFit;
    self.backgroundColor = [UIColor blackColor];
    NSMutableArray *stack = [NSMutableArray arrayWithObject:self];
    while (stack.count) {
        UIView *v = [[stack lastObject] retain];
        [stack removeLastObject];
        if ([v isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)v;
            if ([label.text isEqualToString:@"TWO SCREENS. ZERO LIMITS."] ||
                [label.text isEqualToString:@"WORKS WITH APPLE CARPLAY"] ||
                [label.text isEqualToString:@"TWO FACES ONE SCREEN"])
                label.hidden = YES; // Exact slogan is already part of approved logo.
        }
        [stack addObjectsFromArray:v.subviews];
        [v release];
    }
    if (!splashLogged) {
        NSLog(@"[DuoFaceVisual12] splash %@ applied; original loading untouched", asset); splashLogged=YES;
    }
}
static void DFInstall(void) {
    if (pillInstalled && dividerInstalled && splashInstalled &&
        DFBorderHooksInstalled && DFGripHooksInstalled) return;
    DFHookFn hook = (DFHookFn)dlsym(RTLD_DEFAULT, "MSHookMessageEx");
    static BOOL triedLibrary;
    if (!hook && !triedLibrary) {
        triedLibrary = YES;
        void *handle = dlopen("/var/jb/usr/lib/libsubstrate.dylib", RTLD_NOW | RTLD_GLOBAL);
        if (!handle) handle = dlopen("/usr/lib/libsubstrate.dylib", RTLD_NOW | RTLD_GLOBAL);
        if (handle) hook = (DFHookFn)dlsym(handle, "MSHookMessageEx");
    }
    if (!hook) return;
    if (!visualSetterHooksInstalled) {
        hook(objc_getClass("UIButton"), @selector(setBackgroundColor:), (IMP)DFSetButtonBackgroundColor, &oldButtonSetBackgroundColor);
        hook(objc_getClass("CALayer"), @selector(setBorderWidth:), (IMP)DFSetLayerBorderWidth, &oldLayerSetBorderWidth);
        hook(objc_getClass("CALayer"), @selector(setBorderColor:), (IMP)DFSetLayerBorderColor, &oldLayerSetBorderColor);
        visualSetterHooksInstalled = YES;
    }
    Class pill = objc_getClass("CBSlotPillView");
    Class divider = objc_getClass("CBDividerView");
    Class splash = objc_getClass("CBSplitSplashScreenView");
    Class split = objc_getClass("CBBridgedSplitApp");
    DFInstallBorderRunner(split,hook);
    if (pill && !pillInstalled) {
        hook(pill, @selector(layoutSubviews), (IMP)DFPillLayout, &oldPillLayout);
        pillInstalled=YES; NSLog(@"[DuoFaceVisual12] CBSlotPillView hook installed");
    }
    if (divider && !DFGripHooksInstalled) {
        if (!DFInstallLogoGripHooks(hook, divider))
            NSLog(@"[DuoFaceGrip] native grip methods unavailable; original gestures preserved");
    }
    if (divider && !dividerInstalled) {
        hook(divider, @selector(layoutSubviews), (IMP)DFDividerLayout, &oldDividerLayout);
        dividerInstalled=YES; NSLog(@"[DuoFaceVisual12] CBDividerView hook installed");
    }
    if (splash && !splashInstalled) {
        hook(splash, @selector(layoutSubviews), (IMP)DFSplashLayout, &oldSplashLayout);
        splashInstalled=YES; NSLog(@"[DuoFaceVisual12] CBSplitSplashScreenView hook installed");
    }
}
static void DFImageAdded(const struct mach_header *header, intptr_t slide) {
    (void)header; (void)slide;
    // Wait until ObjC class registration finishes; install on main queue.
    dispatch_async(dispatch_get_main_queue(), ^{ DFInstall(); });
}
__attribute__((constructor)) static void DFInit(void) {
    _dyld_register_func_for_add_image(DFImageAdded);
    dispatch_async(dispatch_get_main_queue(), ^{ DFInstall(); });
}
