#!/usr/bin/env python3
"""Non-invasive source coverage check; never imports private iOS APIs or modifies payloads.

Output facts are SOURCE-STATIC, never proof of device/runtime behavior.
Run from any cwd with Python 3.9+: python3 path/to/verify_admission_coverage.py --strict --output /tmp/report.json
"""
from __future__ import annotations
import argparse
import json
import plistlib
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / "sideplay"
TARGET = "com.duoface.native.scenehost"
GATE = BASE / "firstparty-carplay-admission" / "DFFirstPartyAdmission.m"
FILTER = BASE / "firstparty-carplay-admission" / "DFFirstPartyAdmission.plist"
SPRING = BASE / "springboard-admission-probe" / "DFSpringBoardAdmissionProbe.m"
HOST_INFO = BASE / "duoface-native-scene-host" / "Info.plist"
HOST_ENTITLEMENTS = BASE / "duoface-native-scene-host" / "entitlements.plist"
TYPED3 = "@40@0:8@16#24#32"
TYPED2 = "@32@0:8@16#24"
LSLOOKUP = "@24@0:8@16"
SBBOOL = "B24@0:8@16"

def audit():
    src=GATE.read_text()
    sb=SPRING.read_text()
    plist=plistlib.loads(FILTER.read_bytes())
    info=plistlib.loads(HOST_INFO.read_bytes())
    ent=plistlib.loads(HOST_ENTITLEMENTS.read_bytes())
    executables=plist["Filter"]["Executables"]
    entry=src.split("static void DFAdmissionEntry(void)",1)[1]
    arming=src.split("static void DFCheckConsentAndArm(NSString *reason)",1)[1].split("static void DFRefreshCallback",1)[0]
    guarded=src.split("static BOOL DFEligible(",1)[1].split("static id DFEntitlement3",1)[0]
    result={
      "kind":"source-static-only",
      "target":TARGET,
      "inputs":{
        "gate":str(GATE.relative_to(ROOT)),
        "inject_filter":str(FILTER.relative_to(ROOT)),
        "springboard_probe":str(SPRING.relative_to(ROOT)),
        "host_info":str(HOST_INFO.relative_to(ROOT)),
        "host_entitlements":str(HOST_ENTITLEMENTS.relative_to(ROOT))},
      "evidence":{
        "injection_executables":executables,
        "no_springboard_admission_hook":("SpringBoard" not in executables),
        "two_typed_getter_hooks_present":('hook(c,s3,(IMP)DFEntitlement3' in arming and 'hook(c,s2,(IMP)DFEntitlement2' in arming),
        "typed3_ABI_guarded":TYPED3 in arming,
        "typed2_ABI_guarded":TYPED2 in arming,
        "user_optin_per_call":'DFExplicitConsent()' in guarded,
        "allowlist_firstparty_only":TARGET in src,
        "has_expected_number_check":'expected && expected!=NSNumber.class' in guarded,
        "has_values_expected_number_check":'valuesExpected && valuesExpected!=NSNumber.class' in guarded,
        "prevents_original_non_nil_override":'if(real)return real;' in src,
        "hook_is_queued_on_main_from_constructor":'dispatch_async(dispatch_get_main_queue(), ^{DFCheckConsentAndArm(@"startup");});' in entry,
        "does_not_hook_bulk_getter":'hook(c,sel_registerName("entitlementValuesForKeys:")' not in src and '"entitlementValuesForKeys:"' not in arming,
        "does_not_hook_cached_values":'MSHookMessageEx(cached' not in src and 'LSBundleInfoCachedValues' not in src,
        "does_not_log_all_getter_invocations":('DFLog' not in src.split("static id DFEntitlement3",1)[1].split("id real=DFOriginal3",1)[0]),
        "sb_only_abi_inventory":'Read method type encodings ONLY' in sb and 'DFReadOnlyInventory' in sb and 'MSHookMessageEx' not in sb,
        "sb_bool_encoding_from_device_not_source":SBBOOL,
        "carplay_ls_lookup_encoding_from_device_not_source":LSLOOKUP,
        "host_has_carplay_window_role":'UIWindowSceneSessionRoleCarPlay' in info["UIApplicationSceneManifest"]["UISceneConfigurations"],
        "host_declared_bundle_id":info.get("CFBundleIdentifier"),
        "host_entitlement_keys":sorted(ent),
        "host_has_apple_category_entitlement":any(k.startswith("com.apple.developer.carplay-") for k in ent),
      },
      "runtime_unknown":[
        "process_hosting_DashBoard_in_this_exact_build",
        "typed3_key_and_class_arguments_on_real_inclusion_pass",
        "original_typed3_return_type_and_value",
        "whether_roster_filter_invoked_before_hook_installed",
        "SpringBoard_cached_values_origin_identity_and_actual_return",
        "real_DashBoard_filtered_roster_membership",
        "native_host_scene_issued_by_system"
      ]
    }
    checks={
      "firstparty_bundle_consistent":result["evidence"]["host_declared_bundle_id"]==TARGET,
      "filter_only_CarPlay":executables==["CarPlay"],
      "both_abi_guards_present":result["evidence"]["typed3_ABI_guarded"] and result["evidence"]["typed2_ABI_guarded"],
      "two_getters_hooked":result["evidence"]["two_typed_getter_hooks_present"],
      "sb_readonly":result["evidence"]["sb_only_abi_inventory"],
      "role_declared":result["evidence"]["host_has_carplay_window_role"],
      "permission_per_call":result["evidence"]["user_optin_per_call"],
      "no_new_springboard_hook":result["evidence"]["no_springboard_admission_hook"],
      "original_preserved":result["evidence"]["prevents_original_non_nil_override"],
    }
    result["static_checks"]=checks
    result["result"]="PASS_SOURCE_STATIC" if all(checks.values()) else "FAIL_SOURCE_DRIFT"
    result["device_tested_by_this_script"]=False
    result["source_changed_by_this_script"]=False
    return result

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--strict",action="store_true",help="fail if expectations drift")
    parser.add_argument("--output",type=Path,help="JSON report path; must be an audit/report path, not app payload")
    args=parser.parse_args()
    result=audit()
    output=json.dumps(result,ensure_ascii=False,indent=2,sort_keys=True)+"\n"
    if args.output:
        name=str(args.output.resolve())
        if any(x in name for x in ("DynamicLibraries","Applications",".github/workflows")):
            raise SystemExit("Refusing executable/workflow output location")
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.write_text(output)
    else:
        print(output)
    if args.strict and result["result"]!="PASS_SOURCE_STATIC":
        print("STATIC_GATES_FAILED",file=sys.stderr)
        return 2
    return 0
if __name__=="__main__":raise SystemExit(main())
