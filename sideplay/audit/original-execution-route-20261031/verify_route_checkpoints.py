#!/usr/bin/env python3
"""Read-only, pinned-binary checkpoints; not a CFG or runtime equivalence test.
Requires capstone==5.0.7 and the project's recovery-branch MachO metadata helper.
No binary, commercial implementation, decrypted channels or licensing logic is emitted.
"""
import argparse, hashlib, importlib.util, json, struct
from pathlib import Path
from capstone import Cs, CS_ARCH_ARM64, CS_MODE_ARM

EXPECTED = '44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15'
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--binary', type=Path, required=True)
p.add_argument('--parser', type=Path, required=True,
               help='audit_native12_license_class_xrefs.py (metadata parser only)')
a = p.parse_args()
raw = a.binary.read_bytes()
assert hashlib.sha256(raw).hexdigest() == EXPECTED, 'wrong original binary'
spec = importlib.util.spec_from_file_location('metadata_parser', a.parser)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
m = mod.MachO(mod.select_arm64(raw))
cs = Cs(CS_ARCH_ARM64, CS_MODE_ARM)
checks = []
def ins(pc, mnemonic, operands, meaning):
    i = next(cs.disasm(m.data[m.map(pc):m.map(pc)+4], pc))
    assert (i.mnemonic, i.op_str) == (mnemonic, operands), (hex(pc), i.mnemonic, i.op_str)
    checks.append(dict(pc=hex(pc), kind='instruction', meaning=meaning))
def selector(slot, name):
    assert m.cstr(m.ptr(slot)) == name, (hex(slot), name)
    checks.append(dict(slot=hex(slot), kind='selector_reference', selector=name))
def call(pc, meaning):
    ins(pc, 'bl', '#0x313780', meaning)
# Call sites and selector references are separate checkpoints. Receiver/capture and
# branch relationships were checked manually in bounded basic blocks; no global
# straight-line register propagation is treated as proof.
for pc, desc in [
 (0x2c5d18,'save launch completion'),(0x2c5d2c,'begin preparation'),
 (0x2c5e74,'prepare native Home with activation continuation'),
 (0x2c6088,'close official foreground app with once completion'),
 (0x2c6358,'workspace request deactivates foreground native application'),
 (0x2c6388,'workspace completion handler'),(0x2c6398,'submit workspace change'),
 (0x2c65fc,'build activation request dictionary'),
 
 (0x15b534,'construct CBBridgeRequest'),(0x15b54c,'submit manager state request'),
 (0x179cec,'evict phone app with host continuation'),
 (0x192a90,'create app with bundle and frame in host continuation'),
 (0x192db4,'send app-side shouldBridge state'),
 (0x192e10,'start host in parent controller'),(0x192e20,'fallback start'),
 (0x192e34,'show bridge window'),(0x192e44,'notify manager state'),
 (0x2c6fbc,'clear pending upon state response'),
 (0x2c7034,'activate Dashboard side from manager response'),
 (0x2c7050,'deactivate Dashboard side from manager response'),
 (0x30f5a0,'Home hook requests stop before native forwarding'),
 (0x30f99c,'bridged Dock tap goes to manager'),
 (0x2c726c,'active bridge Dock tap requests bundle switch'),
 (0x2c728c,'inactive bridge Dock tap starts preparation'),
 (0x1bef84,'stop current hosted app'),(0x1befe4,'destroy bridge windows'),
 (0x1bf010,'publish deactivated manager state')]: call(pc, desc)
for slot, name in [
 (0x3a96b0,'evictAppFromPhoneScreen:completion:'),
 (0x3a9da0,'appForBundleIdentifier:frame:'),
 (0x3a9650,'sendStateToApp:shouldBridge:'),
 (0x3a8ed8,'startInParentViewController:'),
 (0x3a9470,'start'),(0x3a9d78,'show'),(0x3a9d80,'notifyStateUpdated'),
 (0x3a9f58,'setActivatingEntity:'),(0x3a9f60,'setCompletionBlock:'),
 (0x3a9f68,'addCompletionHandler:')]: selector(slot,name)
ins(0x26c788,'b','#0x313780','notification continuation tail-calls decoded request handler')
ins(0x179cb0,'adr','x8, #0x18c708','host continuation invoke address')
ins(0x179cc4,'stp','x8, x9, [sp, #0x110]','invoke stored at block base + 16')
ins(0x179cc8,'str','x25, [sp, #0x120]','manager captured at block base + 32')
ins(0x179ce4,'add','x3, sp, #0x100','completion argument points to constructed block')
ins(0x192820,'ldr','x8, [x28, #0x20]!','host continuation loads captured manager; x28 advances by 32')
ins(0x26d2ec,'adr','x9, #0x26d838','eviction once-wrapper invoke')
ins(0x26d680,'adr','x8, #0x26d908','eviction fallback invokes wrapper')
ins(0x26d66c,'mov','w1, #0xe00','eviction fallback delay low 16 bits')
ins(0x26d670,'movk','w1, #0x727, lsl #16','eviction fallback delay total 120000000 ns')
ins(0x26d6a8,'bl','#0x31354c','dispatch eviction fallback')
ins(0x30f5c0,'blr','x8','Home hook forwards saved Apple implementation')
# Host initialization ordering and reference-size contract (bounded methods).
for pc,desc in [(0xae228,'ignore occlusions before reading hosted view'),
 (0xae254,'disable automated lifecycle before reading hosted view'),
 (0xae278,'calculate native size from slot bounds'),
 (0xae2d8,'read hosted view after lifecycle flags'),
 (0xae310,'request native mode before reference setters'),
 (0xae61c,'child two-argument reference size setter'),
 (0xae658,'independent child three-argument reference size setter'),
 (0xae690,'main controller reference size setter'),
 (0xae9c8,'finish parent containment after initial reference setters'),
 (0xf2fec,'outer app sets hosted view frame'),
 (0xf3000,'outer app starts hosted view in parent')]: call(pc,desc)
for slot,name in [(0x3a8dc8,'calculateNativeSizeForSlotRect:'),
 (0x3a8dd8,'setContentReferenceSize:withInterfaceOrientation:'),
 (0x3a8de0,'setContentReferenceSize:withContentOrientation:andContainerOrientation:')]: selector(slot,name)
ins(0xac798,'fadd','d0, d2, d2','native width is twice positive slot width before float rounding')
ins(0xac7a8,'fadd','d1, d3, d3','native height is twice positive slot height before float rounding')
ins(0xae618,'mov','w2, #1','initial child interface orientation 1')
ins(0xae650,'mov','w2, #1','initial child content orientation 1')
ins(0xae654,'mov','w3, #1','initial child container orientation 1')
ins(0xae68c,'mov','w2, #1','initial main interface orientation 1')

# Runtime initialized globals are NOT interpreted as nil on disk. Only compare
# encoded path literal identity; this does not claim plaintext/decryption proof.
for name,left,right,size in [('long',0x34378e,0x342c3f,57),('short',0x3437c7,0x342c1d,34)]:
    l=m.data[m.map(left):m.map(left)+size]
    r=m.data[m.map(right):m.map(right)+size]
    assert l==r
    checks.append(dict(kind='encoded_literal_equality',name=name,left=hex(left),right=hex(right),bytes=size,sha256=hashlib.sha256(l).hexdigest(),plaintext_verified=False))
print(json.dumps(dict(schema=1, binary_sha256=EXPECTED, mode='static_read_only',
                     runtime_equivalence_proven=False, checks=checks),indent=2))
