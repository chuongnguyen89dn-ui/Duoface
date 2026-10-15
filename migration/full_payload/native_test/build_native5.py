#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""DuoFace native5: reversible final expiry UI quarantine over device-OK native4.

Treat this as a STAGED TRIAL, never as proof that all license code is gone:
* neutralize two late-expiry state methods in iPhone app with exact ARM64 ABI;
* mask only user-facing static license/activation wording, not selector/keys;
* generate a complete residual method list with "safe-next-action" categories;
* leave CBBridgeManager and all CarPlay lifecycle/host routines untouched.

All non-whitelisted payloads must remain byte-identical to native4.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import tempfile
from audit_native4_license_code import inspect
from audit_branding import hits

ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/"dist/payload-migration/native4/com.duoface.independent_0.1.0~native4_iphoneos-arm64.deb"
EXPECTED="517cc6ccf84716e40b80116834cf1c874e9ae5027584dc94118cc8f6c4f7f244"
VERSION="0.1.0~native5"
FILES={
    "DuoFaceUI":"var/jb/Applications/DuoFaceUI.app/DuoFaceUI",
    "DuoFaceDashboard":"var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib",
}
FLAG_METHODS={
    ("XXRootViewController","isShowingExpiredModal"):("B16@0:8",struct.pack("<II",0x52800000,0xd65f03c0)),
    ("XXRootViewController","setIsShowingExpiredModal:"):("v20@0:8B16",struct.pack("<I",0xd65f03c0)),
}
NOP=struct.pack("<I",0xd503201f)

# Static, human-visible text ONLY. No Objective-C class, selector, localization
# KEY_..., callback, API URL, resource path, ID or receipt data is edited.
PRESENTATION_ONLY=[
    "License Expired",
    "License Not Activated",
    "License Status",
    "DuoFace Pro License",
    "SUBSCRIPTION & LICENSE",
    "ENTER ACTIVATION CODE (GIFTCODE)",
    "License Download Incomplete",
    "Activation Failed",
    "Lifetime license. All features are permanently available.",
    "DuoFace requires an active license to run on CarPlay. Please activate to get started.",
    "Your DuoFace CarPlay license has expired. Please renew or enter an activation code to continue using the app on your vehicle.",
    "Your license period has ended. Please park your vehicle safely and open DuoFace on your iPhone to renew.",
    "Please park your vehicle safely and open DuoFace on your iPhone to activate your license.",
]
KEYWORDS=("license","licence","subscription","expiration","expired","activation","trial","giftcode","payment","receipt","hardwareid","deviceid")

def sha(data:bytes)->str:return hashlib.sha256(data).hexdigest()
def cmd(*args):subprocess.run(list(map(str,args)),check=True)

def sections(blob:bytes):
    assert blob[:4]==bytes.fromhex("cffaedfe"),"native4 only supports generic arm64 slice"
    n=struct.unpack_from("<I",blob,16)[0]
    cursor=32
    for _ in range(n):
        command,length=struct.unpack_from("<II",blob,cursor)
        assert length>=8 and cursor+length<=len(blob)
        if command==0x19:
            amount=struct.unpack_from("<I",blob,cursor+64)[0]
            for i in range(amount):
                at=cursor+72+i*80
                assert at+80<=cursor+length
                sec=blob[at:at+16].split(b"\x00")[0].decode("ascii","replace")
                seg=blob[at+16:at+32].split(b"\x00")[0].decode("ascii","replace")
                size=struct.unpack_from("<Q",blob,at+40)[0]
                offset=struct.unpack_from("<I",blob,at+48)[0]
                if offset+size<=len(blob):
                    yield seg,sec,offset,size
        cursor+=length

