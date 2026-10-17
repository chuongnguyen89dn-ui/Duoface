#!/usr/bin/env python3
"""Read-only Native12 gate audit. Do not modify license, CarPlay binary or build DEB.

The goal is to TEST user hypothesis "trial expired" against known on-device
symptoms without inferring licensing from retained ObjC selector/class names.
"""
import argparse, hashlib, json, pathlib, subprocess, tempfile
from audit_native12_license_class_xrefs import MachO,select_arm64,BINARIES,NATIVE12_SHA
from audit_native12_carplay_add_app_chain import methods,disassemble

TARGETS = {
 "DuoFaceDashboard": {
  "CBLicenseSyncManager": ["-isLicenseCurrentlyValid","-remainingLicenseSeconds",
                            "-actualLicenseExpirationTimestamp","-checkAndSyncLicenseIfNeeded"],
  "CBBridgeManagerDashboard": ["+isDashboardPolicySignalActive","+isBridgedApp:",
                                  "+shouldInterceptLaunchForApp:",
                                  "-requestActivation:","-requestStateChange:",
                                  "-handleSBStateChange:","-handleDockIconTap:"],
  "CBBridgeManager": ["-syncDashboardPolicySignalToDisk",
                       "-requestStateChange:","-requestStateChangeWithDictionary:",
                       "-receivedStateChangeRequestNotificiation:",
                       "-receivedAppRequestNotification:",
                       "-loadNewAppFromCurrentRequest:","-shouldBridge:"]
 },
 "DuoFaceUI": {
  "CBLicenseSyncManager": ["-isLicenseCurrentlyValid","-remainingLicenseSeconds",
                           "-actualLicenseExpirationTimestamp"]
 }
}
OBSERVED = {
 "uploaded_DIAG3_policy_signal_all_false":27,
 "uploaded_DIAG3_unofficial_app_requests_intercepted":8,
 "uploaded_DIAG3_window_created":False,
 "user_reports_iPhoneX_trial_expired_morning_2026_10_17":True,
 "user_reports_iPhone8Plus_trial_not_expired":True,
 "user_reports_adjusting_1800_days_does_not_restore":True
}
def audit(binary,data):
    m=MachO(select_arm64(data));out={}
    for cls,selectors in TARGETS[binary].items():
        all_methods=methods(m,cls)
        sorted_vm=sorted({rec["vm"] for rec in all_methods.values() if rec["vm"]})
        entries={}
        for selector in selectors:
            if selector not in all_methods:
                entries[selector]={"exists":False,"warning":"selector missing on pinned binary"}
                continue
            rec=all_methods[selector]
            start=rec["vm"]
            limit=next((v for v in sorted_vm if v>start),start+2500)
            end=min(limit,start+2500)
            trace=disassemble(m,start,end)
            prefix=m.data[m.map(start):m.map(start)+20].hex()
            entries[selector]={
                "exists":True,"vm":hex(start),"signature":rec["type"],
                "prefix_hex_first_20_bytes":prefix,
                "bounded_disassembly":trace[:260],
                "candidate_string_or_selector_refs":[x for x in trace
                    if "SEL_OR_LITERAL" in x or "DIRECT_STRING" in x][:75],
                "bounds_are_static_not_runtime_caller_proof":True,
            }
            if selector.endswith("isLicenseCurrentlyValid"):
                entries[selector]["abi_stored_boolean_one_pattern"]=prefix.startswith("20008052c0035fd6")
            if selector.endswith("remainingLicenseSeconds") or selector.endswith("actualLicenseExpirationTimestamp"):
                entries[selector]["returns_fixed_uint32_ffff"]=prefix.startswith("e0ff9fd2")
        out[cls]=entries
    return {"sha256":hashlib.sha256(data).hexdigest(),"classes":out}
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--deb",type=pathlib.Path,required=True)
    ap.add_argument("--out",type=pathlib.Path,required=True)
    args=ap.parse_args()
    if hashlib.sha256(args.deb.read_bytes()).hexdigest()!=NATIVE12_SHA:
        raise SystemExit("Pinned native12 DEB hash changed; abort")
    with tempfile.TemporaryDirectory(prefix="duoface-lic-gate-readonly-") as td:
        subprocess.run(["dpkg-deb","-x",str(args.deb),td],check=True)
        binaries={name:audit(name,(pathlib.Path(td)/path).read_bytes())
                  for name,path in BINARIES.items()}
    v=binaries["DuoFaceDashboard"]["classes"]["CBLicenseSyncManager"]
    app=binaries["DuoFaceUI"]["classes"]["CBLicenseSyncManager"]
    for source in (v,app):
        assert source["-isLicenseCurrentlyValid"]["abi_stored_boolean_one_pattern"], "License validity stub is not BOOL YES"
    signal=binaries["DuoFaceDashboard"]["classes"]["CBBridgeManagerDashboard"]["+isDashboardPolicySignalActive"]
    assert signal["exists"]
    out={
        "status":"NATIVE12_LICENSE_AND_CARPLAY_POLICY_GATE_BINARY_FORENSICS_READONLY",
        "input_native12_sha256":NATIVE12_SHA,
        "observed_user_and_DIAG3_evidence":OBSERVED,
        "binary_changes":False,"build_deb":False,"device_tested_this_run":False,
        "license_expiry_cause_proven":False,
        "static_direct_call_graph_fully_resolved":False,
        "license_remaining_original_classnames_do_not_prove_runtime_license_check":True,
        "binaries":binaries
    }
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(out,indent=2,ensure_ascii=False)+"\n")
    print("NATIVE12_LICENSE_GATE_BOUNDED_READONLY_PASS")
    for binary,bb in binaries.items():
        for cls,entries in bb["classes"].items():
            for selector,details in entries.items():
                if not details["exists"]:print("MISSING",binary,cls,selector);continue
                instr=details["bounded_disassembly"]
                refs=details["candidate_string_or_selector_refs"]
                print("METHOD",binary,cls,selector,details["vm"],details["signature"],
                    "prefix",details["prefix_hex_first_20_bytes"][:24],
                    "instructions",len(instr),"refs",refs[:7])
if __name__=="__main__":main()
