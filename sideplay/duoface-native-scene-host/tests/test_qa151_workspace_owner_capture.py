"""QA151 read-only workspace owner provenance contract. STATIC, not device proof."""
from pathlib import Path
import unittest
import hashlib
R=Path(__file__).resolve().parents[1]
CAP=(R/"DF151WorkspaceOwnerCapture.h").read_text()
SOLO=(R/"DFHomeStandalone144.m").read_text()
HOST=(R/"DFSceneHost.m").read_bytes()

class WorkspaceCapture151(unittest.TestCase):
 def test_captures_only_dashboard_owner_from_original_initializer(self):
  self.assertIn('objc_getClass("DBDashboardWorkspaceOwner")',CAP)
  self.assertIn('[owner isKindOfClass:ownerClass]',CAP)
  self.assertIn('objc_getClass("DBWorkspace")',CAP)
  self.assertIn('sel_registerName("initWithOwner:")',CAP)
  self.assertIn('strcmp(method_getTypeEncoding(m),"@24@0:8@16")',CAP)
  body=CAP.split("static id DF151WorkspaceInitWithOwner(",1)[1].split("static BOOL DF151InstallWorkspaceCapture(",1)[0]
  self.assertLess(body.index("DF151OriginalWorkspaceInit(workspace,selector,owner)"),body.index("DF151DashboardWorkspace=actual"))
  self.assertIn("if(actual && DF151IsDashboardOwner(owner))",body)
  self.assertNotIn("DBMutableWorkspaceStateChangeRequest",body)
 def test_hooks_before_selected_home_tap_and_recovers_image_load(self):
  self.assertIn("objc_addLoadImageFunc(DF151WorkspaceImageLoaded)",CAP)
  self.assertIn("if(!DF151WorkspaceHookInstalled)DF151InstallWorkspaceCapture()",CAP)
  start=SOLO.split("__attribute__((constructor))static void DF144StartCarPlay(void)",1)[1].split("#endif",1)[0]
  self.assertLess(start.index("DF151StartCapture()"),start.index("DF144Install(0)"))
  self.assertIn('#import "DF151WorkspaceOwnerCapture.h"',SOLO)
  launch=SOLO.split("static void DF144Launch(",1)[1].split("static void DF144Install(",1)[0]
  self.assertLess(launch.index("DF144ValidRequest(p,"),launch.index("DF151WorkspaceSnapshot(rid,bundle,display,self)"))
  self.assertLess(launch.index("DF151WorkspaceSnapshot(rid,bundle,display,self)"),launch.index("notify_post(DF144RequestNotify)"))
 def test_live_receiver_provenance_snapshot_never_activates_native_workspace(self):
  body=CAP.split("static void DF151WorkspaceSnapshot(",1)[1]
  for required in ("captured=workspace && DF151IsDashboardOwner(owner)",
    'DF151SafeObjectGetter(home,"workspace"',
    'DF151SafeObjectGetter(home,"showingApp"',
    'DF151SafeObjectGetter(workspace,"state"',
    'DF151SafeObjectGetter(state,"activeBundleIdentifier"',
    "homeWorkspace==workspace","qa151-native-workspace-live-owner"):
   self.assertIn(required,body)
  for forbidden in ('sel_registerName("activateApplication:")',
       'sel_registerName("requestStateChange:")','sel_registerName("deactivateApplication:")',
       "writeToFile:","notify_post(","kill(", "new]",
       "DBAppDockViewController setActiveBundleIdentifier:"):
   self.assertNotIn(forbidden,CAP)
 def test_workspace_getter_abi_fails_closed_and_old_host_is_unchanged(self):
  self.assertIn('strcmp(method_getTypeEncoding(m),"@16@0:8")',CAP)
  self.assertIn("@catch(NSException *error)",CAP)
  sha=hashlib.sha1(b"blob "+str(len(HOST)).encode()+b"\0"+HOST).hexdigest()
  self.assertEqual(sha,"ec2924c145be4edaaa27b7320bb869b18de12c6b")
  self.assertIn("DF149Receive(&DF149Life", (R/"DFNativeDockSync147.h").read_text())

if __name__=="__main__":
 unittest.main()
