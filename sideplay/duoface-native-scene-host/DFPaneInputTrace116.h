// DuoFace .116 FIRST-PARTY, READ-ONLY physical CarPlay pane input diagnostic.
// Imported after DFCLog in DFNative12Chrome.m. No new UI, no event replay.
// Original Native12 root UIWindow had hitTest/pointInside/sendEvent ownership.
// This tracer does NOT copy those vendor IMPs or alter delivery.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
static BOOL DFPane116Began(UIWindow *w,UIEvent *event,UITouch **outTouch) {
    if(!w || !event || event.type!=UIEventTypeTouches ||
       !w.screen || w.screen==UIScreen.mainScreen)return NO;
    for(UITouch *t in event.allTouches)
        if(t.phase==UITouchPhaseBegan && (!t.window || t.window==w)) {
            if(outTouch)*outTouch=t;
            return YES;
        }
    return NO;
}
static void DFPane116Trace(NSString *phase,UIWindow *w,UITouch *touch,
                           CGPoint pt,NSString *status) {
    if(!w || !w.screen || w.screen==UIScreen.mainScreen)return;
    UIView *root=w.rootViewController.view;
    CGFloat fraction=w.bounds.size.height>0?pt.y/w.bounds.size.height:-1;
    DFCLog([NSString stringWithFormat:
        @"pane116-%@ uptime=%.3f window=%p class=%@ frame=%@ bounds=%@ rootBounds=%@ fractionY=%.3f point=%@ touch=%p %@",
        phase,NSProcessInfo.processInfo.systemUptime,w,NSStringFromClass(w.class),
        NSStringFromCGRect(w.frame),NSStringFromCGRect(w.bounds),
        NSStringFromCGRect(root.bounds),fraction,NSStringFromCGPoint(pt),
        touch,status?:@""]);
}
// .117: associate a passive wake callback with ONLY the owned physical pane.
// Do not install touch overlays or alter the UIKit hit target/event routing.
// The owner schedules Chrome UI changes after UIKit completes dispatch.
typedef void (^DFPane117WakeCallback)(UIWindow *);
static char DFPane117WakeKey;
static void DFPane117SetWake(UIWindow *window,DFPane117WakeCallback wake) {
    if(!window)return;
    objc_setAssociatedObject(window,&DFPane117WakeKey,wake,OBJC_ASSOCIATION_COPY_NONATOMIC);
}
static void DFPane117SignalWake(UIWindow *window) {
    DFPane117WakeCallback callback=objc_getAssociatedObject(window,&DFPane117WakeKey);
    if(callback)callback(window);
}
static void DFPane116SendEvent(id self,SEL cmd,UIEvent *event) {
    UIWindow *w=(UIWindow *)self;
    UITouch *touch=nil;
    BOOL began=DFPane116Began(w,event,&touch);
    CGPoint point=began?[touch locationInView:w]:CGPointZero;
    struct objc_super call={self,class_getSuperclass(object_getClass(self))};
    ((void(*)(struct objc_super *,SEL,UIEvent *))objc_msgSendSuper)(&call,cmd,event);
    if(began) {
        DFPane116Trace(@"sendEvent",w,touch,point,@"original-event-forwarded");
        DFPane117SignalWake(w);
    }
}
static UIView *DFPane116HitTest(id self,SEL cmd,CGPoint pt,UIEvent *event) {
    struct objc_super call={self,class_getSuperclass(object_getClass(self))};
    UIView *target=((UIView *(*)(struct objc_super *,SEL,CGPoint,UIEvent *))
                    objc_msgSendSuper)(&call,cmd,pt,event);
    UITouch *touch=nil;
    if(DFPane116Began((UIWindow *)self,event,&touch))
        DFPane116Trace(@"hitTest",(UIWindow *)self,touch,pt,
            [NSString stringWithFormat:@"target=%@ targetIsWindow=%d",
             target?NSStringFromClass(target.class):@"nil",target==self]);
    // Host-controlled windows can be hit-tested without sendEvent being
    // dispatched locally; use only a genuine target and a Began touch.
    if(touch && target)DFPane117SignalWake((UIWindow *)self);
    return target;
}
static BOOL DFPane116PointInside(id self,SEL cmd,CGPoint pt,UIEvent *event) {
    struct objc_super call={self,class_getSuperclass(object_getClass(self))};
    BOOL accepts=((BOOL(*)(struct objc_super *,SEL,CGPoint,UIEvent *))
                  objc_msgSendSuper)(&call,cmd,pt,event);
    UITouch *touch=nil;
    if(DFPane116Began((UIWindow *)self,event,&touch))
        DFPane116Trace(@"pointInside",(UIWindow *)self,touch,pt,
                      accepts?@"inside=1":@"inside=0");
    return accepts;
}
static Class DFPane116TraceClass(Class base) {
    if(!base || ![base isSubclassOfClass:UIWindow.class])return Nil;
    static Class parent=Nil,diagnostic=Nil;
    if(diagnostic)return parent==base?diagnostic:Nil;
    Class candidate=objc_allocateClassPair(base,"DFIndependentCarPlayPaneEventTraceWindow116",0);
    if(!candidate)return Nil;
    const struct {SEL selector;IMP method;} hooks[]={
        {@selector(sendEvent:),(IMP)DFPane116SendEvent},
        {@selector(hitTest:withEvent:),(IMP)DFPane116HitTest},
        {@selector(pointInside:withEvent:),(IMP)DFPane116PointInside},
    };
    for(NSUInteger i=0;i<sizeof(hooks)/sizeof(hooks[0]);i++){
        Method original=class_getInstanceMethod(base,hooks[i].selector);
        if(!original || !class_addMethod(candidate,hooks[i].selector,
                    hooks[i].method,method_getTypeEncoding(original))) {
            objc_disposeClassPair(candidate);
            return Nil;
        }
    }
    objc_registerClassPair(candidate);
    parent=base;
    diagnostic=candidate;
    return diagnostic;
}
