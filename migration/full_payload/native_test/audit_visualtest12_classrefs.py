#!/usr/bin/env python3
"""Read-only VisualTest12 ObjC dependency census. Never patch or ship licensing code."""
import hashlib,json,pathlib,re,subprocess,tempfile,argparse
from audit_native12_license_class_xrefs import MachO,select_arm64,BINARIES
SOURCE=pathlib.Path("dist/visual-1.0.3-12/com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb")
PIN="8b7dedf77b9ec05465b83fdb6e2d7127800eac232a34ecf12f2c08b3983a481a"
EXPR=re.compile("license|subscription|trial|lease|activat|expir|redeem|giftcode|vip",re.I)
def inspect(raw):
    m=MachO(select_arm64(raw)); cls=m.classes()
    selected=[]
    for name,value in cls.items():
        if not EXPR.search(name):continue
        refs=m.class_pointer_refs(value["class_ptr"])
        children=[n for n,c in cls.items() if n!=name and c["superclass_ptr"]==value["class_ptr"]]
        selected.append({
          "class":name,"method_count":len(value["methods"]),
          "direct_refs":[r for r in refs if r["role"]!="class_registration"],
          "subclass_dependents":children,
          "same_named_selectors_elsewhere":sorted({
             x[1:] for x in value["methods"] for c in cls.values()
             if c is not value and x in c["methods"]}),
          "runtime_dispatch_still_unknown":True})
    return {"sha256":hashlib.sha256(raw).hexdigest(),
            "objc_class_count":len(cls),"license_named_class_count":len(selected),
            "license_related_classes":selected,
            "total_non_registration_refs":sum(len(x["direct_refs"]) for x in selected),
            "direct_refs_absence_is_not_dynamic_liveness_proof":True}
def main():
    p=argparse.ArgumentParser();p.add_argument("--out",type=pathlib.Path,required=True);a=p.parse_args()
    assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==PIN,"VisualTest baseline changed"
    assert subprocess.check_output(["dpkg-deb","-f",str(SOURCE),"Package"],text=True).strip()=="com.duonavi.app"
    with tempfile.TemporaryDirectory(prefix="visutest12-refs-") as td:
        subprocess.run(["dpkg-deb","-x",str(SOURCE),td],check=True)
        out={n:inspect((pathlib.Path(td)/rel).read_bytes()) for n,rel in BINARIES.items()}
    assert out["DuoFaceUI"]["license_named_class_count"]>=13
    assert out["DuoFaceDashboard"]["license_named_class_count"]>=3
    result={"status":"VISUALTEST12_CLASSREF_READONLY_PASS","package":"com.duonavi.app",
      "version":"1.0.3-12~visualtest","source_deb_sha256":PIN,
      "binaries":out,"did_patch_binary":False,"did_build_deb":False,
      "hub_touched":False,"sileo_updated":False,"license_removed":False,
      "objc_dynamic_dispatch_proven_absent":False}
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n")
    for n,v in out.items():print(n,"classes",v["license_named_class_count"],"direct_refs",v["total_non_registration_refs"])
    print("VISUALTEST12_CLASSREF_READONLY_PASS")
if __name__=="__main__":main()