def replace_expired_flags(blob:bytearray):
    methods=inspect(bytes(blob))["license_named_methods"]
    targets={}
    for method in methods:
        key=(method["class"],method["selector"])
        if key in FLAG_METHODS:
            assert key not in targets,("duplicate original method",key)
            typ,stub=FLAG_METHODS[key]
            assert method["type_encoding"]==typ,(key,method["type_encoding"])
            assert method["listed_in_lc_function_starts"],key
            assert method["inside_executable_text"],key
            offset=int(method["imp_file_offset"],16)
            length=method["estimated_function_span"]
            assert length%4==0 and length>=len(stub)
            old=bytes(blob[offset:offset+length])
            new=stub+NOP*((length-len(stub))//4)
            assert old!=new,(key,"already neutralized; refuse redundant release")
            blob[offset:offset+length]=new
            targets[key]={
               "class":key[0],"selector":key[1],"signature":typ,
               "file_offset":offset,"byte_count":length,
               "before_sha256":sha(old),"after_sha256":sha(new),
               "replacement":"ABI-compatible false getter/no-op setter; original selector metadata retained",
               "state":"temporarily_disabled_native5",
               "next_after_device_pass":"Candidate to remove unused expiry-state storage/calls after static caller audit; retain ABI if needed",
            }
    assert len(targets)==2,("Expected both expired state methods",list(targets))
    return list(targets.values())

def mask_static_ui(blob:bytearray):
    changes=[]
    for seg,sec,off,length in sections(blob):
        if (seg,sec) not in {("__TEXT","__cstring"),("__TEXT","__ustring"),("__TEXT_EXEC","__cstring")}:continue
        bound=off+length
        enc="utf-16-le" if sec=="__ustring" else "utf-8"
        null=b"\x00\x00" if enc=="utf-16-le" else b"\x00"
        for label in PRESENTATION_ONLY:
            old=label.encode(enc)
            # Mask with spaces; keeps all pointers, file offsets, encodings and
            # original terminators. This *hides*, not deletes from source.
            new=" "*len(label)
            replacement=new.encode(enc)
            assert len(replacement)==len(old)
            cur=off
            while True:
                idx=bytes(blob).find(old,cur,bound)
                if idx<0:break
                end=idx+len(old)
                # Match full NUL-terminated literal, never a suffix of a key,
                # Objective-C method or class name.
                prev_ok=(idx==off or blob[idx-len(null):idx]==null)
                next_ok=(end+len(null)<=bound and blob[end:end+len(null)]==null)
                if prev_ok and next_ok:
                    blob[idx:end]=replacement
                    changes.append({"file_offset":idx,"section":seg+","+sec,
                                    "label":label,"encoding":enc,"byte_count":len(old),
                                    "before_sha256":sha(old),"after_sha256":sha(replacement),
                                    "state":"temporarily_hidden_native5",
                                    "next_after_device_pass":"Candidate for physical deletion only after verifying no referenced localization/data keys"})
                cur=end
    return changes

def categorise_remaining(binary_name,metadata,hidden):
    records=[]
    targets={(item["class"],item["selector"]) for item in hidden}
    for method in metadata["license_named_methods"]:
        key=(method["class"],method["selector"])
        if key in targets:
            state="temporarily_disabled_native5"
            next_step="Check callers; decide whether to remove storage and selector after native5 device PASS"
        elif method["class"]=="CBLicenseSyncManager" and (
             method["selector"] in {"isCarPlayScreenConnected","isCarPlayScreen:",
                                    "isCarPlayScreenConnectedExcludingScreen:"}):
            state="retain_carplay_screen_detection"
            next_step="Keep until code ownership refactoring; active CarPlay screen tracking"
        elif method["selector"] in {"dealloc",".cxx_destruct","init","sharedInstance"}:
            state="retain_runtime_lifecycle"
            next_step="Do not remove until object allocation/caller graph proves dead"
        else:
            state="retained_compatibility_or_unverified"
            next_step="Investigate callers and original binary reference paths before deletion"
        records.append({"binary":binary_name,"class":method["class"],"selector":method["selector"],
                        "kind":method["kind"],"method_type":method["type_encoding"],
                        "state":state,"next_step":next_step})
    return records

def preserve_entitlements_and_resign(file:Path,before:bytes,work:Path,key:str):
    old=work/(key+"-before.dylib")
    old.write_bytes(before)
    probe=subprocess.run(["ldid","-e",str(old)],capture_output=True)
    if probe.returncode==0 and b"<plist" in probe.stdout:
        ent=work/(key+"-entitlements.xml")
        ent.write_bytes(probe.stdout)
        cmd("ldid","-S"+str(ent),file)
        return "reused_prior_entitlements"
    cmd("ldid","-S",file)
    return "no_embedded_entitlements_found"

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--out",type=Path,required=True)
    parser.add_argument("--report",type=Path,required=True)
    parser.add_argument("--deletion-list",type=Path,required=True)
    args=parser.parse_args()
    assert sha(BASE.read_bytes())==EXPECTED,"Do not build from unknown native4 DEB"
    with tempfile.TemporaryDirectory(prefix="duoface-native5-") as work:
        staging=Path(work)/"stage"
        cmd("dpkg-deb","-R",BASE,staging)
        original={p.relative_to(staging).as_posix():sha(p.read_bytes())
                  for p in staging.rglob("*") if p.is_file() and not p.is_symlink()}
        payload={}
        todo=[]
        all_hidden=0
        for name,rel in FILES.items():
            file=staging/rel
            before=file.read_bytes()
            data=bytearray(before)
            hidden=replace_expired_flags(data) if name=="DuoFaceUI" else []
            # Scan remaining ObjC method signatures BEFORE masking data.
            all_methods=inspect(bytes(data))
            literal_masks=mask_static_ui(data)
            payload[name]={"method_flags":hidden,"masked_ui_literals":literal_masks,
                           "before_sha256":sha(before),"mask_count":len(literal_masks)}
            todo+=categorise_remaining(name,all_methods,hidden)
            all_hidden+=len(literal_masks)
            file.write_bytes(bytes(data))
            payload[name]["code_signing"]=preserve_entitlements_and_resign(file,before,Path(work),name)
            payload[name]["after_sha256"]=sha(file.read_bytes())
            assert len(file.read_bytes())>10000
            assert not hits(file.read_bytes())
        assert all_hidden>=4,("No meaningful static license UI strings found in native4",all_hidden)
        control=staging/"DEBIAN/control"
        text=control.read_text(encoding="utf-8")
        assert "Package: com.duoface.independent" in text
        assert "Version: 0.1.0~native4" in text
        control.write_text(text.replace("Version: 0.1.0~native4","Version: "+VERSION),encoding="utf-8")
        md5=[]
        for p in sorted(staging.rglob("*")):
            if p.is_file() and not p.is_symlink() and p.relative_to(staging).parts[0]!="DEBIAN":
                md5.append(hashlib.md5(p.read_bytes()).hexdigest()+"  "+p.relative_to(staging).as_posix())
        (staging/"DEBIAN/md5sums").write_text("\n".join(md5)+"\n")
        newer={p.relative_to(staging).as_posix():sha(p.read_bytes())
               for p in staging.rglob("*") if p.is_file() and not p.is_symlink()}
        changed=sorted(x for x in newer if newer[x]!=original.get(x))
        expected_paths=sorted(list(FILES.values())+["DEBIAN/control","DEBIAN/md5sums"])
        assert changed==expected_paths,(changed,expected_paths)
        assert newer.keys()==original.keys(),"Packaging must not add/remove paths"
        for k in newer:
            if k not in changed:assert original[k]==newer[k],k
        args.out.parent.mkdir(parents=True,exist_ok=True)
        cmd("dpkg-deb","--build","--root-owner-group",staging,args.out)
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Version"],text=True).strip()==VERSION
    assert subprocess.check_output(["dpkg-deb","-f",str(args.out),"Package"],text=True).strip()=="com.duoface.independent"
    ledger={
        "status":"NATIVE5_RESIDUAL_LICENSE_DELETION_LEDGER_PENDING_REAL_DEVICE_APPROVAL",
        "baseline_native4_sha256":EXPECTED,
        "all_method_inventory":todo,
        "ui_literal_hidden_records":[{"binary":k,**m} for k,v in payload.items() for m in v["masked_ui_literals"]],
        "method_hidden_records":[{"binary":k,**m} for k,v in payload.items() for m in v["method_flags"]],
        "caution":"class names, Objective-C selector strings and lifecycle logic remain for ABI; hiding text or neutralizing a method is NOT proof of full removal",
        "next_after_carplay_pass":"Audit dynamic callers/initialization and physical delete only separately verified unused code/data.",
        "device_tested":False,
    }
    result={
       "status":"NATIVE5_STAGED_EXPIRED_UI_HIDDEN_NEEDS_DEVICE_TEST",
       "package":"com.duoface.independent","version":VERSION,
       "source_native4_sha256":EXPECTED,
       "changed_paths":changed,
       "untouched_files":len(original)-len(changed),
       "new_expired_state_methods_neutralized":sum(len(v["method_flags"]) for v in payload.values()),
       "hidden_literal_count":all_hidden,
       "changed_binaries":payload,
       "zero_old_brand_matches":True,
       "remaining_license_class_and_selector_metadata":True,
       "full_license_removal":False,
       "same_native_carplay_source_and_resources":True,
       "native4_rollback_file_preserved":True,
       "device_tested":False,"sileo_published":False,
       "deb_sha256":sha(args.out.read_bytes()),"deb_size":args.out.stat().st_size,
    }
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.deletion_list.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
    args.deletion_list.write_text(json.dumps(ledger,indent=2,ensure_ascii=False)+"\n")
    print(json.dumps({k:v for k,v in result.items() if k!="changed_binaries"},ensure_ascii=False,indent=2))
if __name__=="__main__":main()
