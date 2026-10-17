#!/usr/bin/env python3
"""Static activation and notification forensic of original GOFAHUD 0.3.1 rootless DEB.

Reads original signed package, no installation, no modification of package.
"""
import argparse
import hashlib
import json
import pathlib
import plistlib
import re
import subprocess
import tempfile

PIN = "62d6d818384844591217d74ab446404637127752e1b23bc1f9754ef1da297ad5"
SIGNALS = (
    "local.gofahud.gofa.foreground",
    "local.gofahud.carplay.gofa-active",
    "local.gofahud.carplay.enabled",
    "local.gofahud.carplay.show",
    "local.gofahud.carplay.open-gofa",
    "local.gofahud.carplay.global",
    "local.gofahud.carplay.trace",
    "local.gofahud.source.ready",
    "local.gofahud.background.carplay",
    "local.gofahud.background.phone",
    "local.gofahud.background.permission",
    "local.gofahud.background.location-session",
    "local.gofahud.background.location-source",
)
TOKENS = (
    "autoWake", "autoExit", "carEnabled", "bubbleEnabled",
    "UIApplicationDidBecomeActiveNotification",
    "UIApplicationWillResignActiveNotification",
    "UIApplicationDidEnterBackgroundNotification",
    "UIApplicationWillTerminateNotification",
    "UIScreenDidConnectNotification",
    "_currentDashboard", "activeBundleIdentifier",
    "notify_register_check", "notify_register_dispatch",
    "notify_set_state", "notify_post",
    "__ActivateSuspended", "openApplication:withOptions:completion:",
    "GOFACarHUDSetGOFAActive", "GOFACarHUDRefresh",
    "GOFAHUDEnabled", "GOFAHUDProducerName",
    "CARNotificationWindow", "GOFACarGlobalWindow",
)

def run(*args):
    return subprocess.run(args, capture_output=True, text=True, check=True).stdout

def report(deb):
    digest=hashlib.sha256(deb.read_bytes()).hexdigest()
    assert digest==PIN, f"SHA256 mismatch: {digest}"
    with tempfile.TemporaryDirectory(prefix="duoface-gofahud031-activation-") as d:
        root=pathlib.Path(d)/"payload"
        control=pathlib.Path(d)/"ctrl"
        root.mkdir()
        control.mkdir()
        run("dpkg-deb", "-x", str(deb), str(root))
        run("dpkg-deb", "-e", str(deb), str(control))
        package=run("dpkg-deb", "-f", str(deb), "Package").strip()
        version=run("dpkg-deb", "-f", str(deb), "Version").strip()
        assert (package,version)==("local.gofahud","0.3.1")
        out={"status":"GOFAHUD_031_REAL_DEB_ACTIVATION_SIGNALS_STATIC_PASS",
             "source_deb":"manhtien9x/gofahud-repo v0.3.1-1 GOFAHUD-0.3.1-rootless.deb",
             "sha256":PIN,"package":package,"version":version,
             "binary_extracted":True,"runtime_device_tested":False,
             "signals":{},"dylibs":{},"filters":{},"maintainer_activation":{}}
        for path in sorted(root.rglob("*")):
            if not path.is_file():
                continue
            rel=str(path.relative_to(root))
            if "/MobileSubstrate/DynamicLibraries/" not in rel:
                continue
            if path.suffix==".plist":
                raw=path.read_bytes()
                if raw.startswith(b"bplist00") or raw.startswith(b"<?xml"):
                    obj=plistlib.loads(raw)
                    out["filters"][path.name]=obj.get("Filter",{})
                else:
                    out["filters"][path.name]={
                        "source":raw.decode("utf-8","replace"),
                        "bundles":sorted(set(re.findall(r"com\.[\w.]+",raw.decode("utf-8","replace"))))}
            if path.suffix!=".dylib":
                continue
            lines=set(run("strings","-a",str(path)).splitlines())
            relevant=sorted(s for s in lines if any(x in s for x in SIGNALS+TOKENS))
            out["dylibs"][path.name]={
                "sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
                "byte_length":path.stat().st_size,
                "match_strings":relevant[:220],
            }
        for s in SIGNALS:
            out["signals"][s]=sorted(k for k,v in out["dylibs"].items()
                  if any(s in line for line in v["match_strings"]))
        out["maintainer_activation"]["postinst_signals"]={
            "load_daemons": sorted(set(re.findall(r"local\.gofahud\.[\w-]+", (control/"postinst").read_text(errors="replace")))),
            "respring_and_reopen_Gofa_instruction": "reopen GOFA" in (control/"postinst").read_text(errors="replace"),
        }
        assert len(out["dylibs"])==6 and len(out["filters"])==6, "unexpected actual DEB layout"
        assert "GofaCarplayGlobal.dylib" in out["dylibs"]
        assert "GofaLifecycle.dylib" in out["dylibs"]
        assert "GofaPhoneOverlay.dylib" in out["dylibs"]
        assert "local.gofahud.gofa.foreground" in " ".join(out["dylibs"]["GofaLifecycle.dylib"]["match_strings"])
        for key in ("local.gofahud.carplay.gofa-active","local.gofahud.carplay.enabled","local.gofahud.carplay.show"):
            assert "GofaCarplayGlobal.dylib" in out["signals"][key], f"{key}: missing in global dylib"
        assert "com.apple.CarPlayApp" in str(out["filters"]["GofaCarplayGlobal.plist"])
        assert "com.apple.CarPlayTemplateUIHost" in str(out["filters"]["GofaCarplayGlobal.plist"])
        return out

def main():
    p=argparse.ArgumentParser()
    p.add_argument("--deb",type=pathlib.Path,required=True)
    p.add_argument("--out",type=pathlib.Path,required=True)
    a=p.parse_args()
    data=report(a.deb)
    a.out.parent.mkdir(parents=True,exist_ok=True)
    a.out.write_text(json.dumps(data,indent=2,ensure_ascii=False)+"\n")
    print("GOFAHUD031_ACTIVATION_PINNED_DEB_SHA256_PASS")
    print("GOFAHUD031_ACTIVATION_GLOBAL_SHOW_ACTIVE_NOTIFY_STRINGS_PASS")
    print(json.dumps({"status":data["status"],
                       "signals":data["signals"],
                       "dylib_sizes":{k:v["byte_length"] for k,v in data["dylibs"].items()},
                       "filters":data["filters"],
                       "postinst":data["maintainer_activation"]},indent=2,ensure_ascii=False))
    print("GOFAHUD031_ACTIVATION_STATIC_NOT_DEVICE_TESTED")

if __name__=="__main__":
    main()
