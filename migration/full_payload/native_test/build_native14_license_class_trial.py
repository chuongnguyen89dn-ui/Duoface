#!/usr/bin/env python3
"""Physical trial excision of 14 orphan license/subscription ObjC class records.
Experimental DEVICE-TEST CANDIDATE, not proof of runtime liveness or FULL
license-removal. Input is native13 with two features; native12 stays immutable.
"""
import argparse,hashlib,json,os,pathlib,subprocess,tempfile
from audit_native12_license_class_xrefs import MachO,select_arm64,BINARIES
ROOT=pathlib.Path(__file__).resolve().parents[3]
BASE=ROOT/"dist/payload-migration/native13/com.duoface.independent_0.1.0~native13_iphoneos-arm64.deb"
BASE_SHA="cff76573be10a73bfd423e988b803812e3375af4db6567a9229c1b04156f2cf3"
AUDIT=ROOT/"audit/payload-migration/NATIVE12_ACTUAL_LICENSE_CLASS_XREFS.json"
SOURCE=ROOT/"audit/payload-migration/NATIVE12_LICENSE_XREF_CALLSITE_OWNERS.json"
VERSION="0.1.0~native14"
def sha(b):return hashlib.sha256(b).hexdigest()
def run(*a):
 p=subprocess.run(a,text=True,capture_output=True)
 if p.returncode:raise RuntimeError(f"{a}: {p.stdout[-1000:]} {p.stderr[-2000:]}")
 return p.stdout
def patch_host(original,classes):
 m=MachO(select_arm64(original));out=bytearray(original)
 original_class_names=set(m.classes())
 if len(classes) not in (2,12):raise ValueError("Unexpected proposed count")
 done=[];used=set()
 for item in classes:
  name=item["class"]; pointer=int(item["class_ptr"],16)
  assert name in original_class_names,(name,"original class missing")
  assert not item["safe_to_delete"],"Audit marks this unproven dynamic liveness"
  assert len(item["pointer_references"])==3
  actual_roles={p["role"] for p in item["pointer_references"]}
  assert actual_roles=={"class_registration","direct_reference"}
  for p in item["pointer_references"]:
   off=p["fileoff"]
   assert 0<off<len(out)-8 and off not in used
   assert int.from_bytes(out[off:off+8],"little")==pointer,(name,off,"pointer mismatch")
   out[off:off+8]=b"\x00"*8
   used.add(off)
  seen=0
  for pos in item["literal_file_offsets"]:
   expected=name.encode("ascii")
   assert out[pos:pos+len(expected)+1]==expected+b"\x00",(name,pos)
   out[pos:pos+len(expected)]=b"\x00"*len(expected)
   seen+=1
  # The former xref report lists class-name metadata literals but does not
  # claim the list is complete. Only erase additional NUL-terminated literal
  # occurrences if independently verified inside a non-instruction string
  # section. Never alter __text, method instructions, or arbitrary binary data.
  extra=[]
  needle=name.encode("ascii")
  for sec in m.sections:
   if sec["name"] not in ("__cstring","__objc_classname","__objc_methname"):
    continue
   off=sec["fileoff"]; end=off+sec["size"]
   cursor=off
   while True:
    pos=out.find(needle,cursor,end)
    if pos<0:break
    cursor=pos+len(needle)
    if pos+len(needle)>=end or out[pos+len(needle)]!=0:
     raise ValueError((name,pos,"non terminated extra, refuse unsafe erase"))
    if pos>off and out[pos-1] not in (0,32,34,64,91):
     raise ValueError((name,pos,"embedded name, refuse unsafe erase"))
    out[pos:pos+len(needle)]=b"\x00"*len(needle)
    extra.append({"file_offset":pos,"section":sec["name"]})
  done.append({"class":name,"registry_and_ref_slots_zeroed":3,
               "name_literals_zeroed":seen+len(extra),"extra_validated_literals":extra,
               "method_records_persist_in_unregistered_metadata":item["method_count"]})
 result=bytes(out)
 after=MachO(select_arm64(result))
 actual=set(after.classes())
 assert not set(item["class"] for item in classes)&actual
 assert actual==original_class_names-set(item["class"] for item in classes)
 for item in classes:
  assert item["class"].encode("ascii") not in result,(item["class"],"remaining literal")
 for s in m.sections:
  if s["name"]=="__text":
   assert original[s["fileoff"]:s["fileoff"]+s["size"]]==result[s["fileoff"]:s["fileoff"]+s["size"]]
 return result,done,len(original_class_names),len(actual)
def md5list(stage):
 out=[]
 for f in sorted(stage.rglob("*")):
  if f.is_file() and not f.is_symlink() and f.relative_to(stage).parts[0]!="DEBIAN":
   out.append(f"{hashlib.md5(f.read_bytes()).hexdigest()}  {f.relative_to(stage).as_posix()}")
 return "\n".join(out)+"\n"
