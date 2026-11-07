from pathlib import Path
roots=[Path('sideplay/duoface-native-scene-host'),Path('sideplay/jb-embedded-appbridge/tests')]
paths=[p for root in roots for p in root.rglob('*') if p.is_file() and p.suffix in ('.m','.h','.py','.plist','.sh') or p.is_file() and p.name=='control']
paths += [Path('sideplay/jb-embedded-appbridge/package_integrated.py'),Path('.github/workflows/duoface-184-nativeowner-signed-once.yml')]
for p in paths:
 try:s=p.read_text()
 except UnicodeDecodeError:continue
 t=s.replace('0.0.185~admission1','0.0.186~panelayout1').replace('0.1.185~admission1','0.1.186~panelayout1')
 if p.name=='Info.plist':t=t.replace('<string>185</string>','<string>186</string>').replace('<string>0.1.185</string>','<string>0.1.186</string>')
 if p.name=='test_qa184_signed_package.py':t=t.replace('info["CFBundleVersion"], "185"','info["CFBundleVersion"], "186"').replace('info["CFBundleShortVersionString"], "0.1.185"','info["CFBundleShortVersionString"], "0.1.186"')
 if p.name=='test_qa182_b1nativemaps1.py':t=t.replace('<string>185</string>','<string>186</string>')
 if p.suffix=='.yml':
  t=t.replace('name: QA185 launch-identity admission signed integrated test package','name: QA186 owned pane layout signed integrated test package')
  t=t.replace(" = '185'"," = '186'").replace('QA185-admission1-signed-integrated-PRIVATE-DEB','QA186-panelayout1-signed-integrated-DEB')
  t=t.replace('QA185_WATCHDOG_HOME_APPDELEGATE_FROZEN_PASS','QA186_WATCHDOG_HOME_APPDELEGATE_FROZEN_PASS')
  # Exact source behavior already passed real UIKit CI. Version labels only.
  t=t.replace('      - name: Prepare existing signed iOS16 toolchain','''      - name: Verify exact UIKit-tested layout implementation
        run: |
          git diff --exit-code 47438633c429031c3d03975a5a69ffc44b49b0bd -- \\
            sideplay/native-carplay-scene-v1/DF182NativeMaps.m \\
            sideplay/native-carplay-scene-v1/DF186NativePaneController.h \\
            sideplay/duoface-native-scene-host/DFSceneHost.m
      - name: Prepare existing signed iOS16 toolchain''')
  t=t.replace("          strings -a \"$LIBS/DFNativeMapPaneCoordinator.dylib\" | grep -F 'post-admission-visibility'", """          strings -a "$LIBS/DFNativeMapPaneCoordinator.dylib" | grep -F 'post-admission-visibility'
          strings -a "$LIBS/DFNativeMapPaneCoordinator.dylib" | grep -F 'DF186NativePaneController'
          strings -a "$LIBS/DFNativeMapPaneCoordinator.dylib" | grep -F 'pane-layout-reconciled'
          strings -a "$LIBS/DFTouchOwnerProbe.dylib" | grep -F 'owned-host-layout-reconciled'""")
 if t!=s:p.write_text(t)
