#!/usr/bin/env python3
"""Run maintainer scripts against a private TEMP DIRECTORY, never real user prefs."""
from pathlib import Path
import plistlib, subprocess, tempfile, unittest

SRC=Path(__file__).resolve().parents[1]
NAME="com.duoface.mytweak.carplay-bridge"
TEMPLATE=SRC/"var/jb/usr/share/doc/duoface-nativebridgeqa-activate/enabled.plist"

class ReversibleExplicitOptin(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)
        self.prefs=self.root/"var/mobile/Library/Preferences"
        self.prefs.mkdir(parents=True)
        self.template=self.root/"var/jb/usr/share/doc/duoface-nativebridgeqa-activate/enabled.plist"
        self.template.parent.mkdir(parents=True)
        self.template.write_bytes(TEMPLATE.read_bytes())
        self.scripts=[]
        for name in ["postinst","prerm"]:
            s=(SRC/"DEBIAN"/name).read_text()
            s=s.replace("/var/mobile/Library/Preferences",str(self.prefs))
            s=s.replace("/var/jb/usr/share/doc/duoface-nativebridgeqa-activate/enabled.plist",str(self.template))
            s=s.replace('chown mobile:mobile "$TMP"',': # CI only: simulated mobile ownership')
            s=s.replace('chown mobile:mobile "$MARKER"',': # CI only: simulated mobile ownership')
            path=self.root/name
            path.write_text(s)
            path.chmod(0o755)
            self.scripts.append(path)
    def invoke(self,kind,arg,success=True):
        p=subprocess.run(["/bin/sh",str(self.scripts[kind]),arg],
             capture_output=True,text=True)
        if success:self.assertEqual(0,p.returncode,p.stdout+p.stderr)
        else:self.assertNotEqual(0,p.returncode,p.stdout+p.stderr)
    @property
    def target(self):return self.prefs/(NAME+".plist")
    @property
    def backup(self):return self.prefs/(NAME+".before-activateqa.plist")
    @property
    def marker(self):return self.prefs/(NAME+".activateqa-state")
    @property
    def archive(self):return self.prefs/(NAME+".user-edited-after-activateqa.plist")
    def verify_enabled(self):
        p=plistlib.loads(self.target.read_bytes())
        self.assertEqual({"Enabled":True,"NativeSidebarTrial":True},p)
    def test_new_install_then_remove(self):
        self.invoke(0,"configure")
        self.verify_enabled()
        self.assertEqual("created",self.marker.read_text().strip())
        self.assertFalse(self.backup.exists())
        self.invoke(1,"remove")
        self.assertFalse(self.target.exists())
        self.assertFalse(self.marker.exists())
    def test_preexisting_preferences_exact_restore(self):
        previous=plistlib.dumps({"Enabled":False,"NativeSidebarTrial":False,"Other":"retain"})
        self.target.write_bytes(previous)
        self.invoke(0,"configure")
        self.verify_enabled()
        self.assertEqual(self.backup.read_bytes(),previous)
        self.assertEqual("backedup",self.marker.read_text().strip())
        self.invoke(1,"remove")
        self.assertEqual(self.target.read_bytes(),previous)
        self.assertFalse(self.backup.exists())
    def test_idempotent_reconfiguration_respects_user_changes(self):
        self.invoke(0,"configure")
        user=plistlib.dumps({"Enabled":False,"NativeSidebarTrial":False})
        self.target.write_bytes(user)
        self.invoke(0,"configure")
        self.assertEqual(self.target.read_bytes(),user)
        self.invoke(1,"remove")
        self.assertEqual(self.archive.read_bytes(),user)
        self.assertFalse(self.target.exists())
    def test_user_edits_preserved_when_restore_backup(self):
        original=plistlib.dumps({"Enabled":False,"Owner":"user"})
        edited=plistlib.dumps({"Enabled":False,"Another":"user-change"})
        self.target.write_bytes(original)
        self.invoke(0,"configure")
        self.target.write_bytes(edited)
        self.invoke(1,"remove")
        self.assertEqual(self.target.read_bytes(),original)
        self.assertEqual(self.archive.read_bytes(),edited)
    def test_symlink_protection(self):
        other=self.root/"other"
        other.write_text("no-touch")
        self.target.symlink_to(other)
        self.invoke(0,"configure",success=False)
        self.assertEqual(other.read_text(),"no-touch")
        self.assertFalse(self.marker.exists())
    def test_existing_backup_protection(self):
        self.backup.write_bytes(b"previous backup")
        self.invoke(0,"configure",success=False)
        self.assertEqual(self.backup.read_bytes(),b"previous backup")
        self.assertFalse(self.marker.exists())
    def test_script_not_auto_respring_or_modify_v1bc(self):
        both="\n".join((SRC/"DEBIAN"/p).read_text() for p in ["postinst","prerm"])
        self.assertNotIn("sbreload",both)
        self.assertNotIn("killall",both)
        self.assertNotIn("launchctl",both)
        self.assertNotIn("ldrestart",both)
        self.assertNotIn("UICache",both)
        self.assertNotIn("LSBundleProxy",both)
        self.assertIn("com.duoface.mytweak.v1bc.plist",both) # comment: explicitly protected
        self.assertIn("NativeSidebarTrial",TEMPLATE.read_text())
        self.assertEqual({"Enabled":True,"NativeSidebarTrial":True},
                         plistlib.loads(TEMPLATE.read_bytes()))
if __name__=="__main__": unittest.main(verbosity=2)
