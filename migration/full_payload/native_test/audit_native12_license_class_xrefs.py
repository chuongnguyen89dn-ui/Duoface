#!/usr/bin/env python3
"""Read-only Mach-O class/selector cross-reference map from pinned native12 DEB.

Never patches a Mach-O, does not execute the package, and does not imply
that static references resolve Objective-C dynamic dispatch or dyld fixups.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile

NATIVE12_SHA = "85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7"
BINARIES = {
    "DuoFaceUI": "var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard": "var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
CLASSLIST = {"__objc_classlist", "__objc_nlclslist"}
REFS = {"__objc_classrefs", "__objc_superrefs", "__objc_catlist",
        "__objc_nlcatlist", "__objc_protolist", "__objc_classlist",
        "__objc_nlclslist"}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def select_arm64(raw):
    if raw[:4] == bytes.fromhex("cffaedfe"):
        return raw
    if raw[:4] not in (bytes.fromhex("cafebabe"), bytes.fromhex("cafebabf")):
        raise ValueError("unsupported non arm64 Mach-O header " + raw[:4].hex())
    wide = raw[:4] == bytes.fromhex("cafebabf")
    stride = 32 if wide else 20
    n = struct.unpack_from(">I", raw, 4)[0]
    for idx in range(n):
        pos = 8 + stride * idx
        cpu, subtype = struct.unpack_from(">II", raw, pos)
        off, size = struct.unpack_from(">QQ" if wide else ">II", raw, pos + 8)
        # The arm64 (not arm64e) host slice is the signed one native12 ships.
        if cpu == 0x0100000c and (subtype & 0xffffff) == 0 and 0 < size and off + size <= len(raw):
            part = raw[off:off + size]
            if part[:4] == bytes.fromhex("cffaedfe"):
                return part
    raise ValueError("missing arm64 Mach-O slice")


class MachO:
    def __init__(self, data):
        self.data = data
        self.sections = []
        self.segments = []
        self.commands = []
        self.ncmds = self.u32(16)
        pos = 32
        for _ in range(self.ncmds):
            cmd, length = struct.unpack_from("<II", data, pos)
            if length < 8 or pos + length > len(data):
                raise ValueError("invalid Mach-O load command")
            self.commands.append(cmd)
            if cmd == 0x19:  # LC_SEGMENT_64
                segment_name = data[pos + 8:pos + 24].split(b"\0")[0].decode("ascii", "replace")
                vm, vm_size, off, fsize = struct.unpack_from("<QQQQ", data, pos + 24)
                self.segments.append((vm, vm_size, off, fsize, segment_name))
                section_count = self.u32(pos + 64)
                if pos + 72 + 80 * section_count > pos + length:
                    raise ValueError("segment section array overruns command")
                for j in range(section_count):
                    at = pos + 72 + 80 * j
                    name = data[at:at + 16].split(b"\0")[0].decode("ascii", "replace")
                    secseg = data[at + 16:at + 32].split(b"\0")[0].decode("ascii", "replace")
                    addr, size = struct.unpack_from("<QQ", data, at + 32)
                    fileoff = self.u32(at + 48)
                    if size and fileoff + size > len(data) and not name.startswith("__bss"):
                        raise ValueError("section extends past Mach-O")
                    self.sections.append({"name":name,"segment":secseg,"vm":addr,"size":size,"fileoff":fileoff})
            pos += length

    def u32(self, off):
        return struct.unpack_from("<I", self.data, off)[0]

    def i32(self, off):
        return struct.unpack_from("<i", self.data, off)[0]

    def u64(self, off):
        return struct.unpack_from("<Q", self.data, off)[0]

    def map(self, vm):
        for base, _, off, filesize, _ in self.segments:
            if base <= vm and vm + 8 <= base + filesize:
                mapped = off + vm - base
                if mapped + 8 <= len(self.data):
                    return mapped
        raise ValueError("cannot map Mach-O address " + hex(vm))

    def ptr(self, vm):
        return self.u64(self.map(vm))

    def p32(self, vm):
        return self.u32(self.map(vm))

    def pi32(self, vm):
        return self.i32(self.map(vm))

    def cstr(self, vm):
        if vm == 0:
            return ""
        off = self.map(vm)
        end = self.data.find(b"\0", off, min(off + 256, len(self.data)))
        if end < 0:
            return ""
        return self.data[off:end].decode("utf-8","replace")

    def find_sections(self, name):
        return [s for s in self.sections if s["name"] == name]

    def classes(self):
        result = {}
        for section in self.find_sections("__objc_classlist"):
            if section["size"] % 8:
                raise ValueError("classlist not aligned")
            for entry in range(section["vm"], section["vm"] + section["size"], 8):
                ptr = self.ptr(entry)
                if not ptr:
                    continue
                ro = self.ptr(ptr + 32) & ~7
                name = self.cstr(self.ptr(ro + 24))
                if not name:
                    continue
                methods = []
                for kind, obj in (("-",ptr), ("+",self.ptr(ptr))):
                    if obj == 0:
                        continue
                    head = self.ptr((self.ptr(obj + 32) & ~7) + 32)
                    if head == 0:
                        continue
                    flags, count = self.p32(head), self.p32(head + 4)
                    if count > 500:
                        raise ValueError("suspicious ObjC method count")
                    relative = bool(flags & 0x80000000)
                    stride = 12 if relative else 24
                    for j in range(count):
                        place = head + 8 + stride * j
                        if relative:
                            selref = place + self.pi32(place)
                            selvm = selref if flags & 0x40000000 else self.ptr(selref)
                        else:
                            selvm = self.ptr(place)
                        sel = self.cstr(selvm)
                        if sel:
                            methods.append(kind + sel)
                result[name] = {"class_ptr":ptr,"classlist_entry":entry,
                                "superclass_ptr":self.ptr(ptr + 8),
                                "methods":methods}
        return result

    def class_pointer_refs(self, classptr):
        refs = []
        for sec in self.sections:
            if not sec["size"] or sec["size"] % 8:
                continue
            if not sec["segment"].startswith(("__DATA","__AUTH")):
                continue
            for i in range(0, sec["size"], 8):
                off = sec["fileoff"] + i
                if off + 8 > len(self.data):
                    break
                if self.u64(off) == classptr:
                    refs.append({"section":sec["name"],"segment":sec["segment"],
                                 "fileoff":off,"vm":hex(sec["vm"] + i),
                                 "role":"class_registration" if sec["name"] in CLASSLIST
                                 else "direct_reference"})
        return refs


def audit_binary(name, data, candidates, preserved):
    host = MachO(select_arm64(data))
    classes = host.classes()
    result = {"binary":name,"host_sha256":sha(data),
              "arm64_slice_sha256":sha(host.data),
              "arm64_slice_length":len(host.data),
              "objc_class_count":len(classes),
              "objc_method_count":sum(len(x["methods"]) for x in classes.values()),
              "has_dyld_chained_fixups":0x80000034 in host.commands,
              "has_code_signature":0x1d in host.commands,
              "candidate_classes":[],"carplay_guard":[],"unresolved_dynamic_dispatch":True,
              "safe_to_physically_remove_any_class_without_more_proof":False}
    names = {r["objc_class"] for r in candidates if r["binary"] == name}
    for target in candidates:
        if target["binary"] != name:
            continue
        cname = target["objc_class"]
        if cname not in classes:
            raise AssertionError("missing required class: " + name + "::" + cname)
        c = classes[cname]
        expected = sorted("-" + row["selector"] for row in target["method_ledger"])
        got = sorted(m for m in c["methods"] if m.startswith("-"))
        # Method counts include both class and instance methods in the original ledger.
        if len(c["methods"]) != target["method_count"]:
            raise AssertionError("method-count mismatch: " + cname)
        if sorted(m[1:] for m in c["methods"]) != sorted(row["selector"] for row in target["method_ledger"]):
            raise AssertionError("method-selector mismatch: " + cname)
        superclass_dependents = sorted(other for other,v in classes.items()
                                       if other != cname and v["superclass_ptr"] == c["class_ptr"])
        refs = host.class_pointer_refs(c["class_ptr"])
        other_selector_owners = {}
        for own in classes:
            if own == cname or own in names:
                continue
            reused = sorted(set(m[1:] for m in classes[own]["methods"]) &
                            set(m[1:] for m in c["methods"]))
            if reused:
                other_selector_owners[own] = reused
        literal = cname.encode() + b"\0"
        text_occurrences = [i for i in range(len(host.data)) if host.data.startswith(literal,i)]
        result["candidate_classes"].append({
            "class":cname,"class_ptr":hex(c["class_ptr"]),"classlist_vm":hex(c["classlist_entry"]),
            "method_count":len(c["methods"]),"pointer_references":refs,
            "non_registration_direct_ref_count":sum(x["role"] != "class_registration" for x in refs),
            "superclass_dependents":superclass_dependents,
            "other_class_selector_owners":other_selector_owners,
            "class_name_nul_literal_occurrences":len(text_occurrences),
            "literal_file_offsets":text_occurrences[:12],
            "runtime_liveness_proven_absent":False,
            "safe_to_delete":False})
    for guard in preserved:
        if guard["binary"] != name:
            continue
        offset = guard["offset"]
        # Immutable guard uses original named arm64 method body at fixed file offset.
        reference = guard["sha256_at_native9"]
        length = guard.get("length")
        # Legacy map stores length in source report, not necessarily in the candidate manifest.
        if not isinstance(length,int) or length <= 0 or offset + length > len(host.data):
            raise AssertionError("invalid CarPlay protected function boundaries")
        actual = sha(host.data[offset:offset + length])
        if actual != reference:
            raise AssertionError("CarPlay implementation changed: " + name + "::" + guard["selector"])
        result["carplay_guard"].append({"class":guard["objc_class"],
                "selector":guard["selector"],"file_offset":offset,
                "expected_sha256":reference,"actual_sha256":actual,
                "status":"CARPLAY_METHOD_BYTE_EXACT_PASS"})
    return result


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--deb", required=True, type=Path)
    ap.add_argument("--inventory", required=True, type=Path)
    ap.add_argument("--carplay-guard", required=True, type=Path)
    ap.add_argument("--out", required=True, type=Path)
    args = ap.parse_args()
    if sha(args.deb.read_bytes()) != NATIVE12_SHA:
        raise SystemExit("immutable native12 DEB SHA256 mismatch")
    m = json.loads(args.inventory.read_text())
    candidates = m["candidate_classes"]
    assert len(candidates) == 14
    assert sum(x["method_count"] for x in candidates) == 249
    guard_source = json.loads(args.carplay_guard.read_text())
    guards = [{"binary":x["binary"],"objc_class":x["class"],"selector":x["selector"],
               "offset":x["file_offset"],"length":x["length"],
               "sha256_at_native9":x["sha256_in_native9"]}
              for x in guard_source["immutable_carplay_methods"]]
    assert len(guards) == 8
    with tempfile.TemporaryDirectory(prefix="df12-class-xrefs-") as tmp:
        subprocess.run(["dpkg-deb","-x",str(args.deb),tmp],check=True)
        result = {key:audit_binary(key, (Path(tmp)/path).read_bytes(),
                      candidates, guards)
                  for key,path in BINARIES.items()}
    report = {"status":"NATIVE12_ACTUAL_MACHO_CLASS_REFERENCES_READONLY",
              "deb_sha256":NATIVE12_SHA, "native12_untouched":True,
              "physical_excision_completed":False,
              "dynamic_dispatch_resolved":False,
              "candidates_checked":sum(len(v["candidate_classes"]) for v in result.values()),
              "binaries":result}
    assert report["candidates_checked"] == 14
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(report,indent=2,ensure_ascii=False) + "\n")
    print(json.dumps({"status":report["status"],
       "classes":report["candidates_checked"],
       "references":{k:sum(x["non_registration_direct_ref_count"]
                         for x in v["candidate_classes"]) for k,v in result.items()},
       "blocked_count":sum(len(v["candidate_classes"]) for v in result.values()),
       "runtime_proof":False},indent=2))


if __name__ == "__main__":
    main()
