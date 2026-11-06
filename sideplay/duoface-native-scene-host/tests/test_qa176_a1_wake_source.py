"""QA176 A1 production wiring checks. CarPlay hardware acceptance remains separate."""
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
CHROME=(ROOT/"DFNative12Chrome.m").read_text()
APP=(ROOT/"DFAppTouch177.h").read_text()
GATE=(ROOT/"DFAppWakeGate176.h").read_text()
SCENE=(ROOT/"DFSceneHost.m").read_text()
SCENE_HEADER=(ROOT/"DFSceneHost.h").read_text()
STUB=(ROOT/"tests/qa180_uikit_stub/UIKit/UIKit.h").read_text()

def method(source,start,end):
    first=source.index(start)
    last=source.index(end,first+len(start))
    return source[first:last]

class A1WakeWiring(unittest.TestCase):
    def test_no_second_dispatch_hook_or_window(self):
        self.assertEqual(APP.count("static void DF177SendEventHook("),1)
        self.assertIn("if(DF176ConsumeWakeEvent(event,DF177TouchBundle))return;",APP)
        self.assertLess(APP.index("if(DF176ConsumeWakeEvent(event,DF177TouchBundle))return;"),
                        APP.index("DF177SendEventOriginal)("))
        for forbidden in ("new UIWindow", "wakeShield", "sendHIDEvent"):
            self.assertNotIn(forbidden,GATE)

    def test_sender_ack_precedes_consume_and_throttling(self):
        sender=method(APP,"static inline BOOL DF177AppTouchNoteBegan(","static IMP DF177SendEventOriginal")
        self.assertIn("BOOL wakeReserved",sender)
        self.assertIn("if(!wakeReserved && now-DF177TouchLastSentAt",sender)
        self.assertIn("notify_post(DF177TouchWakeName)!=NOTIFY_STATUS_OK)return NO",sender)
        self.assertLess(sender.index("notify_post(DF177TouchWakeName)"),
                        sender.index("DF177TouchCount=nextCount"))
        self.assertIn('@"reserved":@(wakeReserved)',sender)
        gate=method(GATE,"static BOOL DF176ConsumeWakeEvent(","#endif")
        self.assertIn("if(DF177AppTouchNoteBegan(bundle,YES)) {",gate)
        self.assertLess(gate.index("DF177AppTouchNoteBegan(bundle,YES)"),
                        gate.index("consume=YES;"))
        self.assertNotIn("DF177TouchLastSentAt=0",gate)

    def test_scene_origin_is_exact_not_guessed_external_display(self):
        self.assertIn("sceneIdentifierForHostedView:",SCENE_HEADER)
        self.assertIn("scene!=surface.scene",SCENE)
        self.assertIn('DFCall0(scene,@"identifier")',SCENE)
        self.assertIn("window.windowScene",GATE)
        self.assertIn("scene.session.persistentIdentifier",GATE)
        self.assertIn("[observed isEqualToString:sceneID]",GATE)
        self.assertIn('@"Scenes":sceneIDs',CHROME)
        self.assertIn('sceneID=[host sceneIdentifierForHostedView:surface]',CHROME)
        self.assertIn("windowScene",STUB)
        self.assertNotIn("window.screen!=UIScreen.mainScreen",GATE)

    def test_keyboard_unknown_or_visible_cannot_capture(self):
        pub=method(CHROME,"- (void)df176PublishWakeState {","- (void)df178RefreshChromeArtwork {")
        self.assertIn("[self df177RefreshKeyboardState];",pub)
        self.assertIn("self.kbStateKnown177 && !self.kbVisible177",pub)
        self.assertIn('@"KeyboardKnown":@(self.kbStateKnown177)',pub)
        self.assertIn('@"KeyboardVisible":@(self.kbVisible177)',pub)
        gate=method(GATE,"static BOOL DF176ConsumeWakeEvent(","#endif")
        for token in ('[state[@"KeyboardKnown"] isEqual:@YES]',
                      '[state[@"KeyboardVisible"] isEqual:@NO]',
                      "DF177KbComputeVisible()",
                      "DF177IsKeyboardWindow(window)"):
            self.assertIn(token,GATE)

    def test_both_direct_logo_and_primary_divider_are_wake_only(self):
        logo=method(CHROME,"- (void)logoTouchDown:","- (void)logoTouchChanged:")
        self.assertIn("BOOL hidden=!DF178ChromeVisible",logo)
        self.assertIn("self.logoWakeOnlyTap=hidden;",logo)
        self.assertLess(logo.index("if(hidden) {"),logo.index("[self beginDividerDragAt:point];"))
        self.assertIn("[self df178RecallChromeVisualOnly];",logo)
        self.assertIn("return;",logo.split("[self df178RecallChromeVisualOnly];",1)[1].split("CGPoint point=",1)[0])
        moved=method(CHROME,"- (void)logoTouchChanged:","- (void)logoTouchFinished:")
        self.assertLess(moved.index("self.logoWakeOnlyTap)return"),moved.index("[self updateDividerDragAt:point];"))
        ended=method(CHROME,"- (void)logoTouchFinished:","- (void)swapPressed:")
        self.assertIn("if(self.logoWakeOnlyTap) {",ended)
        self.assertLess(ended.index("if(self.logoWakeOnlyTap) {"),ended.index("[self finishDividerDragAt:point"))
        self.assertIn("qa176-a1-direct-logo-wake-ended-no-swap",ended)
        primary=method(CHROME,"- (void)dividerPan:","- (CGPoint)secondaryTouchOnScreen:")
        self.assertIn("self.dividerWakeOnlyPan=YES;",primary)
        self.assertLess(primary.index("self.dividerWakeOnlyPan=YES;"),primary.index("[self beginDividerDragAt:screen];"))
        secondary=method(CHROME,"- (void)secondaryDividerPan:","// Native12 CBWindow.carPlayUsableBounds")
        self.assertIn("self.secondaryWakeOnlyPan=YES;",secondary)
        self.assertLess(secondary.index("self.secondaryWakeOnlyPan=YES;"),
                        secondary.index("self.secondaryRatio=cancel?"))

    def test_wake_visual_path_does_not_relayout_keyboard(self):
        recv=method(CHROME,"- (void)df177HandleAppTouch {","- (void)realAppTouched:")
        immediate=recv.split("dispatch_after(",1)[0]
        self.assertIn("qa176-a1-host-wake-received",immediate)
        self.assertIn("qa176-a1-host-wake-visual-state",immediate)
        self.assertIn("[self df178RefreshChromeArtwork];",immediate)
        self.assertNotIn("[self layoutControls];",immediate)
        for forbidden in ("stopAllHosts","setRequestedMode:","kill("):
            self.assertNotIn(forbidden,recv)

if __name__=="__main__":
    unittest.main()
