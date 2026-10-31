#!/usr/bin/env python3
"""Read-only original semantic checkpoints, not vendor implementation export."""
import argparse,hashlib,json,pathlib,subprocess,tempfile
from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
from audit_native12_license_class_xrefs import MachO,select_arm64
p=argparse.ArgumentParser();p.add_argument('--deb',type=pathlib.Path,required=True);p.add_argument('--out',type=pathlib.Path,required=True);a=p.parse_args()
assert hashlib.sha256(a.deb.read_bytes()).hexdigest()=='f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd'
with tempfile.TemporaryDirectory() as t:
 subprocess.run(['dpkg-deb','-x',str(a.deb),t],check=True)
 raw=next(pathlib.Path(t).rglob('DuoNaviDashboard.dylib')).read_bytes()
 assert hashlib.sha256(raw).hexdigest()=='44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15'
 m=MachO(select_arm64(raw));cs=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
 def op(pc):return next(cs.disasm(m.data[m.map(pc):m.map(pc)+4],pc))
 assert op(0x2c7378).mnemonic=='mov' and op(0x2c7378).op_str=='x3, #0'
 assert op(0x2c7374).op_str=='x2, x19'
 assert m.cstr(m.ptr(0x3aa128))=='_bundleIdentifierDidBecomeVisible:previousBundleIdentifier:'
 assert op(0x2c750c).mnemonic=='eor' and op(0x2c750c).op_str=='w2, w19, #1'
 assert m.cstr(m.ptr(0x3aa148))=='setDisplayState:'
 assert op(0x2c712c).op_str=='w2, #1' and op(0x2c7180).op_str=='w2, #0'
 report={'original_deb_sha256':hashlib.sha256(a.deb.read_bytes()).hexdigest(),
  'original_dylib_sha256':hashlib.sha256(raw).hexdigest(),
  'history_previous_argument':'nil (x3=0), new bundle passed in x2',
  'history_checkpoint_pc':'0x2c7378','home_boolean_transform':'logical inversion via XOR1',
  'home_checkpoint_pc':'0x2c750c','active_home_display_state':0,'inactive_home_display_state':1,
  'physical_current_abi_source':'observer main8170d2a; setter Q16 unsigned64',
  'vendor_code_executed':False,'vendor_source_copied':False,'physical_behavior_tested':False}
 a.out.write_text(json.dumps(report,indent=2)+'\n');print('ORIGINAL_DOCK_HOME_ARGUMENT_CHECKPOINTS_VERIFIED')
