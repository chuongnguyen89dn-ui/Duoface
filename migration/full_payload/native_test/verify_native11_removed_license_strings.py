#!/usr/bin/env python3
"""Independent QA of signed native11 DEB against byte-pinned native10.

Proves *only* audited 52 obsolete license literal contents were changed in
__cstring, without changing 8 CarPlay method bodies or any machine code,
ObjC class/selector metadata, other payload files, fullscreen/drag UI.
Not a substitute for the subsequent physical iPhone/CarPlay device test.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from build_native5 import FILES, sections, sha
from build_native11_removed_license_strings import SRC, EXPECTED, VERSION
from remove_native11_license_literals import INVENTORY, PROTECTED, erase_binary

ROOT=Path(__file__).resolve().parents[3]

def extracted(root:Path):
    return {p.relative_to(root).as_posix():sha(p.read_bytes())
            for p in root.rglob("*") if p.is_file() and not p.is_symlink()}

def verify():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=Path,required=True)
    ap.add_argument("--report",type=Path,required=True)
    ap.add_argument("--out",type=Path,required=True)
    args=ap.parse_args()
    assert sha(SRC.read_bytes())==EXPECTED
    audit=json.loads(args.report.read_text(encoding="utf-8"))
    assert audit["status"]=="NATIVE11_SIGNED_DEB_52_OLD_LICENSE_STRING_CONTENTS_PHYSICALLY_ERASED"
    assert audit["source_tested_native10_sha256"]==EXPECTED
    assert audit["deb_sha256"]==sha(args.deb.read_bytes())
    assert audit["version"]==VERSION and audit["erased_string_count"]==52
    assert audit["byte_erased_count"]==1816
    assert audit["signed_modified_macho"] and not audit["sileo_published"]
    assert audit["objc_class_and_selector_metadata_not_removed"]
    assert not audit["all_license_data_and_metadata_fully_removed"]
    assert not audit["user_device_test_for_new_package"]
    for fld,expect in (("Package","com.duoface.independent"),("Version",VERSION),("Architecture","iphoneos-arm64")):
        assert subprocess.check_output(["dpkg-deb","-f",str(args.deb),fld],text=True).strip()==expect
    inventory=json.loads(INVENTORY.read_text(encoding="utf-8"))
    protect=json.loads(PROTECTED.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="duoface-native11-qa-") as td:
        base=Path(td)/"native10"
        cur=Path(td)/"native11"
        ctl=Path(td)/"control"
        subprocess.run(["dpkg-deb","-x",str(SRC),str(base)],check=True)
        subprocess.run(["dpkg-deb","-x",str(args.deb),str(cur)],check=True)
        subprocess.run(["dpkg-deb","-e",str(args.deb),str(ctl)],check=True)
        old_files=extracted(base)
        new_files=extracted(cur)
        assert old_files.keys()==new_files.keys()
        modified=sorted(p for p in old_files if old_files[p]!=new_files[p])
        assert modified==sorted(FILES.values())
        assert sorted(audit["modified_existing_paths"])==sorted([*FILES.values(),"DEBIAN/control","DEBIAN/md5sums"])
        for name in old_files:
            if name not in modified:
                assert old_files[name]==new_files[name]
        checks={}
        seen=[]
        for name,rel in FILES.items():
            old=(base/rel).read_bytes()
            new=(cur/rel).read_bytes()
            unsigned,rows,stats=erase_binary(old,name,inventory,protect)
            assert len(new)==len(unsigned)==len(old)
            # ldID changes signature but no Mach-O segment payload section is
            # permitted to differ from the exact deterministic erase.
            orig_sections=list(sections(old))
            new_sections=list(sections(new))
            # Re-signing may add/change a code-signature load command; file
            # offsets for later sections must be compared semantically, not
            # as a raw tuple list. Critically, every mapped section must still
            # contain byte-identical data, except the 52 exact __cstring ranges.
            old_map={}
            new_map={}
            for seg,sect,off,n in orig_sections:
                old_map.setdefault((seg,sect),[]).append((off,n))
            for seg,sect,off,n in new_sections:
                new_map.setdefault((seg,sect),[]).append((off,n))
            assert old_map.keys()==new_map.keys(),(name,"section set drift",set(old_map)^set(new_map))
            for key,old_entries in old_map.items():
                new_entries=new_map[key]
                assert len(old_entries)==len(new_entries),(name,key,"section count changed")
                for (off,n),(new_off,new_n) in zip(old_entries,new_entries):
                    assert n==new_n,(name,key,"section size changed",n,new_n)
                    seg,sect=key
                    if sect=="__cstring":
                        # Rootless arm64 __cstring pointers cannot change:
                        # literal contents are in-place NUL-ed at original offsets.
                        assert off==new_off,(name,key,"cstring layout moved")
                        assert new[new_off:new_off+n]==unsigned[off:off+n],(name,key,"cstring exact erase failed")
                    else:
                        assert old[off:off+n]==new[new_off:new_off+n],(name,key,"non-string section changed")
            assert stats["unsigned_erased_sha256"]==audit["signed_binaries"][name]["unsigned_erased_sha256"]
            assert len(rows)==audit["signed_binaries"][name]["erased_string_count"]
            for row in rows:
                a=row["offset"];z=a+row["length"]
                assert new[a:z]==bytes(z-a)
                assert row["label"].encode("utf-8")==old[a:z]
                seen.append(row)
            for cp in protect["by_binary"][name]["carplay_byte_exact_keep"]:
                a=cp["file_offset"];z=a+cp["length"]
                assert old[a:z]==new[a:z],(name,cp["selector"])
                assert sha(new[a:z])==cp["sha256_in_native9"]
            checks[name]={
                "exact_erase_ranges":len(rows),
                "original_nonzero_bytes_removed":stats["changed_nonzero_bytes"],
                "code_text_and_metadata_byte_identical":True,
                "CarPlay_method_bodies_byte_identical":4,
                "full_screen_logo_and_other_payload_preserved":True,
                "sha256_signed_binary":sha(new),
            }
        assert len(seen)==52
        assert sum(s["original_nonzero_bytes_removed"] for s in checks.values())==1816
        md5lines=(ctl/"md5sums").read_text().splitlines()
        md5map={}
        for line in md5lines:
            digest,filename=line.split("  ",1)
            assert filename not in md5map
            md5map[filename]=digest
        assert set(md5map)==set(new_files)
        for path,digest in md5map.items():
            assert hashlib.md5((cur/path).read_bytes()).hexdigest()==digest
    result={
        "status":"NATIVE11_SIGNED_DEB_EXACT_52_LITERAL_CONTENT_REMOVALS_8_CARPLAY_GUARD_PASS",
        "native11_deb_sha256":audit["deb_sha256"],
        "native10_reference_sha256":EXPECTED,
        "package":"com.duoface.independent",
        "version":VERSION,
        "changed_only_52_selected_license_literal_contents":True,
        "selected_literal_count":52,
        "selected_string_bytes_removed":1816,
        "all_objc_and_machine_code_sections_unchanged":True,
        "all_8_carplay_detection_method_bodies_unchanged":True,
        "all_other_payload_entries_unchanged":True,
        "all_md5sums_verified":True,
        "signed_arm64_rootless":True,
        "objc_license_metadata_still_exists":True,
        "full_license_runtime_removed":False,
        "runtime_localization_lookup_proven_safe":False,
        "device_tested":False,
        "published_to_sileo":False,
        "rollback_native10_unchanged":True,
        "binaries":checks,
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2,ensure_ascii=False))

if __name__=="__main__":
    verify()
