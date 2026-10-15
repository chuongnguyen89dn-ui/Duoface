// DuoFace native9 candidate — surgical standalone 0.30s movable logo.
// DOES NOT change native6's compiled DuoFaceVisualHook.dylib. No style,
// fullscreen/picker, divider ratio, border, or app-host hooks live in this file.
// The filter for this module should mirror native6's original VisualHook.plist.
//
// This is source-only analysis/compile preparation, NOT a published DEB.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <dispatch/dispatch.h>
#import <string.h>

// Reuse the actual gesture logic proven to move the native button on-device.
// Preserve the entire native CBDividerView.handlePan: callback unconditionally.
#define DF_LOGO_PRESERVE_NATIVE_DIVIDER_PAN 1
typedef void (*DFHookFn)(Class, SEL, IMP, IMP *);

static id DFObjectIvar(id object, const char *name) {
    if (!object || !name) return nil;
    Ivar ivar = class_getInstanceVariable([object class], name);
    const char *type = ivar ? ivar_getTypeEncoding(ivar) : NULL;
    return type && type[0] == '@' ? object_getIvar(object, ivar) : nil;
}
#include "DFDividerLogoGrip.inc"

static IMP oldDFGripOnlyLayout;
static BOOL DFGripOnlyLayoutHookInstalled;
static void *DFGripOnlySubstrateHandle;

static void DFGripOnlyLayout(id divider, SEL cmd) {
    // Native6 visual library may already have hooked layoutSubviews.
    // Always call its complete chain FIRST, then only restore the real button
    // frame and native gesture delay; never redraw or replace any image.
    ((void (*)(id, SEL))oldDFGripOnlyLayout)(divider, cmd);
    if (DFLogoRestorePositionBeforeLayout(divider) &&
        [divider respondsToSelector:@selector(updateGripLayout)]) {
        ((void (*)(id, SEL))objc_msgSend)(
            divider, @selector(updateGripLayout));
    }
    id buttons = DFObjectIvar(divider, "_moveButtons");
    if ([buttons isKindOfClass:[NSArray class]]) {
        for (id button in (NSArray *)buttons)
            DFLogoSetNativeHoldThreshold((UIButton *)button);
    }
}

static DFHookFn DFGripOnlySubstrate(void) {
    DFHookFn hook = (DFHookFn)dlsym(RTLD_DEFAULT, "MSHookMessageEx");
    if (hook) return hook;
    static BOOL attempted;
    if (attempted) return NULL;
    attempted = YES;
    DFGripOnlySubstrateHandle =
        dlopen("/var/jb/usr/lib/libsubstrate.dylib", RTLD_NOW | RTLD_GLOBAL);
    if (!DFGripOnlySubstrateHandle)
        DFGripOnlySubstrateHandle =
            dlopen("/usr/lib/libsubstrate.dylib", RTLD_NOW | RTLD_GLOBAL);
    return DFGripOnlySubstrateHandle
        ? (DFHookFn)dlsym(DFGripOnlySubstrateHandle, "MSHookMessageEx") : NULL;
}

static void DFGripOnlyInstall(void) {
    if (DFGripOnlyLayoutHookInstalled) return;
    Class divider = objc_getClass("CBDividerView");
    if (!divider || !class_getInstanceMethod(divider, @selector(layoutSubviews)))
        return;
    DFHookFn hook = DFGripOnlySubstrate();
    if (!hook) return;
    if (!DFInstallLogoGripHooks(hook, divider)) {
        NSLog(@"[DuoFaceGripOnly] missing native methods; original UI/pan preserved");
        return;
    }
    hook(divider, @selector(layoutSubviews),
         (IMP)DFGripOnlyLayout, &oldDFGripOnlyLayout);
    DFGripOnlyLayoutHookInstalled = YES;
    NSLog(@"[DuoFaceGripOnly] installed: 0.30s logo drag; native divider pan, fullscreen, visual library untouched");
}

static void DFGripOnlyImageAdded(const struct mach_header *mh, intptr_t slide) {
    (void)mh;
    (void)slide;
    dispatch_async(dispatch_get_main_queue(), ^{ DFGripOnlyInstall(); });
}

__attribute__((constructor)) static void DFGripOnlyInit(void) {
    _dyld_register_func_for_add_image(DFGripOnlyImageAdded);
    dispatch_async(dispatch_get_main_queue(), ^{ DFGripOnlyInstall(); });
}
