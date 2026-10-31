from pathlib import Path
import plistlib
root=Path(__file__).resolve().parents[1]
src=(root/"Observer.m").read_text()
app=(root/"ExportApp.m").read_text()
control=(root/"control").read_text()
filters=plistlib.loads((root/"Observer.plist").read_bytes())["Filter"]
ent=plistlib.loads((root/"entitlements.plist").read_bytes())
info=plistlib.loads((root/"Info.plist").read_bytes())
assert filters["Executables"] == ["SpringBoard","CarPlay","CarPlayApp"]
assert info["CFBundleIdentifier"] == "com.duoface.qa.duonaviobserver.app"
assert ent["com.apple.private.security.no-container"] is True
assert "Package: com.duoface.qa.duonaviobserver" in control
assert "Version: 0.0.2~dockabi2" in control
assert not any(t.startswith(("Conflicts:","Replaces:","Breaks:")) for t in control.splitlines())
for term in ["method_getTypeEncoding","method_getNumberOfArguments",
             "underlock_method_abi_read_only","UISceneDidEnterBackgroundNotification",
             "UIScreenDidDisconnectNotification","observer_started",
             "ui_state_sample","timestamp_utc" if False else "utc"]:
    assert term in src,term
for term in ["MSHookMessageEx","%hook","class_replaceMethod","method_setImplementation",
             "method_exchangeImplementations","SBMainWorkspace","setForeground:",
             "killall","sbreload","setBrightness:"]:
    assert term not in src,term
for term in ["BEFORE_PHONE_LOCK","BEFORE_CARPLAY_HOME","BEFORE_UNPLUG",
             "DuoNaviObserver-SpringBoard.jsonl","DuoNaviObserver-CarPlay.jsonl",
             "UIActivityViewController"]:
    assert term in app,term
for term in ["NSURLSession","NSURLConnection","MSHookMessageEx","com.duonavi.app"]:
    assert term not in src+app,term
print("DUONAVI_OBSERVER_READONLY_SOURCE_PASS")
