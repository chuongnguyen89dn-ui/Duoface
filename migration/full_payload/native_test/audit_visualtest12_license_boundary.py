#!/usr/bin/env python3
"""VisualTest12 vs Native12 exact-host license boundary (read-only; NEVER publishes).
The original VisualTest package carries unmodified compiled application code.
Assess feasibility of license-free rebuild, without mistaking UI/preference changes
for verified removal of actual runtime license dependencies.
"""
import argparse, hashlib, json, pathlib, plistlib, re, subprocess, tempfile
from audit_native12_license_class_xrefs import MachO,select_arm64,BINARIES,NATIVE12_SHA
from audit_native12_carplay_add_app_chain import methods

VISUAL_SHA="8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
SELECTORS={
 "DuoFaceUI":{
  "CBLicenseSyncManager":["-isLicenseCurrentlyValid","-remainingLicenseSeconds","-actualLicenseExpirationTimestamp","-checkAndSyncLicenseIfNeeded"],
  "XXRootViewController":["-checkAndPresentLicenseModalIfNeeded"],
 },
 "DuoFaceDashboard":{
  "CBLicenseSyncManager":["-isLicenseCurrentlyValid","-remainingLicenseSeconds","-actualLicenseExpirationTimestamp","-checkAndSyncLicenseIfNeeded"],
  "CBBridgeManager":["-requestStateChange:","-loadNewAppFromCurrentRequest:","-shouldBridge:","-syncDashboardPolicySignalToDisk"],
  "CBBridgeManagerDashboard":["+isDashboardPolicySignalActive","+shouldInterceptLaunchForApp:","+requestActivation:"]
 }
}
LIC_RE=re.compile(r"license|subscription|trial|lease|activation|expire|expir|redeem|giftcode|vip|premium|subscript",re.I)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def shell(*cmd):return subprocess.check_output([str(x) for x in cmd],text=True).strip()
def inspect(raw):
    m=MachO(select_arm64(raw))
    cls=m.classes()
    class_rows=[]
    for name,info in cls.items():
        if LIC_RE.search(name):
            class_rows.append({"class":name,"methods":len(info["methods"]),
                "embedded_in_core":True,"other_runtime_references_not_resolved":True})
    method_rows=[]
    for owner,info in cls.items():
        for method in info["methods"]:
            if LIC_RE.search(method):
                method_rows.append({"class":owner,"selector":method})
    return m,cls,class_rows,method_rows

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--visual",type=pathlib.Path,required=True)
    p.add_argument("--native12",type=pathlib.Path,required=True)
    p.add_argument("--out",type=pathlib.Path,required=True)
    a=p.parse_args()
    assert digest(a.visual)==VISUAL_SHA,"VisualTest12 original SHA incorrect"
    assert digest(a.native12)==NATIVE12_SHA,"Hub Native12 baseline changed"
    assert shell("dpkg-deb","-f",a.visual,"Package")=="com.duonavi.app"
    assert shell("dpkg-deb","-f",a.visual,"Version")=="1.0.3-12~visualtest"
    assert shell("dpkg-deb","-f",a.native12,"Package")=="com.duoface.independent"
    with tempfile.TemporaryDirectory(prefix="df12-visual-license-") as tmp:
        origin=pathlib.Path(tmp)/"visual"
        rebuilt=pathlib.Path(tmp)/"native12"
        subprocess.run(["dpkg-deb","-x",str(a.visual),str(origin)],check=True)
        subprocess.run(["dpkg-deb","-x",str(a.native12),str(rebuilt)],check=True)
        report={}
        for binary,relative in BINARIES.items():
            before=(origin/relative).read_bytes()
            after=(rebuilt/relative).read_bytes()
            original_m,original_classes,license_classes,license_methods=inspect(before)
            native_m,native_classes,_,_=inspect(after)
            tracked={}
            for cl,sels in SELECTORS[binary].items():
                if cl not in original_classes or cl not in native_classes:
                    tracked[cl]={"error":"missing_in_one_core"}
                    continue
                o=methods(original_m,cl)
                n=methods(native_m,cl)
                entries={}
                for sel in sels:
                    for tag,c,m in [("visual",o,original_m),("native12",n,native_m)]:
                        if sel not in c:
                            entries.setdefault(sel,{})[tag]={"exists":False}
                            continue
                        imp=c[sel]["vm"]
                        offset=m.map(imp)
                        raw=m.data[offset:offset+16]
                        is_bool1=raw.startswith(bytes.fromhex("20008052c0035fd6"))
                        entries.setdefault(sel,{})[tag]={
                            "exists":True,"impl_address":hex(imp),
                            "method_type":c[sel]["type"],"first_16_bytes":raw.hex(),
                            "returns_const_TRUE":is_bool1 if sel=="-isLicenseCurrentlyValid" else None
                        }
                tracked[cl]=entries
            report[binary]={
                "visualtest_host_sha256":hashlib.sha256(before).hexdigest(),
                "native12_host_sha256":hashlib.sha256(after).hexdigest(),
                "same_host_bytes":before==after,
                "visualtest_host_size":len(before),
                "native12_host_size":len(after),
                "visualtest_objc_classes":len(original_classes),
                "native12_objc_classes":len(native_classes),
                "visualtest_embedded_license_related_classes":license_classes,
                "visualtest_license_named_selectors":license_methods,
                "selected_host_method_comparison":tracked,
                "class_and_dynamic_dispatch_removal_proven_safe":False,
            }
        sync=origin/"var/mobile/Library/Preferences/com.duonavi.sync.plist"
        prefs=plistlib.loads(sync.read_bytes()) if sync.is_file() else {}
    assert report["DuoFaceUI"]["visualtest_host_sha256"]
    assert report["DuoFaceDashboard"]["visualtest_host_sha256"]
    results={
     "status":"VISUALTEST12_EXACT_BINARY_LICENSE_INVENTORY_ONLY",
     "visual_deb_sha256":VISUAL_SHA,
     "visual_package_id":"com.duonavi.app",
     "visual_version":"1.0.3-12~visualtest",
     "hub_native12_sha256_untouched":NATIVE12_SHA,
     "hub_package_id":"com.duoface.independent",
     "visualtest_sync_preference_values":{k:(v if isinstance(v,(int,float,bool)) else "<string>")
                                           for k,v in prefs.items() if isinstance(k,str)},
     "visutest_original_core_modified_by_this_audit":False,
     "license_runtime_fully_removed":False,
     "device_carplay_launch_test_passed":False,
     "sileo_updated":False,
     "reason_not_releasing":"Need to remove all licensing dependencies from VisualTest12 core, not just expiry preference/UI; no validated source-equivalent rebuild or runtime test yet",
     "host_binaries":report
    }
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(results,ensure_ascii=False,indent=2)+"\n")
    print("VISUALTEST12_LICENSE_INVENTORY_STATIC_PASS")
    for binary,data in report.items():
        print(binary,"native_vs_visual_same",data["same_host_bytes"],
              "license_classes",len(data["visualtest_embedded_license_related_classes"]),
              "license_selectors",len(data["visualtest_license_named_selectors"]))
        print("VISUALTEST_SHA",data["visualtest_host_sha256"],"NATIVE12_SHA",data["native12_host_sha256"])
    print("NOT PUBLISHED — preserve Hub Native12 unchanged")
if __name__=="__main__":main()