def main():
 ap=argparse.ArgumentParser()
 ap.add_argument("--out",type=pathlib.Path,required=True)
 ap.add_argument("--report",type=pathlib.Path,required=True)
 a=ap.parse_args()
 assert sha(BASE.read_bytes())==BASE_SHA,(sha(BASE.read_bytes()),"pin native13")
 assert not a.out.exists()
 report=json.loads(AUDIT.read_text())
 assert report["candidates_checked"]==14 and not report["physical_excision_completed"]
 owners=json.loads(SOURCE.read_text())
 assert owners["status"]=="NATIVE12_LICENSE_CLASSREF_CALLSITE_OWNERS_READONLY"
 # 3 direct ARM64 references are in ONE previously neutralized ObjC method.
 links=owners["binaries"]["DuoFaceUI"]["xref_owners"]
 assert len(links)==3
 assert {p["method_owner"]["method"] for p in links}=={"-checkAndPresentLicenseModalIfNeeded"}
 assert {p["method_owner"]["class"] for p in links}=={"XXRootViewController"}
 assert owners["binaries"]["DuoFaceDashboard"]["xref_owners"]==[]
 with tempfile.TemporaryDirectory(prefix="duoface-native14-license-class-excision-") as tmp:
  root=pathlib.Path(tmp)/"unpack"
  run("dpkg-deb","-R",str(BASE),str(root))
  beforeControl=(root/"DEBIAN/control").read_text()
  assert "Version: 0.1.0~native13" in beforeControl
  details={};changed=set()
  for bin,path in BINARIES.items():
   target=root/path
   raw=target.read_bytes()
   old_sig=run("ldid","-e",str(target)).strip()
   patched,classes,oldcount,newcount=patch_host(raw,report["binaries"][bin]["candidate_classes"])
   target.write_bytes(patched)
   # Preserve every original entitlement if present; never downgrade privileges.
   if old_sig.startswith("<?xml") or "<plist" in old_sig:
    ent=pathlib.Path(tmp)/(bin+".entitlements")
    ent.write_text(old_sig)
    run("ldid","-S"+str(ent),str(target))
   elif not old_sig:
    run("ldid","-S",str(target))
   else:
    raise RuntimeError("unrecognized entitlement output for "+bin)
   # Resigning may resize LC_CODE_SIGNATURE but must not change class/object code.
   m=MachO(select_arm64(target.read_bytes()))
   assert len(m.classes())==newcount
   details[bin]={"before_registered_classes":oldcount,"after_registered_classes":newcount,
                 "removed_classes":classes,"host_sha256":sha(target.read_bytes()),
                 "signed":True,"all_original_text_instructions_unchanged_pre_signature":True}
   changed.add(path)
  (root/"DEBIAN/control").write_text(beforeControl.replace("Version: 0.1.0~native13",
                                                            "Version: "+VERSION,1))
  (root/"DEBIAN/md5sums").write_text(md5list(root))
  a.out.parent.mkdir(parents=True,exist_ok=True)
  run("dpkg-deb","--build","--root-owner-group",str(root),str(a.out))
  assert run("dpkg-deb","-f",str(a.out),"Version").strip()==VERSION
  result={
    "status":"NATIVE14_EXPERIMENTAL_14_LICENSE_CLASSES_UNREGISTERED_AND_NAMES_ERASED",
    "package":"com.duoface.independent","version":VERSION,
    "base_native13_sha256":BASE_SHA,"deb_sha256":sha(a.out.read_bytes()),
    "isolated_license_classes_removed_from_objc_registration":sum(
      len(z["removed_classes"]) for z in details.values()),
    "class_registration_and_ref_pointer_slots_zeroed":42,
    "license_class_name_literal_copies_erased":sum(
      z["name_literals_zeroed"] for b in details.values() for z in b["removed_classes"]),
    "remaining_method_metadata_and_shared_license_literals_may_exist":True,
    "all_license_related_code_physically_removed":False,
    "dynamic_runtime_safety_proven":False,
    "remaining_8_carplay_methods_preserved_code_sections":True,
    "license_xref_calls_are_in_previously_neutralized_entry_method":True,
    "source_code_instruction_changes":False,
    "host_modified_paths":sorted(changed),
    "binaries":details,
    "sileo_deployed":False,"device_tested":False,
    "experimental_only_do_not_claim_full_license_cleanup":True
  }
  a.report.parent.mkdir(parents=True,exist_ok=True)
  a.report.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
  print(json.dumps({k:v for k,v in result.items() if k!="binaries"},indent=2))
if __name__=="__main__":main()
