#!/usr/bin/env python3
"""Check actual user iOS16.7.16 Log22 Dashboard ABI before adopting open-source examples."""
import argparse,hashlib,json,pathlib,re
BLOB="4a80d75f6bb831b00be8b5d2075aa9d76d7f99d0"
SIZE=6611528
EXPECTED={
 "-[DBDashboardHomeViewController iconManager:launchIconForIconView:]":"v32@0:8@16@24",
 "-[DBWorkspace initWithOwner:]":"@24@0:8@16",
 "-[DBWorkspace requestStateChange:]":"v24@0:8@16",
 "-[DBWorkspace state]":"@16@0:8",
 "+[DBApplicationController sharedInstance]":"absent",
 "-[DBApplicationController applicationWithBundleIdentifier:]":"absent",
 "-[DBWorkspaceState activeBundleIdentifier]":"absent",
}
def main():
 ap=argparse.ArgumentParser()
 ap.add_argument("--log",type=pathlib.Path,required=True)
 ap.add_argument("--output",type=pathlib.Path,required=True)
 a=ap.parse_args()
 raw=a.log.read_bytes()
 blob=hashlib.sha1(("blob %d\0"%len(raw)).encode()+raw).hexdigest()
 assert len(raw)==SIZE and blob==BLOB,(len(raw),blob)
 s=raw.decode("utf-8","replace")
 sec=re.search(r"^=== DuoFaceHomeLaunch142\.log[^\n]*\n(.*?)(?=^=== |\Z)",s,re.M|re.S)
 if not sec:raise ValueError("Missing exact device HomeLaunch142 log section")
 log=sec.group(1)
 observed={}
 for ln in log.splitlines():
  m=re.search(r"method=(.+?) types=(\S+)",ln)
  if m:observed[m.group(1)]=m.group(2)
 checks={}
 for method,ty in EXPECTED.items():
  got=observed.get(method)
  if got!=ty:raise AssertionError("actual live ABI changed "+method+" expected "+ty+" got "+str(got))
  checks[method]={"type_encoding":got,"present":got!="absent"}
 report={"source":"actual iPhone X iOS16.7.16 Log22; main commit ce436ddb04e62d1762531a97ad74e21d3354a34d",
  "source_blob":blob,"source_sha256":hashlib.sha256(raw).hexdigest(),
  "measured_methods":checks,
  "full_native_home142_abi_inventory":observed,
  "native_home142_section_line_count":len(log.splitlines()),
  "carplay_native_workspace_methods_present":True,
  "carsurf_diagnostic_controller_sharedInstance_missing_on_this_capture":True,
  "carsurf_diagnostic_activeBundleIdentifier_missing_on_this_capture":True,
  "result":"CANNOT_PORT_OTHER_IOS_VERSION_PRIVATE_LAUNCH_ABI_WITHOUT_MEASURING_REAL_OWNER",
  "does_not_prove":"Class/method probe absence can depend on class loading/time/process; no runtime activation has been tested"}
 a.output.parent.mkdir(parents=True,exist_ok=True)
 a.output.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
 print("LOG22_NATIVE_ABI_METHODS_CONFIRMED",len(checks))
 for k,v in checks.items():print("OBSERVED_ABI",k,v["type_encoding"])
 print("LOG22_CARSURF_WORKSPACE_EXAMPLE_NOT_DROP_IN_ON_THIS_IOS_CAPTURE")
if __name__=="__main__":main()
