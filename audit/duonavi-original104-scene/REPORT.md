# Original DuoNavi 1.0.4 scene lifecycle static evidence

Source commit: ae0bd972d0ff25f53ef064ee1f83a17efeb130a5
DEB: dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb sha256=f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd
Mach-O: audit-tmp/original104/payload/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib sha256=44fdd4b4df0e3cc277ca69f71129da356f3bd8d6af70e0fde1ef36f266b66d15

STATIC ONLY. No claim about runtime call order, ownership, actual deallocation sequence, or device-test outcome. Selectors and symbols are leads for disassembly, not proof.

## Package control
Source file: control.txt; matches=0

~~~text
Package: com.duonavi.app
Name: DuoNavi
Description: Split your screen and run apps side-by-side on Apple CarPlay.
Maintainer: DuoNavi Team <support@duonavi.com>
Author: DuoNavi Team
Section: Tweaks
Depends: mobilesubstrate (>= 0.9.5000), firmware (>= 13.0)
Conflicts: oldabi, com.yourcompany.carbridgedashboard, com.bvn.carbridge13, com.leftyfl1p.carbridge13
Replaces: oldabi, com.yourcompany.carbridgedashboard, com.bvn.carbridge13, com.leftyfl1p.carbridge13
Provides: oldabi, com.yourcompany.carbridgedashboard, com.leftyfl1p.carbridge13
SileoDepiction: https://repo.duonavi.com/com.duonavi.app.json
Icon: https://duonavi.com/apple-touch-icon.png
Architecture: iphoneos-arm64
Version: 1.0.4
Installed-Size: 11060
~~~

## Package paths
Source file: files.txt; matches=0

~~~text
drwxrwxrwx 0/root            0 2026-10-12 06:55 .
drwxr-xr-x 0/root            0 2026-10-12 06:55 var
drwxr-xr-x 0/root            0 2026-10-12 06:55 var/jb
drwxr-xr-x 0/root            0 2026-10-12 06:55 var/jb/Applications
drwxrwxrwx 0/root            0 2026-10-12 06:55 var/jb/Applications/DuoNaviUI.app
-rwxrwxrwx 0/root         1683 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon29x29.png
-rwxrwxrwx 0/root         4418 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon29x29@2x.png
-rwxrwxrwx 0/root         6962 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon29x29@3x.png
-rwxrwxrwx 0/root         2558 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon40x40.png
-rwxrwxrwx 0/root         6442 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon40x40@2x.png
-rwxrwxrwx 0/root        11080 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon40x40@3x.png
-rwxrwxrwx 0/root         3512 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon50x50.png
-rwxrwxrwx 0/root         8772 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon50x50@2x.png
-rwxrwxrwx 0/root         4310 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon57x57.png
-rwxrwxrwx 0/root        10259 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon57x57@2x.png
-rwxrwxrwx 0/root        16921 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon57x57@3x.png
-rwxrwxrwx 0/root         4569 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon60x60.png
-rwxrwxrwx 0/root        11080 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon60x60@2x.png
-rwxrwxrwx 0/root        19030 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon60x60@3x.png
-rwxrwxrwx 0/root         5677 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon72x72.png
-rwxrwxrwx 0/root        14138 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon72x72@2x.png
-rwxrwxrwx 0/root         6072 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon76x76.png
-rwxrwxrwx 0/root        14885 2026-10-01 06:31 var/jb/Applications/DuoNaviUI.app/AppIcon76x76@2x.png
-rwxrwxrwx 0/root      2435008 2026-10-12 06:55 var/jb/Applications/DuoNaviUI.app/DuoNaviUI
-rwxrwxrwx 0/root         2303 2026-10-05 04:59 var/jb/Applications/DuoNaviUI.app/Info.plist
drwxrwxrwx 0/root            0 2026-10-12 06:55 var/jb/Library
drwxrwxrwx 0/root            0 2026-09-30 03:20 var/jb/Library/Application Support
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ar
-rwxrwxrwx 0/root        15129 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ar/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/de
-rwxrwxrwx 0/root        12861 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/de/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/en
-rwxrwxrwx 0/root         9945 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/en/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/es
-rwxrwxrwx 0/root        11241 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/es/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/fr
-rwxrwxrwx 0/root        11889 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/fr/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/hi
-rwxrwxrwx 0/root        12753 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/hi/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/id
-rwxrwxrwx 0/root        12753 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/id/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/it
-rwxrwxrwx 0/root        10161 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/it/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ja
-rwxrwxrwx 0/root        17073 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ja/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ko
-rwxrwxrwx 0/root        14157 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ko/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ms
-rwxrwxrwx 0/root        11565 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ms/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/nl
-rwxrwxrwx 0/root        10593 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/nl/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/pl
-rwxrwxrwx 0/root        11673 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/pl/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/pt
-rwxrwxrwx 0/root        15777 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/pt/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ru
-rwxrwxrwx 0/root        12969 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ru/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/th
-rwxrwxrwx 0/root        14049 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/th/error.mp3
-rwxrwxrwx 0/root        25090 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/ting.caf
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/tr
-rwxrwxrwx 0/root        14913 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/tr/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/vi
-rwxrwxrwx 0/root        10161 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/vi/error.mp3
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/zh
drwxrwxrwx 0/root            0 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/zh-Hant
-rwxrwxrwx 0/root        11997 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/zh-Hant/error.mp3
-rwxrwxrwx 0/root        11781 2026-10-12 06:49 var/jb/Library/Application Support/DuoNavi/Audio/zh/error.mp3
-rwxrwxrwx 0/root        19601 2026-09-30 03:20 var/jb/Library/Application Support/DuoNavi/duonavi-icon.png
-rwxrwxrwx 0/root        22348 2026-09-30 03:20 var/jb/Library/Application Support/DuoNavi/duonavi-logo-vert.png
-rwxrwxrwx 0/root        22203 2026-09-30 03:20 var/jb/Library/Application Support/DuoNavi/duonavi-logo.png
drwxr-xr-x 0/root            0 2026-10-12 06:55 var/jb/Library/MobileSubstrate
drwxr-xr-x 0/root            0 2026-10-12 06:55 var/jb/Library/MobileSubstrate/DynamicLibraries
-rwxr-xr-x 0/root      7921472 2026-10-12 06:55 var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib
-rwxr-xr-x 0/root         1446 2026-10-12 06:55 var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.plist
drwxrwxrwx 0/root            0 2026-09-30 03:20 var/jb/etc
drwxrwxrwx 0/root            0 2026-09-30 03:20 var/jb/etc/sudoers.d
-rwxrwxrwx 0/root           28 2026-09-30 03:20 var/jb/etc/sudoers.d/duonavi
drwxrwxrwx 0/root            0 2026-10-12 06:55 var/jb/usr
drwxrwxrwx 0/root            0 2026-09-30 03:20 var/jb/usr/bin
-rwxrwxrwx 0/root         3364 2026-09-30 03:20 var/jb/usr/bin/cboptimize
drwxrwxrwx 0/root            0 2026-09-29 15:43 var/jb/usr/lib
drwxrwxrwx 0/root            0 2026-10-12 06:53 var/jb/usr/lib/ellekit
-rwxrwxrwx 0/root        67552 2026-10-12 06:53 var/jb/usr/lib/ellekit/OldABI.dylib
drwxr-xr-x 0/root            0 2026-10-12 06:55 var/jb/usr/libexec
-rwxr-xr-x 0/root       150720 2026-10-12 06:55 var/jb/usr/libexec/cboptimize_helper
~~~

## Maintainer scripts
Source file: install-scripts.txt; matches=0

~~~text
--- control ---
Package: com.duonavi.app
Name: DuoNavi
Description: Split your screen and run apps side-by-side on Apple CarPlay.
Maintainer: DuoNavi Team <support@duonavi.com>
Author: DuoNavi Team
Section: Tweaks
Depends: mobilesubstrate (>= 0.9.5000), firmware (>= 13.0)
Conflicts: oldabi, com.yourcompany.carbridgedashboard, com.bvn.carbridge13, com.leftyfl1p.carbridge13
Replaces: oldabi, com.yourcompany.carbridgedashboard, com.bvn.carbridge13, com.leftyfl1p.carbridge13
Provides: oldabi, com.yourcompany.carbridgedashboard, com.leftyfl1p.carbridge13
SileoDepiction: https://repo.duonavi.com/com.duonavi.app.json
Icon: https://duonavi.com/apple-touch-icon.png
Architecture: iphoneos-arm64
Version: 1.0.4
Installed-Size: 11060
--- postinst ---
#!/bin/sh
set -e

# Fix tweak preference and state permissions
chmod 0666 /var/jb/Library/MobileSubstrate/DynamicLibraries/CarBridgeDashboard.plist 2>/dev/null || true
chmod 0666 /Library/MobileSubstrate/DynamicLibraries/CarBridgeDashboard.plist 2>/dev/null || true
chmod 0666 /var/tmp/com.duonavi.bridgestate.plist 2>/dev/null || true
chmod 0666 /var/tmp/com.tiz.carbridge.bridgestate.plist 2>/dev/null || true

# Auto-configure OldABI permissions on A12+ PAC devices
if [ -f /var/jb/usr/lib/ellekit/OldABI.dylib ]; then
    chmod 0755 /var/jb/usr/lib/ellekit/OldABI.dylib 2>/dev/null || true
    chown 0:0 /var/jb/usr/lib/ellekit/OldABI.dylib 2>/dev/null || true
fi

# Set setuid root permissions for root helper tool
chown 0:0 /var/jb/usr/libexec/cboptimize_helper 2>/dev/null || true
chmod 4755 /var/jb/usr/libexec/cboptimize_helper 2>/dev/null || true
chown 0:0 /usr/libexec/cboptimize_helper 2>/dev/null || true
chmod 4755 /usr/libexec/cboptimize_helper 2>/dev/null || true

# Pre-grant Speech Recognition and Microphone permissions in TCC.db for SpringBoard
/var/jb/usr/libexec/cboptimize_helper --grant-tcc 2>/dev/null || /usr/libexec/cboptimize_helper --grant-tcc 2>/dev/null || true

# Set sudoers drop-in permissions if present
chown 0:0 /var/jb/etc/sudoers.d/duonavi /var/jb/etc/sudoers.d/carbridge 2>/dev/null || true
chmod 0440 /var/jb/etc/sudoers.d/duonavi /var/jb/etc/sudoers.d/carbridge 2>/dev/null || true

# Auto-initialize initial settings for fresh jailbroken devices
PREF_FILE="/var/mobile/Library/Preferences/com.duonavi.plist"
LEGACY_PREF_FILE="/var/mobile/Library/Preferences/com.tiz.carbridge.plist"
if [ ! -f "$PREF_FILE" ] && [ -f "$LEGACY_PREF_FILE" ]; then
    cp "$LEGACY_PREF_FILE" "$PREF_FILE" 2>/dev/null || true
fi
if [ ! -f "$PREF_FILE" ]; then
    cat << 'EOF' > "$PREF_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>bridgedApps</key>
	<array>
		<string>com.google.Maps</string>
		<string>com.apple.Maps</string>
		<string>com.google.ios.youtube</string>
		<string>com.apple.Music</string>
		<string>com.apple.podcasts</string>
		<string>com.apple.tv</string>
		<string>com.ss.iphone.ugc.Ame</string>
		<string>com.ss.iphone.ugc.tiktok.lite</string>
		<string>vn.com.vng.zingalo</string>
	</array>
	<key>userAppsDefaultInitialized</key>
	<true/>
	<key>splitScreenEnabled</key>
	<true/>
	<key>autoLaunchOnConnect</key>
	<true/>
	<key>autoLaunchBundleID</key>
	<string>com.apple.BarcodeScanner</string>
	<key>systemOptimizerEnabled</key>
	<true/>
</dict>
</plist>
EOF
    chown 501:501 "$PREF_FILE" 2>/dev/null || true
    chmod 0644 "$PREF_FILE" 2>/dev/null || true
fi

# System Optimization for CarPlay (Rootless & Rootful compatible)
LAUNCHCTL_BIN="/var/jb/usr/bin/launchctl"
[ -x "$LAUNCHCTL_BIN" ] || LAUNCHCTL_BIN="/usr/bin/launchctl"

# Check if user explicitly disabled system optimizer in preferences (e.g. iPhone 15 Pro Max)
PREF_FILE="/var/mobile/Library/Preferences/com.duonavi.plist"
[ -f "$PREF_FILE" ] || PREF_FILE="/var/mobile/Library/Preferences/com.tiz.carbridge.plist"
OPT_ENABLED=1
if [ -f "$PREF_FILE" ]; then
    if grep -A 1 "<key>systemOptimizerEnabled</key>" "$PREF_FILE" 2>/dev/null | grep -q "<false/>"; then
        OPT_ENABLED=0
    fi
fi

SERVICES="com.apple.ReportCrash com.apple.ReportCrash.SimulateCrash com.apple.AggregateDictionary.addaily com.apple.symptomsd-diag com.apple.healthd com.apple.healthrecordsd com.apple.OTATaskingAgent com.apple.softwareupdated com.apple.triald com.apple.biomesyncd com.apple.routined com.apple.duetexpertd"

if [ "$OPT_ENABLED" -eq 1 ]; then
    if [ -x "$LAUNCHCTL_BIN" ]; then
        for svc in $SERVICES; do
            "$LAUNCHCTL_BIN" disable "system/$svc" 2>/dev/null || true
            "$LAUNCHCTL_BIN" kill SIGKILL "system/$svc" 2>/dev/null || true
        done
    fi

    # Clean stale crash logs and huge debug logs
    rm -rf /var/mobile/Library/Logs/CrashReporter/* 2>/dev/null || true
    rm -rf /Library/Logs/CrashReporter/* 2>/dev/null || true
    for logfile in /var/mobile/duonavi.log /var/mobile/duonavi_live.log /var/mobile/carbridge.log /var/mobile/carbridge_live.log; do
        if [ -f "$logfile" ]; then
            > "$logfile" || true
        fi
    done
else
    # User chose to keep/restore stock daemons
    if [ -x "$LAUNCHCTL_BIN" ]; then
        for svc in $SERVICES; do
            "$LAUNCHCTL_BIN" enable "system/$svc" 2>/dev/null || true
        done
    fi
fi

# Refresh SpringBoard & LaunchServices Icon / App cache
if command -v uicache >/dev/null 2>&1; then
    uicache -a 2>/dev/null || true
elif [ -x /var/jb/usr/bin/uicache ]; then
    /var/jb/usr/bin/uicache -a 2>/dev/null || true
elif [ -x /usr/bin/uicache ]; then
    /usr/bin/uicache -a 2>/dev/null || true
fi

exit 0
--- prerm ---
#!/bin/sh
# Re-enable system daemons when CarBridge package is removed
LAUNCHCTL_BIN="/var/jb/usr/bin/launchctl"
[ -x "$LAUNCHCTL_BIN" ] || LAUNCHCTL_BIN="/usr/bin/launchctl"

if [ -x "$LAUNCHCTL_BIN" ]; then
    SERVICES="com.apple.ReportCrash com.apple.ReportCrash.SimulateCrash com.apple.AggregateDictionary.addaily com.apple.symptomsd-diag com.apple.healthd com.apple.healthrecordsd com.apple.OTATaskingAgent com.apple.softwareupdated com.apple.triald com.apple.biomesyncd com.apple.routined com.apple.duetexpertd"
    for svc in $SERVICES; do
        "$LAUNCHCTL_BIN" enable "system/$svc" 2>/dev/null || true
    done
fi

exit 0
~~~

## Dynamic dependencies
Source file: libraries.txt; matches=0

~~~text
audit-tmp/original104/payload/var/jb/Library/MobileSubstrate/DynamicLibraries/DuoNaviDashboard.dylib:
	@rpath/DuoNaviDashboard.dylib (compatibility version 0.0.0, current version 0.0.0)
	/usr/lib/libobjc.A.dylib (compatibility version 1.0.0, current version 228.0.0)
	/System/Library/Frameworks/Foundation.framework/Foundation (compatibility version 300.0.0, current version 1971.0.0)
	/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation (compatibility version 150.0.0, current version 1971.0.0)
	/System/Library/Frameworks/UIKit.framework/UIKit (compatibility version 1.0.0, current version 6441.1.101)
	/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics (compatibility version 64.0.0, current version 1690.5.4)
	/System/Library/Frameworks/IOKit.framework/Versions/A/IOKit (compatibility version 1.0.0, current version 275.0.0)
	/System/Library/Frameworks/Security.framework/Security (compatibility version 1.0.0, current version 60420.102.1)
	/System/Library/Frameworks/AVFoundation.framework/AVFoundation (compatibility version 1.0.0, current version 2.0.0)
	/System/Library/Frameworks/QuartzCore.framework/QuartzCore (compatibility version 1.2.0, current version 1.11.0)
	/System/Library/Frameworks/AudioToolbox.framework/AudioToolbox (compatibility version 1.0.0, current version 1000.0.0)
	/System/Library/Frameworks/Speech.framework/Speech (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/Frameworks/CoreMedia.framework/CoreMedia (compatibility version 1.0.0, current version 1.0.0)
	/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport (compatibility version 1.0.0, current version 29.0.0)
	/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices (compatibility version 1.0.0, current version 1.0.0)
	/usr/lib/libsqlite3.dylib (compatibility version 9.0.0, current version 346.0.0)
	/usr/lib/libSystem.B.dylib (compatibility version 1.0.0, current version 1319.100.3)
	/System/Library/Frameworks/AVFAudio.framework/AVFAudio (compatibility version 1.0.0, current version 1.0.0)
	@rpath/CydiaSubstrate.framework/CydiaSubstrate (compatibility version 0.0.0, current version 0.0.0)
~~~

## nm target symbols
Source file: symbols.txt; matches=0

~~~text
[NO_MATCH_IN_OUTPUT]
~~~

## Target strings
Source file: strings.txt; matches=33

~~~text

... context gap ...
  14922 | valueForHTTPHeaderField:
  14923 | finishTasksAndInvalidate
  14924 | localizedCaseInsensitiveContainsString:

... context gap ...
  15017 | addToRunLoop:forMode:
  15018 | invalidate
  15019 | imageView

... context gap ...
  15393 | updateSceneSettingsFrame
  15394 | invalidated
  15395 | hosting

... context gap ...
  15407 | setAutomatesLifecycle:
  15408 | setRequestedMode:
  15409 | setOpaque:

... context gap ...
  15411 | startInParentViewController:
  15412 | setInvalidated:
  15413 | beginAppearanceTransition:animated:
  15414 | endAppearanceTransition
  15415 | willMoveToParentViewController:
  15416 | removeFromParentViewController
  15417 | hostedScene

... context gap ...
  15434 | _hosting
  15435 | _invalidated
  15436 | _audioOnlyBackgroundMode

... context gap ...
  15445 | TB,N,V_hosting
  15446 | TB,N,V_invalidated
  15447 | TB,N,V_audioOnlyBackgroundMode

... context gap ...
  15497 | windowScene
  15498 | destroyWindows
  15499 | multitaskingOverlay

... context gap ...
  15777 | _customScale
  15778 | T@"CBBridgedUIAppView",&,N,V_appView
  15779 | T@"CBSlotPillView",&,N,V_notchPill

... context gap ...
  15837 | _splitApp
  15838 | T@"CBBridgedSplitApp",W,N,V_splitApp
  15839 | updateLocalizedTexts

... context gap ...
  16111 | cancelWithCloseCode:reason:
  16112 | invalidateAndCancel
  16113 | setIsConnected:

... context gap ...
  16275 | _renderSize
  16276 | T@"CBWindow",&,N,V_window
  16277 | T@"CBBridgedApp",&,N,V_currentApp

... context gap ...
  16520 | clientIdentity
  16521 | updateSettings:withTransitionContext:completion:
  16522 | _applyUpdateWithContext:completion:

... context gap ...
  18667 | _deviceAppViewController
  18668 | [CBBridgedUIAppView] Warning: _deviceAppViewController KVC failed: %@
  18669 | setHomeGrabberDisplayMode:
  18670 | [CBBridgedUIAppView] Warning: _deviceAppViewController KVC failed in updateSceneSettingsFrame, falling back to ivar: %@
  18671 | [CBBridgedUIAppView] Warning: Exception resolving sceneHandle: %@
  18672 | CBDuoNaviHosted

... context gap ...
  18701 | External
  18702 | [CBWindow] Warning: Exception getting carPlayWindowScene: %@
  18703 | AVExternalDevice

... context gap ...
  18705 | pointScale
  18706 | [CBWindow] Warning: Exception getting carPlayScreenScale: %@
  18707 | [CBWindow] Warning: Exception reading live screen bounds file: %@
  18708 | [CBWindow] Warning: Exception querying carPlayWindowScene bounds: %@
  18709 | [CBWindow] Warning: Exception querying carPlayUIScreen bounds: %@
  18710 | bounds
  18711 | [CBWindow] Warning: Exception querying carPlayCADisplay bounds: %@
  18712 | [CBWindow] Warning: Exception resolving FBSScene displayConfiguration: %@
  18713 | FBSDisplayConfiguration

... context gap ...
  18982 | [CBVoiceSessionManager] shouldResume is YES. Scheduling seamless media resume in 0.18s (token=%llu)...
  18983 | [CBVoiceSessionManager] Skip media resume: session active again or token invalidated
  18984 | [CBVoiceSessionManager] shouldResume is NO. No media resumption requested.

... context gap ...
  19048 | [DuoNaviSB] [DISCONNECT_TRACE] Stopping and removing _currentApp (%@)...
  19049 | [DuoNaviSB] [DISCONNECT_TRACE] Destroying CBWindow...
  19050 | CBVoiceSessionManager

... context gap ...
  20712 | NSObject
  20713 | CBBridgedUIAppView
  20714 | CBWindow
  20715 | CBVoiceSessionStateDelegate

... context gap ...
  20730 | CBSlotPlaceholderView
  20731 | CBBridgedSplitApp
  20732 | CBVoiceSpeechResponse

... context gap ...
  20873 | {CGSize=dd}16@0:8
  20874 | @"CBBridgedUIAppView"
  20875 | @"CBSlotPillView"
  20876 | @52@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16B48
  20877 | @"CBBridgedSplitApp"
  20878 | @60@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24B56

... context gap ...
  20944 | @"NSMutableSet"
  20945 | @"CBWindow"
  20946 | @"CBBridgedApp"
~~~

## otool Objective-C metadata
Source file: objc.txt; matches=25

~~~text

... context gap ...
   1947 |         weakIvarLayout 0x0
   1948 |         baseProperties 0x0
   1949 | 00000000003a7928 0x3b3100
   1950 |     isa        0x3b3128
   1951 |     superclass 0x0 _OBJC_CLASS_$_UIView
   1952 |     cache      0x0 __objc_empty_cache
   1953 |     vtable     0x0
   1954 |     data       0x3a9a80
   1955 |         flags          0x194 RO_HAS_CXX_STRUCTORS
   1956 |         instanceStart  8
   1957 |         instanceSize   48
   1958 |         reserved       0x0
   1959 |         ivarLayout     0x37535c
   1960 |         layout map     0x13 
   1961 |         name           0x375349 CBBridgedUIAppView
   1962 |         baseMethods    0x31cc50
   1963 |             entsize 12 (relative)
   1964 |             count   31
   1965 |             name    0x942d0 (0x3b0f28)
   1966 |             types   0x58b5a (0x3757b6) @24@0:8@16
   1967 |             imp     0xffd901a4 (0xace04)
   1968 |             name    0x93bbc (0x3b0820)
   1969 |             types   0x59038 (0x375ca0) @32@0:8@16d24
   1970 |             imp     0xffd901a8 (0xace14)
   1971 |             name    0x92c80 (0x3af8f0)
   1972 |             types   0x58be8 (0x37585c) v24@0:8d16
   1973 |             imp     0xffd90304 (0xacf7c)
   1974 |             name    0x94484 (0x3b1100)
   1975 |             types   0x58ba0 (0x375820) v20@0:8B16

... context gap ...
   2054 |             imp     0xffd93524 (0xb02e0)
   2055 |             name    0x92ac8 (0x3af888)
   2056 |             types   0x58a08 (0x3757cc) v16@0:8
   2057 |             imp     0xffd93528 (0xb02f0)
   2058 |         baseProtocols  0x0
   2059 |         ivars          0x3a9920
   2060 |             entsize   32
   2061 |             count     7
   2062 |             offset    0x3b2a60 8
   2063 |             name      0x32769b _hosting
   2064 |             type      0x375867 B
   2065 |             alignment 0
   2066 |             size      1
   2067 |             offset    0x3b2a64 9
   2068 |             name      0x3276a4 _invalidated
   2069 |             type      0x375867 B
   2070 |             alignment 0
   2071 |             size      1
   2072 |             offset    0x3b2a68 10
   2073 |             name      0x3276b1 _audioOnlyBackgroundMode
   2074 |             type      0x375867 B
   2075 |             alignment 0
   2076 |             size      1
   2077 |             offset    0x3b2a58 16
   2078 |             name      0x3276ca _bundleIdentifier
   2079 |             type      0x3757d4 @"NSString"
   2080 |             alignment 3
   2081 |             size      8
   2082 |             offset    0x3b2a70 24

... context gap ...
   2097 |         weakIvarLayout 0x0
   2098 |         baseProperties 0x3a9a08
   2099 |             entsize    16
   2100 |             count      7
   2101 |             name       0x323cc3 bundleIdentifier
   2102 |             attributes 0x327706 T@"NSString",C,N,V_bundleIdentifier
   2103 |             name       0x327636 appViewController
   2104 |             attributes 0x32772a T@"SBAppViewController",&,N,V_appViewController
   2105 |             name       0x32765e wrapperView
   2106 |             attributes 0x32775a T@"UIView",&,N,V_wrapperView
   2107 |             name       0x32767a appScale
   2108 |             attributes 0x327777 Td,N,V_appScale
   2109 |             name       0x32737b hosting
   2110 |             attributes 0x327787 TB,N,V_hosting
   2111 |             name       0x32736f invalidated
   2112 |             attributes 0x327796 TB,N,V_invalidated
   2113 |             name       0x327683 audioOnlyBackgroundMode
   2114 |             attributes 0x3277a9 TB,N,V_audioOnlyBackgroundMode
   2115 | Meta Class
   2116 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   2117 |     superclass 0x0 _OBJC_METACLASS_$_UIView
   2118 |     cache      0x0 __objc_empty_cache
   2119 |     vtable     0x0
   2120 |     data       0x3a98d8
   2121 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   2122 |         instanceStart  40
   2123 |         instanceSize   40
   2124 |         reserved       0x0
   2125 |         ivarLayout     0x0
   2126 |         name           0x375349 CBBridgedUIAppView
   2127 |         baseMethods    0x0
   2128 |         baseProtocols  0x0
   2129 |         ivars          0x0
   2130 |         weakIvarLayout 0x0
   2131 |         baseProperties 0x0
   2132 | 00000000003a7930 0x3b3150
   2133 |     isa        0x3b3178
   2134 |     superclass 0x0 _OBJC_CLASS_$_NSObject
   2135 |     cache      0x0 __objc_empty_cache
   2136 |     vtable     0x0
   2137 |     data       0x3aa050
   2138 |         flags          0x194 RO_HAS_CXX_STRUCTORS
   2139 |         instanceStart  8
   2140 |         instanceSize   112
   2141 |         reserved       0x0
   2142 |         ivarLayout     0x375383
   2143 |         layout map     0x02 0x16 
   2144 |         name           0x37535e CBWindow
   2145 |         baseMethods    0x31ce48
   2146 |             entsize 12 (relative)
   2147 |             count   31
   2148 |             name    0x949e0 (0x3b1830)
   2149 |             types   0x58af9 (0x37594d) @48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
   2150 |             imp     0xffd937f4 (0xb064c)
   2151 |             name    0x92ce4 (0x3afb40)
   2152 |             types   0x5894e (0x3757ae) @16@0:8
   2153 |             imp     0xffd95590 (0xb23f4)
   2154 |             name    0x93b68 (0x3b09d0)
   2155 |             types   0x58960 (0x3757cc) v16@0:8
   2156 |             imp     0xffd95600 (0xb2470)
   2157 |             name    0x93c64 (0x3b0ad8)
   2158 |             types   0x58936 (0x3757ae) @16@0:8

... context gap ...
   2419 |             attributes 0x32696d T@"NSString",R,C
   2420 |             name       0x326952 debugDescription
   2421 |             attributes 0x32696d T@"NSString",R,C
   2422 | Meta Class
   2423 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   2424 |     superclass 0x0 _OBJC_METACLASS_$_NSObject
   2425 |     cache      0x0 __objc_empty_cache
   2426 |     vtable     0x0
   2427 |     data       0x3a9df8
   2428 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   2429 |         instanceStart  40
   2430 |         instanceSize   40
   2431 |         reserved       0x0
   2432 |         ivarLayout     0x0
   2433 |         name           0x37535e CBWindow
   2434 |         baseMethods    0x31cdd0
   2435 |             entsize 12 (relative)
   2436 |             count   9
   2437 |             name    0x93c80 (0x3b0a58)
   2438 |             types   0x589d2 (0x3757ae) @16@0:8
   2439 |             imp     0xffd93934 (0xb0714)
   2440 |             name    0x949cc (0x3b17b0)
   2441 |             types   0x589e4 (0x3757cc) v16@0:8
   2442 |             imp     0xffd9394c (0xb0738)
   2443 |             name    0x93c58 (0x3b0a48)
   2444 |             types   0x589ba (0x3757ae) @16@0:8
   2445 |             imp     0xffd93a68 (0xb0860)
   2446 |             name    0x93bec (0x3b09e8)
   2447 |             types   0x589ae (0x3757ae) @16@0:8

... context gap ...
   3959 |             entsize   32
   3960 |             count     5
   3961 |             offset    0x3b2ba4 8
   3962 |             name      0x328e7b _notchIdleTimer
   3963 |             type      0x375e9b @"NSTimer"
   3964 |             alignment 3
   3965 |             size      8
   3966 |             offset    0x3b2ba0 16
   3967 |             name      0x328e8b _lastActivityTime
   3968 |             type      0x375876 d
   3969 |             alignment 3
   3970 |             size      8
   3971 |             offset    0x3b2b98 24
   3972 |             name      0x328e9d _appView
   3973 |             type      0x3760c5 @"CBBridgedUIAppView"
   3974 |             alignment 3
   3975 |             size      8
   3976 |             offset    0x3b2b9c 32
   3977 |             name      0x328ea6 _notchPill
   3978 |             type      0x3760db @"CBSlotPillView"
   3979 |             alignment 3
   3980 |             size      8
   3981 |             offset    0x3b2b94 40
   3982 |             name      0x328eb1 _customScale
   3983 |             type      0x375876 d
   3984 |             alignment 3
   3985 |             size      8
   3986 |         weakIvarLayout 0x0
   3987 |         baseProperties 0x3ab468
   3988 |             entsize    16
   3989 |             count      3
   3990 |             name       0x328e33 appView
   3991 |             attributes 0x328ebe T@"CBBridgedUIAppView",&,N,V_appView
   3992 |             name       0x328e47 notchPill
   3993 |             attributes 0x328ee3 T@"CBSlotPillView",&,N,V_notchPill
   3994 |             name       0x328e5f customScale
   3995 |             attributes 0x328f06 Td,N,V_customScale
   3996 | Meta Class
   3997 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   3998 |     superclass 0x3b33a8
   3999 |     cache      0x0 __objc_empty_cache
   4000 |     vtable     0x0
   4001 |     data       0x3ab378
   4002 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   4003 |         instanceStart  40
   4004 |         instanceSize   40
   4005 |         reserved       0x0

... context gap ...
   4540 |             types   0x57bee (0x3757ae) @16@0:8
   4541 |             imp     0xffded1c4 (0x10ad88)
   4542 |             name    0x93478 (0x3b1040)
   4543 |             types   0x57bf5 (0x3757c1) v24@0:8@16
   4544 |             imp     0xffded1e0 (0x10adb0)
   4545 |             name    0x91cb4 (0x3af888)
   4546 |             types   0x57bf4 (0x3757cc) v16@0:8
   4547 |             imp     0xffded1e8 (0x10adc4)
   4548 |         baseProtocols  0x0
   4549 |         ivars          0x3abc80
   4550 |             entsize   32
   4551 |             count     1
   4552 |             offset    0x3b2bd0 8
   4553 |             name      0x3292b9 _splitApp
   4554 |             type      0x37611a @"CBBridgedSplitApp"
   4555 |             alignment 3
   4556 |             size      8
   4557 |         weakIvarLayout 0x375456
   4558 |         layout map     0x01 
   4559 |         baseProperties 0x3abca8
   4560 |             entsize    16
   4561 |             count      1
   4562 |             name       0x329292 splitApp
   4563 |             attributes 0x3292c3 T@"CBBridgedSplitApp",W,N,V_splitApp
   4564 | Meta Class
   4565 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   4566 |     superclass 0x0 _OBJC_METACLASS_$_UIView
   4567 |     cache      0x0 __objc_empty_cache
   4568 |     vtable     0x0
   4569 |     data       0x3abc38
   4570 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   4571 |         instanceStart  40
   4572 |         instanceSize   40
   4573 |         reserved       0x0
   4574 |         ivarLayout     0x0
   4575 |         name           0x3754a3 CBSplitContainerView
   4576 |         baseMethods    0x0
   4577 |         baseProtocols  0x0

... context gap ...
   4703 |         weakIvarLayout 0x0
   4704 |         baseProperties 0x0
   4705 | 00000000003a79a8 0x3b3600
   4706 |     isa        0x3b3628
   4707 |     superclass 0x3b3380
   4708 |     cache      0x0 __objc_empty_cache
   4709 |     vtable     0x0
   4710 |     data       0x3ac150
   4711 |         flags          0x194 RO_HAS_CXX_STRUCTORS
   4712 |         instanceStart  8
   4713 |         instanceSize   120
   4714 |         reserved       0x0
   4715 |         ivarLayout     0x3754e0
   4716 |         layout map     0x21 0x26 
   4717 |         name           0x3754ce CBBridgedSplitApp
   4718 |         baseMethods    0x31d6a0
   4719 |             entsize 12 (relative)
   4720 |             count   50
   4721 |             name    0x93858 (0x3b0f00)
   4722 |             types   0x5899b (0x376047) @56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
   4723 |             imp     0xffdee4ec (0x10bb9c)
   4724 |             name    0x93984 (0x3b1038)
   4725 |             types   0x58a77 (0x37612f) @60@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24B56
   4726 |             imp     0xffdee4f0 (0x10bbac)
   4727 |             name    0x93990 (0x3b1050)
   4728 |             types   0x58a9b (0x37615f) v44@0:8{CGPoint=dd}16B32q36
   4729 |             imp     0xffdefe94 (0x10d55c)
   4730 |             name    0x9394c (0x3b1018)
   4731 |             types   0x580fc (0x3757cc) v16@0:8

... context gap ...
   4966 |             attributes 0x32987e Tq,N,V_focusedSlotIndex
   4967 |             name       0x3296d6 isTransitioningFocus
   4968 |             attributes 0x329896 TB,N,V_isTransitioningFocus
   4969 | Meta Class
   4970 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   4971 |     superclass 0x3b33a8
   4972 |     cache      0x0 __objc_empty_cache
   4973 |     vtable     0x0
   4974 |     data       0x3abe98
   4975 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   4976 |         instanceStart  40
   4977 |         instanceSize   40
   4978 |         reserved       0x0
   4979 |         ivarLayout     0x0
   4980 |         name           0x3754ce CBBridgedSplitApp
   4981 |         baseMethods    0x0
   4982 |         baseProtocols  0x0
   4983 |         ivars          0x0
   4984 |         weakIvarLayout 0x0
   4985 |         baseProperties 0x0
   4986 | 00000000003a79b0 0x3b3650
   4987 |     isa        0x3b3678
   4988 |     superclass 0x0 _OBJC_CLASS_$_NSObject
   4989 |     cache      0x0 __objc_empty_cache
   4990 |     vtable     0x0
   4991 |     data       0x3ac250
   4992 |         flags          0x194 RO_HAS_CXX_STRUCTORS
   4993 |         instanceStart  8
   4994 |         instanceSize   24

... context gap ...
   8796 |             alignment 3
   8797 |             size      8
   8798 |             offset    0x3b2d54 48
   8799 |             name      0x32b64b _autoResumeBundleID
   8800 |             type      0x3757d4 @"NSString"
   8801 |             alignment 3
   8802 |             size      8
   8803 |             offset    0x3b2d58 56
   8804 |             name      0x3276ca _bundleIdentifier
   8805 |             type      0x3757d4 @"NSString"
   8806 |             alignment 3
   8807 |             size      8
   8808 |             offset    0x3b2d5c 64
   8809 |             name      0x32b65f _window
   8810 |             type      0x3769d8 @"CBWindow"
   8811 |             alignment 3
   8812 |             size      8
   8813 |             offset    0x3b2d60 72
   8814 |             name      0x32b667 _currentApp
   8815 |             type      0x3769e4 @"CBBridgedApp"
   8816 |             alignment 3
   8817 |             size      8
   8818 |             offset    0x3b2d64 80
   8819 |             name      0x32b673 _licenseWarningModal
   8820 |             type      0x3769f4 @"CBLicenseWarningModalView"
   8821 |             alignment 3
   8822 |             size      8
   8823 |             offset    0x3b2d68 88
   8824 |             name      0x32b688 _licenseWatchdogTimer

... context gap ...
   8829 |             name      0x327cf2 _appFrame
   8830 |             type      0x375e27 {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}}
   8831 |             alignment 3
   8832 |             size      32
   8833 |             offset    0x3b2d70 128
   8834 |             name      0x32b69e _renderSize
   8835 |             type      0x376a11 {CGSize="width"d"height"d}
   8836 |             alignment 3
   8837 |             size      16
   8838 |         weakIvarLayout 0x0
   8839 |         baseProperties 0x3af290
   8840 |             entsize    16
   8841 |             count      8
   8842 |             name       0x3271b4 window
   8843 |             attributes 0x32b6aa T@"CBWindow",&,N,V_window
   8844 |             name       0x325c38 currentApp
   8845 |             attributes 0x32b6c4 T@"CBBridgedApp",&,N,V_currentApp
   8846 |             name       0x32b579 licenseWarningModal
   8847 |             attributes 0x32b6e6 T@"CBLicenseWarningModalView",&,N,V_licenseWarningModal
   8848 |             name       0x323cc3 bundleIdentifier
   8849 |             attributes 0x327706 T@"NSString",C,N,V_bundleIdentifier
   8850 |             name       0x328af3 activated
   8851 |             attributes 0x32b71e TB,N,V_activated
   8852 |             name       0x327bc7 appFrame
   8853 |             attributes 0x327cfc T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame
   8854 |             name       0x328e28 renderSize
   8855 |             attributes 0x32b72f T{CGSize=dd},N,V_renderSize
   8856 |             name       0x32b5b4 autoResumeBundleID
   8857 |             attributes 0x32b74b T@"NSString",C,N,V_autoResumeBundleID

... context gap ...
  11155 |     0x324c07 requestWithURL:cachePolicy:timeoutInterval:
  11156 |     0x324c33 setHTTPMethod:
  11157 |     0x324c42 setValue:forHTTPHeaderField:
  11158 |     0x32409a currentLanguageCode
  11159 |     0x324c5f stringWithUTF8String:
  11160 |     0x324c75 bytes
  11161 |     0x324c7b dataWithBytes:length:
  11162 |     0x324c91 dataWithJSONObject:options:error:
  11163 |     0x324cb3 setHTTPBody:
  11164 |     0x324cc0 ephemeralSessionConfiguration
  11165 |     0x324cde setTimeoutIntervalForRequest:
  11166 |     0x324cfc setTimeoutIntervalForResource:
  11167 |     0x324d1b sessionWithConfiguration:
  11168 |     0x324d35 valueForHTTPHeaderField:
  11169 |     0x324d4e finishTasksAndInvalidate
  11170 |     0x324d67 localizedCaseInsensitiveContainsString:
  11171 |     0x324d8f dataTaskWithRequest:completionHandler:
  11172 |     0x324db6 resume
  11173 |     0x324e2c initWithBytes:length:
  11174 |     0x324e42 dataWithLength:
  11175 |     0x324e52 mutableBytes
  11176 |     0x324e5f initWithData:encoding:
  11177 |     0x324e76 description
  11178 |     0x324e82 URL
  11179 |     0x324e86 absoluteString
  11180 |     0x324e95 statusCode
  11181 |     0x324ea0 allHeaderFields
  11182 |     0x324eb0 stringWithCapacity:
  11183 |     0x324ec4 dataWithContentsOfFile:

... context gap ...
  11232 |     0x325461 anyObject
  11233 |     0x32546b locationInView:
  11234 |     0x32547b sendTouchEventAtPoint:isDown:
  11235 |     0x3254fd initWithFrame:
  11236 |     0x32550c blackColor
  11237 |     0x325517 setBackgroundColor:
  11238 |     0x32552b setContentMode:
  11239 |     0x32553b setAutoresizingMask:
  11240 |     0x325550 addSubview:
  11241 |     0x32555c captureFrame:
  11242 |     0x32556a displayLinkWithTarget:selector:
  11243 |     0x32558a setPreferredFramesPerSecond:
  11244 |     0x3255a7 mainRunLoop
  11245 |     0x3255b3 addToRunLoop:forMode:
  11246 |     0x3255c9 invalidate
  11247 |     0x3255d4 imageView
  11248 |     0x3255de setImage:
  11249 |     0x3255e8 stop
  11250 |     0x3255ed dealloc
  11251 |     0x3256dd clearColor
  11252 |     0x3256e8 setClipsToBounds:
  11253 |     0x3256fa CGColor
  11254 |     0x325702 layer
  11255 |     0x325708 setShadowColor:
  11256 |     0x325718 setShadowOffset:
  11257 |     0x325729 setShadowRadius:
  11258 |     0x32573a setShadowOpacity:
  11259 |     0x32574c effectWithStyle:
  11260 |     0x32575d initWithEffect:

... context gap ...
  11450 |     0x327239 setContentReferenceSize:withContentOrientation:andContainerOrientation:
  11451 |     0x327281 setHomeGrabberDisplayMode:
  11452 |     0x32729c carPlayUsableBounds
  11453 |     0x3272b0 sceneHandle
  11454 |     0x3272bc sceneIfExists
  11455 |     0x3272ca scene
  11456 |     0x3272d0 updateSettingsWithBlock:
  11457 |     0x3272e9 setForeground:
  11458 |     0x3272f8 setOccluded:
  11459 |     0x327305 setUnderLock:
  11460 |     0x327313 setCanShowWhileLocked:
  11461 |     0x32732a setDeactivationReasons:
  11462 |     0x327342 setIdleModeEnabled:
  11463 |     0x327356 updateSceneSettingsFrame
  11464 |     0x32736f invalidated
  11465 |     0x32737b hosting
  11466 |     0x327383 setHosting:
  11467 |     0x32738f sharedInstanceIfExists
  11468 |     0x3273a6 rootViewController
  11469 |     0x3273b9 applicationWithBundleIdentifier:
  11470 |     0x3273da initWithApplicationForMainDisplay:
  11471 |     0x3273fd instancesRespondToSelector:
  11472 |     0x327419 UUID
  11473 |     0x32741e UUIDString
  11474 |     0x327429 initWithIdentifier:andApplicationSceneEntity:
  11475 |     0x327457 addChildViewController:
  11476 |     0x32746f setIgnoresOcclusions:
  11477 |     0x327485 setAutomatesLifecycle:
  11478 |     0x32749c setRequestedMode:
  11479 |     0x3274ae setOpaque:
  11480 |     0x3274b9 didMoveToParentViewController:
  11481 |     0x3274d8 startInParentViewController:
  11482 |     0x3274f5 setInvalidated:
  11483 |     0x327505 beginAppearanceTransition:animated:
  11484 |     0x327529 endAppearanceTransition
  11485 |     0x327541 willMoveToParentViewController:
  11486 |     0x327561 removeFromParentViewController
  11487 |     0x327580 hostedScene
  11488 |     0x32758c initWithURL:
  11489 |     0x327599 sendActions:
  11490 |     0x3275a6 setWithObject:
  11491 |     0x3275b5 dismiss
  11492 |     0x3277c8 createWindows
  11493 |     0x3277d6 resizeWindows
  11494 |     0x3277e4 sharedApplication
  11495 |     0x3277f6 carPlayUIScreen
  11496 |     0x327806 connectedScenes
  11497 |     0x327816 screen
  11498 |     0x32781d session
  11499 |     0x327825 role
  11500 |     0x32782a currentCarPlayExternalDevice

... context gap ...
  11530 |     0x327a13 setVisualState:animated:
  11531 |     0x327a2c dimBubble
  11532 |     0x327a36 wakeBubble
  11533 |     0x327a41 isMainThread
  11534 |     0x327a4e switchToMultiSplitMode:apps:ratio:
  11535 |     0x326bd2 setOnMultiSplitSelected:
  11536 |     0x327a71 setEffect:
  11537 |     0x327a7c updateBoundaryBounds:
  11538 |     0x327a92 removeAllAnimations
  11539 |     0x327aa6 makeKeyAndVisible
  11540 |     0x327ab8 frame
  11541 |     0x327abe windowLevel
  11542 |     0x327aca resignKeyWindow
  11543 |     0x327ada windowScene
  11544 |     0x327ae6 destroyWindows
  11545 |     0x327af5 multitaskingOverlay
  11546 |     0x326b61 showAppPickerForSlot:parentView:
  11547 |     0x326b82 showLayoutChooserInParentView:
  11548 |     0x326ba1 showRecentAppsInParentView:
  11549 |     0x325a5b pointInside:withEvent:
  11550 |     0x327e41 sendEvent:
  11551 |     0x327e4c isUserInteractionEnabled
  11552 |     0x327e65 convertPoint:fromView:
  11553 |     0x327e7c type
  11554 |     0x327e81 allTouches
  11555 |     0x327e8c phase
  11556 |     0x327e92 systemFontOfSize:
  11557 |     0x327ea4 monospacedDigitSystemFontOfSize:weight:
  11558 |     0x327ecc valueLabel

... context gap ...
  11840 |     0x32a415 appendData:
  11841 |     0x32a421 ensurePlaybackAudioSessionWithDucking:
  11842 |     0x32a448 setLength:
  11843 |     0x32a453 isPlaying
  11844 |     0x32a45d initWithData:error:
  11845 |     0x32a471 setVolume:
  11846 |     0x32a47c prepareToPlay
  11847 |     0x32a48a play
  11848 |     0x32a48f setIsPlaying:
  11849 |     0x32a49d playWithCompletion:
  11850 |     0x32a68b _wipeSessionKey
  11851 |     0x32a69b setMaxConcurrentOperationCount:
  11852 |     0x32a6bb isConnected
  11853 |     0x32a6c7 cancelWithCloseCode:reason:
  11854 |     0x32a6e3 invalidateAndCancel
  11855 |     0x32a6f7 setIsConnected:
  11856 |     0x32a707 substringFromIndex:
  11857 |     0x32a71b defaultSessionConfiguration
  11858 |     0x32a737 sessionWithConfiguration:delegate:delegateQueue:
  11859 |     0x32a768 requestWithURL:
  11860 |     0x32a778 webSocketTaskWithRequest:
  11861 |     0x32a792 code
  11862 |     0x32a797 handleSocketCloseWithCode:
  11863 |     0x32a7b2 voiceTransportDidFailWithError:
  11864 |     0x32a7d2 listenForIncomingMessagesForSession:task:generation:
  11865 |     0x3299f7 fromEnvelopeDictionary:
  11866 |     0x32a807 voiceTransportDidReceiveDirective:
  11867 |     0x32a82a voiceTransportDidReceiveTurnFinishWithFollowUp:timeoutSec:
  11868 |     0x32a865 voiceTransportDidReceiveError:

... context gap ...
  12193 |     0x32ca47 setRouteDetectionEnabled:
  12194 |     0x32ca61 isPictureInPictureSupported
  12195 |     0x32ca7d isPictureInPicturePossible
  12196 |     0x32ca98 isPictureInPictureActive
  12197 |     0x32cab1 startPictureInPicture
  12198 |     0x32cac7 setCanStartPictureInPictureAutomaticallyFromInline:
  12199 |     0x32cafb canStartPictureInPictureAutomaticallyFromInline
  12200 |     0x32cb2b isWirelessRouteActive
  12201 |     0x32cb41 areWirelessRoutesAvailable
  12202 |     0x32cb5c application
  12203 |     0x32cb68 clientProcess
  12204 |     0x32cb76 clientHandle
  12205 |     0x32cb83 definition
  12206 |     0x32cb8e clientIdentity
  12207 |     0x32cb9d updateSettings:withTransitionContext:completion:
  12208 |     0x32cbce _applyUpdateWithContext:completion:
  12209 |     0x32cbf2 scene:didPrepareUpdateWithContext:
  12210 |     0x32cc15 interceptUpdateForScene:withNewSettings:
  12211 |     0x32cc3e _shouldBeBackgroundUnderLockForScene:withSettings:
  12212 |     0x32cc71 shouldBeUnderLockForScene:
  12213 |     0x32cc8c _mainSceneSupportsInterfaceOrientation:
  12214 |     0x32ccb4 sceneHandle:didUpdateSettingsWithDiff:previousSettings:
  12215 |     0x32ccec sceneHandle:didDestroyScene:
  12216 |     0x32cd09 systemService:isPasscodeLockedOrBlockedWithResult:
  12217 |     0x32cd3c systemService:canActivateApplication:withResult:
  12218 |     0x32cd6d isForeground
  12219 |     0x32cd7a idleModeEnabled
  12220 |     0x32cd8a displayIdentity
  12221 |     0x32cd9a isRootIdentity
~~~

## LLVM Objective-C metadata
Source file: llvm-objc.txt; matches=28

~~~text

... context gap ...
   1951 |     superclass 0x0 _OBJC_CLASS_$_UIView
   1952 |     cache      0x0 __objc_empty_cache
   1953 |     vtable     0x0
   1954 |     data       0x3a1fe0
   1955 |         flags          0x194 RO_HAS_CXX_STRUCTORS
   1956 |         instanceStart  8
   1957 |         instanceSize   48
   1958 |         reserved       0x00000000
   1959 |         ivarLayout     0x36d364
   1960 |         layout map:    0x13 
   1961 |         name           0x36d351 CBBridgedUIAppView
   1962 |         baseMethods    0x314d78
   1963 |             entsize 12 (relative)
   1964 |             count   31
   1965 |             name    0x94708 (0x3a9488) initWithBundleIdentifier:
   1966 |             types   0x58a3a (0x36d7be) @24@0:8@16
   1967 |             imp     0xffd9741c (0xac1a4)
   1968 |             name    0x93ff4 (0x3a8d80) initWithBundleIdentifier:scale:
   1969 |             types   0x58f18 (0x36dca8) @32@0:8@16d24
   1970 |             imp     0xffd97420 (0xac1b4)
   1971 |             name    0x930b8 (0x3a7e50) setAppScale:

... context gap ...
   2036 |             imp     0xffd9a704 (0xaf5a0)
   2037 |             name    0x93210 (0x3a80b0) appScale
   2038 |             types   0x589b8 (0x36d85c) d16@0:8
   2039 |             imp     0xffd9a70c (0xaf5b4)
   2040 |             name    0x93fac (0x3a8e58) hosting
   2041 |             types   0x58991 (0x36d841) B16@0:8
   2042 |             imp     0xffd9a710 (0xaf5c4)
   2043 |             name    0x93fa8 (0x3a8e60) setHosting:
   2044 |             types   0x5896c (0x36d828) v20@0:8B16
   2045 |             imp     0xffd9a714 (0xaf5d4)
   2046 |             name    0x93f8c (0x3a8e50) invalidated
   2047 |             types   0x58979 (0x36d841) B16@0:8
   2048 |             imp     0xffd9a718 (0xaf5e4)
   2049 |             name    0x94010 (0x3a8ee0) setInvalidated:
   2050 |             types   0x58954 (0x36d828) v20@0:8B16
   2051 |             imp     0xffd9a71c (0xaf5f4)
   2052 |             name    0x931cc (0x3a80a8) audioOnlyBackgroundMode
   2053 |             types   0x58961 (0x36d841) B16@0:8
   2054 |             imp     0xffd9a720 (0xaf604)
   2055 |             name    0x92f00 (0x3a7de8) .cxx_destruct
   2056 |             types   0x588e8 (0x36d7d4) v16@0:8
   2057 |             imp     0xffd9a724 (0xaf614)
   2058 |         baseProtocols  0x0
   2059 |         ivars          0x3a1e80
   2060 |             entsize   32
   2061 |             count     7
   2062 |             offset    0x3aafc0 8
   2063 |             name      0x31f7b7 _hosting
   2064 |             type      0x36d86f B
   2065 |             alignment 0
   2066 |             size      1
   2067 |             offset    0x3aafc4 9
   2068 |             name      0x31f7c0 _invalidated
   2069 |             type      0x36d86f B
   2070 |             alignment 0
   2071 |             size      1
   2072 |             offset    0x3aafc8 10
   2073 |             name      0x31f7cd _audioOnlyBackgroundMode
   2074 |             type      0x36d86f B
   2075 |             alignment 0
   2076 |             size      1
   2077 |             offset    0x3aafb8 16
   2078 |             name      0x31f7e6 _bundleIdentifier

... context gap ...
   2101 |             name       0x31bddf bundleIdentifier
   2102 |             attributes 0x31f822 T@"NSString",C,N,V_bundleIdentifier
   2103 |             name       0x31f752 appViewController
   2104 |             attributes 0x31f846 T@"SBAppViewController",&,N,V_appViewController
   2105 |             name       0x31f77a wrapperView
   2106 |             attributes 0x31f876 T@"UIView",&,N,V_wrapperView
   2107 |             name       0x31f796 appScale
   2108 |             attributes 0x31f893 Td,N,V_appScale
   2109 |             name       0x31f497 hosting
   2110 |             attributes 0x31f8a3 TB,N,V_hosting
   2111 |             name       0x31f48b invalidated
   2112 |             attributes 0x31f8b2 TB,N,V_invalidated
   2113 |             name       0x31f79f audioOnlyBackgroundMode
   2114 |             attributes 0x31f8c5 TB,N,V_audioOnlyBackgroundMode
   2115 | Meta Class
   2116 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   2117 |     superclass 0x0 _OBJC_METACLASS_$_UIView
   2118 |     cache      0x0 __objc_empty_cache
   2119 |     vtable     0x0
   2120 |     data       0x3a1e38
   2121 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   2122 |         instanceStart  40
   2123 |         instanceSize   40
   2124 |         reserved       0x00000000
   2125 |         ivarLayout     0x0
   2126 |         name           0x36d351 CBBridgedUIAppView
   2127 |         baseMethods    0x0
   2128 |         baseProtocols  0x0
   2129 |         ivars          0x0
   2130 |         weakIvarLayout 0x0
   2131 |         baseProperties 0x0
   2132 | 000000000039f3e0 0x3ab6b0
   2133 |     isa        0x3ab6d8
   2134 |     superclass 0x0 _OBJC_CLASS_$_NSObject
   2135 |     cache      0x0 __objc_empty_cache
   2136 |     vtable     0x0
   2137 |     data       0x3a25b0
   2138 |         flags          0x194 RO_HAS_CXX_STRUCTORS
   2139 |         instanceStart  8
   2140 |         instanceSize   112
   2141 |         reserved       0x00000000
   2142 |         ivarLayout     0x36d38b
   2143 |         layout map:    0x02 0x16 
   2144 |         name           0x36d366 CBWindow
   2145 |         baseMethods    0x314f70
   2146 |             entsize 12 (relative)
   2147 |             count   31
   2148 |             name    0x94e18 (0x3a9d90) initWithAppFrame:
   2149 |             types   0x589d9 (0x36d955) @48@0:8{CGRect={CGPoint=dd}{CGSize=dd}}16
   2150 |             imp     0xffd9a9e0 (0xaf960)
   2151 |             name    0x9311c (0x3a80a0) getCarPlayDisplay
   2152 |             types   0x5882e (0x36d7b6) @16@0:8
   2153 |             imp     0xffd9c73c (0xb16c8)
   2154 |             name    0x93fa0 (0x3a8f30) createWindows

... context gap ...
   2168 |             imp     0xffd9d4e4 (0xb24ac)
   2169 |             name    0x94dac (0x3a9d78) show
   2170 |             types   0x58804 (0x36d7d4) v16@0:8
   2171 |             imp     0xffd9d840 (0xb2814)
   2172 |             name    0x930c0 (0x3a8098) hide:
   2173 |             types   0x588e4 (0x36d8c0) v24@0:8@?16
   2174 |             imp     0xffd9d9d0 (0xb29b0)
   2175 |             name    0x94d64 (0x3a9d48) isDisplayValid
   2176 |             types   0x58859 (0x36d841) B16@0:8
   2177 |             imp     0xffd9dbd4 (0xb2bc0)
   2178 |             name    0x940e0 (0x3a90d0) destroyWindows
   2179 |             types   0x587e0 (0x36d7d4) v16@0:8
   2180 |             imp     0xffd9dd1c (0xb2d14)
   2181 |             name    0x93f2c (0x3a8f28) dismiss
   2182 |             types   0x587d4 (0x36d7d4) v16@0:8
   2183 |             imp     0xffd9e0c0 (0xb30c4)
   2184 |             name    0x93798 (0x3a87a0) dealloc
   2185 |             types   0x587c8 (0x36d7d4) v16@0:8
   2186 |             imp     0xffd9e0c0 (0xb30d0)
   2187 |             name    0x945b4 (0x3a95c8) showAppPickerForSlot:
   2188 |             types   0x58839 (0x36d851) v24@0:8q16

... context gap ...
   2423 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   2424 |     superclass 0x0 _OBJC_METACLASS_$_NSObject
   2425 |     cache      0x0 __objc_empty_cache
   2426 |     vtable     0x0
   2427 |     data       0x3a2358
   2428 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   2429 |         instanceStart  40
   2430 |         instanceSize   40
   2431 |         reserved       0x00000000
   2432 |         ivarLayout     0x0
   2433 |         name           0x36d366 CBWindow
   2434 |         baseMethods    0x314ef8
   2435 |             entsize 12 (relative)
   2436 |             count   9
   2437 |             name    0x940b8 (0x3a8fb8) activeCarPlayWindow
   2438 |             types   0x588b2 (0x36d7b6) @16@0:8
   2439 |             imp     0xffd9ab1c (0xafa24)
   2440 |             name    0x94e04 (0x3a9d10) resetCachedBounds
   2441 |             types   0x588c4 (0x36d7d4) v16@0:8
   2442 |             imp     0xffd9ab2c (0xafa40)
   2443 |             name    0x94090 (0x3a8fa8) carPlayWindowScene

... context gap ...
   3963 |             type      0x36dea3 @"NSTimer"
   3964 |             alignment 3
   3965 |             size      8
   3966 |             offset    0x3ab100 16
   3967 |             name      0x320fa7 _lastActivityTime
   3968 |             type      0x36d87e d
   3969 |             alignment 3
   3970 |             size      8
   3971 |             offset    0x3ab0f8 24
   3972 |             name      0x320fb9 _appView
   3973 |             type      0x36e0cd @"CBBridgedUIAppView"
   3974 |             alignment 3
   3975 |             size      8
   3976 |             offset    0x3ab0fc 32
   3977 |             name      0x320fc2 _notchPill
   3978 |             type      0x36e0e3 @"CBSlotPillView"
   3979 |             alignment 3
   3980 |             size      8
   3981 |             offset    0x3ab0f4 40
   3982 |             name      0x320fcd _customScale
   3983 |             type      0x36d87e d
   3984 |             alignment 3
   3985 |             size      8
   3986 |         weakIvarLayout 0x0
   3987 |         baseProperties 0x3a39c8
   3988 |             entsize    16
   3989 |             count      3
   3990 |             name       0x320f4f appView
   3991 |             attributes 0x320fda T@"CBBridgedUIAppView",&,N,V_appView
   3992 |             name       0x320f63 notchPill
   3993 |             attributes 0x320fff T@"CBSlotPillView",&,N,V_notchPill
   3994 |             name       0x320f7b customScale
   3995 |             attributes 0x321022 Td,N,V_customScale
   3996 | Meta Class
   3997 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   3998 |     superclass 0x3ab908
   3999 |     cache      0x0 __objc_empty_cache
   4000 |     vtable     0x0
   4001 |     data       0x3a38d8

... context gap ...
   4544 |             imp     0xffdf312c (0x108e24)
   4545 |             name    0x920ec (0x3a7de8) .cxx_destruct
   4546 |             types   0x57ad4 (0x36d7d4) v16@0:8
   4547 |             imp     0xffdf3134 (0x108e38)
   4548 |         baseProtocols  0x0
   4549 |         ivars          0x3a41e0
   4550 |             entsize   32
   4551 |             count     1
   4552 |             offset    0x3ab130 8
   4553 |             name      0x3213d5 _splitApp
   4554 |             type      0x36e122 @"CBBridgedSplitApp"
   4555 |             alignment 3
   4556 |             size      8
   4557 |         weakIvarLayout 0x36d45e
   4558 |         layout map:    0x01 
   4559 |         baseProperties 0x3a4208
   4560 |             entsize    16
   4561 |             count      1
   4562 |             name       0x3213ae splitApp
   4563 |             attributes 0x3213df T@"CBBridgedSplitApp",W,N,V_splitApp
   4564 | Meta Class
   4565 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   4566 |     superclass 0x0 _OBJC_METACLASS_$_UIView
   4567 |     cache      0x0 __objc_empty_cache
   4568 |     vtable     0x0
   4569 |     data       0x3a4198
   4570 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   4571 |         instanceStart  40
   4572 |         instanceSize   40
   4573 |         reserved       0x00000000

... context gap ...
   4707 |     superclass 0x3ab8e0
   4708 |     cache      0x0 __objc_empty_cache
   4709 |     vtable     0x0
   4710 |     data       0x3a46b0
   4711 |         flags          0x194 RO_HAS_CXX_STRUCTORS
   4712 |         instanceStart  8
   4713 |         instanceSize   120
   4714 |         reserved       0x00000000
   4715 |         ivarLayout     0x36d4e8
   4716 |         layout map:    0x21 0x26 
   4717 |         name           0x36d4d6 CBBridgedSplitApp
   4718 |         baseMethods    0x3157c8
   4719 |             entsize 12 (relative)
   4720 |             count   50
   4721 |             name    0x93c90 (0x3a9460) initWithBundleIdentifier:frame:
   4722 |             types   0x5887b (0x36e04f) @56@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24
   4723 |             imp     0xffdf43e0 (0x109bb8)
   4724 |             name    0x93dbc (0x3a9598) initWithBundleIdentifier:frame:showSplash:
   4725 |             types   0x58957 (0x36e137) @60@0:8@16{CGRect={CGPoint=dd}{CGSize=dd}}24B56
   4726 |             imp     0xffdf43e4 (0x109bc8)
   4727 |             name    0x93dc8 (0x3a95b0) handleDividerPan:isVertical:state:

... context gap ...
   4970 |     isa        0x0 _OBJC_METACLASS_$_NSObject
   4971 |     superclass 0x3ab908
   4972 |     cache      0x0 __objc_empty_cache
   4973 |     vtable     0x0
   4974 |     data       0x3a43f8
   4975 |         flags          0x195 RO_META RO_HAS_CXX_STRUCTORS
   4976 |         instanceStart  40
   4977 |         instanceSize   40
   4978 |         reserved       0x00000000
   4979 |         ivarLayout     0x0
   4980 |         name           0x36d4d6 CBBridgedSplitApp
   4981 |         baseMethods    0x0
   4982 |         baseProtocols  0x0
   4983 |         ivars          0x0
   4984 |         weakIvarLayout 0x0
   4985 |         baseProperties 0x0
   4986 | 000000000039f460 0x3abbb0
   4987 |     isa        0x3abbd8
   4988 |     superclass 0x0 _OBJC_CLASS_$_NSObject
   4989 |     cache      0x0 __objc_empty_cache
   4990 |     vtable     0x0

... context gap ...
   8800 |             type      0x36d7dc @"NSString"
   8801 |             alignment 3
   8802 |             size      8
   8803 |             offset    0x3ab2b8 56
   8804 |             name      0x31f7e6 _bundleIdentifier
   8805 |             type      0x36d7dc @"NSString"
   8806 |             alignment 3
   8807 |             size      8
   8808 |             offset    0x3ab2bc 64
   8809 |             name      0x32377b _window
   8810 |             type      0x36e9e0 @"CBWindow"
   8811 |             alignment 3
   8812 |             size      8
   8813 |             offset    0x3ab2c0 72
   8814 |             name      0x323783 _currentApp
   8815 |             type      0x36e9ec @"CBBridgedApp"
   8816 |             alignment 3
   8817 |             size      8
   8818 |             offset    0x3ab2c4 80
   8819 |             name      0x32378f _licenseWarningModal
   8820 |             type      0x36e9fc @"CBLicenseWarningModalView"

... context gap ...
   8833 |             offset    0x3ab2d0 128
   8834 |             name      0x3237ba _renderSize
   8835 |             type      0x36ea19 {CGSize="width"d"height"d}
   8836 |             alignment 3
   8837 |             size      16
   8838 |         weakIvarLayout 0x0
   8839 |         baseProperties 0x3a77f0
   8840 |             entsize    16
   8841 |             count      8
   8842 |             name       0x31f2d0 window
   8843 |             attributes 0x3237c6 T@"CBWindow",&,N,V_window
   8844 |             name       0x31dd54 currentApp
   8845 |             attributes 0x3237e0 T@"CBBridgedApp",&,N,V_currentApp
   8846 |             name       0x323695 licenseWarningModal
   8847 |             attributes 0x323802 T@"CBLicenseWarningModalView",&,N,V_licenseWarningModal
   8848 |             name       0x31bddf bundleIdentifier
   8849 |             attributes 0x31f822 T@"NSString",C,N,V_bundleIdentifier
   8850 |             name       0x320c0f activated
   8851 |             attributes 0x32383a TB,N,V_activated
   8852 |             name       0x31fce3 appFrame
   8853 |             attributes 0x31fe18 T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_appFrame

... context gap ...
  11159 |      0x31cd7b stringWithUTF8String:
  11160 |      0x31cd91 bytes
  11161 |      0x31cd97 dataWithBytes:length:
  11162 |      0x31cdad dataWithJSONObject:options:error:
  11163 |      0x31cdcf setHTTPBody:
  11164 |      0x31cddc ephemeralSessionConfiguration
  11165 |      0x31cdfa setTimeoutIntervalForRequest:
  11166 |      0x31ce18 setTimeoutIntervalForResource:
  11167 |      0x31ce37 sessionWithConfiguration:
  11168 |      0x31ce51 valueForHTTPHeaderField:
  11169 |      0x31ce6a finishTasksAndInvalidate
  11170 |      0x31ce83 localizedCaseInsensitiveContainsString:
  11171 |      0x31ceab dataTaskWithRequest:completionHandler:
  11172 |      0x31ced2 resume
  11173 |      0x31cf48 initWithBytes:length:
  11174 |      0x31cf5e dataWithLength:
  11175 |      0x31cf6e mutableBytes
  11176 |      0x31cf7b initWithData:encoding:
  11177 |      0x31cf92 description
  11178 |      0x31cf9e URL
  11179 |      0x31cfa2 absoluteString

... context gap ...
  11236 |      0x31d628 blackColor
  11237 |      0x31d633 setBackgroundColor:
  11238 |      0x31d647 setContentMode:
  11239 |      0x31d657 setAutoresizingMask:
  11240 |      0x31d66c addSubview:
  11241 |      0x31d678 captureFrame:
  11242 |      0x31d686 displayLinkWithTarget:selector:
  11243 |      0x31d6a6 setPreferredFramesPerSecond:
  11244 |      0x31d6c3 mainRunLoop
  11245 |      0x31d6cf addToRunLoop:forMode:
  11246 |      0x31d6e5 invalidate
  11247 |      0x31d6f0 imageView
  11248 |      0x31d6fa setImage:
  11249 |      0x31d704 stop
  11250 |      0x31d709 dealloc
  11251 |      0x31d7f9 clearColor
  11252 |      0x31d804 setClipsToBounds:
  11253 |      0x31d816 CGColor
  11254 |      0x31d81e layer
  11255 |      0x31d824 setShadowColor:
  11256 |      0x31d834 setShadowOffset:

... context gap ...
  11454 |      0x31f3d8 sceneIfExists
  11455 |      0x31f3e6 scene
  11456 |      0x31f3ec updateSettingsWithBlock:
  11457 |      0x31f405 setForeground:
  11458 |      0x31f414 setOccluded:
  11459 |      0x31f421 setUnderLock:
  11460 |      0x31f42f setCanShowWhileLocked:
  11461 |      0x31f446 setDeactivationReasons:
  11462 |      0x31f45e setIdleModeEnabled:
  11463 |      0x31f472 updateSceneSettingsFrame
  11464 |      0x31f48b invalidated
  11465 |      0x31f497 hosting
  11466 |      0x31f49f setHosting:
  11467 |      0x31f4ab sharedInstanceIfExists
  11468 |      0x31f4c2 rootViewController
  11469 |      0x31f4d5 applicationWithBundleIdentifier:
  11470 |      0x31f4f6 initWithApplicationForMainDisplay:
  11471 |      0x31f519 instancesRespondToSelector:
  11472 |      0x31f535 UUID
  11473 |      0x31f53a UUIDString
  11474 |      0x31f545 initWithIdentifier:andApplicationSceneEntity:
  11475 |      0x31f573 addChildViewController:
  11476 |      0x31f58b setIgnoresOcclusions:
  11477 |      0x31f5a1 setAutomatesLifecycle:
  11478 |      0x31f5b8 setRequestedMode:
  11479 |      0x31f5ca setOpaque:
  11480 |      0x31f5d5 didMoveToParentViewController:
  11481 |      0x31f5f4 startInParentViewController:
  11482 |      0x31f611 setInvalidated:
  11483 |      0x31f621 beginAppearanceTransition:animated:
  11484 |      0x31f645 endAppearanceTransition
  11485 |      0x31f65d willMoveToParentViewController:
  11486 |      0x31f67d removeFromParentViewController
  11487 |      0x31f69c hostedScene
  11488 |      0x31f6a8 initWithURL:
  11489 |      0x31f6b5 sendActions:
  11490 |      0x31f6c2 setWithObject:
  11491 |      0x31f6d1 dismiss
  11492 |      0x31f8e4 createWindows
  11493 |      0x31f8f2 resizeWindows
  11494 |      0x31f900 sharedApplication
  11495 |      0x31f912 carPlayUIScreen
  11496 |      0x31f922 connectedScenes

... context gap ...
  11534 |      0x31fb6a switchToMultiSplitMode:apps:ratio:
  11535 |      0x31ecee setOnMultiSplitSelected:
  11536 |      0x31fb8d setEffect:
  11537 |      0x31fb98 updateBoundaryBounds:
  11538 |      0x31fbae removeAllAnimations
  11539 |      0x31fbc2 makeKeyAndVisible
  11540 |      0x31fbd4 frame
  11541 |      0x31fbda windowLevel
  11542 |      0x31fbe6 resignKeyWindow
  11543 |      0x31fbf6 windowScene
  11544 |      0x31fc02 destroyWindows
  11545 |      0x31fc11 multitaskingOverlay
  11546 |      0x31ec7d showAppPickerForSlot:parentView:
  11547 |      0x31ec9e showLayoutChooserInParentView:
  11548 |      0x31ecbd showRecentAppsInParentView:
  11549 |      0x31db77 pointInside:withEvent:
  11550 |      0x31ff5d sendEvent:
  11551 |      0x31ff68 isUserInteractionEnabled
  11552 |      0x31ff81 convertPoint:fromView:
  11553 |      0x31ff98 type
  11554 |      0x31ff9d allTouches

... context gap ...
  11844 |      0x322579 initWithData:error:
  11845 |      0x32258d setVolume:
  11846 |      0x322598 prepareToPlay
  11847 |      0x3225a6 play
  11848 |      0x3225ab setIsPlaying:
  11849 |      0x3225b9 playWithCompletion:
  11850 |      0x3227a7 _wipeSessionKey
  11851 |      0x3227b7 setMaxConcurrentOperationCount:
  11852 |      0x3227d7 isConnected
  11853 |      0x3227e3 cancelWithCloseCode:reason:
  11854 |      0x3227ff invalidateAndCancel
  11855 |      0x322813 setIsConnected:
  11856 |      0x322823 substringFromIndex:
  11857 |      0x322837 defaultSessionConfiguration
  11858 |      0x322853 sessionWithConfiguration:delegate:delegateQueue:
  11859 |      0x322884 requestWithURL:
  11860 |      0x322894 webSocketTaskWithRequest:
  11861 |      0x3228ae code
  11862 |      0x3228b3 handleSocketCloseWithCode:
  11863 |      0x3228ce voiceTransportDidFailWithError:
  11864 |      0x3228ee listenForIncomingMessagesForSession:task:generation:

... context gap ...
  12197 |      0x324bcd startPictureInPicture
  12198 |      0x324be3 setCanStartPictureInPictureAutomaticallyFromInline:
  12199 |      0x324c17 canStartPictureInPictureAutomaticallyFromInline
  12200 |      0x324c47 isWirelessRouteActive
  12201 |      0x324c5d areWirelessRoutesAvailable
  12202 |      0x324c78 application
  12203 |      0x324c84 clientProcess
  12204 |      0x324c92 clientHandle
  12205 |      0x324c9f definition
  12206 |      0x324caa clientIdentity
  12207 |      0x324cb9 updateSettings:withTransitionContext:completion:
  12208 |      0x324cea _applyUpdateWithContext:completion:
  12209 |      0x324d0e scene:didPrepareUpdateWithContext:
  12210 |      0x324d31 interceptUpdateForScene:withNewSettings:
  12211 |      0x324d5a _shouldBeBackgroundUnderLockForScene:withSettings:
  12212 |      0x324d8d shouldBeUnderLockForScene:
  12213 |      0x324da8 _mainSceneSupportsInterfaceOrientation:
  12214 |      0x324dd0 sceneHandle:didUpdateSettingsWithDiff:previousSettings:
  12215 |      0x324e08 sceneHandle:didDestroyScene:
  12216 |      0x324e25 systemService:isPasscodeLockedOrBlockedWithResult:
  12217 |      0x324e58 systemService:canActivateApplication:withResult:
~~~

## LLVM disassembly contexts
Source file: disasm.txt; matches=147

~~~text

... context gap ...
  46861 |    333f0:	fd 03 1d aa	mov	x29, x29
  46862 |    333f4:	fb 80 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  46863 |    333f8:	fa 03 00 aa	mov	x26, x0
  46864 |    333fc:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  46865 |    33400:	01 4d 42 f9	ldr	x1, [x8, #0x498] ; Objc selector ref: errorWithDomain:code:userInfo:
  46866 |    33404:	22 1b 00 90	adrp	x2, 868 ; 0x397000
  46867 |    33408:	42 80 39 91	add	x2, x2, #0xe60 ; Objc cfstring ref: @"CBHttpClientErrorDomain"
  46868 |    3340c:	e0 03 19 aa	mov	x0, x25
  46869 |    33410:	63 7d 80 92	mov	x3, #-0x3ec
  46870 |    33414:	e4 03 1a aa	mov	x4, x26
  46871 |    33418:	da 80 0b 94	bl	0x313780 ; Objc message: -[x0 errorWithDomain:code:userInfo:]
  46872 |    3341c:	fd 03 1d aa	mov	x29, x29
  46873 |    33420:	f0 80 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  46874 |    33424:	f9 03 00 aa	mov	x25, x0
  46875 |    33428:	e0 03 1a aa	mov	x0, x26
  46876 |    3342c:	e1 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46877 |    33430:	e0 16 40 f9	ldr	x0, [x23, #0x28]
  46878 |    33434:	c0 00 00 b4	cbz	x0, 0x3344c
  46879 |    33438:	08 08 40 f9	ldr	x8, [x0, #0x10]
  46880 |    3343c:	e1 03 14 aa	mov	x1, x20
  46881 |    33440:	e2 03 16 aa	mov	x2, x22
  46882 |    33444:	e3 03 19 aa	mov	x3, x25
  46883 |    33448:	00 01 3f d6	blr	x8
  46884 |    3344c:	e0 1a 40 f9	ldr	x0, [x23, #0x30]
  46885 |    33450:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  46886 |    33454:	01 8d 42 f9	ldr	x1, [x8, #0x518] ; Objc selector ref: finishTasksAndInvalidate
  46887 |    33458:	ca 80 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  46888 |    3345c:	f5 03 40 f9	ldr	x21, [sp]
  46889 |    33460:	e0 03 19 aa	mov	x0, x25
  46890 |    33464:	d3 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46891 |    33468:	e0 03 18 aa	mov	x0, x24
  46892 |    3346c:	d1 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46893 |    33470:	58 00 00 14	b	0x335d0
  46894 |    33474:	e0 03 14 aa	mov	x0, x20
  46895 |    33478:	e1 03 19 aa	mov	x1, x25
  46896 |    3347c:	c1 80 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  46897 |    33480:	1f 14 00 f1	cmp	x0, #0x5
  46898 |    33484:	83 04 00 54	b.lo	0x33514
  46899 |    33488:	e0 03 14 aa	mov	x0, x20
  46900 |    3348c:	e1 03 19 aa	mov	x1, x25
  46901 |    33490:	bc 80 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  46902 |    33494:	1f 00 04 f1	cmp	x0, #0x100
  46903 |    33498:	08 20 80 52	mov	w8, #0x100
  46904 |    3349c:	1b 30 88 9a	csel	x27, x0, x8, lo
  46905 |    334a0:	e0 03 14 aa	mov	x0, x20
  46906 |    334a4:	c9 80 0b 94	bl	0x3137c8 ; symbol stub for: _objc_retainAutorelease
  46907 |    334a8:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  46908 |    334ac:	01 69 42 f9	ldr	x1, [x8, #0x4d0] ; Objc selector ref: bytes
  46909 |    334b0:	b4 80 0b 94	bl	0x313780 ; Objc message: -[x0 bytes]
  46910 |    334b4:	7f 17 00 f1	cmp	x27, #0x5
  46911 |    334b8:	e3 02 00 54	b.lo	0x33514
  46912 |    334bc:	f9 03 00 aa	mov	x25, x0
  46913 |    334c0:	18 00 80 d2	mov	x24, #0x0
  46914 |    334c4:	75 13 00 d1	sub	x21, x27, #0x4
  46915 |    334c8:	3c 03 18 8b	add	x28, x25, x24
  46916 |    334cc:	e0 03 1c aa	mov	x0, x28
  46917 |    334d0:	e1 17 00 b0	adrp	x1, 765 ; 0x330000
  46918 |    334d4:	21 6c 39 91	add	x1, x1, #0xe5b ; literal pool for: "<html"
  46919 |    334d8:	a2 00 80 52	mov	w2, #0x5
  46920 |    334dc:	09 81 0b 94	bl	0x313900 ; symbol stub for: _strncasecmp
  46921 |    334e0:	20 f5 ff 34	cbz	w0, 0x33384
  46922 |    334e4:	08 27 00 91	add	x8, x24, #0x9
  46923 |    334e8:	1f 01 1b eb	cmp	x8, x27
  46924 |    334ec:	e8 00 00 54	b.hi	0x33508
  46925 |    334f0:	e0 03 1c aa	mov	x0, x28
  46926 |    334f4:	e1 17 00 b0	adrp	x1, 765 ; 0x330000

... context gap ...
  46954 |    33564:	f9 03 00 aa	mov	x25, x0
  46955 |    33568:	40 0c 00 b4	cbz	x0, 0x336f0
  46956 |    3356c:	e0 03 14 aa	mov	x0, x20
  46957 |    33570:	90 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46958 |    33574:	f4 03 19 aa	mov	x20, x25
  46959 |    33578:	09 00 00 14	b	0x3359c
  46960 |    3357c:	f5 03 40 f9	ldr	x21, [sp]
  46961 |    33580:	07 00 00 14	b	0x3359c
  46962 |    33584:	22 1b 00 90	adrp	x2, 868 ; 0x397000
  46963 |    33588:	42 80 3b 91	add	x2, x2, #0xee0 ; Objc cfstring ref: @"application/json"
  46964 |    3358c:	e0 03 18 aa	mov	x0, x24
  46965 |    33590:	e1 03 19 aa	mov	x1, x25
  46966 |    33594:	7b 80 0b 94	bl	0x313780 ; Objc message: -[x0 localizedCaseInsensitiveContainsString:]
  46967 |    33598:	80 04 00 36	tbz	w0, #0x0, 0x33628
  46968 |    3359c:	e0 03 18 aa	mov	x0, x24
  46969 |    335a0:	84 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46970 |    335a4:	e0 16 40 f9	ldr	x0, [x23, #0x28]
  46971 |    335a8:	c0 00 00 b4	cbz	x0, 0x335c0
  46972 |    335ac:	08 08 40 f9	ldr	x8, [x0, #0x10]
  46973 |    335b0:	e1 03 14 aa	mov	x1, x20
  46974 |    335b4:	e2 03 16 aa	mov	x2, x22
  46975 |    335b8:	e3 03 15 aa	mov	x3, x21
  46976 |    335bc:	00 01 3f d6	blr	x8
  46977 |    335c0:	e0 1a 40 f9	ldr	x0, [x23, #0x30]
  46978 |    335c4:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  46979 |    335c8:	01 8d 42 f9	ldr	x1, [x8, #0x518] ; Objc selector ref: finishTasksAndInvalidate
  46980 |    335cc:	6d 80 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  46981 |    335d0:	e0 03 16 aa	mov	x0, x22
  46982 |    335d4:	77 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46983 |    335d8:	e0 03 15 aa	mov	x0, x21
  46984 |    335dc:	75 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46985 |    335e0:	e0 03 13 aa	mov	x0, x19
  46986 |    335e4:	73 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46987 |    335e8:	e0 03 14 aa	mov	x0, x20
  46988 |    335ec:	71 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  46989 |    335f0:	e8 1f 40 f9	ldr	x8, [sp, #0x38]
  46990 |    335f4:	e9 19 00 b0	adrp	x9, 829 ; 0x370000
  46991 |    335f8:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
  46992 |    335fc:	29 01 40 f9	ldr	x9, [x9]
  46993 |    33600:	3f 01 08 eb	cmp	x9, x8
  46994 |    33604:	e1 0d 00 54	b.ne	0x337c0
  46995 |    33608:	fd 7b 49 a9	ldp	x29, x30, [sp, #0x90]
  46996 |    3360c:	f4 4f 48 a9	ldp	x20, x19, [sp, #0x80]
  46997 |    33610:	f6 57 47 a9	ldp	x22, x21, [sp, #0x70]
  46998 |    33614:	f8 5f 46 a9	ldp	x24, x23, [sp, #0x60]
  46999 |    33618:	fa 67 45 a9	ldp	x26, x25, [sp, #0x50]
  47000 |    3361c:	fc 6f 44 a9	ldp	x28, x27, [sp, #0x40]
  47001 |    33620:	ff 83 02 91	add	sp, sp, #0xa0
  47002 |    33624:	c0 03 5f d6	ret
  47003 |    33628:	e1 12 40 f9	ldr	x1, [x23, #0x20]
  47004 |    3362c:	23 1b 00 b0	adrp	x3, 869 ; 0x398000
  47005 |    33630:	63 80 02 91	add	x3, x3, #0xa0 ; Objc cfstring ref: @"UNSUPPORTED_CONTENT_TYPE"

... context gap ...
  47025 |    33680:	fd 03 1d aa	mov	x29, x29
  47026 |    33684:	57 80 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  47027 |    33688:	fa 03 00 aa	mov	x26, x0
  47028 |    3368c:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  47029 |    33690:	01 4d 42 f9	ldr	x1, [x8, #0x498] ; Objc selector ref: errorWithDomain:code:userInfo:
  47030 |    33694:	22 1b 00 90	adrp	x2, 868 ; 0x397000
  47031 |    33698:	42 80 39 91	add	x2, x2, #0xe60 ; Objc cfstring ref: @"CBHttpClientErrorDomain"
  47032 |    3369c:	e0 03 19 aa	mov	x0, x25
  47033 |    336a0:	63 7d 80 92	mov	x3, #-0x3ec
  47034 |    336a4:	e4 03 1a aa	mov	x4, x26
  47035 |    336a8:	36 80 0b 94	bl	0x313780 ; Objc message: -[x0 errorWithDomain:code:userInfo:]
  47036 |    336ac:	fd 03 1d aa	mov	x29, x29
  47037 |    336b0:	4c 80 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  47038 |    336b4:	f9 03 00 aa	mov	x25, x0
  47039 |    336b8:	e0 03 1a aa	mov	x0, x26
  47040 |    336bc:	3d 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  47041 |    336c0:	e0 16 40 f9	ldr	x0, [x23, #0x28]
  47042 |    336c4:	c0 00 00 b4	cbz	x0, 0x336dc
  47043 |    336c8:	08 08 40 f9	ldr	x8, [x0, #0x10]
  47044 |    336cc:	e1 03 14 aa	mov	x1, x20
  47045 |    336d0:	e2 03 16 aa	mov	x2, x22
  47046 |    336d4:	e3 03 19 aa	mov	x3, x25
  47047 |    336d8:	00 01 3f d6	blr	x8
  47048 |    336dc:	e0 1a 40 f9	ldr	x0, [x23, #0x30]
  47049 |    336e0:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  47050 |    336e4:	01 8d 42 f9	ldr	x1, [x8, #0x518] ; Objc selector ref: finishTasksAndInvalidate
  47051 |    336e8:	26 80 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  47052 |    336ec:	5d ff ff 17	b	0x33460
  47053 |    336f0:	e1 12 40 f9	ldr	x1, [x23, #0x20]
  47054 |    336f4:	23 1b 00 b0	adrp	x3, 869 ; 0x398000
  47055 |    336f8:	63 80 01 91	add	x3, x3, #0x60 ; Objc cfstring ref: @"AUTH_TAG_MISMATCH"
  47056 |    336fc:	e0 03 16 aa	mov	x0, x22
  47057 |    33700:	e2 03 14 aa	mov	x2, x20
  47058 |    33704:	30 00 00 94	bl	0x337c4
  47059 |    33708:	a8 1b 00 f0	adrp	x8, 887 ; 0x3aa000
  47060 |    3370c:	1a 1d 45 f9	ldr	x26, [x8, #0xa38] ; Objc class ref: _OBJC_CLASS_$_NSError
  47061 |    33710:	e8 19 00 b0	adrp	x8, 829 ; 0x370000
  47062 |    33714:	08 45 40 f9	ldr	x8, [x8, #0x88] ; literal pool symbol address: _NSLocalizedDescriptionKey
  47063 |    33718:	08 01 40 f9	ldr	x8, [x8]
  47064 |    3371c:	29 1b 00 b0	adrp	x9, 869 ; 0x398000
  47065 |    33720:	29 01 02 91	add	x9, x9, #0x80 ; Objc cfstring ref: @"Ciphertext integrity tag mismatch"
  47066 |    33724:	e8 a7 01 a9	stp	x8, x9, [sp, #0x18]
  47067 |    33728:	a8 1b 00 f0	adrp	x8, 887 ; 0x3aa000
  47068 |    3372c:	00 f1 44 f9	ldr	x0, [x8, #0x9e0] ; Objc class ref: _OBJC_CLASS_$_NSDictionary
  47069 |    33730:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  47070 |    33734:	01 65 41 f9	ldr	x1, [x8, #0x2c8] ; Objc selector ref: dictionaryWithObjects:forKeys:count:
  47071 |    33738:	e2 83 00 91	add	x2, sp, #0x20
  47072 |    3373c:	e3 63 00 91	add	x3, sp, #0x18
  47073 |    33740:	24 00 80 52	mov	w4, #0x1
  47074 |    33744:	0f 80 0b 94	bl	0x313780 ; Objc message: +[NSDictionary dictionaryWithObjects:forKeys:count:]
  47075 |    33748:	fd 03 1d aa	mov	x29, x29
  47076 |    3374c:	25 80 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  47077 |    33750:	fb 03 00 aa	mov	x27, x0
  47078 |    33754:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  47079 |    33758:	01 4d 42 f9	ldr	x1, [x8, #0x498] ; Objc selector ref: errorWithDomain:code:userInfo:
  47080 |    3375c:	22 1b 00 90	adrp	x2, 868 ; 0x397000
  47081 |    33760:	42 80 39 91	add	x2, x2, #0xe60 ; Objc cfstring ref: @"CBHttpClientErrorDomain"
  47082 |    33764:	e0 03 1a aa	mov	x0, x26
  47083 |    33768:	43 7d 80 92	mov	x3, #-0x3eb
  47084 |    3376c:	e4 03 1b aa	mov	x4, x27
  47085 |    33770:	04 80 0b 94	bl	0x313780 ; Objc message: -[x0 errorWithDomain:code:userInfo:]
  47086 |    33774:	fd 03 1d aa	mov	x29, x29
  47087 |    33778:	1a 80 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  47088 |    3377c:	fa 03 00 aa	mov	x26, x0
  47089 |    33780:	e0 03 1b aa	mov	x0, x27
  47090 |    33784:	0b 80 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  47091 |    33788:	e0 16 40 f9	ldr	x0, [x23, #0x28]
  47092 |    3378c:	c0 00 00 b4	cbz	x0, 0x337a4
  47093 |    33790:	08 08 40 f9	ldr	x8, [x0, #0x10]
  47094 |    33794:	e1 03 14 aa	mov	x1, x20
  47095 |    33798:	e2 03 16 aa	mov	x2, x22
  47096 |    3379c:	e3 03 1a aa	mov	x3, x26
  47097 |    337a0:	00 01 3f d6	blr	x8
  47098 |    337a4:	e0 1a 40 f9	ldr	x0, [x23, #0x30]
  47099 |    337a8:	a8 1b 00 b0	adrp	x8, 885 ; 0x3a8000
  47100 |    337ac:	01 8d 42 f9	ldr	x1, [x8, #0x518] ; Objc selector ref: finishTasksAndInvalidate
  47101 |    337b0:	f4 7f 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  47102 |    337b4:	e0 03 1a aa	mov	x0, x26
  47103 |    337b8:	fe 7f 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  47104 |    337bc:	29 ff ff 17	b	0x33460
  47105 |    337c0:	3f 7f 0b 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
  47106 |    337c4:	ff 83 02 d1	sub	sp, sp, #0xa0
  47107 |    337c8:	fc 6f 04 a9	stp	x28, x27, [sp, #0x40]
  47108 |    337cc:	fa 67 05 a9	stp	x26, x25, [sp, #0x50]
  47109 |    337d0:	f8 5f 06 a9	stp	x24, x23, [sp, #0x60]
  47110 |    337d4:	f6 57 07 a9	stp	x22, x21, [sp, #0x70]
  47111 |    337d8:	f4 4f 08 a9	stp	x20, x19, [sp, #0x80]
  47112 |    337dc:	fd 7b 09 a9	stp	x29, x30, [sp, #0x90]
  47113 |    337e0:	fd 43 02 91	add	x29, sp, #0x90
  47114 |    337e4:	f6 03 03 aa	mov	x22, x3
  47115 |    337e8:	f5 03 02 aa	mov	x21, x2
  47116 |    337ec:	f4 03 01 aa	mov	x20, x1
  47117 |    337f0:	f3 7f 0b 94	bl	0x3137bc ; symbol stub for: _objc_retain
  47118 |    337f4:	f3 03 00 aa	mov	x19, x0
  47119 |    337f8:	e0 03 14 aa	mov	x0, x20
  47120 |    337fc:	f0 7f 0b 94	bl	0x3137bc ; symbol stub for: _objc_retain
  47121 |    33800:	fc 03 00 aa	mov	x28, x0
  47122 |    33804:	e0 03 15 aa	mov	x0, x21
  47123 |    33808:	ed 7f 0b 94	bl	0x3137bc ; symbol stub for: _objc_retain
  47124 |    3380c:	f5 03 00 aa	mov	x21, x0
  47125 |    33810:	e0 03 16 aa	mov	x0, x22
  47126 |    33814:	ea 7f 0b 94	bl	0x3137bc ; symbol stub for: _objc_retain

... context gap ...
  49271 |    35998:	fd 03 1d aa	mov	x29, x29
  49272 |    3599c:	91 77 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  49273 |    359a0:	fa 03 00 aa	mov	x26, x0
  49274 |    359a4:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49275 |    359a8:	01 4d 42 f9	ldr	x1, [x8, #0x498] ; Objc selector ref: errorWithDomain:code:userInfo:
  49276 |    359ac:	02 1b 00 d0	adrp	x2, 866 ; 0x397000
  49277 |    359b0:	42 80 39 91	add	x2, x2, #0xe60 ; Objc cfstring ref: @"CBHttpClientErrorDomain"
  49278 |    359b4:	e0 03 19 aa	mov	x0, x25
  49279 |    359b8:	63 7d 80 92	mov	x3, #-0x3ec
  49280 |    359bc:	e4 03 1a aa	mov	x4, x26
  49281 |    359c0:	70 77 0b 94	bl	0x313780 ; Objc message: -[x0 errorWithDomain:code:userInfo:]
  49282 |    359c4:	fd 03 1d aa	mov	x29, x29
  49283 |    359c8:	86 77 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  49284 |    359cc:	f9 03 00 aa	mov	x25, x0
  49285 |    359d0:	e0 03 1a aa	mov	x0, x26
  49286 |    359d4:	77 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49287 |    359d8:	e0 16 40 f9	ldr	x0, [x23, #0x28]
  49288 |    359dc:	c0 00 00 b4	cbz	x0, 0x359f4
  49289 |    359e0:	08 08 40 f9	ldr	x8, [x0, #0x10]
  49290 |    359e4:	e1 03 14 aa	mov	x1, x20
  49291 |    359e8:	e2 03 16 aa	mov	x2, x22
  49292 |    359ec:	e3 03 19 aa	mov	x3, x25
  49293 |    359f0:	00 01 3f d6	blr	x8
  49294 |    359f4:	e0 1a 40 f9	ldr	x0, [x23, #0x30]
  49295 |    359f8:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49296 |    359fc:	01 8d 42 f9	ldr	x1, [x8, #0x518] ; Objc selector ref: finishTasksAndInvalidate
  49297 |    35a00:	60 77 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  49298 |    35a04:	f5 03 40 f9	ldr	x21, [sp]
  49299 |    35a08:	e0 03 19 aa	mov	x0, x25
  49300 |    35a0c:	69 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49301 |    35a10:	e0 03 18 aa	mov	x0, x24
  49302 |    35a14:	67 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49303 |    35a18:	58 00 00 14	b	0x35b78
  49304 |    35a1c:	e0 03 14 aa	mov	x0, x20
  49305 |    35a20:	e1 03 19 aa	mov	x1, x25
  49306 |    35a24:	57 77 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  49307 |    35a28:	1f 14 00 f1	cmp	x0, #0x5
  49308 |    35a2c:	83 04 00 54	b.lo	0x35abc
  49309 |    35a30:	e0 03 14 aa	mov	x0, x20
  49310 |    35a34:	e1 03 19 aa	mov	x1, x25
  49311 |    35a38:	52 77 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  49312 |    35a3c:	1f 00 04 f1	cmp	x0, #0x100
  49313 |    35a40:	08 20 80 52	mov	w8, #0x100
  49314 |    35a44:	1b 30 88 9a	csel	x27, x0, x8, lo
  49315 |    35a48:	e0 03 14 aa	mov	x0, x20
  49316 |    35a4c:	5f 77 0b 94	bl	0x3137c8 ; symbol stub for: _objc_retainAutorelease
  49317 |    35a50:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49318 |    35a54:	01 69 42 f9	ldr	x1, [x8, #0x4d0] ; Objc selector ref: bytes
  49319 |    35a58:	4a 77 0b 94	bl	0x313780 ; Objc message: -[x0 bytes]
  49320 |    35a5c:	7f 17 00 f1	cmp	x27, #0x5
  49321 |    35a60:	e3 02 00 54	b.lo	0x35abc
  49322 |    35a64:	f9 03 00 aa	mov	x25, x0
  49323 |    35a68:	18 00 80 d2	mov	x24, #0x0
  49324 |    35a6c:	75 13 00 d1	sub	x21, x27, #0x4
  49325 |    35a70:	3c 03 18 8b	add	x28, x25, x24
  49326 |    35a74:	e0 03 1c aa	mov	x0, x28
  49327 |    35a78:	c1 17 00 f0	adrp	x1, 763 ; 0x330000
  49328 |    35a7c:	21 6c 39 91	add	x1, x1, #0xe5b ; literal pool for: "<html"
  49329 |    35a80:	a2 00 80 52	mov	w2, #0x5
  49330 |    35a84:	9f 77 0b 94	bl	0x313900 ; symbol stub for: _strncasecmp
  49331 |    35a88:	20 f5 ff 34	cbz	w0, 0x3592c
  49332 |    35a8c:	08 27 00 91	add	x8, x24, #0x9
  49333 |    35a90:	1f 01 1b eb	cmp	x8, x27
  49334 |    35a94:	e8 00 00 54	b.hi	0x35ab0
  49335 |    35a98:	e0 03 1c aa	mov	x0, x28
  49336 |    35a9c:	c1 17 00 f0	adrp	x1, 763 ; 0x330000

... context gap ...
  49364 |    35b0c:	f9 03 00 aa	mov	x25, x0
  49365 |    35b10:	40 0c 00 b4	cbz	x0, 0x35c98
  49366 |    35b14:	e0 03 14 aa	mov	x0, x20
  49367 |    35b18:	26 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49368 |    35b1c:	f4 03 19 aa	mov	x20, x25
  49369 |    35b20:	09 00 00 14	b	0x35b44
  49370 |    35b24:	f5 03 40 f9	ldr	x21, [sp]
  49371 |    35b28:	07 00 00 14	b	0x35b44
  49372 |    35b2c:	02 1b 00 d0	adrp	x2, 866 ; 0x397000
  49373 |    35b30:	42 80 3b 91	add	x2, x2, #0xee0 ; Objc cfstring ref: @"application/json"
  49374 |    35b34:	e0 03 18 aa	mov	x0, x24
  49375 |    35b38:	e1 03 19 aa	mov	x1, x25
  49376 |    35b3c:	11 77 0b 94	bl	0x313780 ; Objc message: -[x0 localizedCaseInsensitiveContainsString:]
  49377 |    35b40:	80 04 00 36	tbz	w0, #0x0, 0x35bd0
  49378 |    35b44:	e0 03 18 aa	mov	x0, x24
  49379 |    35b48:	1a 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49380 |    35b4c:	e0 16 40 f9	ldr	x0, [x23, #0x28]
  49381 |    35b50:	c0 00 00 b4	cbz	x0, 0x35b68
  49382 |    35b54:	08 08 40 f9	ldr	x8, [x0, #0x10]
  49383 |    35b58:	e1 03 14 aa	mov	x1, x20
  49384 |    35b5c:	e2 03 16 aa	mov	x2, x22
  49385 |    35b60:	e3 03 15 aa	mov	x3, x21
  49386 |    35b64:	00 01 3f d6	blr	x8
  49387 |    35b68:	e0 1a 40 f9	ldr	x0, [x23, #0x30]
  49388 |    35b6c:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49389 |    35b70:	01 8d 42 f9	ldr	x1, [x8, #0x518] ; Objc selector ref: finishTasksAndInvalidate
  49390 |    35b74:	03 77 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  49391 |    35b78:	e0 03 16 aa	mov	x0, x22
  49392 |    35b7c:	0d 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49393 |    35b80:	e0 03 15 aa	mov	x0, x21
  49394 |    35b84:	0b 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49395 |    35b88:	e0 03 13 aa	mov	x0, x19
  49396 |    35b8c:	09 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49397 |    35b90:	e0 03 14 aa	mov	x0, x20
  49398 |    35b94:	07 77 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49399 |    35b98:	e8 1f 40 f9	ldr	x8, [sp, #0x38]
  49400 |    35b9c:	c9 19 00 f0	adrp	x9, 827 ; 0x370000
  49401 |    35ba0:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
  49402 |    35ba4:	29 01 40 f9	ldr	x9, [x9]
  49403 |    35ba8:	3f 01 08 eb	cmp	x9, x8
  49404 |    35bac:	e1 0d 00 54	b.ne	0x35d68
  49405 |    35bb0:	fd 7b 49 a9	ldp	x29, x30, [sp, #0x90]
  49406 |    35bb4:	f4 4f 48 a9	ldp	x20, x19, [sp, #0x80]
  49407 |    35bb8:	f6 57 47 a9	ldp	x22, x21, [sp, #0x70]
  49408 |    35bbc:	f8 5f 46 a9	ldp	x24, x23, [sp, #0x60]
  49409 |    35bc0:	fa 67 45 a9	ldp	x26, x25, [sp, #0x50]
  49410 |    35bc4:	fc 6f 44 a9	ldp	x28, x27, [sp, #0x40]
  49411 |    35bc8:	ff 83 02 91	add	sp, sp, #0xa0
  49412 |    35bcc:	c0 03 5f d6	ret
  49413 |    35bd0:	e1 12 40 f9	ldr	x1, [x23, #0x20]
  49414 |    35bd4:	03 1b 00 f0	adrp	x3, 867 ; 0x398000
  49415 |    35bd8:	63 80 02 91	add	x3, x3, #0xa0 ; Objc cfstring ref: @"UNSUPPORTED_CONTENT_TYPE"

... context gap ...
  49435 |    35c28:	fd 03 1d aa	mov	x29, x29
  49436 |    35c2c:	ed 76 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  49437 |    35c30:	fa 03 00 aa	mov	x26, x0
  49438 |    35c34:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49439 |    35c38:	01 4d 42 f9	ldr	x1, [x8, #0x498] ; Objc selector ref: errorWithDomain:code:userInfo:
  49440 |    35c3c:	02 1b 00 d0	adrp	x2, 866 ; 0x397000
  49441 |    35c40:	42 80 39 91	add	x2, x2, #0xe60 ; Objc cfstring ref: @"CBHttpClientErrorDomain"
  49442 |    35c44:	e0 03 19 aa	mov	x0, x25
  49443 |    35c48:	63 7d 80 92	mov	x3, #-0x3ec
  49444 |    35c4c:	e4 03 1a aa	mov	x4, x26
  49445 |    35c50:	cc 76 0b 94	bl	0x313780 ; Objc message: -[x0 errorWithDomain:code:userInfo:]
  49446 |    35c54:	fd 03 1d aa	mov	x29, x29
  49447 |    35c58:	e2 76 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  49448 |    35c5c:	f9 03 00 aa	mov	x25, x0
  49449 |    35c60:	e0 03 1a aa	mov	x0, x26
  49450 |    35c64:	d3 76 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49451 |    35c68:	e0 16 40 f9	ldr	x0, [x23, #0x28]
  49452 |    35c6c:	c0 00 00 b4	cbz	x0, 0x35c84
  49453 |    35c70:	08 08 40 f9	ldr	x8, [x0, #0x10]
  49454 |    35c74:	e1 03 14 aa	mov	x1, x20
  49455 |    35c78:	e2 03 16 aa	mov	x2, x22
  49456 |    35c7c:	e3 03 19 aa	mov	x3, x25
  49457 |    35c80:	00 01 3f d6	blr	x8
  49458 |    35c84:	e0 1a 40 f9	ldr	x0, [x23, #0x30]
  49459 |    35c88:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49460 |    35c8c:	01 8d 42 f9	ldr	x1, [x8, #0x518] ; Objc selector ref: finishTasksAndInvalidate
  49461 |    35c90:	bc 76 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  49462 |    35c94:	5d ff ff 17	b	0x35a08
  49463 |    35c98:	e1 12 40 f9	ldr	x1, [x23, #0x20]
  49464 |    35c9c:	03 1b 00 f0	adrp	x3, 867 ; 0x398000
  49465 |    35ca0:	63 80 01 91	add	x3, x3, #0x60 ; Objc cfstring ref: @"AUTH_TAG_MISMATCH"
  49466 |    35ca4:	e0 03 16 aa	mov	x0, x22
  49467 |    35ca8:	e2 03 14 aa	mov	x2, x20
  49468 |    35cac:	c6 f6 ff 97	bl	0x337c4
  49469 |    35cb0:	a8 1b 00 b0	adrp	x8, 885 ; 0x3aa000
  49470 |    35cb4:	1a 1d 45 f9	ldr	x26, [x8, #0xa38] ; Objc class ref: _OBJC_CLASS_$_NSError
  49471 |    35cb8:	c8 19 00 f0	adrp	x8, 827 ; 0x370000
  49472 |    35cbc:	08 45 40 f9	ldr	x8, [x8, #0x88] ; literal pool symbol address: _NSLocalizedDescriptionKey
  49473 |    35cc0:	08 01 40 f9	ldr	x8, [x8]
  49474 |    35cc4:	09 1b 00 f0	adrp	x9, 867 ; 0x398000
  49475 |    35cc8:	29 01 02 91	add	x9, x9, #0x80 ; Objc cfstring ref: @"Ciphertext integrity tag mismatch"
  49476 |    35ccc:	e8 a7 01 a9	stp	x8, x9, [sp, #0x18]
  49477 |    35cd0:	a8 1b 00 b0	adrp	x8, 885 ; 0x3aa000
  49478 |    35cd4:	00 f1 44 f9	ldr	x0, [x8, #0x9e0] ; Objc class ref: _OBJC_CLASS_$_NSDictionary
  49479 |    35cd8:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49480 |    35cdc:	01 65 41 f9	ldr	x1, [x8, #0x2c8] ; Objc selector ref: dictionaryWithObjects:forKeys:count:
  49481 |    35ce0:	e2 83 00 91	add	x2, sp, #0x20
  49482 |    35ce4:	e3 63 00 91	add	x3, sp, #0x18
  49483 |    35ce8:	24 00 80 52	mov	w4, #0x1
  49484 |    35cec:	a5 76 0b 94	bl	0x313780 ; Objc message: +[NSDictionary dictionaryWithObjects:forKeys:count:]
  49485 |    35cf0:	fd 03 1d aa	mov	x29, x29
  49486 |    35cf4:	bb 76 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  49487 |    35cf8:	fb 03 00 aa	mov	x27, x0
  49488 |    35cfc:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49489 |    35d00:	01 4d 42 f9	ldr	x1, [x8, #0x498] ; Objc selector ref: errorWithDomain:code:userInfo:
  49490 |    35d04:	02 1b 00 d0	adrp	x2, 866 ; 0x397000
  49491 |    35d08:	42 80 39 91	add	x2, x2, #0xe60 ; Objc cfstring ref: @"CBHttpClientErrorDomain"
  49492 |    35d0c:	e0 03 1a aa	mov	x0, x26
  49493 |    35d10:	43 7d 80 92	mov	x3, #-0x3eb
  49494 |    35d14:	e4 03 1b aa	mov	x4, x27
  49495 |    35d18:	9a 76 0b 94	bl	0x313780 ; Objc message: -[x0 errorWithDomain:code:userInfo:]
  49496 |    35d1c:	fd 03 1d aa	mov	x29, x29
  49497 |    35d20:	b0 76 0b 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  49498 |    35d24:	fa 03 00 aa	mov	x26, x0
  49499 |    35d28:	e0 03 1b aa	mov	x0, x27
  49500 |    35d2c:	a1 76 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49501 |    35d30:	e0 16 40 f9	ldr	x0, [x23, #0x28]
  49502 |    35d34:	c0 00 00 b4	cbz	x0, 0x35d4c
  49503 |    35d38:	08 08 40 f9	ldr	x8, [x0, #0x10]
  49504 |    35d3c:	e1 03 14 aa	mov	x1, x20
  49505 |    35d40:	e2 03 16 aa	mov	x2, x22
  49506 |    35d44:	e3 03 1a aa	mov	x3, x26
  49507 |    35d48:	00 01 3f d6	blr	x8
  49508 |    35d4c:	e0 1a 40 f9	ldr	x0, [x23, #0x30]
  49509 |    35d50:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49510 |    35d54:	01 8d 42 f9	ldr	x1, [x8, #0x518] ; Objc selector ref: finishTasksAndInvalidate
  49511 |    35d58:	8a 76 0b 94	bl	0x313780 ; Objc message: -[x0 finishTasksAndInvalidate]
  49512 |    35d5c:	e0 03 1a aa	mov	x0, x26
  49513 |    35d60:	94 76 0b 94	bl	0x3137b0 ; symbol stub for: _objc_release
  49514 |    35d64:	29 ff ff 17	b	0x35a08
  49515 |    35d68:	d5 75 0b 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
  49516 |    35d6c:	ff 83 01 d1	sub	sp, sp, #0x60
  49517 |    35d70:	f6 57 03 a9	stp	x22, x21, [sp, #0x30]
  49518 |    35d74:	f4 4f 04 a9	stp	x20, x19, [sp, #0x40]
  49519 |    35d78:	fd 7b 05 a9	stp	x29, x30, [sp, #0x50]
  49520 |    35d7c:	fd 43 01 91	add	x29, sp, #0x50
  49521 |    35d80:	c8 19 00 f0	adrp	x8, 827 ; 0x370000
  49522 |    35d84:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
  49523 |    35d88:	08 01 40 f9	ldr	x8, [x8]
  49524 |    35d8c:	e8 17 00 f9	str	x8, [sp, #0x28]
  49525 |    35d90:	a8 1b 00 f0	adrp	x8, 887 ; 0x3ac000
  49526 |    35d94:	08 b5 46 f9	ldr	x8, [x8, #0xd68]
  49527 |    35d98:	1f 05 00 b1	cmn	x8, #0x1
  49528 |    35d9c:	01 06 00 54	b.ne	0x35e5c
  49529 |    35da0:	a8 1b 00 f0	adrp	x8, 887 ; 0x3ac000
  49530 |    35da4:	00 b1 46 f9	ldr	x0, [x8, #0xd60]
  49531 |    35da8:	85 76 0b 94	bl	0x3137bc ; symbol stub for: _objc_retain
  49532 |    35dac:	87 76 0b 94	bl	0x3137c8 ; symbol stub for: _objc_retainAutorelease
  49533 |    35db0:	f3 03 00 aa	mov	x19, x0
  49534 |    35db4:	88 1b 00 f0	adrp	x8, 883 ; 0x3a8000
  49535 |    35db8:	01 1d 41 f9	ldr	x1, [x8, #0x238] ; Objc selector ref: UTF8String
  49536 |    35dbc:	71 76 0b 94	bl	0x313780 ; Objc message: -[x0 UTF8String]

... context gap ...
 127577 |    820e8:	a6 45 0a 94	bl	0x313780 ; Objc message: +[NSRunLoop mainRunLoop]
 127578 |    820ec:	fd 03 1d aa	mov	x29, x29
 127579 |    820f0:	bc 45 0a 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 127580 |    820f4:	f4 03 00 aa	mov	x20, x0
 127581 |    820f8:	68 17 00 d0	adrp	x8, 750 ; 0x370000
 127582 |    820fc:	08 4d 40 f9	ldr	x8, [x8, #0x98] ; literal pool symbol address: _NSRunLoopCommonModes
 127583 |    82100:	03 01 40 f9	ldr	x3, [x8]
 127584 |    82104:	28 19 00 d0	adrp	x8, 806 ; 0x3a8000
 127585 |    82108:	01 bd 43 f9	ldr	x1, [x8, #0x778] ; Objc selector ref: addToRunLoop:forMode:
 127586 |    8210c:	e0 03 13 aa	mov	x0, x19
 127587 |    82110:	e2 03 14 aa	mov	x2, x20
 127588 |    82114:	9b 45 0a 94	bl	0x313780 ; Objc message: -[x0 addToRunLoop:forMode:]
 127589 |    82118:	e0 03 14 aa	mov	x0, x20
 127590 |    8211c:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
 127591 |    82120:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
 127592 |    82124:	a3 45 0a 14	b	0x3137b0 ; symbol stub for: _objc_release
 127593 |    82128:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
 127594 |    8212c:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
 127595 |    82130:	fd 43 00 91	add	x29, sp, #0x10
 127596 |    82134:	f3 03 00 aa	mov	x19, x0
 127597 |    82138:	48 19 00 90	adrp	x8, 808 ; 0x3aa000
 127598 |    8213c:	14 21 8f b9	ldrsw	x20, [x8, #0xf20]
 127599 |    82140:	00 68 74 f8	ldr	x0, [x0, x20]
 127600 |    82144:	20 01 00 b4	cbz	x0, 0x82168
 127601 |    82148:	28 19 00 d0	adrp	x8, 806 ; 0x3a8000
 127602 |    8214c:	01 c1 43 f9	ldr	x1, [x8, #0x780] ; Objc selector ref: invalidate
 127603 |    82150:	8c 45 0a 94	bl	0x313780 ; Objc message: -[x0 invalidate]
 127604 |    82154:	60 6a 74 f8	ldr	x0, [x19, x20]
 127605 |    82158:	7f 6a 34 f8	str	xzr, [x19, x20]
 127606 |    8215c:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
 127607 |    82160:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
 127608 |    82164:	93 45 0a 14	b	0x3137b0 ; symbol stub for: _objc_release
 127609 |    82168:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
 127610 |    8216c:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
 127611 |    82170:	c0 03 5f d6	ret
 127612 |    82174:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
 127613 |    82178:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
 127614 |    8217c:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
 127615 |    82180:	fd 83 00 91	add	x29, sp, #0x20
 127616 |    82184:	f6 03 00 aa	mov	x22, x0
 127617 |    82188:	e0 03 02 aa	mov	x0, x2
 127618 |    8218c:	8c 45 0a 94	bl	0x3137bc ; symbol stub for: _objc_retain
 127619 |    82190:	f3 03 00 aa	mov	x19, x0
 127620 |    82194:	54 45 0a 94	bl	0x3136e4 ; symbol stub for: _objc_autoreleasePoolPush
 127621 |    82198:	f4 03 00 aa	mov	x20, x0
 127622 |    8219c:	bc 44 0a 94	bl	0x31348c ; symbol stub for: __UICreateScreenUIImage
 127623 |    821a0:	fd 03 1d aa	mov	x29, x29
 127624 |    821a4:	8f 45 0a 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 127625 |    821a8:	f5 03 00 aa	mov	x21, x0
 127626 |    821ac:	c0 01 00 b4	cbz	x0, 0x821e4
 127627 |    821b0:	28 19 00 d0	adrp	x8, 806 ; 0x3a8000
 127628 |    821b4:	01 c5 43 f9	ldr	x1, [x8, #0x788] ; Objc selector ref: imageView

... context gap ...
 168332 |    a9da4:	e0 03 19 aa	mov	x0, x25
 168333 |    a9da8:	02 00 80 d2	mov	x2, #0x0
 168334 |    a9dac:	03 00 80 d2	mov	x3, #0x0
 168335 |    a9db0:	24 00 80 52	mov	w4, #0x1
 168336 |    a9db4:	05 a5 09 94	bl	0x3131c8 ; symbol stub for: _CFNotificationCenterPostNotification
 168337 |    a9db8:	08 18 00 b0	adrp	x8, 769 ; 0x3aa000
 168338 |    a9dbc:	00 81 45 f9	ldr	x0, [x8, #0xb00] ; Objc class ref: CBBridgeManager
 168339 |    a9dc0:	e1 03 1a aa	mov	x1, x26
 168340 |    a9dc4:	6f a6 09 94	bl	0x313780 ; Objc message: +[CBBridgeManager writeToFile:atomically:]
 168341 |    a9dc8:	fd 03 1d aa	mov	x29, x29
 168342 |    a9dcc:	85 a6 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 168343 |    a9dd0:	f9 03 00 aa	mov	x25, x0
 168344 |    a9dd4:	e8 17 00 f0	adrp	x8, 767 ; 0x3a8000
 168345 |    a9dd8:	01 79 46 f9	ldr	x1, [x8, #0xcf0] ; Objc selector ref: isUIAppBridging
 168346 |    a9ddc:	69 a6 09 94	bl	0x313780 ; Objc message: -[x0 isUIAppBridging]
 168347 |    a9de0:	e0 05 00 34	cbz	w0, 0xa9e9c
 168348 |    a9de4:	e8 17 00 f0	adrp	x8, 767 ; 0x3a8000
 168349 |    a9de8:	1a cd 44 f9	ldr	x26, [x8, #0x998] ; Objc selector ref: currentApp
 168350 |    a9dec:	e0 03 19 aa	mov	x0, x25
 168351 |    a9df0:	e1 03 1a aa	mov	x1, x26
 168352 |    a9df4:	63 a6 09 94	bl	0x313780 ; Objc message: -[x0 currentApp]
 168353 |    a9df8:	fd 03 1d aa	mov	x29, x29
 168354 |    a9dfc:	79 a6 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 168355 |    a9e00:	fb 03 00 aa	mov	x27, x0
 168356 |    a9e04:	08 18 00 b0	adrp	x8, 769 ; 0x3aa000
 168357 |    a9e08:	00 99 45 f9	ldr	x0, [x8, #0xb30] ; Objc class ref: CBBridgedSplitApp
 168358 |    a9e0c:	e8 17 00 f0	adrp	x8, 767 ; 0x3a8000
 168359 |    a9e10:	01 c9 41 f9	ldr	x1, [x8, #0x390] ; Objc selector ref: class
 168360 |    a9e14:	5b a6 09 94	bl	0x313780 ; Objc message: +[CBBridgedSplitApp class]
 168361 |    a9e18:	e2 03 00 aa	mov	x2, x0
 168362 |    a9e1c:	e8 17 00 f0	adrp	x8, 767 ; 0x3a8000
 168363 |    a9e20:	01 cd 41 f9	ldr	x1, [x8, #0x398] ; Objc selector ref: isKindOfClass:
 168364 |    a9e24:	e0 03 1b aa	mov	x0, x27
 168365 |    a9e28:	56 a6 09 94	bl	0x313780 ; Objc message: -[x0 isKindOfClass:]
 168366 |    a9e2c:	fc 03 00 aa	mov	x28, x0
 168367 |    a9e30:	e0 03 1b aa	mov	x0, x27
 168368 |    a9e34:	5f a6 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 168369 |    a9e38:	3c 03 00 34	cbz	w28, 0xa9e9c
 168370 |    a9e3c:	e0 03 19 aa	mov	x0, x25
 168371 |    a9e40:	e1 03 1a aa	mov	x1, x26
 168372 |    a9e44:	4f a6 09 94	bl	0x313780 ; Objc message: -[x0 isKindOfClass:]
 168373 |    a9e48:	fd 03 1d aa	mov	x29, x29
 168374 |    a9e4c:	65 a6 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 168375 |    a9e50:	fa 03 00 aa	mov	x26, x0
 168376 |    a9e54:	e8 17 00 f0	adrp	x8, 767 ; 0x3a8000
 168377 |    a9e58:	01 7d 46 f9	ldr	x1, [x8, #0xcf8] ; Objc selector ref: splitPreset
 168378 |    a9e5c:	49 a6 09 94	bl	0x313780 ; Objc message: -[x0 splitPreset]
 168379 |    a9e60:	e8 07 40 f9	ldr	x8, [sp, #0x8]
 168380 |    a9e64:	68 6a 68 f8	ldr	x8, [x19, x8]
 168381 |    a9e68:	1f 00 08 eb	cmp	x0, x8
 168382 |    a9e6c:	41 01 00 54	b.ne	0xa9e94
 168383 |    a9e70:	62 6a 74 f8	ldr	x2, [x19, x20]
 168384 |    a9e74:	77 08 f8 b7	tbnz	x23, #0x3f, 0xa9f80
 168385 |    a9e78:	e8 17 00 f0	adrp	x8, 767 ; 0x3a8000

... context gap ...
 170629 |    ac188:	c1 00 00 54	b.ne	0xac1a0
 170630 |    ac18c:	fd 7b 53 a9	ldp	x29, x30, [sp, #0x130]
 170631 |    ac190:	f4 4f 52 a9	ldp	x20, x19, [sp, #0x120]
 170632 |    ac194:	fc 6f 51 a9	ldp	x28, x27, [sp, #0x110]
 170633 |    ac198:	ff 03 05 91	add	sp, sp, #0x140
 170634 |    ac19c:	c0 03 5f d6	ret
 170635 |    ac1a0:	c7 9c 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
 170636 |    ac1a4:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170637 |    ac1a8:	01 c1 46 f9	ldr	x1, [x8, #0xd80] ; Objc selector ref: initWithBundleIdentifier:scale:
 170638 |    ac1ac:	00 10 6c 1e	fmov	d0, #0.50000000
 170639 |    ac1b0:	74 9d 09 14	b	0x313780 ; Objc message: -[x0 initWithBundleIdentifier:scale:]
 170640 |    ac1b4:	ff 43 01 d1	sub	sp, sp, #0x50
 170641 |    ac1b8:	f6 57 02 a9	stp	x22, x21, [sp, #0x20]
 170642 |    ac1bc:	f4 4f 03 a9	stp	x20, x19, [sp, #0x30]
 170643 |    ac1c0:	fd 7b 04 a9	stp	x29, x30, [sp, #0x40]
 170644 |    ac1c4:	fd 03 01 91	add	x29, sp, #0x40
 170645 |    ac1c8:	f4 03 00 aa	mov	x20, x0
 170646 |    ac1cc:	28 16 00 90	adrp	x8, 708 ; 0x370000
 170647 |    ac1d0:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 170648 |    ac1d4:	08 01 40 f9	ldr	x8, [x8]
 170649 |    ac1d8:	e8 0f 00 f9	str	x8, [sp, #0x18]
 170650 |    ac1dc:	e0 03 02 aa	mov	x0, x2
 170651 |    ac1e0:	77 9d 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
 170652 |    ac1e4:	f3 03 00 aa	mov	x19, x0
 170653 |    ac1e8:	e8 17 00 d0	adrp	x8, 766 ; 0x3aa000
 170654 |    ac1ec:	08 e1 46 f9	ldr	x8, [x8, #0xdc0] ; Objc class ref: CBBridgedUIAppView
 170655 |    ac1f0:	f4 a3 00 a9	stp	x20, x8, [sp, #0x8]
 170656 |    ac1f4:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170657 |    ac1f8:	01 95 43 f9	ldr	x1, [x8, #0x728] ; Objc selector ref: initWithFrame:
 170658 |    ac1fc:	28 16 00 90	adrp	x8, 708 ; 0x370000
 170659 |    ac200:	08 25 40 f9	ldr	x8, [x8, #0x48] ; literal pool symbol address: _CGRectZero
 170660 |    ac204:	00 05 40 6d	ldp	d0, d1, [x8]
 170661 |    ac208:	02 0d 41 6d	ldp	d2, d3, [x8, #0x10]
 170662 |    ac20c:	e0 23 00 91	add	x0, sp, #0x8
 170663 |    ac210:	62 9d 09 94	bl	0x313798 ; Objc message: -[[x0 super] initWithFrame:]
 170664 |    ac214:	f4 03 00 aa	mov	x20, x0
 170665 |    ac218:	20 06 00 b4	cbz	x0, 0xac2dc
 170666 |    ac21c:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170667 |    ac220:	01 25 42 f9	ldr	x1, [x8, #0x448] ; Objc selector ref: copy
 170668 |    ac224:	e0 03 13 aa	mov	x0, x19
 170669 |    ac228:	56 9d 09 94	bl	0x313780 ; Objc message: -[x0 copy]
 170670 |    ac22c:	e8 17 00 d0	adrp	x8, 766 ; 0x3aa000
 170671 |    ac230:	09 b9 8f b9	ldrsw	x9, [x8, #0xfb8]
 170672 |    ac234:	88 6a 69 f8	ldr	x8, [x20, x9]
 170673 |    ac238:	80 6a 29 f8	str	x0, [x20, x9]
 170674 |    ac23c:	e0 03 08 aa	mov	x0, x8
 170675 |    ac240:	5c 9d 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 170676 |    ac244:	e8 17 00 d0	adrp	x8, 766 ; 0x3aa000
 170677 |    ac248:	08 bd 8f b9	ldrsw	x8, [x8, #0xfbc]
 170678 |    ac24c:	09 fc e7 d2	mov	x9, #0x3fe0000000000000
 170679 |    ac250:	89 6a 28 f8	str	x9, [x20, x8]

... context gap ...
 170759 |    ac390:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170760 |    ac394:	01 15 44 f9	ldr	x1, [x8, #0x828] ; Objc selector ref: setUserInteractionEnabled:
 170761 |    ac398:	e0 03 13 aa	mov	x0, x19
 170762 |    ac39c:	22 00 80 52	mov	w2, #0x1
 170763 |    ac3a0:	f8 9c 09 94	bl	0x313780 ; Objc message: -[x0 setUserInteractionEnabled:]
 170764 |    ac3a4:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170765 |    ac3a8:	01 c5 46 f9	ldr	x1, [x8, #0xd88] ; Objc selector ref: updateLayout
 170766 |    ac3ac:	e0 03 13 aa	mov	x0, x19
 170767 |    ac3b0:	f4 9c 09 94	bl	0x313780 ; Objc message: -[x0 updateLayout]
 170768 |    ac3b4:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170769 |    ac3b8:	01 c9 46 f9	ldr	x1, [x8, #0xd90] ; Objc selector ref: refreshSceneLayout
 170770 |    ac3bc:	e0 03 13 aa	mov	x0, x19
 170771 |    ac3c0:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
 170772 |    ac3c4:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
 170773 |    ac3c8:	ee 9c 09 14	b	0x313780 ; Objc message: -[x0 refreshSceneLayout]
 170774 |    ac3cc:	ff 03 01 d1	sub	sp, sp, #0x40
 170775 |    ac3d0:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
 170776 |    ac3d4:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
 170777 |    ac3d8:	fd c3 00 91	add	x29, sp, #0x30
 170778 |    ac3dc:	f3 03 00 aa	mov	x19, x0
 170779 |    ac3e0:	28 16 00 90	adrp	x8, 708 ; 0x370000
 170780 |    ac3e4:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 170781 |    ac3e8:	08 01 40 f9	ldr	x8, [x8]
 170782 |    ac3ec:	e8 0f 00 f9	str	x8, [sp, #0x18]
 170783 |    ac3f0:	e8 17 00 d0	adrp	x8, 766 ; 0x3aa000
 170784 |    ac3f4:	08 e1 46 f9	ldr	x8, [x8, #0xdc0] ; Objc class ref: CBBridgedUIAppView
 170785 |    ac3f8:	e0 a3 00 a9	stp	x0, x8, [sp, #0x8]
 170786 |    ac3fc:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170787 |    ac400:	01 b1 44 f9	ldr	x1, [x8, #0x960] ; Objc selector ref: layoutSubviews
 170788 |    ac404:	e0 23 00 91	add	x0, sp, #0x8
 170789 |    ac408:	e4 9c 09 94	bl	0x313798 ; Objc message: -[[x0 super] layoutSubviews]
 170790 |    ac40c:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170791 |    ac410:	01 c5 46 f9	ldr	x1, [x8, #0xd88] ; Objc selector ref: updateLayout
 170792 |    ac414:	e0 03 13 aa	mov	x0, x19
 170793 |    ac418:	da 9c 09 94	bl	0x313780 ; Objc message: -[x0 updateLayout]
 170794 |    ac41c:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
 170795 |    ac420:	29 16 00 90	adrp	x9, 708 ; 0x370000
 170796 |    ac424:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
 170797 |    ac428:	29 01 40 f9	ldr	x9, [x9]
 170798 |    ac42c:	3f 01 08 eb	cmp	x9, x8
 170799 |    ac430:	a1 00 00 54	b.ne	0xac444
 170800 |    ac434:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
 170801 |    ac438:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
 170802 |    ac43c:	ff 03 01 91	add	sp, sp, #0x40
 170803 |    ac440:	c0 03 5f d6	ret
 170804 |    ac444:	1e 9c 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
 170805 |    ac448:	ff 03 02 d1	sub	sp, sp, #0x80
 170806 |    ac44c:	e9 23 02 6d	stp	d9, d8, [sp, #0x20]
 170807 |    ac450:	fa 67 03 a9	stp	x26, x25, [sp, #0x30]
 170808 |    ac454:	f8 5f 04 a9	stp	x24, x23, [sp, #0x40]
 170809 |    ac458:	f6 57 05 a9	stp	x22, x21, [sp, #0x50]

... context gap ...
 170834 |    ac4bc:	b1 9c 09 94	bl	0x313780 ; Objc message: -[x0 currentApp]
 170835 |    ac4c0:	fd 03 1d aa	mov	x29, x29
 170836 |    ac4c4:	c7 9c 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 170837 |    ac4c8:	f8 03 00 aa	mov	x24, x0
 170838 |    ac4cc:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170839 |    ac4d0:	17 d1 44 f9	ldr	x23, [x8, #0x9a0] ; Objc selector ref: noteUserActivity
 170840 |    ac4d4:	1f 20 03 d5	nop
 170841 |    ac4d8:	01 ad 41 f9	ldr	x1, [x8, #0x358]
 170842 |    ac4dc:	e2 03 17 aa	mov	x2, x23
 170843 |    ac4e0:	a8 9c 09 94	bl	0x313780 ; Objc message: -[x0 noteUserActivity]
 170844 |    ac4e4:	f9 03 00 aa	mov	x25, x0
 170845 |    ac4e8:	e0 03 18 aa	mov	x0, x24
 170846 |    ac4ec:	b1 9c 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 170847 |    ac4f0:	79 01 00 34	cbz	w25, 0xac51c
 170848 |    ac4f4:	e0 03 15 aa	mov	x0, x21
 170849 |    ac4f8:	e1 03 16 aa	mov	x1, x22
 170850 |    ac4fc:	a1 9c 09 94	bl	0x313780 ; Objc message: -[x0 noteUserActivity]
 170851 |    ac500:	fd 03 1d aa	mov	x29, x29
 170852 |    ac504:	b7 9c 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 170853 |    ac508:	f6 03 00 aa	mov	x22, x0
 170854 |    ac50c:	e1 03 17 aa	mov	x1, x23
 170855 |    ac510:	9c 9c 09 94	bl	0x313780 ; Objc message: -[x0 noteUserActivity]
 170856 |    ac514:	e0 03 16 aa	mov	x0, x22
 170857 |    ac518:	a6 9c 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 170858 |    ac51c:	e8 17 00 d0	adrp	x8, 766 ; 0x3aa000
 170859 |    ac520:	08 e1 46 f9	ldr	x8, [x8, #0xdc0] ; Objc class ref: CBBridgedUIAppView
 170860 |    ac524:	f4 a3 00 a9	stp	x20, x8, [sp, #0x8]
 170861 |    ac528:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170862 |    ac52c:	01 cd 46 f9	ldr	x1, [x8, #0xd98] ; Objc selector ref: hitTest:withEvent:
 170863 |    ac530:	e0 23 00 91	add	x0, sp, #0x8
 170864 |    ac534:	20 1d a9 4e	mov.16b	v0, v9
 170865 |    ac538:	01 1d a8 4e	mov.16b	v1, v8
 170866 |    ac53c:	e2 03 13 aa	mov	x2, x19
 170867 |    ac540:	96 9c 09 94	bl	0x313798 ; Objc message: -[[x0 super] hitTest:withEvent:]
 170868 |    ac544:	fd 03 1d aa	mov	x29, x29
 170869 |    ac548:	a6 9c 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 170870 |    ac54c:	f4 03 00 aa	mov	x20, x0
 170871 |    ac550:	e0 03 15 aa	mov	x0, x21
 170872 |    ac554:	97 9c 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 170873 |    ac558:	e0 03 13 aa	mov	x0, x19
 170874 |    ac55c:	95 9c 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 170875 |    ac560:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
 170876 |    ac564:	29 16 00 90	adrp	x9, 708 ; 0x370000
 170877 |    ac568:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
 170878 |    ac56c:	29 01 40 f9	ldr	x9, [x9]
 170879 |    ac570:	3f 01 08 eb	cmp	x9, x8
 170880 |    ac574:	41 01 00 54	b.ne	0xac59c
 170881 |    ac578:	e0 03 14 aa	mov	x0, x20
 170882 |    ac57c:	fd 7b 47 a9	ldp	x29, x30, [sp, #0x70]
 170883 |    ac580:	f4 4f 46 a9	ldp	x20, x19, [sp, #0x60]
 170884 |    ac584:	f6 57 45 a9	ldp	x22, x21, [sp, #0x50]
 170885 |    ac588:	f8 5f 44 a9	ldp	x24, x23, [sp, #0x40]
 170886 |    ac58c:	fa 67 43 a9	ldp	x26, x25, [sp, #0x30]
 170887 |    ac590:	e9 23 42 6d	ldp	d9, d8, [sp, #0x20]
 170888 |    ac594:	ff 03 02 91	add	sp, sp, #0x80
 170889 |    ac598:	56 9c 09 14	b	0x3136f0 ; symbol stub for: _objc_autoreleaseReturnValue
 170890 |    ac59c:	c8 9b 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
 170891 |    ac5a0:	ff c3 01 d1	sub	sp, sp, #0x70
 170892 |    ac5a4:	fa 67 02 a9	stp	x26, x25, [sp, #0x20]
 170893 |    ac5a8:	f8 5f 03 a9	stp	x24, x23, [sp, #0x30]
 170894 |    ac5ac:	f6 57 04 a9	stp	x22, x21, [sp, #0x40]
 170895 |    ac5b0:	f4 4f 05 a9	stp	x20, x19, [sp, #0x50]
 170896 |    ac5b4:	fd 7b 06 a9	stp	x29, x30, [sp, #0x60]
 170897 |    ac5b8:	fd 83 01 91	add	x29, sp, #0x60
 170898 |    ac5bc:	f4 03 00 aa	mov	x20, x0
 170899 |    ac5c0:	28 16 00 90	adrp	x8, 708 ; 0x370000
 170900 |    ac5c4:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 170901 |    ac5c8:	08 01 40 f9	ldr	x8, [x8]
 170902 |    ac5cc:	e8 0f 00 f9	str	x8, [sp, #0x18]
 170903 |    ac5d0:	e8 17 00 d0	adrp	x8, 766 ; 0x3aa000
 170904 |    ac5d4:	08 e1 46 f9	ldr	x8, [x8, #0xdc0] ; Objc class ref: CBBridgedUIAppView
 170905 |    ac5d8:	e0 a3 00 a9	stp	x0, x8, [sp, #0x8]
 170906 |    ac5dc:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170907 |    ac5e0:	01 d1 46 f9	ldr	x1, [x8, #0xda0] ; Objc selector ref: touchesBegan:withEvent:
 170908 |    ac5e4:	e0 23 00 91	add	x0, sp, #0x8
 170909 |    ac5e8:	6c 9c 09 94	bl	0x313798 ; Objc message: -[[x0 super] touchesBegan:withEvent:]
 170910 |    ac5ec:	e8 17 00 d0	adrp	x8, 766 ; 0x3aa000
 170911 |    ac5f0:	00 81 45 f9	ldr	x0, [x8, #0xb00] ; Objc class ref: CBBridgeManager
 170912 |    ac5f4:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170913 |    ac5f8:	01 51 41 f9	ldr	x1, [x8, #0x2a0] ; Objc selector ref: sharedInstance
 170914 |    ac5fc:	61 9c 09 94	bl	0x313780 ; Objc message: +[CBBridgeManager sharedInstance]
 170915 |    ac600:	fd 03 1d aa	mov	x29, x29
 170916 |    ac604:	77 9c 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 170917 |    ac608:	f3 03 00 aa	mov	x19, x0
 170918 |    ac60c:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170919 |    ac610:	16 cd 44 f9	ldr	x22, [x8, #0x998] ; Objc selector ref: currentApp
 170920 |    ac614:	e1 03 16 aa	mov	x1, x22
 170921 |    ac618:	5a 9c 09 94	bl	0x313780 ; Objc message: -[x0 currentApp]
 170922 |    ac61c:	fd 03 1d aa	mov	x29, x29
 170923 |    ac620:	70 9c 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 170924 |    ac624:	f8 03 00 aa	mov	x24, x0
 170925 |    ac628:	e8 17 00 90	adrp	x8, 764 ; 0x3a8000
 170926 |    ac62c:	17 d1 44 f9	ldr	x23, [x8, #0x9a0] ; Objc selector ref: noteUserActivity
 170927 |    ac630:	1f 20 03 d5	nop
 170928 |    ac634:	15 ad 41 f9	ldr	x21, [x8, #0x358]
 170929 |    ac638:	e1 03 15 aa	mov	x1, x21

... context gap ...
 171386 |    acd5c:	29 01 40 f9	ldr	x9, [x9]
 171387 |    acd60:	3f 01 08 eb	cmp	x9, x8
 171388 |    acd64:	81 01 00 54	b.ne	0xacd94
 171389 |    acd68:	fd 7b 59 a9	ldp	x29, x30, [sp, #0x190]
 171390 |    acd6c:	f4 4f 58 a9	ldp	x20, x19, [sp, #0x180]
 171391 |    acd70:	f6 57 57 a9	ldp	x22, x21, [sp, #0x170]
 171392 |    acd74:	f8 5f 56 a9	ldp	x24, x23, [sp, #0x160]
 171393 |    acd78:	fa 67 55 a9	ldp	x26, x25, [sp, #0x150]
 171394 |    acd7c:	fc 6f 54 a9	ldp	x28, x27, [sp, #0x140]
 171395 |    acd80:	e9 23 53 6d	ldp	d9, d8, [sp, #0x130]
 171396 |    acd84:	eb 2b 52 6d	ldp	d11, d10, [sp, #0x120]
 171397 |    acd88:	ed 33 51 6d	ldp	d13, d12, [sp, #0x110]
 171398 |    acd8c:	ff 83 06 91	add	sp, sp, #0x1a0
 171399 |    acd90:	c0 03 5f d6	ret
 171400 |    acd94:	ca 99 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
 171401 |    acd98:	f6 03 00 aa	mov	x22, x0
 171402 |    acd9c:	3f 04 00 71	cmp	w1, #0x1
 171403 |    acda0:	21 02 00 54	b.ne	0xacde4
 171404 |    acda4:	e0 03 16 aa	mov	x0, x22
 171405 |    acda8:	55 9a 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 171406 |    acdac:	fd 03 1d aa	mov	x29, x29
 171407 |    acdb0:	8c 9a 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 171408 |    acdb4:	f6 03 00 aa	mov	x22, x0
 171409 |    acdb8:	e0 03 00 f9	str	x0, [sp]
 171410 |    acdbc:	60 17 00 b0	adrp	x0, 749 ; 0x399000
 171411 |    acdc0:	00 00 2c 91	add	x0, x0, #0xb00 ; Objc cfstring ref: @"[CBBridgedUIAppView] Warning: _deviceAppViewController KVC failed: %@"
 171412 |    acdc4:	0b 00 00 94	bl	0xacdf0
 171413 |    acdc8:	e0 03 16 aa	mov	x0, x22
 171414 |    acdcc:	79 9a 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 171415 |    acdd0:	54 9a 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 171416 |    acdd4:	16 00 80 d2	mov	x22, #0x0
 171417 |    acdd8:	7b ff ff 17	b	0xacbc4
 171418 |    acddc:	f6 03 00 aa	mov	x22, x0
 171419 |    acde0:	50 9a 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 171420 |    acde4:	e0 03 16 aa	mov	x0, x22
 171421 |    acde8:	ac 99 09 94	bl	0x313498 ; symbol stub for: __Unwind_Resume
 171422 |    acdec:	20 00 20 d4	brk	#0x1
 171423 |    acdf0:	ff 83 02 d1	sub	sp, sp, #0xa0
 171424 |    acdf4:	fc 6f 04 a9	stp	x28, x27, [sp, #0x40]
 171425 |    acdf8:	fa 67 05 a9	stp	x26, x25, [sp, #0x50]
 171426 |    acdfc:	f8 5f 06 a9	stp	x24, x23, [sp, #0x60]
 171427 |    ace00:	f6 57 07 a9	stp	x22, x21, [sp, #0x70]
 171428 |    ace04:	f4 4f 08 a9	stp	x20, x19, [sp, #0x80]
 171429 |    ace08:	fd 7b 09 a9	stp	x29, x30, [sp, #0x90]
 171430 |    ace0c:	fd 43 02 91	add	x29, sp, #0x90
 171431 |    ace10:	28 16 00 90	adrp	x8, 708 ; 0x370000
 171432 |    ace14:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 171433 |    ace18:	08 01 40 f9	ldr	x8, [x8]
 171434 |    ace1c:	e8 1f 00 f9	str	x8, [sp, #0x38]
 171435 |    ace20:	67 9a 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
 171436 |    ace24:	f3 03 00 aa	mov	x19, x0

... context gap ...
 171775 |    ad36c:	e9 23 04 6d	stp	d9, d8, [sp, #0x40]
 171776 |    ad370:	fc 6f 05 a9	stp	x28, x27, [sp, #0x50]
 171777 |    ad374:	fa 67 06 a9	stp	x26, x25, [sp, #0x60]
 171778 |    ad378:	f8 5f 07 a9	stp	x24, x23, [sp, #0x70]
 171779 |    ad37c:	f6 57 08 a9	stp	x22, x21, [sp, #0x80]
 171780 |    ad380:	f4 4f 09 a9	stp	x20, x19, [sp, #0x90]
 171781 |    ad384:	fd 7b 0a a9	stp	x29, x30, [sp, #0xa0]
 171782 |    ad388:	fd 83 02 91	add	x29, sp, #0xa0
 171783 |    ad38c:	08 16 00 f0	adrp	x8, 707 ; 0x370000
 171784 |    ad390:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 171785 |    ad394:	08 01 40 f9	ldr	x8, [x8]
 171786 |    ad398:	e8 1f 00 f9	str	x8, [sp, #0x38]
 171787 |    ad39c:	e8 17 00 b0	adrp	x8, 765 ; 0x3aa000
 171788 |    ad3a0:	18 d1 8f b9	ldrsw	x24, [x8, #0xfd0]
 171789 |    ad3a4:	08 68 78 f8	ldr	x8, [x0, x24]
 171790 |    ad3a8:	68 30 00 b4	cbz	x8, 0xad9b4
 171791 |    ad3ac:	f4 03 00 aa	mov	x20, x0
 171792 |    ad3b0:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 171793 |    ad3b4:	01 85 43 f9	ldr	x1, [x8, #0x708] ; Objc selector ref: bounds
 171794 |    ad3b8:	f2 98 09 94	bl	0x313780 ; Objc message: -[x0 bounds]
 171795 |    ad3bc:	48 20 60 1e	fcmp	d2, #0.0
 171796 |    ad3c0:	69 00 00 54	b.ls	0xad3cc
 171797 |    ad3c4:	68 20 60 1e	fcmp	d3, #0.0
 171798 |    ad3c8:	08 01 00 54	b.hi	0xad3e8
 171799 |    ad3cc:	e8 17 00 b0	adrp	x8, 765 ; 0x3aa000
 171800 |    ad3d0:	00 9d 45 f9	ldr	x0, [x8, #0xb38] ; Objc class ref: CBWindow
 171801 |    ad3d4:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 171802 |    ad3d8:	01 f9 46 f9	ldr	x1, [x8, #0xdf0] ; Objc selector ref: carPlayUsableBounds
 171803 |    ad3dc:	e9 98 09 94	bl	0x313780 ; Objc message: +[CBWindow carPlayUsableBounds]
 171804 |    ad3e0:	e0 03 67 9e	fmov	d0, xzr
 171805 |    ad3e4:	e1 03 67 9e	fmov	d1, xzr
 171806 |    ad3e8:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 171807 |    ad3ec:	01 e5 46 f9	ldr	x1, [x8, #0xdc8] ; Objc selector ref: calculateNativeSizeForSlotRect:
 171808 |    ad3f0:	e0 03 14 aa	mov	x0, x20
 171809 |    ad3f4:	e3 98 09 94	bl	0x313780 ; Objc message: -[x0 calculateNativeSizeForSlotRect:]
 171810 |    ad3f8:	08 1c a0 4e	mov.16b	v8, v0
 171811 |    ad3fc:	29 1c a1 4e	mov.16b	v9, v1
 171812 |    ad400:	80 6a 78 f8	ldr	x0, [x20, x24]
 171813 |    ad404:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 171814 |    ad408:	01 e9 46 f9	ldr	x1, [x8, #0xdd0] ; Objc selector ref: valueForKey:
 171815 |    ad40c:	62 17 00 90	adrp	x2, 748 ; 0x399000
 171816 |    ad410:	42 80 2b 91	add	x2, x2, #0xae0 ; Objc cfstring ref: @"_deviceAppViewController"
 171817 |    ad414:	db 98 09 94	bl	0x313780 ; Objc message: -[x0 valueForKey:]
 171818 |    ad418:	fd 03 1d aa	mov	x29, x29
 171819 |    ad41c:	f1 98 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 171820 |    ad420:	f3 03 00 aa	mov	x19, x0
 171821 |    ad424:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 171822 |    ad428:	15 ed 46 f9	ldr	x21, [x8, #0xdd8] ; Objc selector ref: setContentReferenceSize:withInterfaceOrientation:
 171823 |    ad42c:	1f 20 03 d5	nop
 171824 |    ad430:	16 ad 41 f9	ldr	x22, [x8, #0x358]
 171825 |    ad434:	53 03 00 b4	cbz	x19, 0xad49c
 171826 |    ad438:	e0 03 13 aa	mov	x0, x19
 171827 |    ad43c:	e1 03 16 aa	mov	x1, x22
 171828 |    ad440:	e2 03 15 aa	mov	x2, x21

... context gap ...
 172106 |    ad898:	41 0d 00 54	b.ne	0xada40
 172107 |    ad89c:	e0 03 16 aa	mov	x0, x22
 172108 |    ad8a0:	97 97 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 172109 |    ad8a4:	fd 03 1d aa	mov	x29, x29
 172110 |    ad8a8:	ce 97 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 172111 |    ad8ac:	f4 03 00 aa	mov	x20, x0
 172112 |    ad8b0:	e0 03 00 f9	str	x0, [sp]
 172113 |    ad8b4:	60 17 00 90	adrp	x0, 748 ; 0x399000
 172114 |    ad8b8:	00 00 2e 91	add	x0, x0, #0xb80 ; Objc cfstring ref: @"[DuoNavi] updateSettingsWithBlock error: %@"
 172115 |    ad8bc:	c1 96 09 94	bl	0x3133c0 ; symbol stub for: _NSLog
 172116 |    ad8c0:	e0 03 14 aa	mov	x0, x20
 172117 |    ad8c4:	bb 97 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 172118 |    ad8c8:	96 97 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 172119 |    ad8cc:	34 00 00 14	b	0xad99c
 172120 |    ad8d0:	5a 00 00 14	b	0xada38
 172121 |    ad8d4:	f6 03 00 aa	mov	x22, x0
 172122 |    ad8d8:	3f 04 00 71	cmp	w1, #0x1
 172123 |    ad8dc:	21 0b 00 54	b.ne	0xada40
 172124 |    ad8e0:	e0 03 16 aa	mov	x0, x22
 172125 |    ad8e4:	86 97 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 172126 |    ad8e8:	fd 03 1d aa	mov	x29, x29
 172127 |    ad8ec:	bd 97 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 172128 |    ad8f0:	f5 03 00 aa	mov	x21, x0
 172129 |    ad8f4:	e0 03 00 f9	str	x0, [sp]
 172130 |    ad8f8:	60 17 00 90	adrp	x0, 748 ; 0x399000
 172131 |    ad8fc:	00 80 2c 91	add	x0, x0, #0xb20 ; Objc cfstring ref: @"[CBBridgedUIAppView] Warning: _deviceAppViewController KVC failed in updateSceneSettingsFrame, falling back to ivar: %@"
 172132 |    ad900:	3c fd ff 97	bl	0xacdf0
 172133 |    ad904:	80 6a 78 f8	ldr	x0, [x20, x24]
 172134 |    ad908:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 172135 |    ad90c:	01 c9 41 f9	ldr	x1, [x8, #0x390] ; Objc selector ref: class
 172136 |    ad910:	9c 97 09 94	bl	0x313780 ; Objc message: -[x0 class]
 172137 |    ad914:	21 14 00 b0	adrp	x1, 645 ; 0x332000
 172138 |    ad918:	21 6c 14 91	add	x1, x1, #0x51b ; literal pool for: "_deviceAppViewController"
 172139 |    ad91c:	03 97 09 94	bl	0x313528 ; symbol stub for: _class_getInstanceVariable
 172140 |    ad920:	e1 03 00 aa	mov	x1, x0
 172141 |    ad924:	e1 00 00 b4	cbz	x1, 0xad940
 172142 |    ad928:	80 6a 78 f8	ldr	x0, [x20, x24]
 172143 |    ad92c:	ce 97 09 94	bl	0x313864 ; symbol stub for: _object_getIvar
 172144 |    ad930:	fd 03 1d aa	mov	x29, x29
 172145 |    ad934:	ab 97 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 172146 |    ad938:	f3 03 00 aa	mov	x19, x0
 172147 |    ad93c:	02 00 00 14	b	0xad944
 172148 |    ad940:	13 00 80 d2	mov	x19, #0x0
 172149 |    ad944:	e0 03 15 aa	mov	x0, x21
 172150 |    ad948:	9a 97 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 172151 |    ad94c:	75 97 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 172152 |    ad950:	b5 fe ff 17	b	0xad424
 172153 |    ad954:	39 00 00 14	b	0xada38
 172154 |    ad958:	38 00 00 14	b	0xada38
 172155 |    ad95c:	f6 03 00 aa	mov	x22, x0
 172156 |    ad960:	3f 04 00 71	cmp	w1, #0x1

... context gap ...
 172179 |    ad9bc:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
 172180 |    ad9c0:	29 01 40 f9	ldr	x9, [x9]
 172181 |    ad9c4:	3f 01 08 eb	cmp	x9, x8
 172182 |    ad9c8:	41 01 00 54	b.ne	0xad9f0
 172183 |    ad9cc:	fd 7b 4a a9	ldp	x29, x30, [sp, #0xa0]
 172184 |    ad9d0:	f4 4f 49 a9	ldp	x20, x19, [sp, #0x90]
 172185 |    ad9d4:	f6 57 48 a9	ldp	x22, x21, [sp, #0x80]
 172186 |    ad9d8:	f8 5f 47 a9	ldp	x24, x23, [sp, #0x70]
 172187 |    ad9dc:	fa 67 46 a9	ldp	x26, x25, [sp, #0x60]
 172188 |    ad9e0:	fc 6f 45 a9	ldp	x28, x27, [sp, #0x50]
 172189 |    ad9e4:	e9 23 44 6d	ldp	d9, d8, [sp, #0x40]
 172190 |    ad9e8:	ff c3 02 91	add	sp, sp, #0xb0
 172191 |    ad9ec:	c0 03 5f d6	ret
 172192 |    ad9f0:	b3 96 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
 172193 |    ad9f4:	11 00 00 14	b	0xada38
 172194 |    ad9f8:	f6 03 00 aa	mov	x22, x0
 172195 |    ad9fc:	3f 04 00 71	cmp	w1, #0x1
 172196 |    ada00:	01 02 00 54	b.ne	0xada40
 172197 |    ada04:	e0 03 16 aa	mov	x0, x22
 172198 |    ada08:	3d 97 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 172199 |    ada0c:	fd 03 1d aa	mov	x29, x29
 172200 |    ada10:	74 97 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 172201 |    ada14:	f4 03 00 aa	mov	x20, x0
 172202 |    ada18:	e0 03 00 f9	str	x0, [sp]
 172203 |    ada1c:	60 17 00 90	adrp	x0, 748 ; 0x399000
 172204 |    ada20:	00 00 2d 91	add	x0, x0, #0xb40 ; Objc cfstring ref: @"[CBBridgedUIAppView] Warning: Exception resolving sceneHandle: %@"
 172205 |    ada24:	f3 fc ff 97	bl	0xacdf0
 172206 |    ada28:	e0 03 14 aa	mov	x0, x20
 172207 |    ada2c:	61 97 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 172208 |    ada30:	3c 97 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 172209 |    ada34:	de ff ff 17	b	0xad9ac
 172210 |    ada38:	f6 03 00 aa	mov	x22, x0
 172211 |    ada3c:	39 97 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 172212 |    ada40:	e0 03 16 aa	mov	x0, x22
 172213 |    ada44:	95 96 09 94	bl	0x313498 ; symbol stub for: __Unwind_Resume
 172214 |    ada48:	20 00 20 d4	brk	#0x1
 172215 |    ada4c:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
 172216 |    ada50:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
 172217 |    ada54:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
 172218 |    ada58:	fd 83 00 91	add	x29, sp, #0x20
 172219 |    ada5c:	f5 03 00 aa	mov	x21, x0
 172220 |    ada60:	e0 03 01 aa	mov	x0, x1
 172221 |    ada64:	56 97 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
 172222 |    ada68:	f3 03 00 aa	mov	x19, x0
 172223 |    ada6c:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 172224 |    ada70:	16 fd 43 f9	ldr	x22, [x8, #0x7f8] ; Objc selector ref: setFrame:
 172225 |    ada74:	1f 20 03 d5	nop
 172226 |    ada78:	14 ad 41 f9	ldr	x20, [x8, #0x358]
 172227 |    ada7c:	e1 03 14 aa	mov	x1, x20
 172228 |    ada80:	e2 03 16 aa	mov	x2, x22
 172229 |    ada84:	3f 97 09 94	bl	0x313780 ; Objc message: -[x0 setFrame:]

... context gap ...
 172383 |    adcec:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
 172384 |    adcf0:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
 172385 |    adcf4:	af 96 09 14	b	0x3137b0 ; symbol stub for: _objc_release
 172386 |    adcf8:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
 172387 |    adcfc:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
 172388 |    add00:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
 172389 |    add04:	c0 03 5f d6	ret
 172390 |    add08:	e9 23 b9 6d	stp	d9, d8, [sp, #-0x70]!
 172391 |    add0c:	fc 6f 01 a9	stp	x28, x27, [sp, #0x10]
 172392 |    add10:	fa 67 02 a9	stp	x26, x25, [sp, #0x20]
 172393 |    add14:	f8 5f 03 a9	stp	x24, x23, [sp, #0x30]
 172394 |    add18:	f6 57 04 a9	stp	x22, x21, [sp, #0x40]
 172395 |    add1c:	f4 4f 05 a9	stp	x20, x19, [sp, #0x50]
 172396 |    add20:	fd 7b 06 a9	stp	x29, x30, [sp, #0x60]
 172397 |    add24:	fd 83 01 91	add	x29, sp, #0x60
 172398 |    add28:	ff 43 07 d1	sub	sp, sp, #0x1d0
 172399 |    add2c:	f4 03 00 aa	mov	x20, x0
 172400 |    add30:	08 16 00 f0	adrp	x8, 707 ; 0x370000
 172401 |    add34:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 172402 |    add38:	08 01 40 f9	ldr	x8, [x8]
 172403 |    add3c:	a8 83 18 f8	stur	x8, [x29, #-0x78]
 172404 |    add40:	e0 03 02 aa	mov	x0, x2
 172405 |    add44:	9e 96 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
 172406 |    add48:	f3 03 00 aa	mov	x19, x0
 172407 |    add4c:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 172408 |    add50:	01 29 47 f9	ldr	x1, [x8, #0xe50] ; Objc selector ref: invalidated
 172409 |    add54:	e0 03 14 aa	mov	x0, x20
 172410 |    add58:	8a 96 09 94	bl	0x313780 ; Objc message: -[x0 invalidated]
 172411 |    add5c:	a0 7b 00 37	tbnz	w0, #0x0, 0xaecd0
 172412 |    add60:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 172413 |    add64:	01 2d 47 f9	ldr	x1, [x8, #0xe58] ; Objc selector ref: hosting
 172414 |    add68:	e0 03 14 aa	mov	x0, x20
 172415 |    add6c:	85 96 09 94	bl	0x313780 ; Objc message: -[x0 hosting]
 172416 |    add70:	00 7b 00 37	tbnz	w0, #0x0, 0xaecd0
 172417 |    add74:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 172418 |    add78:	01 31 47 f9	ldr	x1, [x8, #0xe60] ; Objc selector ref: setHosting:
 172419 |    add7c:	e0 03 14 aa	mov	x0, x20
 172420 |    add80:	22 00 80 52	mov	w2, #0x1
 172421 |    add84:	7f 96 09 94	bl	0x313780 ; Objc message: -[x0 setHosting:]
 172422 |    add88:	33 03 00 b5	cbnz	x19, 0xaddec
 172423 |    add8c:	e8 17 00 b0	adrp	x8, 765 ; 0x3aa000
 172424 |    add90:	00 81 45 f9	ldr	x0, [x8, #0xb00] ; Objc class ref: CBBridgeManager
 172425 |    add94:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 172426 |    add98:	01 35 47 f9	ldr	x1, [x8, #0xe68] ; Objc selector ref: sharedInstanceIfExists
 172427 |    add9c:	79 96 09 94	bl	0x313780 ; Objc message: +[CBBridgeManager sharedInstanceIfExists]
 172428 |    adda0:	fd 03 1d aa	mov	x29, x29
 172429 |    adda4:	8f 96 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 172430 |    adda8:	f5 03 00 aa	mov	x21, x0
 172431 |    addac:	c8 17 00 f0	adrp	x8, 763 ; 0x3a8000
 172432 |    addb0:	01 d5 46 f9	ldr	x1, [x8, #0xda8] ; Objc selector ref: window
 172433 |    addb4:	73 96 09 94	bl	0x313780 ; Objc message: -[x0 window]
 172434 |    addb8:	fd 03 1d aa	mov	x29, x29
 172435 |    addbc:	89 96 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue

... context gap ...
 172722 |    ae238:	e1 03 18 aa	mov	x1, x24
 172723 |    ae23c:	e2 03 15 aa	mov	x2, x21
 172724 |    ae240:	50 95 09 94	bl	0x313780 ; Objc message: -[x0 setAutomatesLifecycle:]
 172725 |    ae244:	a0 00 00 34	cbz	w0, 0xae258
 172726 |    ae248:	80 6a 76 f8	ldr	x0, [x20, x22]
 172727 |    ae24c:	e1 03 15 aa	mov	x1, x21
 172728 |    ae250:	02 00 80 52	mov	w2, #0x0
 172729 |    ae254:	4b 95 09 94	bl	0x313780 ; Objc message: -[x0 setAutomatesLifecycle:]
 172730 |    ae258:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 172731 |    ae25c:	17 85 43 f9	ldr	x23, [x8, #0x708] ; Objc selector ref: bounds
 172732 |    ae260:	e0 03 14 aa	mov	x0, x20
 172733 |    ae264:	e1 03 17 aa	mov	x1, x23
 172734 |    ae268:	46 95 09 94	bl	0x313780 ; Objc message: -[x0 bounds]
 172735 |    ae26c:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 172736 |    ae270:	01 e5 46 f9	ldr	x1, [x8, #0xdc8] ; Objc selector ref: calculateNativeSizeForSlotRect:
 172737 |    ae274:	e0 03 14 aa	mov	x0, x20
 172738 |    ae278:	42 95 09 94	bl	0x313780 ; Objc message: -[x0 calculateNativeSizeForSlotRect:]
 172739 |    ae27c:	08 20 60 1e	fcmp	d0, #0.0
 172740 |    ae280:	c9 00 00 54	b.ls	0xae298
 172741 |    ae284:	29 1c a1 4e	mov.16b	v9, v1
 172742 |    ae288:	28 20 60 1e	fcmp	d1, #0.0
 172743 |    ae28c:	69 00 00 54	b.ls	0xae298
 172744 |    ae290:	08 1c a0 4e	mov.16b	v8, v0
 172745 |    ae294:	0e 00 00 14	b	0xae2cc
 172746 |    ae298:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
 172747 |    ae29c:	00 9d 45 f9	ldr	x0, [x8, #0xb38] ; Objc class ref: CBWindow
 172748 |    ae2a0:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 172749 |    ae2a4:	01 f9 46 f9	ldr	x1, [x8, #0xdf0] ; Objc selector ref: carPlayUsableBounds
 172750 |    ae2a8:	36 95 09 94	bl	0x313780 ; Objc message: +[CBWindow carPlayUsableBounds]
 172751 |    ae2ac:	40 28 62 1e	fadd	d0, d2, d2
 172752 |    ae2b0:	00 40 62 1e	fcvt	s0, d0
 172753 |    ae2b4:	00 40 26 1e	frinta	s0, s0
 172754 |    ae2b8:	08 c0 22 1e	fcvt	d8, s0
 172755 |    ae2bc:	60 28 63 1e	fadd	d0, d3, d3
 172756 |    ae2c0:	00 40 62 1e	fcvt	s0, d0
 172757 |    ae2c4:	00 40 26 1e	frinta	s0, s0
 172758 |    ae2c8:	09 c0 22 1e	fcvt	d9, s0
 172759 |    ae2cc:	80 6a 76 f8	ldr	x0, [x20, x22]
 172760 |    ae2d0:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 172761 |    ae2d4:	01 e1 46 f9	ldr	x1, [x8, #0xdc0] ; Objc selector ref: view
 172762 |    ae2d8:	2a 95 09 94	bl	0x313780 ; Objc message: -[x0 view]
 172763 |    ae2dc:	fd 03 1d aa	mov	x29, x29
 172764 |    ae2e0:	40 95 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 172765 |    ae2e4:	e0 1f 00 f9	str	x0, [sp, #0x38]
 172766 |    ae2e8:	80 6a 76 f8	ldr	x0, [x20, x22]
 172767 |    ae2ec:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 172768 |    ae2f0:	15 61 47 f9	ldr	x21, [x8, #0xec0] ; Objc selector ref: setRequestedMode:
 172769 |    ae2f4:	e1 03 18 aa	mov	x1, x24
 172770 |    ae2f8:	e2 03 15 aa	mov	x2, x21
 172771 |    ae2fc:	21 95 09 94	bl	0x313780 ; Objc message: -[x0 setRequestedMode:]
 172772 |    ae300:	a0 00 00 34	cbz	w0, 0xae314
 172773 |    ae304:	80 6a 76 f8	ldr	x0, [x20, x22]
 172774 |    ae308:	e1 03 15 aa	mov	x1, x21
 172775 |    ae30c:	42 00 80 52	mov	w2, #0x2
 172776 |    ae310:	1c 95 09 94	bl	0x313780 ; Objc message: -[x0 setRequestedMode:]
 172777 |    ae314:	fa 13 00 f9	str	x26, [sp, #0x20]
 172778 |    ae318:	f3 27 00 f9	str	x19, [sp, #0x48]
 172779 |    ae31c:	00 00 80 d2	mov	x0, #0x0
 172780 |    ae320:	01 00 80 52	mov	w1, #0x0
 172781 |    ae324:	ab 94 09 94	bl	0x3135d0 ; symbol stub for: _dlopen
 172782 |    ae328:	21 14 00 90	adrp	x1, 644 ; 0x332000
 172783 |    ae32c:	21 d4 20 91	add	x1, x1, #0x835 ; literal pool for: "BKSDisplayServicesSetScreenBlanked"
 172784 |    ae330:	ab 94 09 94	bl	0x3135dc ; symbol stub for: _dlsym
 172785 |    ae334:	80 00 00 b4	cbz	x0, 0xae344
 172786 |    ae338:	e8 03 00 aa	mov	x8, x0
 172787 |    ae33c:	00 00 80 52	mov	w0, #0x0
 172788 |    ae340:	00 01 3f d6	blr	x8
 172789 |    ae344:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
 172790 |    ae348:	00 71 45 f9	ldr	x0, [x8, #0xae0] ; Objc class ref: _OBJC_CLASS_$_UIView
 172791 |    ae34c:	d7 94 09 94	bl	0x3136a8 ; symbol stub for: _objc_alloc
 172792 |    ae350:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 172793 |    ae354:	01 95 43 f9	ldr	x1, [x8, #0x728] ; Objc selector ref: initWithFrame:
 172794 |    ae358:	e0 03 67 9e	fmov	d0, xzr
 172795 |    ae35c:	e1 03 67 9e	fmov	d1, xzr
 172796 |    ae360:	02 1d a8 4e	mov.16b	v2, v8
 172797 |    ae364:	23 1d a9 4e	mov.16b	v3, v9
 172798 |    ae368:	06 95 09 94	bl	0x313780 ; Objc message: +[UIView initWithFrame:]
 172799 |    ae36c:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
 172800 |    ae370:	1a cd 8f b9	ldrsw	x26, [x8, #0xfcc]
 172801 |    ae374:	88 6a 7a f8	ldr	x8, [x20, x26]

... context gap ...
 173428 |    aed40:	90 92 09 94	bl	0x313780 ; Objc message: -[x0 doubleValue]
 173429 |    aed44:	9e 92 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
 173430 |    aed48:	f8 03 00 aa	mov	x24, x0
 173431 |    aed4c:	e0 57 00 a9	stp	x0, x21, [sp]
 173432 |    aed50:	40 17 00 f0	adrp	x0, 747 ; 0x399000
 173433 |    aed54:	00 80 2e 91	add	x0, x0, #0xba0 ; Objc cfstring ref: @"[DuoNaviSB] Warning: Exception setting scene association for %@: %@"
 173434 |    aed58:	26 f8 ff 97	bl	0xacdf0
 173435 |    aed5c:	e0 03 18 aa	mov	x0, x24
 173436 |    aed60:	94 92 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 173437 |    aed64:	e0 03 15 aa	mov	x0, x21
 173438 |    aed68:	92 92 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 173439 |    aed6c:	6d 92 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 173440 |    aed70:	f3 eb 44 a9	ldp	x19, x26, [sp, #0x48]
 173441 |    aed74:	04 ff ff 17	b	0xae984
 173442 |    aed78:	f5 03 00 aa	mov	x21, x0
 173443 |    aed7c:	69 92 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 173444 |    aed80:	e0 03 15 aa	mov	x0, x21
 173445 |    aed84:	c5 91 09 94	bl	0x313498 ; symbol stub for: __Unwind_Resume
 173446 |    aed88:	20 00 20 d4	brk	#0x1
 173447 |    aed8c:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
 173448 |    aed90:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
 173449 |    aed94:	fd 43 00 91	add	x29, sp, #0x10
 173450 |    aed98:	f3 03 00 aa	mov	x19, x0
 173451 |    aed9c:	00 10 40 f9	ldr	x0, [x0, #0x20]
 173452 |    aeda0:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173453 |    aeda4:	01 29 47 f9	ldr	x1, [x8, #0xe50] ; Objc selector ref: invalidated
 173454 |    aeda8:	76 92 09 94	bl	0x313780 ; Objc message: -[x0 invalidated]
 173455 |    aedac:	80 01 00 37	tbnz	w0, #0x0, 0xaeddc
 173456 |    aedb0:	60 12 40 f9	ldr	x0, [x19, #0x20]
 173457 |    aedb4:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173458 |    aedb8:	01 2d 47 f9	ldr	x1, [x8, #0xe58] ; Objc selector ref: hosting
 173459 |    aedbc:	71 92 09 94	bl	0x313780 ; Objc message: -[x0 hosting]
 173460 |    aedc0:	e0 00 00 34	cbz	w0, 0xaeddc
 173461 |    aedc4:	60 12 40 f9	ldr	x0, [x19, #0x20]
 173462 |    aedc8:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173463 |    aedcc:	01 c9 46 f9	ldr	x1, [x8, #0xd90] ; Objc selector ref: refreshSceneLayout
 173464 |    aedd0:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
 173465 |    aedd4:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
 173466 |    aedd8:	6a 92 09 14	b	0x313780 ; Objc message: -[x0 refreshSceneLayout]
 173467 |    aeddc:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
 173468 |    aede0:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
 173469 |    aede4:	c0 03 5f d6	ret
 173470 |    aede8:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173471 |    aedec:	01 6d 47 f9	ldr	x1, [x8, #0xed8] ; Objc selector ref: startInParentViewController:
 173472 |    aedf0:	02 00 80 d2	mov	x2, #0x0
 173473 |    aedf4:	63 92 09 14	b	0x313780 ; Objc message: -[x0 startInParentViewController:]
 173474 |    aedf8:	f8 5f bc a9	stp	x24, x23, [sp, #-0x40]!
 173475 |    aedfc:	f6 57 01 a9	stp	x22, x21, [sp, #0x10]
 173476 |    aee00:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
 173477 |    aee04:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
 173478 |    aee08:	fd c3 00 91	add	x29, sp, #0x30
 173479 |    aee0c:	f3 03 00 aa	mov	x19, x0
 173480 |    aee10:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173481 |    aee14:	01 71 47 f9	ldr	x1, [x8, #0xee0] ; Objc selector ref: setInvalidated:
 173482 |    aee18:	22 00 80 52	mov	w2, #0x1
 173483 |    aee1c:	59 92 09 94	bl	0x313780 ; Objc message: -[x0 setInvalidated:]
 173484 |    aee20:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173485 |    aee24:	01 31 47 f9	ldr	x1, [x8, #0xe60] ; Objc selector ref: setHosting:
 173486 |    aee28:	e0 03 13 aa	mov	x0, x19
 173487 |    aee2c:	02 00 80 52	mov	w2, #0x0
 173488 |    aee30:	54 92 09 94	bl	0x313780 ; Objc message: -[x0 setHosting:]
 173489 |    aee34:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
 173490 |    aee38:	17 d1 8f b9	ldrsw	x23, [x8, #0xfd0]
 173491 |    aee3c:	60 6a 77 f8	ldr	x0, [x19, x23]
 173492 |    aee40:	d6 17 00 d0	adrp	x22, 762 ; 0x3a8000
 173493 |    aee44:	40 09 00 b4	cbz	x0, 0xaef6c
 173494 |    aee48:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173495 |    aee4c:	15 75 47 f9	ldr	x21, [x8, #0xee8] ; Objc selector ref: beginAppearanceTransition:animated:
 173496 |    aee50:	1f 20 03 d5	nop
 173497 |    aee54:	14 ad 41 f9	ldr	x20, [x8, #0x358]
 173498 |    aee58:	e1 03 14 aa	mov	x1, x20
 173499 |    aee5c:	e2 03 15 aa	mov	x2, x21
 173500 |    aee60:	48 92 09 94	bl	0x313780 ; Objc message: -[x0 beginAppearanceTransition:animated:]
 173501 |    aee64:	40 01 00 34	cbz	w0, 0xaee8c
 173502 |    aee68:	60 6a 77 f8	ldr	x0, [x19, x23]
 173503 |    aee6c:	e1 03 15 aa	mov	x1, x21
 173504 |    aee70:	02 00 80 52	mov	w2, #0x0
 173505 |    aee74:	03 00 80 52	mov	w3, #0x0
 173506 |    aee78:	42 92 09 94	bl	0x313780 ; Objc message: -[x0 beginAppearanceTransition:animated:]
 173507 |    aee7c:	60 6a 77 f8	ldr	x0, [x19, x23]
 173508 |    aee80:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173509 |    aee84:	01 79 47 f9	ldr	x1, [x8, #0xef0] ; Objc selector ref: endAppearanceTransition
 173510 |    aee88:	3e 92 09 94	bl	0x313780 ; Objc message: -[x0 endAppearanceTransition]
 173511 |    aee8c:	60 6a 77 f8	ldr	x0, [x19, x23]
 173512 |    aee90:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173513 |    aee94:	15 61 47 f9	ldr	x21, [x8, #0xec0] ; Objc selector ref: setRequestedMode:
 173514 |    aee98:	e1 03 14 aa	mov	x1, x20
 173515 |    aee9c:	e2 03 15 aa	mov	x2, x21
 173516 |    aeea0:	38 92 09 94	bl	0x313780 ; Objc message: -[x0 setRequestedMode:]
 173517 |    aeea4:	a0 00 00 34	cbz	w0, 0xaeeb8
 173518 |    aeea8:	60 6a 77 f8	ldr	x0, [x19, x23]
 173519 |    aeeac:	e1 03 15 aa	mov	x1, x21
 173520 |    aeeb0:	02 00 80 d2	mov	x2, #0x0
 173521 |    aeeb4:	33 92 09 94	bl	0x313780 ; Objc message: -[x0 setRequestedMode:]
 173522 |    aeeb8:	60 6a 77 f8	ldr	x0, [x19, x23]
 173523 |    aeebc:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173524 |    aeec0:	01 e1 46 f9	ldr	x1, [x8, #0xdc0] ; Objc selector ref: view
 173525 |    aeec4:	2f 92 09 94	bl	0x313780 ; Objc message: -[x0 view]
 173526 |    aeec8:	fd 03 1d aa	mov	x29, x29
 173527 |    aeecc:	45 92 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 173528 |    aeed0:	f5 03 00 aa	mov	x21, x0
 173529 |    aeed4:	c1 2a 45 f9	ldr	x1, [x22, #0xa50]
 173530 |    aeed8:	2a 92 09 94	bl	0x313780 ; Objc message: -[x0 view]
 173531 |    aeedc:	e0 03 15 aa	mov	x0, x21
 173532 |    aeee0:	34 92 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 173533 |    aeee4:	60 6a 77 f8	ldr	x0, [x19, x23]
 173534 |    aeee8:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173535 |    aeeec:	15 7d 47 f9	ldr	x21, [x8, #0xef8] ; Objc selector ref: willMoveToParentViewController:
 173536 |    aeef0:	e1 03 14 aa	mov	x1, x20
 173537 |    aeef4:	e2 03 15 aa	mov	x2, x21
 173538 |    aeef8:	22 92 09 94	bl	0x313780 ; Objc message: -[x0 willMoveToParentViewController:]
 173539 |    aeefc:	a0 00 00 34	cbz	w0, 0xaef10
 173540 |    aef00:	60 6a 77 f8	ldr	x0, [x19, x23]
 173541 |    aef04:	e1 03 15 aa	mov	x1, x21
 173542 |    aef08:	02 00 80 d2	mov	x2, #0x0
 173543 |    aef0c:	1d 92 09 94	bl	0x313780 ; Objc message: -[x0 willMoveToParentViewController:]
 173544 |    aef10:	60 6a 77 f8	ldr	x0, [x19, x23]
 173545 |    aef14:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173546 |    aef18:	15 81 47 f9	ldr	x21, [x8, #0xf00] ; Objc selector ref: removeFromParentViewController
 173547 |    aef1c:	e1 03 14 aa	mov	x1, x20
 173548 |    aef20:	e2 03 15 aa	mov	x2, x21
 173549 |    aef24:	17 92 09 94	bl	0x313780 ; Objc message: -[x0 removeFromParentViewController]
 173550 |    aef28:	80 00 00 34	cbz	w0, 0xaef38
 173551 |    aef2c:	60 6a 77 f8	ldr	x0, [x19, x23]
 173552 |    aef30:	e1 03 15 aa	mov	x1, x21
 173553 |    aef34:	13 92 09 94	bl	0x313780 ; Objc message: -[x0 removeFromParentViewController]
 173554 |    aef38:	60 6a 77 f8	ldr	x0, [x19, x23]
 173555 |    aef3c:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173556 |    aef40:	15 c1 43 f9	ldr	x21, [x8, #0x780] ; Objc selector ref: invalidate
 173557 |    aef44:	e1 03 14 aa	mov	x1, x20
 173558 |    aef48:	e2 03 15 aa	mov	x2, x21
 173559 |    aef4c:	0d 92 09 94	bl	0x313780 ; Objc message: -[x0 invalidate]
 173560 |    aef50:	80 00 00 34	cbz	w0, 0xaef60
 173561 |    aef54:	60 6a 77 f8	ldr	x0, [x19, x23]
 173562 |    aef58:	e1 03 15 aa	mov	x1, x21
 173563 |    aef5c:	09 92 09 94	bl	0x313780 ; Objc message: -[x0 invalidate]
 173564 |    aef60:	60 6a 77 f8	ldr	x0, [x19, x23]
 173565 |    aef64:	7f 6a 37 f8	str	xzr, [x19, x23]
 173566 |    aef68:	12 92 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 173567 |    aef6c:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
 173568 |    aef70:	14 cd 8f b9	ldrsw	x20, [x8, #0xfcc]
 173569 |    aef74:	60 6a 74 f8	ldr	x0, [x19, x20]
 173570 |    aef78:	40 01 00 b4	cbz	x0, 0xaefa0
 173571 |    aef7c:	c1 2a 45 f9	ldr	x1, [x22, #0xa50]
 173572 |    aef80:	00 92 09 94	bl	0x313780 ; Objc message: -[x0 invalidate]
 173573 |    aef84:	60 6a 74 f8	ldr	x0, [x19, x20]
 173574 |    aef88:	7f 6a 34 f8	str	xzr, [x19, x20]
 173575 |    aef8c:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
 173576 |    aef90:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
 173577 |    aef94:	f6 57 41 a9	ldp	x22, x21, [sp, #0x10]
 173578 |    aef98:	f8 5f c4 a8	ldp	x24, x23, [sp], #0x40
 173579 |    aef9c:	05 92 09 14	b	0x3137b0 ; symbol stub for: _objc_release
 173580 |    aefa0:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
 173581 |    aefa4:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
 173582 |    aefa8:	f6 57 41 a9	ldp	x22, x21, [sp, #0x10]
 173583 |    aefac:	f8 5f c4 a8	ldp	x24, x23, [sp], #0x40
 173584 |    aefb0:	c0 03 5f d6	ret
 173585 |    aefb4:	fa 67 bb a9	stp	x26, x25, [sp, #-0x50]!
 173586 |    aefb8:	f8 5f 01 a9	stp	x24, x23, [sp, #0x10]
 173587 |    aefbc:	f6 57 02 a9	stp	x22, x21, [sp, #0x20]
 173588 |    aefc0:	f4 4f 03 a9	stp	x20, x19, [sp, #0x30]
 173589 |    aefc4:	fd 7b 04 a9	stp	x29, x30, [sp, #0x40]
 173590 |    aefc8:	fd 03 01 91	add	x29, sp, #0x40
 173591 |    aefcc:	f6 03 00 aa	mov	x22, x0
 173592 |    aefd0:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
 173593 |    aefd4:	1a d1 8f b9	ldrsw	x26, [x8, #0xfd0]
 173594 |    aefd8:	00 68 7a f8	ldr	x0, [x0, x26]
 173595 |    aefdc:	a0 12 00 b4	cbz	x0, 0xaf230
 173596 |    aefe0:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
 173597 |    aefe4:	13 05 47 f9	ldr	x19, [x8, #0xe08] ; Objc selector ref: scene

... context gap ...
 173902 |    af4a8:	e0 03 14 aa	mov	x0, x20
 173903 |    af4ac:	c1 90 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 173904 |    af4b0:	e0 03 13 aa	mov	x0, x19
 173905 |    af4b4:	bf 90 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 173906 |    af4b8:	e0 03 15 aa	mov	x0, x21
 173907 |    af4bc:	fd 7b 46 a9	ldp	x29, x30, [sp, #0x60]
 173908 |    af4c0:	f4 4f 45 a9	ldp	x20, x19, [sp, #0x50]
 173909 |    af4c4:	f6 57 44 a9	ldp	x22, x21, [sp, #0x40]
 173910 |    af4c8:	f8 5f 43 a9	ldp	x24, x23, [sp, #0x30]
 173911 |    af4cc:	fa 67 42 a9	ldp	x26, x25, [sp, #0x20]
 173912 |    af4d0:	ff c3 01 91	add	sp, sp, #0x70
 173913 |    af4d4:	c0 03 5f d6	ret
 173914 |    af4d8:	ff 03 01 d1	sub	sp, sp, #0x40
 173915 |    af4dc:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
 173916 |    af4e0:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
 173917 |    af4e4:	fd c3 00 91	add	x29, sp, #0x30
 173918 |    af4e8:	f3 03 00 aa	mov	x19, x0
 173919 |    af4ec:	08 16 00 b0	adrp	x8, 705 ; 0x370000
 173920 |    af4f0:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 173921 |    af4f4:	08 01 40 f9	ldr	x8, [x8]
 173922 |    af4f8:	e8 0f 00 f9	str	x8, [sp, #0x18]
 173923 |    af4fc:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
 173924 |    af500:	01 95 47 f9	ldr	x1, [x8, #0xf28] ; Objc selector ref: dismiss
 173925 |    af504:	9f 90 09 94	bl	0x313780 ; Objc message: -[x0 dismiss]
 173926 |    af508:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
 173927 |    af50c:	08 e1 46 f9	ldr	x8, [x8, #0xdc0] ; Objc class ref: CBBridgedUIAppView
 173928 |    af510:	f3 a3 00 a9	stp	x19, x8, [sp, #0x8]
 173929 |    af514:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
 173930 |    af518:	01 d1 43 f9	ldr	x1, [x8, #0x7a0] ; Objc selector ref: dealloc
 173931 |    af51c:	e0 23 00 91	add	x0, sp, #0x8
 173932 |    af520:	9e 90 09 94	bl	0x313798 ; Objc message: -[[x0 super] dealloc]
 173933 |    af524:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
 173934 |    af528:	09 16 00 b0	adrp	x9, 705 ; 0x370000
 173935 |    af52c:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
 173936 |    af530:	29 01 40 f9	ldr	x9, [x9]
 173937 |    af534:	3f 01 08 eb	cmp	x9, x8
 173938 |    af538:	a1 00 00 54	b.ne	0xaf54c
 173939 |    af53c:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
 173940 |    af540:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
 173941 |    af544:	ff 03 01 91	add	sp, sp, #0x40
 173942 |    af548:	c0 03 5f d6	ret
 173943 |    af54c:	dc 8f 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
 173944 |    af550:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
 173945 |    af554:	02 b9 8f b9	ldrsw	x2, [x8, #0xfb8]
 173946 |    af558:	03 00 80 52	mov	w3, #0x0
 173947 |    af55c:	80 90 09 14	b	0x31375c ; symbol stub for: _objc_getProperty
 173948 |    af560:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
 173949 |    af564:	03 b9 8f b9	ldrsw	x3, [x8, #0xfb8]
 173950 |    af568:	a7 90 09 14	b	0x313804 ; symbol stub for: _objc_setProperty_nonatomic_copy
 173951 |    af56c:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
 173952 |    af570:	08 d1 8f b9	ldrsw	x8, [x8, #0xfd0]

... context gap ...
 174194 |    af938:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
 174195 |    af93c:	29 01 40 f9	ldr	x9, [x9]
 174196 |    af940:	3f 01 08 eb	cmp	x9, x8
 174197 |    af944:	c1 00 00 54	b.ne	0xaf95c
 174198 |    af948:	fd 7b 53 a9	ldp	x29, x30, [sp, #0x130]
 174199 |    af94c:	f4 4f 52 a9	ldp	x20, x19, [sp, #0x120]
 174200 |    af950:	fc 6f 51 a9	ldp	x28, x27, [sp, #0x110]
 174201 |    af954:	ff 03 05 91	add	sp, sp, #0x140
 174202 |    af958:	c0 03 5f d6	ret
 174203 |    af95c:	d8 8e 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
 174204 |    af960:	ff 83 01 d1	sub	sp, sp, #0x60
 174205 |    af964:	eb 2b 02 6d	stp	d11, d10, [sp, #0x20]
 174206 |    af968:	e9 23 03 6d	stp	d9, d8, [sp, #0x30]
 174207 |    af96c:	f4 4f 04 a9	stp	x20, x19, [sp, #0x40]
 174208 |    af970:	fd 7b 05 a9	stp	x29, x30, [sp, #0x50]
 174209 |    af974:	fd 43 01 91	add	x29, sp, #0x50
 174210 |    af978:	68 1c a3 4e	mov.16b	v8, v3
 174211 |    af97c:	49 1c a2 4e	mov.16b	v9, v2
 174212 |    af980:	2a 1c a1 4e	mov.16b	v10, v1
 174213 |    af984:	0b 1c a0 4e	mov.16b	v11, v0
 174214 |    af988:	08 16 00 b0	adrp	x8, 705 ; 0x370000
 174215 |    af98c:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 174216 |    af990:	08 01 40 f9	ldr	x8, [x8]
 174217 |    af994:	e8 0f 00 f9	str	x8, [sp, #0x18]
 174218 |    af998:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
 174219 |    af99c:	08 e5 46 f9	ldr	x8, [x8, #0xdc8] ; Objc class ref: CBWindow
 174220 |    af9a0:	e0 a3 00 a9	stp	x0, x8, [sp, #0x8]
 174221 |    af9a4:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
 174222 |    af9a8:	01 5d 41 f9	ldr	x1, [x8, #0x2b8] ; Objc selector ref: init
 174223 |    af9ac:	e0 23 00 91	add	x0, sp, #0x8
 174224 |    af9b0:	7a 8f 09 94	bl	0x313798 ; Objc message: -[[x0 super] init]
 174225 |    af9b4:	f3 03 00 aa	mov	x19, x0
 174226 |    af9b8:	a0 01 00 b4	cbz	x0, 0xaf9ec
 174227 |    af9bc:	6b 2a 00 fd	str	d11, [x19, #0x50]
 174228 |    af9c0:	6a 2e 00 fd	str	d10, [x19, #0x58]
 174229 |    af9c4:	69 32 00 fd	str	d9, [x19, #0x60]
 174230 |    af9c8:	68 36 00 fd	str	d8, [x19, #0x68]
 174231 |    af9cc:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
 174232 |    af9d0:	01 99 47 f9	ldr	x1, [x8, #0xf30] ; Objc selector ref: createWindows
 174233 |    af9d4:	e0 03 13 aa	mov	x0, x19
 174234 |    af9d8:	6a 8f 09 94	bl	0x313780 ; Objc message: -[x0 createWindows]
 174235 |    af9dc:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
 174236 |    af9e0:	01 9d 47 f9	ldr	x1, [x8, #0xf38] ; Objc selector ref: resizeWindows
 174237 |    af9e4:	e0 03 13 aa	mov	x0, x19
 174238 |    af9e8:	66 8f 09 94	bl	0x313780 ; Objc message: -[x0 resizeWindows]
 174239 |    af9ec:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
 174240 |    af9f0:	09 16 00 b0	adrp	x9, 705 ; 0x370000
 174241 |    af9f4:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
 174242 |    af9f8:	29 01 40 f9	ldr	x9, [x9]
 174243 |    af9fc:	3f 01 08 eb	cmp	x9, x8
 174244 |    afa00:	01 01 00 54	b.ne	0xafa20

... context gap ...
 174576 |    aff30:	f4 4f 58 a9	ldp	x20, x19, [sp, #0x180]
 174577 |    aff34:	f6 57 57 a9	ldp	x22, x21, [sp, #0x170]
 174578 |    aff38:	f8 5f 56 a9	ldp	x24, x23, [sp, #0x160]
 174579 |    aff3c:	fa 67 55 a9	ldp	x26, x25, [sp, #0x150]
 174580 |    aff40:	fc 6f 54 a9	ldp	x28, x27, [sp, #0x140]
 174581 |    aff44:	e9 23 53 6d	ldp	d9, d8, [sp, #0x130]
 174582 |    aff48:	ff 83 06 91	add	sp, sp, #0x1a0
 174583 |    aff4c:	e9 8d 09 14	b	0x3136f0 ; symbol stub for: _objc_autoreleaseReturnValue
 174584 |    aff50:	5b 8d 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
 174585 |    aff54:	06 00 00 14	b	0xaff6c
 174586 |    aff58:	05 00 00 14	b	0xaff6c
 174587 |    aff5c:	04 00 00 14	b	0xaff6c
 174588 |    aff60:	03 00 00 14	b	0xaff6c
 174589 |    aff64:	02 00 00 14	b	0xaff6c
 174590 |    aff68:	01 00 00 14	b	0xaff6c
 174591 |    aff6c:	f3 03 00 aa	mov	x19, x0
 174592 |    aff70:	3f 04 00 71	cmp	w1, #0x1
 174593 |    aff74:	01 02 00 54	b.ne	0xaffb4
 174594 |    aff78:	e0 03 13 aa	mov	x0, x19
 174595 |    aff7c:	e0 8d 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 174596 |    aff80:	fd 03 1d aa	mov	x29, x29
 174597 |    aff84:	17 8e 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 174598 |    aff88:	f3 03 00 aa	mov	x19, x0
 174599 |    aff8c:	e0 03 00 f9	str	x0, [sp]
 174600 |    aff90:	40 17 00 d0	adrp	x0, 746 ; 0x399000
 174601 |    aff94:	00 80 31 91	add	x0, x0, #0xc60 ; Objc cfstring ref: @"[CBWindow] Warning: Exception getting carPlayWindowScene: %@"
 174602 |    aff98:	0a 00 00 94	bl	0xaffc0
 174603 |    aff9c:	e0 03 13 aa	mov	x0, x19
 174604 |    affa0:	04 8e 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 174605 |    affa4:	df 8d 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 174606 |    affa8:	c9 ff ff 17	b	0xafecc
 174607 |    affac:	f3 03 00 aa	mov	x19, x0
 174608 |    affb0:	dc 8d 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 174609 |    affb4:	e0 03 13 aa	mov	x0, x19
 174610 |    affb8:	38 8d 09 94	bl	0x313498 ; symbol stub for: __Unwind_Resume
 174611 |    affbc:	20 00 20 d4	brk	#0x1
 174612 |    affc0:	ff 83 02 d1	sub	sp, sp, #0xa0
 174613 |    affc4:	fc 6f 04 a9	stp	x28, x27, [sp, #0x40]
 174614 |    affc8:	fa 67 05 a9	stp	x26, x25, [sp, #0x50]
 174615 |    affcc:	f8 5f 06 a9	stp	x24, x23, [sp, #0x60]
 174616 |    affd0:	f6 57 07 a9	stp	x22, x21, [sp, #0x70]
 174617 |    affd4:	f4 4f 08 a9	stp	x20, x19, [sp, #0x80]
 174618 |    affd8:	fd 7b 09 a9	stp	x29, x30, [sp, #0x90]
 174619 |    affdc:	fd 43 02 91	add	x29, sp, #0x90
 174620 |    affe0:	08 16 00 b0	adrp	x8, 705 ; 0x370000
 174621 |    affe4:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
 174622 |    affe8:	08 01 40 f9	ldr	x8, [x8]
 174623 |    affec:	e8 1f 00 f9	str	x8, [sp, #0x38]
 174624 |    afff0:	f3 8d 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
 174625 |    afff4:	f3 03 00 aa	mov	x19, x0
 174626 |    afff8:	a8 43 00 91	add	x8, x29, #0x10

... context gap ...
 175480 |    b0d4c:	08 10 6e 1e	fmov	d8, #1.00000000
 175481 |    b0d50:	05 00 00 14	b	0xb0d64
 175482 |    b0d54:	e0 03 14 aa	mov	x0, x20
 175483 |    b0d58:	96 8a 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 175484 |    b0d5c:	e0 03 13 aa	mov	x0, x19
 175485 |    b0d60:	94 8a 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 175486 |    b0d64:	00 1d a8 4e	mov.16b	v0, v8
 175487 |    b0d68:	fd 7b 44 a9	ldp	x29, x30, [sp, #0x40]
 175488 |    b0d6c:	f4 4f 43 a9	ldp	x20, x19, [sp, #0x30]
 175489 |    b0d70:	f6 57 42 a9	ldp	x22, x21, [sp, #0x20]
 175490 |    b0d74:	e9 23 41 6d	ldp	d9, d8, [sp, #0x10]
 175491 |    b0d78:	ff 43 01 91	add	sp, sp, #0x50
 175492 |    b0d7c:	c0 03 5f d6	ret
 175493 |    b0d80:	02 00 00 14	b	0xb0d88
 175494 |    b0d84:	01 00 00 14	b	0xb0d88
 175495 |    b0d88:	f3 03 00 aa	mov	x19, x0
 175496 |    b0d8c:	3f 04 00 71	cmp	w1, #0x1
 175497 |    b0d90:	01 02 00 54	b.ne	0xb0dd0
 175498 |    b0d94:	e0 03 13 aa	mov	x0, x19
 175499 |    b0d98:	59 8a 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 175500 |    b0d9c:	fd 03 1d aa	mov	x29, x29
 175501 |    b0da0:	90 8a 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175502 |    b0da4:	f3 03 00 aa	mov	x19, x0
 175503 |    b0da8:	e0 03 00 f9	str	x0, [sp]
 175504 |    b0dac:	40 17 00 b0	adrp	x0, 745 ; 0x399000
 175505 |    b0db0:	00 80 32 91	add	x0, x0, #0xca0 ; Objc cfstring ref: @"[CBWindow] Warning: Exception getting carPlayScreenScale: %@"
 175506 |    b0db4:	83 fc ff 97	bl	0xaffc0
 175507 |    b0db8:	e0 03 13 aa	mov	x0, x19
 175508 |    b0dbc:	7d 8a 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 175509 |    b0dc0:	58 8a 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 175510 |    b0dc4:	e2 ff ff 17	b	0xb0d4c
 175511 |    b0dc8:	f3 03 00 aa	mov	x19, x0
 175512 |    b0dcc:	55 8a 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 175513 |    b0dd0:	e0 03 13 aa	mov	x0, x19
 175514 |    b0dd4:	b1 89 09 94	bl	0x313498 ; symbol stub for: __Unwind_Resume
 175515 |    b0dd8:	20 00 20 d4	brk	#0x1
 175516 |    b0ddc:	ff 83 01 d1	sub	sp, sp, #0x60
 175517 |    b0de0:	eb 2b 01 6d	stp	d11, d10, [sp, #0x10]
 175518 |    b0de4:	e9 23 02 6d	stp	d9, d8, [sp, #0x20]
 175519 |    b0de8:	f6 57 03 a9	stp	x22, x21, [sp, #0x30]
 175520 |    b0dec:	f4 4f 04 a9	stp	x20, x19, [sp, #0x40]
 175521 |    b0df0:	fd 7b 05 a9	stp	x29, x30, [sp, #0x50]
 175522 |    b0df4:	fd 43 01 91	add	x29, sp, #0x50
 175523 |    b0df8:	e8 17 00 b0	adrp	x8, 765 ; 0x3ad000
 175524 |    b0dfc:	08 c1 00 91	add	x8, x8, #0x30
 175525 |    b0e00:	08 25 40 6d	ldp	d8, d9, [x8]
 175526 |    b0e04:	28 0b e8 d2	mov	x8, #0x4059000000000000
 175527 |    b0e08:	00 01 67 9e	fmov	d0, x8
 175528 |    b0e0c:	00 21 60 1e	fcmp	d8, d0
 175529 |    b0e10:	28 0b e8 d2	mov	x8, #0x4059000000000000
 175530 |    b0e14:	00 01 67 9e	fmov	d0, x8

... context gap ...
 175786 |    b1214:	e9 23 42 6d	ldp	d9, d8, [sp, #0x20]
 175787 |    b1218:	eb 2b 41 6d	ldp	d11, d10, [sp, #0x10]
 175788 |    b121c:	ff 83 01 91	add	sp, sp, #0x60
 175789 |    b1220:	c0 03 5f d6	ret
 175790 |    b1224:	e0 17 00 90	adrp	x0, 764 ; 0x3ad000
 175791 |    b1228:	00 e0 01 91	add	x0, x0, #0x78
 175792 |    b122c:	e1 15 00 f0	adrp	x1, 703 ; 0x370000
 175793 |    b1230:	21 c0 3a 91	add	x1, x1, #0xeb0
 175794 |    b1234:	cf 88 09 94	bl	0x313570 ; symbol stub for: _dispatch_once
 175795 |    b1238:	01 ff ff 17	b	0xb0e3c
 175796 |    b123c:	05 00 00 14	b	0xb1250
 175797 |    b1240:	04 00 00 14	b	0xb1250
 175798 |    b1244:	36 00 00 14	b	0xb131c
 175799 |    b1248:	13 00 00 14	b	0xb1294
 175800 |    b124c:	23 00 00 14	b	0xb12d8
 175801 |    b1250:	f4 03 00 aa	mov	x20, x0
 175802 |    b1254:	3f 04 00 71	cmp	w1, #0x1
 175803 |    b1258:	61 08 00 54	b.ne	0xb1364
 175804 |    b125c:	e0 03 14 aa	mov	x0, x20
 175805 |    b1260:	27 89 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 175806 |    b1264:	fd 03 1d aa	mov	x29, x29
 175807 |    b1268:	5e 89 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175808 |    b126c:	f3 03 00 aa	mov	x19, x0
 175809 |    b1270:	e0 03 00 f9	str	x0, [sp]
 175810 |    b1274:	40 17 00 90	adrp	x0, 744 ; 0x399000
 175811 |    b1278:	00 80 34 91	add	x0, x0, #0xd20 ; Objc cfstring ref: @"[CBWindow] Warning: Exception querying carPlayCADisplay bounds: %@"
 175812 |    b127c:	51 fb ff 97	bl	0xaffc0
 175813 |    b1280:	e0 03 13 aa	mov	x0, x19
 175814 |    b1284:	4b 89 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 175815 |    b1288:	26 89 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 175816 |    b128c:	a4 ff ff 17	b	0xb111c
 175817 |    b1290:	33 00 00 14	b	0xb135c
 175818 |    b1294:	f4 03 00 aa	mov	x20, x0
 175819 |    b1298:	3f 04 00 71	cmp	w1, #0x1
 175820 |    b129c:	41 06 00 54	b.ne	0xb1364
 175821 |    b12a0:	e0 03 14 aa	mov	x0, x20
 175822 |    b12a4:	16 89 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 175823 |    b12a8:	fd 03 1d aa	mov	x29, x29
 175824 |    b12ac:	4d 89 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175825 |    b12b0:	f4 03 00 aa	mov	x20, x0
 175826 |    b12b4:	e0 03 00 f9	str	x0, [sp]
 175827 |    b12b8:	40 17 00 90	adrp	x0, 744 ; 0x399000
 175828 |    b12bc:	00 00 34 91	add	x0, x0, #0xd00 ; Objc cfstring ref: @"[CBWindow] Warning: Exception querying carPlayUIScreen bounds: %@"
 175829 |    b12c0:	40 fb ff 97	bl	0xaffc0
 175830 |    b12c4:	e0 03 14 aa	mov	x0, x20
 175831 |    b12c8:	3a 89 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 175832 |    b12cc:	15 89 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 175833 |    b12d0:	54 ff ff 17	b	0xb1020
 175834 |    b12d4:	22 00 00 14	b	0xb135c
 175835 |    b12d8:	f4 03 00 aa	mov	x20, x0
 175836 |    b12dc:	3f 04 00 71	cmp	w1, #0x1
 175837 |    b12e0:	21 04 00 54	b.ne	0xb1364
 175838 |    b12e4:	e0 03 14 aa	mov	x0, x20
 175839 |    b12e8:	05 89 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 175840 |    b12ec:	fd 03 1d aa	mov	x29, x29
 175841 |    b12f0:	3c 89 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175842 |    b12f4:	f4 03 00 aa	mov	x20, x0
 175843 |    b12f8:	e0 03 00 f9	str	x0, [sp]
 175844 |    b12fc:	40 17 00 90	adrp	x0, 744 ; 0x399000
 175845 |    b1300:	00 80 33 91	add	x0, x0, #0xce0 ; Objc cfstring ref: @"[CBWindow] Warning: Exception querying carPlayWindowScene bounds: %@"
 175846 |    b1304:	2f fb ff 97	bl	0xaffc0
 175847 |    b1308:	e0 03 14 aa	mov	x0, x20
 175848 |    b130c:	29 89 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 175849 |    b1310:	04 89 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 175850 |    b1314:	21 ff ff 17	b	0xb0f98
 175851 |    b1318:	11 00 00 14	b	0xb135c
 175852 |    b131c:	f4 03 00 aa	mov	x20, x0
 175853 |    b1320:	3f 04 00 71	cmp	w1, #0x1
 175854 |    b1324:	01 02 00 54	b.ne	0xb1364
 175855 |    b1328:	e0 03 14 aa	mov	x0, x20
 175856 |    b132c:	f4 88 09 94	bl	0x3136fc ; symbol stub for: _objc_begin_catch
 175857 |    b1330:	fd 03 1d aa	mov	x29, x29
 175858 |    b1334:	2b 89 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175859 |    b1338:	f4 03 00 aa	mov	x20, x0
 175860 |    b133c:	e0 03 00 f9	str	x0, [sp]
 175861 |    b1340:	40 17 00 90	adrp	x0, 744 ; 0x399000
 175862 |    b1344:	00 00 33 91	add	x0, x0, #0xcc0 ; Objc cfstring ref: @"[CBWindow] Warning: Exception reading live screen bounds file: %@"
 175863 |    b1348:	1e fb ff 97	bl	0xaffc0
 175864 |    b134c:	e0 03 14 aa	mov	x0, x20
 175865 |    b1350:	18 89 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 175866 |    b1354:	f3 88 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 175867 |    b1358:	dc fe ff 17	b	0xb0ec8
 175868 |    b135c:	f4 03 00 aa	mov	x20, x0
 175869 |    b1360:	f0 88 09 94	bl	0x313720 ; symbol stub for: _objc_end_catch
 175870 |    b1364:	e0 03 14 aa	mov	x0, x20
 175871 |    b1368:	4c 88 09 94	bl	0x313498 ; symbol stub for: __Unwind_Resume
 175872 |    b136c:	20 00 20 d4	brk	#0x1
 175873 |    b1370:	ed 33 b8 6d	stp	d13, d12, [sp, #-0x80]!
 175874 |    b1374:	eb 2b 01 6d	stp	d11, d10, [sp, #0x10]
 175875 |    b1378:	e9 23 02 6d	stp	d9, d8, [sp, #0x20]
 175876 |    b137c:	fa 67 03 a9	stp	x26, x25, [sp, #0x30]
 175877 |    b1380:	f8 5f 04 a9	stp	x24, x23, [sp, #0x40]
 175878 |    b1384:	f6 57 05 a9	stp	x22, x21, [sp, #0x50]
 175879 |    b1388:	f4 4f 06 a9	stp	x20, x19, [sp, #0x60]
 175880 |    b138c:	fd 7b 07 a9	stp	x29, x30, [sp, #0x70]
 175881 |    b1390:	fd c3 01 91	add	x29, sp, #0x70
 175882 |    b1394:	fa 17 00 90	adrp	x26, 764 ; 0x3ad000
 175883 |    b1398:	5a 03 01 91	add	x26, x26, #0x40
 175884 |    b139c:	4a 2f 41 6d	ldp	d10, d11, [x26, #0x10]
 175885 |    b13a0:	48 27 40 6d	ldp	d8, d9, [x26]
 175886 |    b13a4:	28 21 60 1e	fcmp	d9, #0.0
 175887 |    b13a8:	ec 0d 00 54	b.gt	0xb1564

... context gap ...
 175907 |    b13f8:	e2 88 09 94	bl	0x313780 ; Objc message: +[NSString stringWithContentsOfFile:encoding:error:]
 175908 |    b13fc:	fd 03 1d aa	mov	x29, x29
 175909 |    b1400:	f8 88 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175910 |    b1404:	f3 03 00 aa	mov	x19, x0
 175911 |    b1408:	80 02 00 b4	cbz	x0, 0xb1458
 175912 |    b140c:	a8 17 00 f0	adrp	x8, 759 ; 0x3a8000
 175913 |    b1410:	01 75 41 f9	ldr	x1, [x8, #0x2e8] ; Objc selector ref: length
 175914 |    b1414:	e0 03 13 aa	mov	x0, x19
 175915 |    b1418:	da 88 09 94	bl	0x313780 ; Objc message: -[x0 length]
 175916 |    b141c:	e0 01 00 b4	cbz	x0, 0xb1458
 175917 |    b1420:	e0 03 13 aa	mov	x0, x19
 175918 |    b1424:	05 88 09 94	bl	0x313438 ; symbol stub for: _UIEdgeInsetsFromString
 175919 |    b1428:	08 1c a0 4e	mov.16b	v8, v0
 175920 |    b142c:	29 1c a1 4e	mov.16b	v9, v1
 175921 |    b1430:	4a 1c a2 4e	mov.16b	v10, v2
 175922 |    b1434:	6b 1c a3 4e	mov.16b	v11, v3
 175923 |    b1438:	08 20 60 1e	fcmp	d0, #0.0
 175924 |    b143c:	ec 0a 00 54	b.gt	0xb1598
 175925 |    b1440:	48 21 60 1e	fcmp	d10, #0.0
 175926 |    b1444:	ac 0a 00 54	b.gt	0xb1598
 175927 |    b1448:	28 21 60 1e	fcmp	d9, #0.0
 175928 |    b144c:	6c 0a 00 54	b.gt	0xb1598
 175929 |    b1450:	68 21 60 1e	fcmp	d11, #0.0
 175930 |    b1454:	2c 0a 00 54	b.gt	0xb1598
 175931 |    b1458:	c8 17 00 b0	adrp	x8, 761 ; 0x3aa000
 175932 |    b145c:	00 9d 45 f9	ldr	x0, [x8, #0xb38] ; Objc class ref: CBWindow
 175933 |    b1460:	a8 17 00 f0	adrp	x8, 759 ; 0x3a8000
 175934 |    b1464:	01 dd 47 f9	ldr	x1, [x8, #0xfb8] ; Objc selector ref: activeCarPlayWindow
 175935 |    b1468:	c6 88 09 94	bl	0x313780 ; Objc message: +[CBWindow activeCarPlayWindow]
 175936 |    b146c:	fd 03 1d aa	mov	x29, x29
 175937 |    b1470:	dc 88 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175938 |    b1474:	f4 03 00 aa	mov	x20, x0
 175939 |    b1478:	e8 03 67 9e	fmov	d8, xzr
 175940 |    b147c:	40 06 00 b4	cbz	x0, 0xb1544
 175941 |    b1480:	a8 17 00 f0	adrp	x8, 759 ; 0x3a8000
 175942 |    b1484:	15 e1 47 f9	ldr	x21, [x8, #0xfc0] ; Objc selector ref: rootWindow
 175943 |    b1488:	e0 03 14 aa	mov	x0, x20
 175944 |    b148c:	e1 03 15 aa	mov	x1, x21
 175945 |    b1490:	bc 88 09 94	bl	0x313780 ; Objc message: -[x0 rootWindow]
 175946 |    b1494:	fd 03 1d aa	mov	x29, x29
 175947 |    b1498:	d2 88 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175948 |    b149c:	40 05 00 b4	cbz	x0, 0xb1544
 175949 |    b14a0:	f7 03 00 aa	mov	x23, x0
 175950 |    b14a4:	e0 03 14 aa	mov	x0, x20
 175951 |    b14a8:	e1 03 15 aa	mov	x1, x21
 175952 |    b14ac:	b5 88 09 94	bl	0x313780 ; Objc message: -[x0 rootWindow]
 175953 |    b14b0:	fd 03 1d aa	mov	x29, x29
 175954 |    b14b4:	cb 88 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 175955 |    b14b8:	f8 03 00 aa	mov	x24, x0
 175956 |    b14bc:	a8 17 00 f0	adrp	x8, 759 ; 0x3a8000
 175957 |    b14c0:	16 e5 47 f9	ldr	x22, [x8, #0xfc8] ; Objc selector ref: safeAreaInsets
 175958 |    b14c4:	1f 20 03 d5	nop
 175959 |    b14c8:	01 ad 41 f9	ldr	x1, [x8, #0x358]
 175960 |    b14cc:	e2 03 16 aa	mov	x2, x22

... context gap ...
 176066 |    b1674:	a8 20 60 1e	fcmp	d5, #0.0
 176067 |    b1678:	84 dc 62 1e	fcsel	d4, d4, d2, le
 176068 |    b167c:	00 dc 62 1e	fcsel	d0, d0, d2, le
 176069 |    b1680:	25 dc 69 1e	fcsel	d5, d1, d9, le
 176070 |    b1684:	c6 dc 67 1e	fcsel	d6, d6, d7, le
 176071 |    b1688:	27 39 63 1e	fsub	d7, d9, d3
 176072 |    b168c:	68 20 60 1e	fcmp	d3, #0.0
 176073 |    b1690:	83 dc 62 1e	fcsel	d3, d4, d2, le
 176074 |    b1694:	01 dc 62 1e	fcsel	d1, d0, d2, le
 176075 |    b1698:	a2 dc 67 1e	fcsel	d2, d5, d7, le
 176076 |    b169c:	c4 dc 68 1e	fcsel	d4, d6, d8, le
 176077 |    b16a0:	03 00 00 14	b	0xb16ac
 176078 |    b16a4:	43 29 61 1e	fadd	d3, d10, d1
 176079 |    b16a8:	61 29 60 1e	fadd	d1, d11, d0
 176080 |    b16ac:	60 1c a3 4e	mov.16b	v0, v3
 176081 |    b16b0:	83 1c a4 4e	mov.16b	v3, v4
 176082 |    b16b4:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
 176083 |    b16b8:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
 176084 |    b16bc:	e9 23 41 6d	ldp	d9, d8, [sp, #0x10]
 176085 |    b16c0:	eb 2b c4 6c	ldp	d11, d10, [sp], #0x40
 176086 |    b16c4:	c0 03 5f d6	ret
 176087 |    b16c8:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
 176088 |    b16cc:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
 176089 |    b16d0:	fd 43 00 91	add	x29, sp, #0x10
 176090 |    b16d4:	c8 17 00 b0	adrp	x8, 761 ; 0x3aa000
 176091 |    b16d8:	00 9d 45 f9	ldr	x0, [x8, #0xb38] ; Objc class ref: CBWindow
 176092 |    b16dc:	a8 17 00 f0	adrp	x8, 759 ; 0x3a8000
 176093 |    b16e0:	01 cd 47 f9	ldr	x1, [x8, #0xf98] ; Objc selector ref: carPlayCADisplay
 176094 |    b16e4:	27 88 09 94	bl	0x313780 ; Objc message: +[CBWindow carPlayCADisplay]
 176095 |    b16e8:	fd 03 1d aa	mov	x29, x29
 176096 |    b16ec:	3d 88 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 176097 |    b16f0:	f3 03 00 aa	mov	x19, x0
 176098 |    b16f4:	80 00 00 b4	cbz	x0, 0xb1704
 176099 |    b16f8:	e0 03 13 aa	mov	x0, x19
 176100 |    b16fc:	30 88 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
 176101 |    b1700:	08 00 00 14	b	0xb1720
 176102 |    b1704:	c8 17 00 b0	adrp	x8, 761 ; 0x3aa000
 176103 |    b1708:	00 b1 45 f9	ldr	x0, [x8, #0xb60] ; Objc class ref: _OBJC_CLASS_$_CADisplay
 176104 |    b170c:	a8 17 00 f0	adrp	x8, 759 ; 0x3a8000
 176105 |    b1710:	01 f1 47 f9	ldr	x1, [x8, #0xfe0] ; Objc selector ref: mainDisplay
 176106 |    b1714:	1b 88 09 94	bl	0x313780 ; Objc message: +[CADisplay mainDisplay]
 176107 |    b1718:	fd 03 1d aa	mov	x29, x29
 176108 |    b171c:	31 88 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
 176109 |    b1720:	f4 03 00 aa	mov	x20, x0
 176110 |    b1724:	e0 03 13 aa	mov	x0, x19
 176111 |    b1728:	22 88 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
 176112 |    b172c:	e0 03 14 aa	mov	x0, x20
 176113 |    b1730:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
 176114 |    b1734:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
 176115 |    b1738:	ee 87 09 14	b	0x3136f0 ; symbol stub for: _objc_autoreleaseReturnValue
 176116 |    b173c:	f
[TRUNCATED]
~~~

## Original class instance methods with IMP addresses

Method addresses below are statically derived from original 1.0.4 ObjC metadata.
They are not V12 addresses and do not by themselves show call order.

- CBBridgedUIAppView::initWithBundleIdentifier: IMP=0xac1a4
- CBBridgedUIAppView::initWithBundleIdentifier:scale: IMP=0xac1b4
- CBBridgedUIAppView::setAppScale: IMP=0xac318
- CBBridgedUIAppView::setAudioOnlyBackgroundMode: IMP=0xac334
- CBBridgedUIAppView::layoutSubviews IMP=0xac3cc
- CBBridgedUIAppView::hitTest:withEvent: IMP=0xac448
- CBBridgedUIAppView::touchesBegan:withEvent: IMP=0xac5a0
- CBBridgedUIAppView::calculateNativeSizeForSlotRect: IMP=0xac788
- CBBridgedUIAppView::updateLayout IMP=0xac7cc
- CBBridgedUIAppView::updateSceneSettingsFrame IMP=0xad368
- CBBridgedUIAppView::updateSceneFrame IMP=0xadc24
- CBBridgedUIAppView::refreshSceneLayout IMP=0xadc30
- CBBridgedUIAppView::startInParentViewController: IMP=0xadd08
- CBBridgedUIAppView::start IMP=0xaede8
- CBBridgedUIAppView::dismiss IMP=0xaedf8
- CBBridgedUIAppView::hostedScene IMP=0xaefb4
- CBBridgedUIAppView::openURLInScene: IMP=0xaf250
- CBBridgedUIAppView::dealloc IMP=0xaf4d8
- CBBridgedUIAppView::bundleIdentifier IMP=0xaf550
- CBBridgedUIAppView::setBundleIdentifier: IMP=0xaf560
- CBBridgedUIAppView::appViewController IMP=0xaf56c
- CBBridgedUIAppView::setAppViewController: IMP=0xaf57c
- CBBridgedUIAppView::wrapperView IMP=0xaf590
- CBBridgedUIAppView::setWrapperView: IMP=0xaf5a0
- CBBridgedUIAppView::appScale IMP=0xaf5b4
- CBBridgedUIAppView::hosting IMP=0xaf5c4
- CBBridgedUIAppView::setHosting: IMP=0xaf5d4
- CBBridgedUIAppView::invalidated IMP=0xaf5e4
- CBBridgedUIAppView::setInvalidated: IMP=0xaf5f4
- CBBridgedUIAppView::audioOnlyBackgroundMode IMP=0xaf604
- CBBridgedUIAppView::.cxx_destruct IMP=0xaf614
- CBWindow::initWithAppFrame: IMP=0xaf960
- CBWindow::getCarPlayDisplay IMP=0xb16c8
- CBWindow::createWindows IMP=0xb173c
- CBWindow::aiBubbleView IMP=0xb2064
- CBWindow::voiceSessionManager:didChangeState: IMP=0xb2230
- CBWindow::multitaskingOverlay IMP=0xb2374
- CBWindow::resizeWindows IMP=0xb24ac
- CBWindow::show IMP=0xb2814
- CBWindow::hide: IMP=0xb29b0
- CBWindow::isDisplayValid IMP=0xb2bc0
- CBWindow::destroyWindows IMP=0xb2d14
- CBWindow::dismiss IMP=0xb30c4
- CBWindow::dealloc IMP=0xb30d0
- CBWindow::showAppPickerForSlot: IMP=0xb3148
- CBWindow::showLayoutChooser IMP=0xb31f8
- CBWindow::showRecentApps IMP=0xb32a0
- CBWindow::appFrame IMP=0xb3348
- CBWindow::setAppFrame: IMP=0xb3354
- CBWindow::rootWindow IMP=0xb3368
- CBWindow::setRootWindow: IMP=0xb3370
- CBWindow::rootViewController IMP=0xb337c
- CBWindow::setRootViewController: IMP=0xb3384
- CBWindow::contentView IMP=0xb3390
- CBWindow::setContentView: IMP=0xb3398
- CBWindow::multitaskingPill IMP=0xb33a4
- CBWindow::setMultitaskingPill: IMP=0xb33ac
- CBWindow::setMultitaskingOverlay: IMP=0xb33b8
- CBWindow::setAiBubbleView: IMP=0xb33c4
- CBWindow::isVisible IMP=0xb33d0
- CBWindow::setIsVisible: IMP=0xb33d8
- CBWindow::.cxx_destruct IMP=0xb33e0
- CBWindow::activeCarPlayWindow IMP=0xafa24
- CBWindow::resetCachedBounds IMP=0xafa40
- CBWindow::carPlayWindowScene IMP=0xafb60
- CBWindow::carPlayUIScreen IMP=0xb0538
- CBWindow::carPlayCADisplay IMP=0xb06d4
- CBWindow::carPlayScreenScale IMP=0xb0c74
- CBWindow::carPlayScreenBounds IMP=0xb0ddc
- CBWindow::carPlayContentInsets IMP=0xb1370
- CBWindow::carPlayUsableBounds IMP=0xb15cc
- CBBridgedSplitApp::initWithBundleIdentifier:frame: IMP=0x109bb8
- CBBridgedSplitApp::initWithBundleIdentifier:frame:showSplash: IMP=0x109bc8
- CBBridgedSplitApp::handleDividerPan:isVertical:state: IMP=0x10b4c0
- CBBridgedSplitApp::layoutSplitViews IMP=0x10bad8
- CBBridgedSplitApp::focusSlot:animated: IMP=0x10ce70
- CBBridgedSplitApp::restoreSplitAnimated: IMP=0x10d40c
- CBBridgedSplitApp::toggleFocusForSlot: IMP=0x10daf8
- CBBridgedSplitApp::rotateAllSlotsClockwise IMP=0x10db40
- CBBridgedSplitApp::configureDividerButtons IMP=0x10ddf4
- CBBridgedSplitApp::updateScale:forSlot: IMP=0x11042c
- CBBridgedSplitApp::moveSlot:direction: IMP=0x11057c
- CBBridgedSplitApp::handleDividerSwapPressed: IMP=0x11061c
- CBBridgedSplitApp::swapSlot:withSlot: IMP=0x1107b0
- CBBridgedSplitApp::evictAppFromPhoneScreen: IMP=0x110f70
- CBBridgedSplitApp::replaceAppInSlot:withBundleIdentifier: IMP=0x111090
- CBBridgedSplitApp::restartSlot: IMP=0x1117d4
- CBBridgedSplitApp::restartAppWithBundleIdentifier: IMP=0x1120a8
- CBBridgedSplitApp::removeAppWithBundleIdentifier: IMP=0x1121e0
- CBBridgedSplitApp::closeSlot: IMP=0x112318
- CBBridgedSplitApp::closeAllSlots IMP=0x1128a8
- CBBridgedSplitApp::persistSlotOrder IMP=0x112c9c
- CBBridgedSplitApp::start IMP=0x1132fc
- CBBridgedSplitApp::startInParentViewController: IMP=0x11330c
- CBBridgedSplitApp::stop IMP=0x1136dc
- CBBridgedSplitApp::noteUserActivity IMP=0x113b68
- CBBridgedSplitApp::startBlinkingSession IMP=0x113c98
- CBBridgedSplitApp::stopBlinkingSession IMP=0x1276ec
- CBBridgedSplitApp::startContainerBorderBlinking: IMP=0x127c20
- CBBridgedSplitApp::stopContainerBorderBlinking: IMP=0x127e6c
- CBBridgedSplitApp::splashScreenView IMP=0x127f74
- CBBridgedSplitApp::setSplashScreenView: IMP=0x127f84
- CBBridgedSplitApp::appViews IMP=0x127f98
- CBBridgedSplitApp::setAppViews: IMP=0x127fa8
- CBBridgedSplitApp::placeholders IMP=0x127fbc
- CBBridgedSplitApp::setPlaceholders: IMP=0x127fcc
- CBBridgedSplitApp::containers IMP=0x127fe0
- CBBridgedSplitApp::setContainers: IMP=0x127ff0
- CBBridgedSplitApp::dividers IMP=0x128004
- CBBridgedSplitApp::setDividers: IMP=0x128014
- CBBridgedSplitApp::slotPills IMP=0x128028
- CBBridgedSplitApp::setSlotPills: IMP=0x128038
- CBBridgedSplitApp::splitPreset IMP=0x12804c
- CBBridgedSplitApp::setSplitPreset: IMP=0x12805c
- CBBridgedSplitApp::splitRatio IMP=0x12806c
- CBBridgedSplitApp::setSplitRatio: IMP=0x12807c
- CBBridgedSplitApp::focusedSlotIndex IMP=0x12808c
- CBBridgedSplitApp::setFocusedSlotIndex: IMP=0x12809c
- CBBridgedSplitApp::isTransitioningFocus IMP=0x1280ac
- CBBridgedSplitApp::setIsTransitioningFocus: IMP=0x1280bc
- CBBridgedSplitApp::.cxx_destruct IMP=0x1280cc
- CBBridgedSplitApp::text IMP=0x128654
- CBBridgedSplitApp::setText: IMP=0x128660
- CBBridgedSplitApp::audioStreamFollowing IMP=0x128668
- CBBridgedSplitApp::setAudioStreamFollowing: IMP=0x128670
- CBBridgedSplitApp::.cxx_destruct IMP=0x128678

### Original CBBridgedUIAppView::dismiss at 0xaedf8

~~~asm
   aedf8:	f8 5f bc a9	stp	x24, x23, [sp, #-0x40]!
   aedfc:	f6 57 01 a9	stp	x22, x21, [sp, #0x10]
   aee00:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
   aee04:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
   aee08:	fd c3 00 91	add	x29, sp, #0x30
   aee0c:	f3 03 00 aa	mov	x19, x0
   aee10:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aee14:	01 71 47 f9	ldr	x1, [x8, #0xee0] ; Objc selector ref: setInvalidated:
   aee18:	22 00 80 52	mov	w2, #0x1
   aee1c:	59 92 09 94	bl	0x313780 ; Objc message: -[x0 setInvalidated:]
   aee20:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aee24:	01 31 47 f9	ldr	x1, [x8, #0xe60] ; Objc selector ref: setHosting:
   aee28:	e0 03 13 aa	mov	x0, x19
   aee2c:	02 00 80 52	mov	w2, #0x0
   aee30:	54 92 09 94	bl	0x313780 ; Objc message: -[x0 setHosting:]
   aee34:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
   aee38:	17 d1 8f b9	ldrsw	x23, [x8, #0xfd0]
   aee3c:	60 6a 77 f8	ldr	x0, [x19, x23]
   aee40:	d6 17 00 d0	adrp	x22, 762 ; 0x3a8000
   aee44:	40 09 00 b4	cbz	x0, 0xaef6c
   aee48:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aee4c:	15 75 47 f9	ldr	x21, [x8, #0xee8] ; Objc selector ref: beginAppearanceTransition:animated:
   aee50:	1f 20 03 d5	nop
   aee54:	14 ad 41 f9	ldr	x20, [x8, #0x358]
   aee58:	e1 03 14 aa	mov	x1, x20
   aee5c:	e2 03 15 aa	mov	x2, x21
   aee60:	48 92 09 94	bl	0x313780 ; Objc message: -[x0 beginAppearanceTransition:animated:]
   aee64:	40 01 00 34	cbz	w0, 0xaee8c
   aee68:	60 6a 77 f8	ldr	x0, [x19, x23]
   aee6c:	e1 03 15 aa	mov	x1, x21
   aee70:	02 00 80 52	mov	w2, #0x0
   aee74:	03 00 80 52	mov	w3, #0x0
   aee78:	42 92 09 94	bl	0x313780 ; Objc message: -[x0 beginAppearanceTransition:animated:]
   aee7c:	60 6a 77 f8	ldr	x0, [x19, x23]
   aee80:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aee84:	01 79 47 f9	ldr	x1, [x8, #0xef0] ; Objc selector ref: endAppearanceTransition
   aee88:	3e 92 09 94	bl	0x313780 ; Objc message: -[x0 endAppearanceTransition]
   aee8c:	60 6a 77 f8	ldr	x0, [x19, x23]
   aee90:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aee94:	15 61 47 f9	ldr	x21, [x8, #0xec0] ; Objc selector ref: setRequestedMode:
   aee98:	e1 03 14 aa	mov	x1, x20
   aee9c:	e2 03 15 aa	mov	x2, x21
   aeea0:	38 92 09 94	bl	0x313780 ; Objc message: -[x0 setRequestedMode:]
   aeea4:	a0 00 00 34	cbz	w0, 0xaeeb8
   aeea8:	60 6a 77 f8	ldr	x0, [x19, x23]
   aeeac:	e1 03 15 aa	mov	x1, x21
   aeeb0:	02 00 80 d2	mov	x2, #0x0
   aeeb4:	33 92 09 94	bl	0x313780 ; Objc message: -[x0 setRequestedMode:]
   aeeb8:	60 6a 77 f8	ldr	x0, [x19, x23]
   aeebc:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aeec0:	01 e1 46 f9	ldr	x1, [x8, #0xdc0] ; Objc selector ref: view
   aeec4:	2f 92 09 94	bl	0x313780 ; Objc message: -[x0 view]
   aeec8:	fd 03 1d aa	mov	x29, x29
   aeecc:	45 92 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   aeed0:	f5 03 00 aa	mov	x21, x0
   aeed4:	c1 2a 45 f9	ldr	x1, [x22, #0xa50]
   aeed8:	2a 92 09 94	bl	0x313780 ; Objc message: -[x0 view]
   aeedc:	e0 03 15 aa	mov	x0, x21
   aeee0:	34 92 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   aeee4:	60 6a 77 f8	ldr	x0, [x19, x23]
   aeee8:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aeeec:	15 7d 47 f9	ldr	x21, [x8, #0xef8] ; Objc selector ref: willMoveToParentViewController:
   aeef0:	e1 03 14 aa	mov	x1, x20
   aeef4:	e2 03 15 aa	mov	x2, x21
   aeef8:	22 92 09 94	bl	0x313780 ; Objc message: -[x0 willMoveToParentViewController:]
   aeefc:	a0 00 00 34	cbz	w0, 0xaef10
   aef00:	60 6a 77 f8	ldr	x0, [x19, x23]
   aef04:	e1 03 15 aa	mov	x1, x21
   aef08:	02 00 80 d2	mov	x2, #0x0
   aef0c:	1d 92 09 94	bl	0x313780 ; Objc message: -[x0 willMoveToParentViewController:]
   aef10:	60 6a 77 f8	ldr	x0, [x19, x23]
   aef14:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aef18:	15 81 47 f9	ldr	x21, [x8, #0xf00] ; Objc selector ref: removeFromParentViewController
   aef1c:	e1 03 14 aa	mov	x1, x20
   aef20:	e2 03 15 aa	mov	x2, x21
   aef24:	17 92 09 94	bl	0x313780 ; Objc message: -[x0 removeFromParentViewController]
   aef28:	80 00 00 34	cbz	w0, 0xaef38
   aef2c:	60 6a 77 f8	ldr	x0, [x19, x23]
   aef30:	e1 03 15 aa	mov	x1, x21
   aef34:	13 92 09 94	bl	0x313780 ; Objc message: -[x0 removeFromParentViewController]
   aef38:	60 6a 77 f8	ldr	x0, [x19, x23]
   aef3c:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aef40:	15 c1 43 f9	ldr	x21, [x8, #0x780] ; Objc selector ref: invalidate
   aef44:	e1 03 14 aa	mov	x1, x20
   aef48:	e2 03 15 aa	mov	x2, x21
   aef4c:	0d 92 09 94	bl	0x313780 ; Objc message: -[x0 invalidate]
   aef50:	80 00 00 34	cbz	w0, 0xaef60
   aef54:	60 6a 77 f8	ldr	x0, [x19, x23]
   aef58:	e1 03 15 aa	mov	x1, x21
   aef5c:	09 92 09 94	bl	0x313780 ; Objc message: -[x0 invalidate]
   aef60:	60 6a 77 f8	ldr	x0, [x19, x23]
   aef64:	7f 6a 37 f8	str	xzr, [x19, x23]
   aef68:	12 92 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   aef6c:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
   aef70:	14 cd 8f b9	ldrsw	x20, [x8, #0xfcc]
   aef74:	60 6a 74 f8	ldr	x0, [x19, x20]
   aef78:	40 01 00 b4	cbz	x0, 0xaefa0
   aef7c:	c1 2a 45 f9	ldr	x1, [x22, #0xa50]
   aef80:	00 92 09 94	bl	0x313780 ; Objc message: -[x0 invalidate]
   aef84:	60 6a 74 f8	ldr	x0, [x19, x20]
   aef88:	7f 6a 34 f8	str	xzr, [x19, x20]
   aef8c:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
   aef90:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
   aef94:	f6 57 41 a9	ldp	x22, x21, [sp, #0x10]
   aef98:	f8 5f c4 a8	ldp	x24, x23, [sp], #0x40
   aef9c:	05 92 09 14	b	0x3137b0 ; symbol stub for: _objc_release
   aefa0:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
   aefa4:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
   aefa8:	f6 57 41 a9	ldp	x22, x21, [sp, #0x10]
   aefac:	f8 5f c4 a8	ldp	x24, x23, [sp], #0x40
   aefb0:	c0 03 5f d6	ret
   aefb4:	fa 67 bb a9	stp	x26, x25, [sp, #-0x50]!
   aefb8:	f8 5f 01 a9	stp	x24, x23, [sp, #0x10]
   aefbc:	f6 57 02 a9	stp	x22, x21, [sp, #0x20]
   aefc0:	f4 4f 03 a9	stp	x20, x19, [sp, #0x30]
   aefc4:	fd 7b 04 a9	stp	x29, x30, [sp, #0x40]
   aefc8:	fd 03 01 91	add	x29, sp, #0x40
   aefcc:	f6 03 00 aa	mov	x22, x0
   aefd0:	e8 17 00 90	adrp	x8, 764 ; 0x3aa000
   aefd4:	1a d1 8f b9	ldrsw	x26, [x8, #0xfd0]
   aefd8:	00 68 7a f8	ldr	x0, [x0, x26]
   aefdc:	a0 12 00 b4	cbz	x0, 0xaf230
   aefe0:	c8 17 00 d0	adrp	x8, 762 ; 0x3a8000
   aefe4:	13 05 47 f9	ldr	x19, [x8, #0xe08] ; Objc selector ref: scene
   aefe8:	1f 20 03 d5	nop
   aefec:	14 ad 41 f9	ldr	x20, [x8, #0x358]
   aeff0:	e1 03 14 aa	mov	x1, x20
   aeff4:	e2 03 13 aa	mov	x2, x19
   aeff8:	e2 91 09 94	bl	0x313780 ; Objc message: -[x0 scene]
   aeffc:	60 01 00 34	cbz	w0, 0xaf028
   af000:	c0 6a 7a f8	ldr	x0, [x22, x26]
   af004:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af008:	01 25 45 f9	ldr	x1, [x8, #0xa48] ; Objc selector ref: performSelector:
   af00c:	e2 03 13 aa	mov	x2, x19
   af010:	dc 91 09 94	bl	0x313780 ; Objc message: -[x0 performSelector:]
   af014:	fd 03 1d aa	mov	x29, x29
   af018:	f2 91 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   af01c:	60 00 00 b4	cbz	x0, 0xaf028
   af020:	f8 03 00 aa	mov	x24, x0
   af024:	84 00 00 14	b	0xaf234
   af028:	c0 6a 7a f8	ldr	x0, [x22, x26]
   af02c:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af030:	15 fd 46 f9	ldr	x21, [x8, #0xdf8] ; Objc selector ref: sceneHandle
   af034:	e1 03 14 aa	mov	x1, x20
   af038:	e2 03 15 aa	mov	x2, x21
   af03c:	d1 91 09 94	bl	0x313780 ; Objc message: -[x0 sceneHandle]
   af040:	60 05 00 34	cbz	w0, 0xaf0ec
   af044:	c0 6a 7a f8	ldr	x0, [x22, x26]
   af048:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af04c:	19 25 45 f9	ldr	x25, [x8, #0xa48] ; Objc selector ref: performSelector:
   af050:	e1 03 19 aa	mov	x1, x25
   af054:	e2 03 15 aa	mov	x2, x21
   af058:	ca 91 09 94	bl	0x313780 ; Objc message: -[x0 performSelector:]
   af05c:	fd 03 1d aa	mov	x29, x29
   af060:	e0 91 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   af064:	f7 03 00 aa	mov	x23, x0
   af068:	e0 03 00 b4	cbz	x0, 0xaf0e4
   af06c:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af070:	18 01 47 f9	ldr	x24, [x8, #0xe00] ; Objc selector ref: sceneIfExists
   af074:	e0 03 17 aa	mov	x0, x23
   af078:	e1 03 14 aa	mov	x1, x20
   af07c:	e2 03 18 aa	mov	x2, x24
   af080:	c0 91 09 94	bl	0x313780 ; Objc message: -[x0 sceneIfExists]
   af084:	20 01 00 34	cbz	w0, 0xaf0a8
   af088:	e0 03 17 aa	mov	x0, x23
   af08c:	e1 03 19 aa	mov	x1, x25
   af090:	e2 03 18 aa	mov	x2, x24
   af094:	bb 91 09 94	bl	0x313780 ; Objc message: -[x0 sceneIfExists]
   af098:	fd 03 1d aa	mov	x29, x29
   af09c:	d1 91 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   af0a0:	f8 03 00 aa	mov	x24, x0
   af0a4:	c0 01 00 b5	cbnz	x0, 0xaf0dc
   af0a8:	e0 03 17 aa	mov	x0, x23
   af0ac:	e1 03 14 aa	mov	x1, x20
   af0b0:	e2 03 13 aa	mov	x2, x19
   af0b4:	b3 91 09 94	bl	0x313780 ; Objc message: -[x0 sceneIfExists]
   af0b8:	60 01 00 34	cbz	w0, 0xaf0e4
   af0bc:	e0 03 17 aa	mov	x0, x23
   af0c0:	e1 03 19 aa	mov	x1, x25
   af0c4:	e2 03 13 aa	mov	x2, x19
   af0c8:	ae 91 09 94	bl	0x313780 ; Objc message: -[x0 sceneIfExists]
   af0cc:	fd 03 1d aa	mov	x29, x29
   af0d0:	c4 91 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   af0d4:	f8 03 00 aa	mov	x24, x0
   af0d8:	60 00 00 b4	cbz	x0, 0xaf0e4
   af0dc:	e0 03 17 aa	mov	x0, x23
   af0e0:	4e 00 00 14	b	0xaf218
   af0e4:	e0 03 17 aa	mov	x0, x23
   af0e8:	b2 91 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af0ec:	c0 6a 7a f8	ldr	x0, [x22, x26]
   af0f0:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af0f4:	01 c9 41 f9	ldr	x1, [x8, #0x390] ; Objc selector ref: class
   af0f8:	a2 91 09 94	bl	0x313780 ; Objc message: -[x0 class]
   af0fc:	01 14 00 f0	adrp	x1, 643 ; 0x332000
   af100:	21 6c 14 91	add	x1, x1, #0x51b ; literal pool for: "_deviceAppViewController"
   af104:	09 91 09 94	bl	0x313528 ; symbol stub for: _class_getInstanceVariable
   af108:	40 09 00 b4	cbz	x0, 0xaf230
   af10c:	e1 03 00 aa	mov	x1, x0
   af110:	c0 6a 7a f8	ldr	x0, [x22, x26]
   af114:	d4 91 09 94	bl	0x313864 ; symbol stub for: _object_getIvar
   af118:	fd 03 1d aa	mov	x29, x29
   af11c:	b1 91 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   af120:	f6 03 00 aa	mov	x22, x0
   af124:	20 08 00 b4	cbz	x0, 0xaf228
   af128:	e0 03 16 aa	mov	x0, x22
   af12c:	e1 03 14 aa	mov	x1, x20
   af130:	e2 03 13 aa	mov	x2, x19
   af134:	93 91 09 94	bl	0x313780 ; Objc message: -[x0 class]
   af138:	40 01 00 34	cbz	w0, 0xaf160
   af13c:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af140:	01 25 45 f9	ldr	x1, [x8, #0xa48] ; Objc selector ref: performSelector:
   af144:	e0 03 16 aa	mov	x0, x22
   af148:	e2 03 13 aa	mov	x2, x19
   af14c:	8d 91 09 94	bl	0x313780 ; Objc message: -[x0 performSelector:]
   af150:	fd 03 1d aa	mov	x29, x29
   af154:	a3 91 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   af158:	f8 03 00 aa	mov	x24, x0
   af15c:	c0 05 00 b5	cbnz	x0, 0xaf214
   af160:	e0 03 16 aa	mov	x0, x22
   af164:	e1 03 14 aa	mov	x1, x20
~~~

### Original CBBridgedUIAppView::dealloc at 0xaf4d8

~~~asm
   af4d8:	ff 03 01 d1	sub	sp, sp, #0x40
   af4dc:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
   af4e0:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
   af4e4:	fd c3 00 91	add	x29, sp, #0x30
   af4e8:	f3 03 00 aa	mov	x19, x0
   af4ec:	08 16 00 b0	adrp	x8, 705 ; 0x370000
   af4f0:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af4f4:	08 01 40 f9	ldr	x8, [x8]
   af4f8:	e8 0f 00 f9	str	x8, [sp, #0x18]
   af4fc:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af500:	01 95 47 f9	ldr	x1, [x8, #0xf28] ; Objc selector ref: dismiss
   af504:	9f 90 09 94	bl	0x313780 ; Objc message: -[x0 dismiss]
   af508:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af50c:	08 e1 46 f9	ldr	x8, [x8, #0xdc0] ; Objc class ref: CBBridgedUIAppView
   af510:	f3 a3 00 a9	stp	x19, x8, [sp, #0x8]
   af514:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af518:	01 d1 43 f9	ldr	x1, [x8, #0x7a0] ; Objc selector ref: dealloc
   af51c:	e0 23 00 91	add	x0, sp, #0x8
   af520:	9e 90 09 94	bl	0x313798 ; Objc message: -[[x0 super] dealloc]
   af524:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
   af528:	09 16 00 b0	adrp	x9, 705 ; 0x370000
   af52c:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af530:	29 01 40 f9	ldr	x9, [x9]
   af534:	3f 01 08 eb	cmp	x9, x8
   af538:	a1 00 00 54	b.ne	0xaf54c
   af53c:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
   af540:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
   af544:	ff 03 01 91	add	sp, sp, #0x40
   af548:	c0 03 5f d6	ret
   af54c:	dc 8f 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
   af550:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af554:	02 b9 8f b9	ldrsw	x2, [x8, #0xfb8]
   af558:	03 00 80 52	mov	w3, #0x0
   af55c:	80 90 09 14	b	0x31375c ; symbol stub for: _objc_getProperty
   af560:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af564:	03 b9 8f b9	ldrsw	x3, [x8, #0xfb8]
   af568:	a7 90 09 14	b	0x313804 ; symbol stub for: _objc_setProperty_nonatomic_copy
   af56c:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af570:	08 d1 8f b9	ldrsw	x8, [x8, #0xfd0]
   af574:	00 68 68 f8	ldr	x0, [x0, x8]
   af578:	c0 03 5f d6	ret
   af57c:	e1 03 02 aa	mov	x1, x2
   af580:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af584:	08 d1 8f b9	ldrsw	x8, [x8, #0xfd0]
   af588:	00 00 08 8b	add	x0, x0, x8
   af58c:	a1 90 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   af590:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af594:	08 cd 8f b9	ldrsw	x8, [x8, #0xfcc]
   af598:	00 68 68 f8	ldr	x0, [x0, x8]
   af59c:	c0 03 5f d6	ret
   af5a0:	e1 03 02 aa	mov	x1, x2
   af5a4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5a8:	08 cd 8f b9	ldrsw	x8, [x8, #0xfcc]
   af5ac:	00 00 08 8b	add	x0, x0, x8
   af5b0:	98 90 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   af5b4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5b8:	08 bd 8f b9	ldrsw	x8, [x8, #0xfbc]
   af5bc:	00 68 68 fc	ldr	d0, [x0, x8]
   af5c0:	c0 03 5f d6	ret
   af5c4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5c8:	08 c1 8f b9	ldrsw	x8, [x8, #0xfc0]
   af5cc:	00 68 68 38	ldrb	w0, [x0, x8]
   af5d0:	c0 03 5f d6	ret
   af5d4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5d8:	08 c1 8f b9	ldrsw	x8, [x8, #0xfc0]
   af5dc:	02 68 28 38	strb	w2, [x0, x8]
   af5e0:	c0 03 5f d6	ret
   af5e4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5e8:	08 c5 8f b9	ldrsw	x8, [x8, #0xfc4]
   af5ec:	00 68 68 38	ldrb	w0, [x0, x8]
   af5f0:	c0 03 5f d6	ret
   af5f4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5f8:	08 c5 8f b9	ldrsw	x8, [x8, #0xfc4]
   af5fc:	02 68 28 38	strb	w2, [x0, x8]
   af600:	c0 03 5f d6	ret
   af604:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af608:	08 c9 8f b9	ldrsw	x8, [x8, #0xfc8]
   af60c:	00 68 68 38	ldrb	w0, [x0, x8]
   af610:	c0 03 5f d6	ret
   af614:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
   af618:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
   af61c:	fd 43 00 91	add	x29, sp, #0x10
   af620:	f3 03 00 aa	mov	x19, x0
   af624:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af628:	08 cd 8f b9	ldrsw	x8, [x8, #0xfcc]
   af62c:	00 00 08 8b	add	x0, x0, x8
   af630:	01 00 80 d2	mov	x1, #0x0
   af634:	77 90 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   af638:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af63c:	08 d1 8f b9	ldrsw	x8, [x8, #0xfd0]
   af640:	60 02 08 8b	add	x0, x19, x8
   af644:	01 00 80 d2	mov	x1, #0x0
   af648:	72 90 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   af64c:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af650:	08 b9 8f b9	ldrsw	x8, [x8, #0xfb8]
   af654:	60 02 08 8b	add	x0, x19, x8
   af658:	01 00 80 d2	mov	x1, #0x0
   af65c:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
   af660:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
   af664:	6b 90 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   af668:	ff 03 05 d1	sub	sp, sp, #0x140
   af66c:	fc 6f 11 a9	stp	x28, x27, [sp, #0x110]
   af670:	f4 4f 12 a9	stp	x20, x19, [sp, #0x120]
   af674:	fd 7b 13 a9	stp	x29, x30, [sp, #0x130]
   af678:	fd c3 04 91	add	x29, sp, #0x130
   af67c:	09 00 80 d2	mov	x9, #0x0
   af680:	08 16 00 b0	adrp	x8, 705 ; 0x370000
   af684:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af688:	08 01 40 f9	ldr	x8, [x8]
   af68c:	a8 83 1d f8	stur	x8, [x29, #-0x28]
   af690:	68 14 00 f0	adrp	x8, 655 ; 0x33e000
   af694:	08 81 20 91	add	x8, x8, #0x820
   af698:	8a 0d 80 52	mov	w10, #0x6c
   af69c:	4a 5d 00 11	add	w10, w10, #0x17
   af6a0:	eb e7 02 b2	mov	x11, #-0x3333333333333334
   af6a4:	ab 99 99 f2	movk	x11, #0xcccd
   af6a8:	6c 05 80 52	mov	w12, #0x2b
   af6ac:	4d 0b 80 12	mov	w13, #-0x5b
   af6b0:	4e 15 80 52	mov	w14, #0xaa
   af6b4:	ef 03 00 91	mov	x15, sp
   af6b8:	30 7d cb 9b	umulh	x16, x9, x11
   af6bc:	10 fe 42 d3	lsr	x16, x16, #2
   af6c0:	10 0a 10 0b	add	w16, w16, w16, lsl #2
   af6c4:	31 29 0c 1b	madd	w17, w9, w12, w10
   af6c8:	00 69 69 38	ldrb	w0, [x8, x9]
   af6cc:	21 01 0d 4a	eor	w1, w9, w13
   af6d0:	22 00 00 2a	orr	w2, w1, w0
   af6d4:	42 78 1f 53	lsl	w2, w2, #1
   af6d8:	20 00 00 0b	add	w0, w1, w0
   af6dc:	40 00 00 4b	sub	w0, w2, w0
   af6e0:	30 01 10 4b	sub	w16, w9, w16
   af6e4:	01 06 00 11	add	w1, w16, #0x1
   af6e8:	00 1c 00 12	and	w0, w0, #0xff
   af6ec:	01 24 c1 1a	lsr	w1, w0, w1
   af6f0:	10 0a 00 52	eor	w16, w16, #0x7
   af6f4:	10 20 d0 1a	lsl	w16, w0, w16
   af6f8:	30 00 10 2a	orr	w16, w1, w16
   af6fc:	20 02 10 2a	orr	w0, w17, w16
   af700:	00 78 1f 53	lsl	w0, w0, #1
   af704:	30 02 10 0b	add	w16, w17, w16
   af708:	10 00 10 4b	sub	w16, w0, w16
   af70c:	10 76 01 51	sub	w16, w16, #0x5d
   af710:	31 05 00 91	add	x17, x9, #0x1
   af714:	20 7e 09 1b	mul	w0, w17, w9
   af718:	01 02 0e 4a	eor	w1, w16, w14
   af71c:	1f 00 00 72	tst	w0, #0x1
   af720:	10 02 81 1a	csel	w16, w16, w1, eq
   af724:	f0 69 29 38	strb	w16, [x15, x9]
   af728:	e9 03 11 aa	mov	x9, x17
   af72c:	3f 5e 00 f1	cmp	x17, #0x17
   af730:	41 fc ff 54	b.ne	0xaf6b8
   af734:	ff 5f 00 39	strb	wzr, [sp, #0x17]
   af738:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af73c:	00 cd 44 f9	ldr	x0, [x8, #0x998] ; Objc class ref: _OBJC_CLASS_$_NSString
   af740:	da 8f 09 94	bl	0x3136a8 ; symbol stub for: _objc_alloc
   af744:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af748:	01 45 41 f9	ldr	x1, [x8, #0x288] ; Objc selector ref: initWithBytes:length:encoding:
   af74c:	e2 03 00 91	mov	x2, sp
   af750:	e3 02 80 52	mov	w3, #0x17
   af754:	84 00 80 52	mov	w4, #0x4
   af758:	0a 90 09 94	bl	0x313780 ; Objc message: +[NSString initWithBytes:length:encoding:]
   af75c:	f3 03 00 aa	mov	x19, x0
   af760:	00 e4 00 4f	movi.16b	v0, #0x0
   af764:	e0 03 00 ad	stp	q0, q0, [sp]
   af768:	e0 03 01 ad	stp	q0, q0, [sp, #0x20]
   af76c:	e0 03 02 ad	stp	q0, q0, [sp, #0x40]
   af770:	e0 03 03 ad	stp	q0, q0, [sp, #0x60]
   af774:	e0 03 04 ad	stp	q0, q0, [sp, #0x80]
   af778:	e0 03 05 ad	stp	q0, q0, [sp, #0xa0]
   af77c:	e0 03 06 ad	stp	q0, q0, [sp, #0xc0]
   af780:	08 16 00 f0	adrp	x8, 707 ; 0x372000
   af784:	08 81 2f 91	add	x8, x8, #0xbe0 ; Objc cfstring ref: @""
   af788:	1f 00 00 f1	cmp	x0, #0x0
   af78c:	00 01 80 9a	csel	x0, x8, x0, eq
   af790:	e0 03 07 ad	stp	q0, q0, [sp, #0xe0]
   af794:	0a 90 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   af798:	f4 03 00 aa	mov	x20, x0
   af79c:	e0 03 13 aa	mov	x0, x19
   af7a0:	04 90 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af7a4:	e8 17 00 b0	adrp	x8, 765 ; 0x3ac000
   af7a8:	00 fd 47 f9	ldr	x0, [x8, #0xff8]
   af7ac:	14 fd 07 f9	str	x20, [x8, #0xff8]
   af7b0:	00 90 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af7b4:	a8 83 5d f8	ldur	x8, [x29, #-0x28]
   af7b8:	09 16 00 b0	adrp	x9, 705 ; 0x370000
   af7bc:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af7c0:	29 01 40 f9	ldr	x9, [x9]
   af7c4:	3f 01 08 eb	cmp	x9, x8
   af7c8:	c1 00 00 54	b.ne	0xaf7e0
   af7cc:	fd 7b 53 a9	ldp	x29, x30, [sp, #0x130]
   af7d0:	f4 4f 52 a9	ldp	x20, x19, [sp, #0x120]
   af7d4:	fc 6f 51 a9	ldp	x28, x27, [sp, #0x110]
   af7d8:	ff 03 05 91	add	sp, sp, #0x140
   af7dc:	c0 03 5f d6	ret
   af7e0:	37 8f 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
   af7e4:	ff 03 05 d1	sub	sp, sp, #0x140
   af7e8:	fc 6f 11 a9	stp	x28, x27, [sp, #0x110]
   af7ec:	f4 4f 12 a9	stp	x20, x19, [sp, #0x120]
   af7f0:	fd 7b 13 a9	stp	x29, x30, [sp, #0x130]
   af7f4:	fd c3 04 91	add	x29, sp, #0x130
   af7f8:	09 00 80 d2	mov	x9, #0x0
   af7fc:	08 16 00 b0	adrp	x8, 705 ; 0x370000
   af800:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af804:	08 01 40 f9	ldr	x8, [x8]
   af808:	a8 83 1d f8	stur	x8, [x29, #-0x28]
   af80c:	68 14 00 f0	adrp	x8, 655 ; 0x33e000
   af810:	08 dd 20 91	add	x8, x8, #0x837
   af814:	8a 0d 80 52	mov	w10, #0x6c
   af818:	4a 5d 00 11	add	w10, w10, #0x17
   af81c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
   af820:	ab 99 99 f2	movk	x11, #0xcccd
   af824:	6c 05 80 52	mov	w12, #0x2b
   af828:	4d 0b 80 12	mov	w13, #-0x5b
   af82c:	4e 15 80 52	mov	w14, #0xaa
   af830:	ef 03 00 91	mov	x15, sp
   af834:	30 7d cb 9b	umulh	x16, x9, x11
   af838:	10 fe 42 d3	lsr	x16, x16, #2
   af83c:	10 0a 10 0b	add	w16, w16, w16, lsl #2
   af840:	31 29 0c 1b	madd	w17, w9, w12, w10
   af844:	00 69 69 38	ldrb	w0, [x8, x9]
~~~

### Original CBBridgedUIAppView::invalidated at 0xaf5e4

~~~asm
   af5e4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5e8:	08 c5 8f b9	ldrsw	x8, [x8, #0xfc4]
   af5ec:	00 68 68 38	ldrb	w0, [x0, x8]
   af5f0:	c0 03 5f d6	ret
   af5f4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5f8:	08 c5 8f b9	ldrsw	x8, [x8, #0xfc4]
   af5fc:	02 68 28 38	strb	w2, [x0, x8]
   af600:	c0 03 5f d6	ret
   af604:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af608:	08 c9 8f b9	ldrsw	x8, [x8, #0xfc8]
   af60c:	00 68 68 38	ldrb	w0, [x0, x8]
   af610:	c0 03 5f d6	ret
   af614:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
   af618:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
   af61c:	fd 43 00 91	add	x29, sp, #0x10
   af620:	f3 03 00 aa	mov	x19, x0
   af624:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af628:	08 cd 8f b9	ldrsw	x8, [x8, #0xfcc]
   af62c:	00 00 08 8b	add	x0, x0, x8
   af630:	01 00 80 d2	mov	x1, #0x0
   af634:	77 90 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   af638:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af63c:	08 d1 8f b9	ldrsw	x8, [x8, #0xfd0]
   af640:	60 02 08 8b	add	x0, x19, x8
   af644:	01 00 80 d2	mov	x1, #0x0
   af648:	72 90 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   af64c:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af650:	08 b9 8f b9	ldrsw	x8, [x8, #0xfb8]
   af654:	60 02 08 8b	add	x0, x19, x8
   af658:	01 00 80 d2	mov	x1, #0x0
   af65c:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
   af660:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
   af664:	6b 90 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   af668:	ff 03 05 d1	sub	sp, sp, #0x140
   af66c:	fc 6f 11 a9	stp	x28, x27, [sp, #0x110]
   af670:	f4 4f 12 a9	stp	x20, x19, [sp, #0x120]
   af674:	fd 7b 13 a9	stp	x29, x30, [sp, #0x130]
   af678:	fd c3 04 91	add	x29, sp, #0x130
   af67c:	09 00 80 d2	mov	x9, #0x0
   af680:	08 16 00 b0	adrp	x8, 705 ; 0x370000
   af684:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af688:	08 01 40 f9	ldr	x8, [x8]
   af68c:	a8 83 1d f8	stur	x8, [x29, #-0x28]
   af690:	68 14 00 f0	adrp	x8, 655 ; 0x33e000
   af694:	08 81 20 91	add	x8, x8, #0x820
   af698:	8a 0d 80 52	mov	w10, #0x6c
   af69c:	4a 5d 00 11	add	w10, w10, #0x17
   af6a0:	eb e7 02 b2	mov	x11, #-0x3333333333333334
   af6a4:	ab 99 99 f2	movk	x11, #0xcccd
   af6a8:	6c 05 80 52	mov	w12, #0x2b
   af6ac:	4d 0b 80 12	mov	w13, #-0x5b
   af6b0:	4e 15 80 52	mov	w14, #0xaa
   af6b4:	ef 03 00 91	mov	x15, sp
   af6b8:	30 7d cb 9b	umulh	x16, x9, x11
   af6bc:	10 fe 42 d3	lsr	x16, x16, #2
   af6c0:	10 0a 10 0b	add	w16, w16, w16, lsl #2
   af6c4:	31 29 0c 1b	madd	w17, w9, w12, w10
   af6c8:	00 69 69 38	ldrb	w0, [x8, x9]
   af6cc:	21 01 0d 4a	eor	w1, w9, w13
   af6d0:	22 00 00 2a	orr	w2, w1, w0
   af6d4:	42 78 1f 53	lsl	w2, w2, #1
   af6d8:	20 00 00 0b	add	w0, w1, w0
   af6dc:	40 00 00 4b	sub	w0, w2, w0
   af6e0:	30 01 10 4b	sub	w16, w9, w16
   af6e4:	01 06 00 11	add	w1, w16, #0x1
   af6e8:	00 1c 00 12	and	w0, w0, #0xff
   af6ec:	01 24 c1 1a	lsr	w1, w0, w1
   af6f0:	10 0a 00 52	eor	w16, w16, #0x7
   af6f4:	10 20 d0 1a	lsl	w16, w0, w16
   af6f8:	30 00 10 2a	orr	w16, w1, w16
   af6fc:	20 02 10 2a	orr	w0, w17, w16
   af700:	00 78 1f 53	lsl	w0, w0, #1
   af704:	30 02 10 0b	add	w16, w17, w16
   af708:	10 00 10 4b	sub	w16, w0, w16
   af70c:	10 76 01 51	sub	w16, w16, #0x5d
   af710:	31 05 00 91	add	x17, x9, #0x1
   af714:	20 7e 09 1b	mul	w0, w17, w9
   af718:	01 02 0e 4a	eor	w1, w16, w14
   af71c:	1f 00 00 72	tst	w0, #0x1
   af720:	10 02 81 1a	csel	w16, w16, w1, eq
   af724:	f0 69 29 38	strb	w16, [x15, x9]
   af728:	e9 03 11 aa	mov	x9, x17
   af72c:	3f 5e 00 f1	cmp	x17, #0x17
   af730:	41 fc ff 54	b.ne	0xaf6b8
   af734:	ff 5f 00 39	strb	wzr, [sp, #0x17]
   af738:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af73c:	00 cd 44 f9	ldr	x0, [x8, #0x998] ; Objc class ref: _OBJC_CLASS_$_NSString
   af740:	da 8f 09 94	bl	0x3136a8 ; symbol stub for: _objc_alloc
   af744:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af748:	01 45 41 f9	ldr	x1, [x8, #0x288] ; Objc selector ref: initWithBytes:length:encoding:
   af74c:	e2 03 00 91	mov	x2, sp
   af750:	e3 02 80 52	mov	w3, #0x17
   af754:	84 00 80 52	mov	w4, #0x4
   af758:	0a 90 09 94	bl	0x313780 ; Objc message: +[NSString initWithBytes:length:encoding:]
   af75c:	f3 03 00 aa	mov	x19, x0
   af760:	00 e4 00 4f	movi.16b	v0, #0x0
   af764:	e0 03 00 ad	stp	q0, q0, [sp]
   af768:	e0 03 01 ad	stp	q0, q0, [sp, #0x20]
   af76c:	e0 03 02 ad	stp	q0, q0, [sp, #0x40]
   af770:	e0 03 03 ad	stp	q0, q0, [sp, #0x60]
   af774:	e0 03 04 ad	stp	q0, q0, [sp, #0x80]
   af778:	e0 03 05 ad	stp	q0, q0, [sp, #0xa0]
   af77c:	e0 03 06 ad	stp	q0, q0, [sp, #0xc0]
   af780:	08 16 00 f0	adrp	x8, 707 ; 0x372000
   af784:	08 81 2f 91	add	x8, x8, #0xbe0 ; Objc cfstring ref: @""
   af788:	1f 00 00 f1	cmp	x0, #0x0
   af78c:	00 01 80 9a	csel	x0, x8, x0, eq
   af790:	e0 03 07 ad	stp	q0, q0, [sp, #0xe0]
   af794:	0a 90 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   af798:	f4 03 00 aa	mov	x20, x0
   af79c:	e0 03 13 aa	mov	x0, x19
   af7a0:	04 90 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af7a4:	e8 17 00 b0	adrp	x8, 765 ; 0x3ac000
   af7a8:	00 fd 47 f9	ldr	x0, [x8, #0xff8]
   af7ac:	14 fd 07 f9	str	x20, [x8, #0xff8]
   af7b0:	00 90 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af7b4:	a8 83 5d f8	ldur	x8, [x29, #-0x28]
   af7b8:	09 16 00 b0	adrp	x9, 705 ; 0x370000
   af7bc:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af7c0:	29 01 40 f9	ldr	x9, [x9]
   af7c4:	3f 01 08 eb	cmp	x9, x8
   af7c8:	c1 00 00 54	b.ne	0xaf7e0
   af7cc:	fd 7b 53 a9	ldp	x29, x30, [sp, #0x130]
   af7d0:	f4 4f 52 a9	ldp	x20, x19, [sp, #0x120]
   af7d4:	fc 6f 51 a9	ldp	x28, x27, [sp, #0x110]
   af7d8:	ff 03 05 91	add	sp, sp, #0x140
   af7dc:	c0 03 5f d6	ret
   af7e0:	37 8f 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
   af7e4:	ff 03 05 d1	sub	sp, sp, #0x140
   af7e8:	fc 6f 11 a9	stp	x28, x27, [sp, #0x110]
   af7ec:	f4 4f 12 a9	stp	x20, x19, [sp, #0x120]
   af7f0:	fd 7b 13 a9	stp	x29, x30, [sp, #0x130]
   af7f4:	fd c3 04 91	add	x29, sp, #0x130
   af7f8:	09 00 80 d2	mov	x9, #0x0
   af7fc:	08 16 00 b0	adrp	x8, 705 ; 0x370000
   af800:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af804:	08 01 40 f9	ldr	x8, [x8]
   af808:	a8 83 1d f8	stur	x8, [x29, #-0x28]
   af80c:	68 14 00 f0	adrp	x8, 655 ; 0x33e000
   af810:	08 dd 20 91	add	x8, x8, #0x837
   af814:	8a 0d 80 52	mov	w10, #0x6c
   af818:	4a 5d 00 11	add	w10, w10, #0x17
   af81c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
   af820:	ab 99 99 f2	movk	x11, #0xcccd
   af824:	6c 05 80 52	mov	w12, #0x2b
   af828:	4d 0b 80 12	mov	w13, #-0x5b
   af82c:	4e 15 80 52	mov	w14, #0xaa
   af830:	ef 03 00 91	mov	x15, sp
   af834:	30 7d cb 9b	umulh	x16, x9, x11
   af838:	10 fe 42 d3	lsr	x16, x16, #2
   af83c:	10 0a 10 0b	add	w16, w16, w16, lsl #2
   af840:	31 29 0c 1b	madd	w17, w9, w12, w10
   af844:	00 69 69 38	ldrb	w0, [x8, x9]
   af848:	21 01 0d 4a	eor	w1, w9, w13
   af84c:	22 00 00 2a	orr	w2, w1, w0
   af850:	42 78 1f 53	lsl	w2, w2, #1
   af854:	20 00 00 0b	add	w0, w1, w0
   af858:	40 00 00 4b	sub	w0, w2, w0
   af85c:	30 01 10 4b	sub	w16, w9, w16
   af860:	01 06 00 11	add	w1, w16, #0x1
   af864:	00 1c 00 12	and	w0, w0, #0xff
   af868:	01 24 c1 1a	lsr	w1, w0, w1
   af86c:	10 0a 00 52	eor	w16, w16, #0x7
   af870:	10 20 d0 1a	lsl	w16, w0, w16
   af874:	30 00 10 2a	orr	w16, w1, w16
   af878:	20 02 10 2a	orr	w0, w17, w16
   af87c:	00 78 1f 53	lsl	w0, w0, #1
   af880:	30 02 10 0b	add	w16, w17, w16
   af884:	10 00 10 4b	sub	w16, w0, w16
   af888:	10 76 01 51	sub	w16, w16, #0x5d
   af88c:	31 05 00 91	add	x17, x9, #0x1
   af890:	20 7e 09 1b	mul	w0, w17, w9
   af894:	01 02 0e 4a	eor	w1, w16, w14
   af898:	1f 00 00 72	tst	w0, #0x1
   af89c:	10 02 81 1a	csel	w16, w16, w1, eq
   af8a0:	f0 69 29 38	strb	w16, [x15, x9]
   af8a4:	e9 03 11 aa	mov	x9, x17
   af8a8:	3f 9a 00 f1	cmp	x17, #0x26
   af8ac:	41 fc ff 54	b.ne	0xaf834
   af8b0:	ff 9b 00 39	strb	wzr, [sp, #0x26]
   af8b4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af8b8:	00 cd 44 f9	ldr	x0, [x8, #0x998] ; Objc class ref: _OBJC_CLASS_$_NSString
   af8bc:	7b 8f 09 94	bl	0x3136a8 ; symbol stub for: _objc_alloc
   af8c0:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af8c4:	01 45 41 f9	ldr	x1, [x8, #0x288] ; Objc selector ref: initWithBytes:length:encoding:
   af8c8:	e2 03 00 91	mov	x2, sp
   af8cc:	c3 04 80 52	mov	w3, #0x26
   af8d0:	84 00 80 52	mov	w4, #0x4
   af8d4:	ab 8f 09 94	bl	0x313780 ; Objc message: +[NSString initWithBytes:length:encoding:]
   af8d8:	f3 03 00 aa	mov	x19, x0
   af8dc:	00 e4 00 4f	movi.16b	v0, #0x0
   af8e0:	e0 03 00 ad	stp	q0, q0, [sp]
   af8e4:	e0 03 01 ad	stp	q0, q0, [sp, #0x20]
   af8e8:	e0 03 02 ad	stp	q0, q0, [sp, #0x40]
   af8ec:	e0 03 03 ad	stp	q0, q0, [sp, #0x60]
   af8f0:	e0 03 04 ad	stp	q0, q0, [sp, #0x80]
   af8f4:	e0 03 05 ad	stp	q0, q0, [sp, #0xa0]
   af8f8:	e0 03 06 ad	stp	q0, q0, [sp, #0xc0]
   af8fc:	08 16 00 f0	adrp	x8, 707 ; 0x372000
   af900:	08 81 2f 91	add	x8, x8, #0xbe0 ; Objc cfstring ref: @""
   af904:	1f 00 00 f1	cmp	x0, #0x0
   af908:	00 01 80 9a	csel	x0, x8, x0, eq
   af90c:	e0 03 07 ad	stp	q0, q0, [sp, #0xe0]
   af910:	ab 8f 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   af914:	f4 03 00 aa	mov	x20, x0
   af918:	e0 03 13 aa	mov	x0, x19
   af91c:	a5 8f 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af920:	e8 17 00 d0	adrp	x8, 766 ; 0x3ad000
   af924:	00 05 40 f9	ldr	x0, [x8, #0x8]
   af928:	14 05 00 f9	str	x20, [x8, #0x8]
   af92c:	a1 8f 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af930:	a8 83 5d f8	ldur	x8, [x29, #-0x28]
   af934:	09 16 00 b0	adrp	x9, 705 ; 0x370000
   af938:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af93c:	29 01 40 f9	ldr	x9, [x9]
   af940:	3f 01 08 eb	cmp	x9, x8
   af944:	c1 00 00 54	b.ne	0xaf95c
   af948:	fd 7b 53 a9	ldp	x29, x30, [sp, #0x130]
   af94c:	f4 4f 52 a9	ldp	x20, x19, [sp, #0x120]
   af950:	fc 6f 51 a9	ldp	x28, x27, [sp, #0x110]
~~~

### Original CBBridgedUIAppView::setInvalidated: at 0xaf5f4

~~~asm
   af5f4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af5f8:	08 c5 8f b9	ldrsw	x8, [x8, #0xfc4]
   af5fc:	02 68 28 38	strb	w2, [x0, x8]
   af600:	c0 03 5f d6	ret
   af604:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af608:	08 c9 8f b9	ldrsw	x8, [x8, #0xfc8]
   af60c:	00 68 68 38	ldrb	w0, [x0, x8]
   af610:	c0 03 5f d6	ret
   af614:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
   af618:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
   af61c:	fd 43 00 91	add	x29, sp, #0x10
   af620:	f3 03 00 aa	mov	x19, x0
   af624:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af628:	08 cd 8f b9	ldrsw	x8, [x8, #0xfcc]
   af62c:	00 00 08 8b	add	x0, x0, x8
   af630:	01 00 80 d2	mov	x1, #0x0
   af634:	77 90 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   af638:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af63c:	08 d1 8f b9	ldrsw	x8, [x8, #0xfd0]
   af640:	60 02 08 8b	add	x0, x19, x8
   af644:	01 00 80 d2	mov	x1, #0x0
   af648:	72 90 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   af64c:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af650:	08 b9 8f b9	ldrsw	x8, [x8, #0xfb8]
   af654:	60 02 08 8b	add	x0, x19, x8
   af658:	01 00 80 d2	mov	x1, #0x0
   af65c:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
   af660:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
   af664:	6b 90 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   af668:	ff 03 05 d1	sub	sp, sp, #0x140
   af66c:	fc 6f 11 a9	stp	x28, x27, [sp, #0x110]
   af670:	f4 4f 12 a9	stp	x20, x19, [sp, #0x120]
   af674:	fd 7b 13 a9	stp	x29, x30, [sp, #0x130]
   af678:	fd c3 04 91	add	x29, sp, #0x130
   af67c:	09 00 80 d2	mov	x9, #0x0
   af680:	08 16 00 b0	adrp	x8, 705 ; 0x370000
   af684:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af688:	08 01 40 f9	ldr	x8, [x8]
   af68c:	a8 83 1d f8	stur	x8, [x29, #-0x28]
   af690:	68 14 00 f0	adrp	x8, 655 ; 0x33e000
   af694:	08 81 20 91	add	x8, x8, #0x820
   af698:	8a 0d 80 52	mov	w10, #0x6c
   af69c:	4a 5d 00 11	add	w10, w10, #0x17
   af6a0:	eb e7 02 b2	mov	x11, #-0x3333333333333334
   af6a4:	ab 99 99 f2	movk	x11, #0xcccd
   af6a8:	6c 05 80 52	mov	w12, #0x2b
   af6ac:	4d 0b 80 12	mov	w13, #-0x5b
   af6b0:	4e 15 80 52	mov	w14, #0xaa
   af6b4:	ef 03 00 91	mov	x15, sp
   af6b8:	30 7d cb 9b	umulh	x16, x9, x11
   af6bc:	10 fe 42 d3	lsr	x16, x16, #2
   af6c0:	10 0a 10 0b	add	w16, w16, w16, lsl #2
   af6c4:	31 29 0c 1b	madd	w17, w9, w12, w10
   af6c8:	00 69 69 38	ldrb	w0, [x8, x9]
   af6cc:	21 01 0d 4a	eor	w1, w9, w13
   af6d0:	22 00 00 2a	orr	w2, w1, w0
   af6d4:	42 78 1f 53	lsl	w2, w2, #1
   af6d8:	20 00 00 0b	add	w0, w1, w0
   af6dc:	40 00 00 4b	sub	w0, w2, w0
   af6e0:	30 01 10 4b	sub	w16, w9, w16
   af6e4:	01 06 00 11	add	w1, w16, #0x1
   af6e8:	00 1c 00 12	and	w0, w0, #0xff
   af6ec:	01 24 c1 1a	lsr	w1, w0, w1
   af6f0:	10 0a 00 52	eor	w16, w16, #0x7
   af6f4:	10 20 d0 1a	lsl	w16, w0, w16
   af6f8:	30 00 10 2a	orr	w16, w1, w16
   af6fc:	20 02 10 2a	orr	w0, w17, w16
   af700:	00 78 1f 53	lsl	w0, w0, #1
   af704:	30 02 10 0b	add	w16, w17, w16
   af708:	10 00 10 4b	sub	w16, w0, w16
   af70c:	10 76 01 51	sub	w16, w16, #0x5d
   af710:	31 05 00 91	add	x17, x9, #0x1
   af714:	20 7e 09 1b	mul	w0, w17, w9
   af718:	01 02 0e 4a	eor	w1, w16, w14
   af71c:	1f 00 00 72	tst	w0, #0x1
   af720:	10 02 81 1a	csel	w16, w16, w1, eq
   af724:	f0 69 29 38	strb	w16, [x15, x9]
   af728:	e9 03 11 aa	mov	x9, x17
   af72c:	3f 5e 00 f1	cmp	x17, #0x17
   af730:	41 fc ff 54	b.ne	0xaf6b8
   af734:	ff 5f 00 39	strb	wzr, [sp, #0x17]
   af738:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af73c:	00 cd 44 f9	ldr	x0, [x8, #0x998] ; Objc class ref: _OBJC_CLASS_$_NSString
   af740:	da 8f 09 94	bl	0x3136a8 ; symbol stub for: _objc_alloc
   af744:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af748:	01 45 41 f9	ldr	x1, [x8, #0x288] ; Objc selector ref: initWithBytes:length:encoding:
   af74c:	e2 03 00 91	mov	x2, sp
   af750:	e3 02 80 52	mov	w3, #0x17
   af754:	84 00 80 52	mov	w4, #0x4
   af758:	0a 90 09 94	bl	0x313780 ; Objc message: +[NSString initWithBytes:length:encoding:]
   af75c:	f3 03 00 aa	mov	x19, x0
   af760:	00 e4 00 4f	movi.16b	v0, #0x0
   af764:	e0 03 00 ad	stp	q0, q0, [sp]
   af768:	e0 03 01 ad	stp	q0, q0, [sp, #0x20]
   af76c:	e0 03 02 ad	stp	q0, q0, [sp, #0x40]
   af770:	e0 03 03 ad	stp	q0, q0, [sp, #0x60]
   af774:	e0 03 04 ad	stp	q0, q0, [sp, #0x80]
   af778:	e0 03 05 ad	stp	q0, q0, [sp, #0xa0]
   af77c:	e0 03 06 ad	stp	q0, q0, [sp, #0xc0]
   af780:	08 16 00 f0	adrp	x8, 707 ; 0x372000
   af784:	08 81 2f 91	add	x8, x8, #0xbe0 ; Objc cfstring ref: @""
   af788:	1f 00 00 f1	cmp	x0, #0x0
   af78c:	00 01 80 9a	csel	x0, x8, x0, eq
   af790:	e0 03 07 ad	stp	q0, q0, [sp, #0xe0]
   af794:	0a 90 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   af798:	f4 03 00 aa	mov	x20, x0
   af79c:	e0 03 13 aa	mov	x0, x19
   af7a0:	04 90 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af7a4:	e8 17 00 b0	adrp	x8, 765 ; 0x3ac000
   af7a8:	00 fd 47 f9	ldr	x0, [x8, #0xff8]
   af7ac:	14 fd 07 f9	str	x20, [x8, #0xff8]
   af7b0:	00 90 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af7b4:	a8 83 5d f8	ldur	x8, [x29, #-0x28]
   af7b8:	09 16 00 b0	adrp	x9, 705 ; 0x370000
   af7bc:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af7c0:	29 01 40 f9	ldr	x9, [x9]
   af7c4:	3f 01 08 eb	cmp	x9, x8
   af7c8:	c1 00 00 54	b.ne	0xaf7e0
   af7cc:	fd 7b 53 a9	ldp	x29, x30, [sp, #0x130]
   af7d0:	f4 4f 52 a9	ldp	x20, x19, [sp, #0x120]
   af7d4:	fc 6f 51 a9	ldp	x28, x27, [sp, #0x110]
   af7d8:	ff 03 05 91	add	sp, sp, #0x140
   af7dc:	c0 03 5f d6	ret
   af7e0:	37 8f 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
   af7e4:	ff 03 05 d1	sub	sp, sp, #0x140
   af7e8:	fc 6f 11 a9	stp	x28, x27, [sp, #0x110]
   af7ec:	f4 4f 12 a9	stp	x20, x19, [sp, #0x120]
   af7f0:	fd 7b 13 a9	stp	x29, x30, [sp, #0x130]
   af7f4:	fd c3 04 91	add	x29, sp, #0x130
   af7f8:	09 00 80 d2	mov	x9, #0x0
   af7fc:	08 16 00 b0	adrp	x8, 705 ; 0x370000
   af800:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af804:	08 01 40 f9	ldr	x8, [x8]
   af808:	a8 83 1d f8	stur	x8, [x29, #-0x28]
   af80c:	68 14 00 f0	adrp	x8, 655 ; 0x33e000
   af810:	08 dd 20 91	add	x8, x8, #0x837
   af814:	8a 0d 80 52	mov	w10, #0x6c
   af818:	4a 5d 00 11	add	w10, w10, #0x17
   af81c:	eb e7 02 b2	mov	x11, #-0x3333333333333334
   af820:	ab 99 99 f2	movk	x11, #0xcccd
   af824:	6c 05 80 52	mov	w12, #0x2b
   af828:	4d 0b 80 12	mov	w13, #-0x5b
   af82c:	4e 15 80 52	mov	w14, #0xaa
   af830:	ef 03 00 91	mov	x15, sp
   af834:	30 7d cb 9b	umulh	x16, x9, x11
   af838:	10 fe 42 d3	lsr	x16, x16, #2
   af83c:	10 0a 10 0b	add	w16, w16, w16, lsl #2
   af840:	31 29 0c 1b	madd	w17, w9, w12, w10
   af844:	00 69 69 38	ldrb	w0, [x8, x9]
   af848:	21 01 0d 4a	eor	w1, w9, w13
   af84c:	22 00 00 2a	orr	w2, w1, w0
   af850:	42 78 1f 53	lsl	w2, w2, #1
   af854:	20 00 00 0b	add	w0, w1, w0
   af858:	40 00 00 4b	sub	w0, w2, w0
   af85c:	30 01 10 4b	sub	w16, w9, w16
   af860:	01 06 00 11	add	w1, w16, #0x1
   af864:	00 1c 00 12	and	w0, w0, #0xff
   af868:	01 24 c1 1a	lsr	w1, w0, w1
   af86c:	10 0a 00 52	eor	w16, w16, #0x7
   af870:	10 20 d0 1a	lsl	w16, w0, w16
   af874:	30 00 10 2a	orr	w16, w1, w16
   af878:	20 02 10 2a	orr	w0, w17, w16
   af87c:	00 78 1f 53	lsl	w0, w0, #1
   af880:	30 02 10 0b	add	w16, w17, w16
   af884:	10 00 10 4b	sub	w16, w0, w16
   af888:	10 76 01 51	sub	w16, w16, #0x5d
   af88c:	31 05 00 91	add	x17, x9, #0x1
   af890:	20 7e 09 1b	mul	w0, w17, w9
   af894:	01 02 0e 4a	eor	w1, w16, w14
   af898:	1f 00 00 72	tst	w0, #0x1
   af89c:	10 02 81 1a	csel	w16, w16, w1, eq
   af8a0:	f0 69 29 38	strb	w16, [x15, x9]
   af8a4:	e9 03 11 aa	mov	x9, x17
   af8a8:	3f 9a 00 f1	cmp	x17, #0x26
   af8ac:	41 fc ff 54	b.ne	0xaf834
   af8b0:	ff 9b 00 39	strb	wzr, [sp, #0x26]
   af8b4:	c8 17 00 f0	adrp	x8, 763 ; 0x3aa000
   af8b8:	00 cd 44 f9	ldr	x0, [x8, #0x998] ; Objc class ref: _OBJC_CLASS_$_NSString
   af8bc:	7b 8f 09 94	bl	0x3136a8 ; symbol stub for: _objc_alloc
   af8c0:	c8 17 00 b0	adrp	x8, 761 ; 0x3a8000
   af8c4:	01 45 41 f9	ldr	x1, [x8, #0x288] ; Objc selector ref: initWithBytes:length:encoding:
   af8c8:	e2 03 00 91	mov	x2, sp
   af8cc:	c3 04 80 52	mov	w3, #0x26
   af8d0:	84 00 80 52	mov	w4, #0x4
   af8d4:	ab 8f 09 94	bl	0x313780 ; Objc message: +[NSString initWithBytes:length:encoding:]
   af8d8:	f3 03 00 aa	mov	x19, x0
   af8dc:	00 e4 00 4f	movi.16b	v0, #0x0
   af8e0:	e0 03 00 ad	stp	q0, q0, [sp]
   af8e4:	e0 03 01 ad	stp	q0, q0, [sp, #0x20]
   af8e8:	e0 03 02 ad	stp	q0, q0, [sp, #0x40]
   af8ec:	e0 03 03 ad	stp	q0, q0, [sp, #0x60]
   af8f0:	e0 03 04 ad	stp	q0, q0, [sp, #0x80]
   af8f4:	e0 03 05 ad	stp	q0, q0, [sp, #0xa0]
   af8f8:	e0 03 06 ad	stp	q0, q0, [sp, #0xc0]
   af8fc:	08 16 00 f0	adrp	x8, 707 ; 0x372000
   af900:	08 81 2f 91	add	x8, x8, #0xbe0 ; Objc cfstring ref: @""
   af904:	1f 00 00 f1	cmp	x0, #0x0
   af908:	00 01 80 9a	csel	x0, x8, x0, eq
   af90c:	e0 03 07 ad	stp	q0, q0, [sp, #0xe0]
   af910:	ab 8f 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   af914:	f4 03 00 aa	mov	x20, x0
   af918:	e0 03 13 aa	mov	x0, x19
   af91c:	a5 8f 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af920:	e8 17 00 d0	adrp	x8, 766 ; 0x3ad000
   af924:	00 05 40 f9	ldr	x0, [x8, #0x8]
   af928:	14 05 00 f9	str	x20, [x8, #0x8]
   af92c:	a1 8f 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   af930:	a8 83 5d f8	ldur	x8, [x29, #-0x28]
   af934:	09 16 00 b0	adrp	x9, 705 ; 0x370000
   af938:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   af93c:	29 01 40 f9	ldr	x9, [x9]
   af940:	3f 01 08 eb	cmp	x9, x8
   af944:	c1 00 00 54	b.ne	0xaf95c
   af948:	fd 7b 53 a9	ldp	x29, x30, [sp, #0x130]
   af94c:	f4 4f 52 a9	ldp	x20, x19, [sp, #0x120]
   af950:	fc 6f 51 a9	ldp	x28, x27, [sp, #0x110]
   af954:	ff 03 05 91	add	sp, sp, #0x140
   af958:	c0 03 5f d6	ret
   af95c:	d8 8e 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
   af960:	ff 83 01 d1	sub	sp, sp, #0x60
~~~

### Original CBWindow::hide: at 0xb29b0

~~~asm
   b29b0:	ff 43 02 d1	sub	sp, sp, #0x90
   b29b4:	f6 57 06 a9	stp	x22, x21, [sp, #0x60]
   b29b8:	f4 4f 07 a9	stp	x20, x19, [sp, #0x70]
   b29bc:	fd 7b 08 a9	stp	x29, x30, [sp, #0x80]
   b29c0:	fd 03 02 91	add	x29, sp, #0x80
   b29c4:	f3 03 00 aa	mov	x19, x0
   b29c8:	e8 15 00 d0	adrp	x8, 702 ; 0x370000
   b29cc:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   b29d0:	08 01 40 f9	ldr	x8, [x8]
   b29d4:	a8 83 1d f8	stur	x8, [x29, #-0x28]
   b29d8:	e0 03 02 aa	mov	x0, x2
   b29dc:	78 83 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   b29e0:	f4 03 00 aa	mov	x20, x0
   b29e4:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b29e8:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b29ec:	01 e1 43 f9	ldr	x1, [x8, #0x7c0] ; Objc selector ref: layer
   b29f0:	64 83 09 94	bl	0x313780 ; Objc message: -[x0 layer]
   b29f4:	fd 03 1d aa	mov	x29, x29
   b29f8:	7a 83 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b29fc:	f5 03 00 aa	mov	x21, x0
   b2a00:	a8 17 00 f0	adrp	x8, 759 ; 0x3a9000
   b2a04:	01 51 40 f9	ldr	x1, [x8, #0xa0] ; Objc selector ref: removeAllAnimations
   b2a08:	5e 83 09 94	bl	0x313780 ; Objc message: -[x0 removeAllAnimations]
   b2a0c:	e0 03 15 aa	mov	x0, x21
   b2a10:	68 83 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2a14:	e8 15 00 d0	adrp	x8, 702 ; 0x370000
   b2a18:	08 a1 40 f9	ldr	x8, [x8, #0x140] ; literal pool symbol address: __NSConcreteStackBlock
   b2a1c:	c9 17 00 90	adrp	x9, 760 ; 0x3aa000
   b2a20:	35 71 45 f9	ldr	x21, [x9, #0xae0] ; Objc class ref: _OBJC_CLASS_$_UIView
   b2a24:	f4 a3 02 a9	stp	x20, x8, [sp, #0x28]
   b2a28:	49 14 00 d0	adrp	x9, 650 ; 0x33c000
   b2a2c:	20 d9 44 fd	ldr	d0, [x9, #0x9b0]
   b2a30:	69 05 00 10	adr	x9, #172
   b2a34:	1f 20 03 d5	nop
   b2a38:	e0 1f 00 fd	str	d0, [sp, #0x38]
   b2a3c:	ea 15 00 d0	adrp	x10, 702 ; 0x370000
   b2a40:	4a c1 2f 91	add	x10, x10, #0xbf0
   b2a44:	e9 2b 04 a9	stp	x9, x10, [sp, #0x40]
   b2a48:	f3 2b 00 f9	str	x19, [sp, #0x50]
   b2a4c:	e8 03 00 f9	str	x8, [sp]
   b2a50:	e0 07 00 fd	str	d0, [sp, #0x8]
   b2a54:	08 05 00 10	adr	x8, #160
   b2a58:	1f 20 03 d5	nop
   b2a5c:	e9 15 00 d0	adrp	x9, 702 ; 0x370000
   b2a60:	29 81 39 91	add	x9, x9, #0xe60
   b2a64:	e8 27 01 a9	stp	x8, x9, [sp, #0x10]
   b2a68:	f3 13 00 f9	str	x19, [sp, #0x20]
   b2a6c:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2a70:	13 4d 44 f9	ldr	x19, [x8, #0x898] ; Objc selector ref: animateWithDuration:animations:completion:
   b2a74:	e0 03 14 aa	mov	x0, x20
   b2a78:	51 83 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   b2a7c:	f4 03 00 aa	mov	x20, x0
   b2a80:	68 14 00 90	adrp	x8, 652 ; 0x33e000
   b2a84:	00 e1 42 fd	ldr	d0, [x8, #0x5c0]
   b2a88:	e2 c3 00 91	add	x2, sp, #0x30
   b2a8c:	e3 03 00 91	mov	x3, sp
   b2a90:	e0 03 15 aa	mov	x0, x21
   b2a94:	e1 03 13 aa	mov	x1, x19
   b2a98:	3a 83 09 94	bl	0x313780 ; Objc message: +[UIView animateWithDuration:animations:completion:]
   b2a9c:	e0 17 40 f9	ldr	x0, [sp, #0x28]
   b2aa0:	44 83 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2aa4:	e0 03 14 aa	mov	x0, x20
   b2aa8:	42 83 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2aac:	a8 83 5d f8	ldur	x8, [x29, #-0x28]
   b2ab0:	e9 15 00 d0	adrp	x9, 702 ; 0x370000
   b2ab4:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   b2ab8:	29 01 40 f9	ldr	x9, [x9]
   b2abc:	3f 01 08 eb	cmp	x9, x8
   b2ac0:	c1 00 00 54	b.ne	0xb2ad8
   b2ac4:	fd 7b 48 a9	ldp	x29, x30, [sp, #0x80]
   b2ac8:	f4 4f 47 a9	ldp	x20, x19, [sp, #0x70]
   b2acc:	f6 57 46 a9	ldp	x22, x21, [sp, #0x60]
   b2ad0:	ff 43 02 91	add	sp, sp, #0x90
   b2ad4:	c0 03 5f d6	ret
   b2ad8:	79 82 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
   b2adc:	08 10 40 f9	ldr	x8, [x0, #0x20]
   b2ae0:	00 11 40 f9	ldr	x0, [x8, #0x20]
   b2ae4:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2ae8:	01 1d 45 f9	ldr	x1, [x8, #0xa38] ; Objc selector ref: setAlpha:
   b2aec:	e0 03 67 9e	fmov	d0, xzr
   b2af0:	24 83 09 14	b	0x313780 ; Objc message: -[x0 setAlpha:]
   b2af4:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
   b2af8:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
   b2afc:	fd 43 00 91	add	x29, sp, #0x10
   b2b00:	f3 03 00 aa	mov	x19, x0
   b2b04:	c1 04 00 34	cbz	w1, 0xb2b9c
   b2b08:	68 12 40 f9	ldr	x8, [x19, #0x20]
   b2b0c:	00 11 40 f9	ldr	x0, [x8, #0x20]
   b2b10:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2b14:	01 a9 44 f9	ldr	x1, [x8, #0x950] ; Objc selector ref: setHidden:
   b2b18:	22 00 80 52	mov	w2, #0x1
   b2b1c:	19 83 09 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
   b2b20:	68 12 40 f9	ldr	x8, [x19, #0x20]
   b2b24:	1f 61 00 39	strb	wzr, [x8, #0x18]
   b2b28:	68 12 40 f9	ldr	x8, [x19, #0x20]
   b2b2c:	00 11 40 f9	ldr	x0, [x8, #0x20]
   b2b30:	a8 17 00 f0	adrp	x8, 759 ; 0x3a9000
   b2b34:	14 61 40 f9	ldr	x20, [x8, #0xc0] ; Objc selector ref: resignKeyWindow
   b2b38:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2b3c:	01 ad 41 f9	ldr	x1, [x8, #0x358] ; Objc selector ref: respondsToSelector:
   b2b40:	e2 03 14 aa	mov	x2, x20
   b2b44:	0f 83 09 94	bl	0x313780 ; Objc message: -[x0 respondsToSelector:]
   b2b48:	a0 00 00 34	cbz	w0, 0xb2b5c
   b2b4c:	68 12 40 f9	ldr	x8, [x19, #0x20]
   b2b50:	00 11 40 f9	ldr	x0, [x8, #0x20]
   b2b54:	e1 03 14 aa	mov	x1, x20
   b2b58:	0a 83 09 94	bl	0x313780 ; Objc message: -[x0 respondsToSelector:]
   b2b5c:	68 12 40 f9	ldr	x8, [x19, #0x20]
   b2b60:	00 21 40 f9	ldr	x0, [x8, #0x40]
   b2b64:	c0 01 00 b4	cbz	x0, 0xb2b9c
   b2b68:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2b6c:	01 55 44 f9	ldr	x1, [x8, #0x8a8] ; Objc selector ref: superview
   b2b70:	04 83 09 94	bl	0x313780 ; Objc message: -[x0 superview]
   b2b74:	fd 03 1d aa	mov	x29, x29
   b2b78:	1a 83 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2b7c:	f4 03 00 aa	mov	x20, x0
   b2b80:	0c 83 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2b84:	d4 00 00 b4	cbz	x20, 0xb2b9c
   b2b88:	68 12 40 f9	ldr	x8, [x19, #0x20]
   b2b8c:	00 21 40 f9	ldr	x0, [x8, #0x40]
   b2b90:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2b94:	01 35 45 f9	ldr	x1, [x8, #0xa68] ; Objc selector ref: dismissOverlay
   b2b98:	fa 82 09 94	bl	0x313780 ; Objc message: -[x0 dismissOverlay]
   b2b9c:	60 16 40 f9	ldr	x0, [x19, #0x28]
   b2ba0:	a0 00 00 b4	cbz	x0, 0xb2bb4
   b2ba4:	01 08 40 f9	ldr	x1, [x0, #0x10]
   b2ba8:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
   b2bac:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
   b2bb0:	20 00 1f d6	br	x1
   b2bb4:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
   b2bb8:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
   b2bbc:	c0 03 5f d6	ret
   b2bc0:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
   b2bc4:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
   b2bc8:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
   b2bcc:	fd 83 00 91	add	x29, sp, #0x20
   b2bd0:	08 10 40 f9	ldr	x8, [x0, #0x20]
   b2bd4:	48 03 00 b4	cbz	x8, 0xb2c3c
   b2bd8:	f5 03 00 aa	mov	x21, x0
   b2bdc:	d6 17 00 90	adrp	x22, 760 ; 0x3aa000
   b2be0:	c0 9e 45 f9	ldr	x0, [x22, #0xb38] ; Objc class ref: CBWindow
   b2be4:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2be8:	01 d5 47 f9	ldr	x1, [x8, #0xfa8] ; Objc selector ref: carPlayWindowScene
   b2bec:	e5 82 09 94	bl	0x313780 ; Objc message: +[CBWindow carPlayWindowScene]
   b2bf0:	fd 03 1d aa	mov	x29, x29
   b2bf4:	fb 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2bf8:	f3 03 00 aa	mov	x19, x0
   b2bfc:	40 02 00 b4	cbz	x0, 0xb2c44
   b2c00:	a0 12 40 f9	ldr	x0, [x21, #0x20]
   b2c04:	a8 17 00 f0	adrp	x8, 759 ; 0x3a9000
   b2c08:	14 65 40 f9	ldr	x20, [x8, #0xc8] ; Objc selector ref: windowScene
   b2c0c:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2c10:	01 ad 41 f9	ldr	x1, [x8, #0x358] ; Objc selector ref: respondsToSelector:
   b2c14:	e2 03 14 aa	mov	x2, x20
   b2c18:	da 82 09 94	bl	0x313780 ; Objc message: -[x0 respondsToSelector:]
   b2c1c:	60 04 00 34	cbz	w0, 0xb2ca8
   b2c20:	a0 12 40 f9	ldr	x0, [x21, #0x20]
   b2c24:	e1 03 14 aa	mov	x1, x20
   b2c28:	d6 82 09 94	bl	0x313780 ; Objc message: -[x0 respondsToSelector:]
   b2c2c:	fd 03 1d aa	mov	x29, x29
   b2c30:	ec 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2c34:	f4 03 00 aa	mov	x20, x0
   b2c38:	1a 00 00 14	b	0xb2ca0
   b2c3c:	15 00 80 52	mov	w21, #0x0
   b2c40:	30 00 00 14	b	0xb2d00
   b2c44:	c0 9e 45 f9	ldr	x0, [x22, #0xb38]
   b2c48:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2c4c:	01 a5 47 f9	ldr	x1, [x8, #0xf48] ; Objc selector ref: carPlayUIScreen
   b2c50:	cc 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayUIScreen]
   b2c54:	fd 03 1d aa	mov	x29, x29
   b2c58:	e2 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2c5c:	f4 03 00 aa	mov	x20, x0
   b2c60:	80 02 00 b4	cbz	x0, 0xb2cb0
   b2c64:	a0 12 40 f9	ldr	x0, [x21, #0x20]
   b2c68:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2c6c:	16 ad 47 f9	ldr	x22, [x8, #0xf58] ; Objc selector ref: screen
   b2c70:	1f 20 03 d5	nop
   b2c74:	01 ad 41 f9	ldr	x1, [x8, #0x358]
   b2c78:	e2 03 16 aa	mov	x2, x22
   b2c7c:	c1 82 09 94	bl	0x313780 ; Objc message: -[x0 screen]
   b2c80:	00 01 00 34	cbz	w0, 0xb2ca0
   b2c84:	a0 12 40 f9	ldr	x0, [x21, #0x20]
   b2c88:	e1 03 16 aa	mov	x1, x22
   b2c8c:	bd 82 09 94	bl	0x313780 ; Objc message: -[x0 screen]
   b2c90:	fd 03 1d aa	mov	x29, x29
   b2c94:	d3 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2c98:	35 00 80 52	mov	w21, #0x1
   b2c9c:	14 00 00 14	b	0xb2cec
   b2ca0:	35 00 80 52	mov	w21, #0x1
   b2ca4:	13 00 00 14	b	0xb2cf0
   b2ca8:	35 00 80 52	mov	w21, #0x1
   b2cac:	13 00 00 14	b	0xb2cf8
   b2cb0:	c0 9e 45 f9	ldr	x0, [x22, #0xb38]
   b2cb4:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2cb8:	01 cd 47 f9	ldr	x1, [x8, #0xf98] ; Objc selector ref: carPlayCADisplay
   b2cbc:	b1 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayCADisplay]
   b2cc0:	fd 03 1d aa	mov	x29, x29
   b2cc4:	c7 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2cc8:	00 01 00 b4	cbz	x0, 0xb2ce8
   b2ccc:	a8 06 40 f9	ldr	x8, [x21, #0x8]
   b2cd0:	1f 01 00 f1	cmp	x8, #0x0
   b2cd4:	e9 17 9f 1a	cset	w9, eq
   b2cd8:	1f 01 00 eb	cmp	x8, x0
   b2cdc:	e8 17 9f 1a	cset	w8, eq
   b2ce0:	35 01 08 2a	orr	w21, w9, w8
   b2ce4:	02 00 00 14	b	0xb2cec
   b2ce8:	15 00 80 52	mov	w21, #0x0
   b2cec:	b1 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2cf0:	e0 03 14 aa	mov	x0, x20
   b2cf4:	af 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2cf8:	e0 03 13 aa	mov	x0, x19
   b2cfc:	ad 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2d00:	e0 03 15 aa	mov	x0, x21
   b2d04:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
   b2d08:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
   b2d0c:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
   b2d10:	c0 03 5f d6	ret
   b2d14:	fc 6f ba a9	stp	x28, x27, [sp, #-0x60]!
   b2d18:	fa 67 01 a9	stp	x26, x25, [sp, #0x10]
   b2d1c:	f8 5f 02 a9	stp	x24, x23, [sp, #0x20]
~~~

### Original CBWindow::destroyWindows at 0xb2d14

~~~asm
   b2d14:	fc 6f ba a9	stp	x28, x27, [sp, #-0x60]!
   b2d18:	fa 67 01 a9	stp	x26, x25, [sp, #0x10]
   b2d1c:	f8 5f 02 a9	stp	x24, x23, [sp, #0x20]
   b2d20:	f6 57 03 a9	stp	x22, x21, [sp, #0x30]
   b2d24:	f4 4f 04 a9	stp	x20, x19, [sp, #0x40]
   b2d28:	fd 7b 05 a9	stp	x29, x30, [sp, #0x50]
   b2d2c:	fd 43 01 91	add	x29, sp, #0x50
   b2d30:	ff 43 09 d1	sub	sp, sp, #0x250
   b2d34:	f3 03 00 aa	mov	x19, x0
   b2d38:	e8 15 00 d0	adrp	x8, 702 ; 0x370000
   b2d3c:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   b2d40:	08 01 40 f9	ldr	x8, [x8]
   b2d44:	a8 03 1a f8	stur	x8, [x29, #-0x60]
   b2d48:	1f 60 00 39	strb	wzr, [x0, #0x18]
   b2d4c:	00 20 40 f9	ldr	x0, [x0, #0x40]
   b2d50:	b9 17 00 d0	adrp	x25, 758 ; 0x3a8000
   b2d54:	c0 00 00 b4	cbz	x0, 0xb2d6c
   b2d58:	21 2b 45 f9	ldr	x1, [x25, #0xa50]
   b2d5c:	89 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayCADisplay]
   b2d60:	60 22 40 f9	ldr	x0, [x19, #0x40]
   b2d64:	7f 22 00 f9	str	xzr, [x19, #0x40]
   b2d68:	92 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2d6c:	60 1e 40 f9	ldr	x0, [x19, #0x38]
   b2d70:	c0 00 00 b4	cbz	x0, 0xb2d88
   b2d74:	21 2b 45 f9	ldr	x1, [x25, #0xa50]
   b2d78:	82 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayCADisplay]
   b2d7c:	60 1e 40 f9	ldr	x0, [x19, #0x38]
   b2d80:	7f 1e 00 f9	str	xzr, [x19, #0x38]
   b2d84:	8b 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2d88:	60 26 40 f9	ldr	x0, [x19, #0x48]
   b2d8c:	c0 00 00 b4	cbz	x0, 0xb2da4
   b2d90:	21 2b 45 f9	ldr	x1, [x25, #0xa50]
   b2d94:	7b 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayCADisplay]
   b2d98:	60 26 40 f9	ldr	x0, [x19, #0x48]
   b2d9c:	7f 26 00 f9	str	xzr, [x19, #0x48]
   b2da0:	84 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2da4:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b2da8:	bb 17 00 d0	adrp	x27, 758 ; 0x3a8000
   b2dac:	b7 17 00 d0	adrp	x23, 758 ; 0x3a8000
   b2db0:	e0 0d 00 b4	cbz	x0, 0xb2f6c
   b2db4:	00 e4 00 4f	movi.16b	v0, #0x0
   b2db8:	a0 03 3c ad	stp	q0, q0, [x29, #-0x80]
   b2dbc:	a0 03 3b ad	stp	q0, q0, [x29, #-0xa0]
   b2dc0:	75 2f 45 f9	ldr	x21, [x27, #0xa58]
   b2dc4:	e1 03 15 aa	mov	x1, x21
   b2dc8:	6e 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayCADisplay]
   b2dcc:	fd 03 1d aa	mov	x29, x29
   b2dd0:	84 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2dd4:	f6 03 00 aa	mov	x22, x0
   b2dd8:	f4 d6 41 f9	ldr	x20, [x23, #0x3a8]
   b2ddc:	a2 83 02 d1	sub	x2, x29, #0xa0
   b2de0:	e3 03 06 91	add	x3, sp, #0x180
   b2de4:	e1 03 14 aa	mov	x1, x20
   b2de8:	04 02 80 52	mov	w4, #0x10
   b2dec:	65 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayCADisplay]
   b2df0:	60 03 00 b4	cbz	x0, 0xb2e5c
   b2df4:	f7 03 00 aa	mov	x23, x0
   b2df8:	a8 03 57 f8	ldur	x8, [x29, #-0x90]
   b2dfc:	1c 01 40 f9	ldr	x28, [x8]
   b2e00:	1a 00 80 d2	mov	x26, #0x0
   b2e04:	38 2b 45 f9	ldr	x24, [x25, #0xa50]
   b2e08:	a8 03 57 f8	ldur	x8, [x29, #-0x90]
   b2e0c:	08 01 40 f9	ldr	x8, [x8]
   b2e10:	1f 01 1c eb	cmp	x8, x28
   b2e14:	60 00 00 54	b.eq	0xb2e20
   b2e18:	e0 03 16 aa	mov	x0, x22
   b2e1c:	44 82 09 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
   b2e20:	a8 83 56 f8	ldur	x8, [x29, #-0x98]
   b2e24:	00 79 7a f8	ldr	x0, [x8, x26, lsl #3]
   b2e28:	e1 03 18 aa	mov	x1, x24
   b2e2c:	55 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayCADisplay]
   b2e30:	5a 07 00 91	add	x26, x26, #0x1
   b2e34:	5f 03 17 eb	cmp	x26, x23
   b2e38:	83 fe ff 54	b.lo	0xb2e08
   b2e3c:	a2 83 02 d1	sub	x2, x29, #0xa0
   b2e40:	e3 03 06 91	add	x3, sp, #0x180
   b2e44:	e0 03 16 aa	mov	x0, x22
   b2e48:	e1 03 14 aa	mov	x1, x20
   b2e4c:	04 02 80 52	mov	w4, #0x10
   b2e50:	4c 82 09 94	bl	0x313780 ; Objc message: -[x0 carPlayCADisplay]
   b2e54:	f7 03 00 aa	mov	x23, x0
   b2e58:	40 fd ff b5	cbnz	x0, 0xb2e00
   b2e5c:	e0 03 16 aa	mov	x0, x22
   b2e60:	54 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2e64:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b2e68:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2e6c:	16 21 44 f9	ldr	x22, [x8, #0x840] ; Objc selector ref: contentView
   b2e70:	1f 20 03 d5	nop
   b2e74:	01 ad 41 f9	ldr	x1, [x8, #0x358]
   b2e78:	e2 03 16 aa	mov	x2, x22
   b2e7c:	41 82 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b2e80:	80 06 00 34	cbz	w0, 0xb2f50
   b2e84:	00 e4 00 4f	movi.16b	v0, #0x0
   b2e88:	e0 03 0b ad	stp	q0, q0, [sp, #0x160]
   b2e8c:	e0 03 0a ad	stp	q0, q0, [sp, #0x140]
   b2e90:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b2e94:	e1 03 16 aa	mov	x1, x22
   b2e98:	3a 82 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b2e9c:	fd 03 1d aa	mov	x29, x29
   b2ea0:	50 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2ea4:	f6 03 00 aa	mov	x22, x0
   b2ea8:	e1 03 15 aa	mov	x1, x21
   b2eac:	35 82 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b2eb0:	fd 03 1d aa	mov	x29, x29
   b2eb4:	4b 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2eb8:	f5 03 00 aa	mov	x21, x0
   b2ebc:	e0 03 16 aa	mov	x0, x22
   b2ec0:	3c 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2ec4:	e2 03 05 91	add	x2, sp, #0x140
   b2ec8:	e3 03 03 91	add	x3, sp, #0xc0
   b2ecc:	e0 03 15 aa	mov	x0, x21
   b2ed0:	e1 03 14 aa	mov	x1, x20
   b2ed4:	04 02 80 52	mov	w4, #0x10
   b2ed8:	2a 82 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b2edc:	60 03 00 b4	cbz	x0, 0xb2f48
   b2ee0:	f6 03 00 aa	mov	x22, x0
   b2ee4:	e8 ab 40 f9	ldr	x8, [sp, #0x150]
   b2ee8:	18 01 40 f9	ldr	x24, [x8]
   b2eec:	1a 00 80 d2	mov	x26, #0x0
   b2ef0:	37 2b 45 f9	ldr	x23, [x25, #0xa50]
   b2ef4:	e8 ab 40 f9	ldr	x8, [sp, #0x150]
   b2ef8:	08 01 40 f9	ldr	x8, [x8]
   b2efc:	1f 01 18 eb	cmp	x8, x24
   b2f00:	60 00 00 54	b.eq	0xb2f0c
   b2f04:	e0 03 15 aa	mov	x0, x21
   b2f08:	09 82 09 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
   b2f0c:	e8 a7 40 f9	ldr	x8, [sp, #0x148]
   b2f10:	00 79 7a f8	ldr	x0, [x8, x26, lsl #3]
   b2f14:	e1 03 17 aa	mov	x1, x23
   b2f18:	1a 82 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b2f1c:	5a 07 00 91	add	x26, x26, #0x1
   b2f20:	5f 03 16 eb	cmp	x26, x22
   b2f24:	83 fe ff 54	b.lo	0xb2ef4
   b2f28:	e2 03 05 91	add	x2, sp, #0x140
   b2f2c:	e3 03 03 91	add	x3, sp, #0xc0
   b2f30:	e0 03 15 aa	mov	x0, x21
   b2f34:	e1 03 14 aa	mov	x1, x20
   b2f38:	04 02 80 52	mov	w4, #0x10
   b2f3c:	11 82 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b2f40:	f6 03 00 aa	mov	x22, x0
   b2f44:	40 fd ff b5	cbnz	x0, 0xb2eec
   b2f48:	e0 03 15 aa	mov	x0, x21
   b2f4c:	19 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2f50:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b2f54:	21 2b 45 f9	ldr	x1, [x25, #0xa50]
   b2f58:	0a 82 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b2f5c:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b2f60:	7f 1a 00 f9	str	xzr, [x19, #0x30]
   b2f64:	13 82 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b2f68:	b7 17 00 d0	adrp	x23, 758 ; 0x3a8000
   b2f6c:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b2f70:	00 08 00 b4	cbz	x0, 0xb3070
   b2f74:	a8 17 00 d0	adrp	x8, 758 ; 0x3a8000
   b2f78:	01 a9 44 f9	ldr	x1, [x8, #0x950] ; Objc selector ref: setHidden:
   b2f7c:	22 00 80 52	mov	w2, #0x1
   b2f80:	00 82 09 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
   b2f84:	00 e4 00 4f	movi.16b	v0, #0x0
   b2f88:	e0 03 05 ad	stp	q0, q0, [sp, #0xa0]
   b2f8c:	e0 03 04 ad	stp	q0, q0, [sp, #0x80]
   b2f90:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b2f94:	61 2f 45 f9	ldr	x1, [x27, #0xa58]
   b2f98:	fa 81 09 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
   b2f9c:	fd 03 1d aa	mov	x29, x29
   b2fa0:	10 82 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b2fa4:	f4 03 00 aa	mov	x20, x0
   b2fa8:	f5 d6 41 f9	ldr	x21, [x23, #0x3a8]
   b2fac:	e2 03 02 91	add	x2, sp, #0x80
   b2fb0:	e3 03 00 91	mov	x3, sp
   b2fb4:	e1 03 15 aa	mov	x1, x21
   b2fb8:	04 02 80 52	mov	w4, #0x10
   b2fbc:	f1 81 09 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
   b2fc0:	60 03 00 b4	cbz	x0, 0xb302c
   b2fc4:	f6 03 00 aa	mov	x22, x0
   b2fc8:	e8 4b 40 f9	ldr	x8, [sp, #0x90]
   b2fcc:	18 01 40 f9	ldr	x24, [x8]
   b2fd0:	1a 00 80 d2	mov	x26, #0x0
   b2fd4:	37 2b 45 f9	ldr	x23, [x25, #0xa50]
   b2fd8:	e8 4b 40 f9	ldr	x8, [sp, #0x90]
   b2fdc:	08 01 40 f9	ldr	x8, [x8]
   b2fe0:	1f 01 18 eb	cmp	x8, x24
   b2fe4:	60 00 00 54	b.eq	0xb2ff0
   b2fe8:	e0 03 14 aa	mov	x0, x20
   b2fec:	d0 81 09 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
   b2ff0:	e8 47 40 f9	ldr	x8, [sp, #0x88]
   b2ff4:	00 79 7a f8	ldr	x0, [x8, x26, lsl #3]
   b2ff8:	e1 03 17 aa	mov	x1, x23
   b2ffc:	e1 81 09 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
   b3000:	5a 07 00 91	add	x26, x26, #0x1
   b3004:	5f 03 16 eb	cmp	x26, x22
   b3008:	83 fe ff 54	b.lo	0xb2fd8
   b300c:	e2 03 02 91	add	x2, sp, #0x80
   b3010:	e3 03 00 91	mov	x3, sp
   b3014:	e0 03 14 aa	mov	x0, x20
   b3018:	e1 03 15 aa	mov	x1, x21
   b301c:	04 02 80 52	mov	w4, #0x10
   b3020:	d8 81 09 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
   b3024:	f6 03 00 aa	mov	x22, x0
   b3028:	40 fd ff b5	cbnz	x0, 0xb2fd0
   b302c:	e0 03 14 aa	mov	x0, x20
   b3030:	e0 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b3034:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b3038:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b303c:	01 d9 46 f9	ldr	x1, [x8, #0xdb0] ; Objc selector ref: isKeyWindow
   b3040:	d0 81 09 94	bl	0x313780 ; Objc message: -[x0 isKeyWindow]
   b3044:	a0 00 00 34	cbz	w0, 0xb3058
   b3048:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b304c:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b3050:	01 61 40 f9	ldr	x1, [x8, #0xc0] ; Objc selector ref: resignKeyWindow
   b3054:	cb 81 09 94	bl	0x313780 ; Objc message: -[x0 resignKeyWindow]
   b3058:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b305c:	21 2b 45 f9	ldr	x1, [x25, #0xa50]
   b3060:	c8 81 09 94	bl	0x313780 ; Objc message: -[x0 resignKeyWindow]
   b3064:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b3068:	7f 12 00 f9	str	xzr, [x19, #0x20]
   b306c:	d1 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b3070:	60 06 40 f9	ldr	x0, [x19, #0x8]
   b3074:	7f 06 00 f9	str	xzr, [x19, #0x8]
   b3078:	ce 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b307c:	60 0a 40 f9	ldr	x0, [x19, #0x10]
   b3080:	7f 0a 00 f9	str	xzr, [x19, #0x10]
~~~

### Original CBWindow::dismiss at 0xb30c4

~~~asm
   b30c4:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b30c8:	01 69 40 f9	ldr	x1, [x8, #0xd0] ; Objc selector ref: destroyWindows
   b30cc:	ad 81 09 14	b	0x313780 ; Objc message: -[x0 destroyWindows]
   b30d0:	ff 03 01 d1	sub	sp, sp, #0x40
   b30d4:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
   b30d8:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
   b30dc:	fd c3 00 91	add	x29, sp, #0x30
   b30e0:	f3 03 00 aa	mov	x19, x0
   b30e4:	e8 15 00 b0	adrp	x8, 701 ; 0x370000
   b30e8:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   b30ec:	08 01 40 f9	ldr	x8, [x8]
   b30f0:	e8 0f 00 f9	str	x8, [sp, #0x18]
   b30f4:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b30f8:	01 69 40 f9	ldr	x1, [x8, #0xd0] ; Objc selector ref: destroyWindows
   b30fc:	a1 81 09 94	bl	0x313780 ; Objc message: -[x0 destroyWindows]
   b3100:	a8 17 00 f0	adrp	x8, 759 ; 0x3aa000
   b3104:	08 e5 46 f9	ldr	x8, [x8, #0xdc8] ; Objc class ref: CBWindow
   b3108:	f3 a3 00 a9	stp	x19, x8, [sp, #0x8]
   b310c:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b3110:	01 d1 43 f9	ldr	x1, [x8, #0x7a0] ; Objc selector ref: dealloc
   b3114:	e0 23 00 91	add	x0, sp, #0x8
   b3118:	a0 81 09 94	bl	0x313798 ; Objc message: -[[x0 super] dealloc]
   b311c:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
   b3120:	e9 15 00 b0	adrp	x9, 701 ; 0x370000
   b3124:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   b3128:	29 01 40 f9	ldr	x9, [x9]
   b312c:	3f 01 08 eb	cmp	x9, x8
   b3130:	a1 00 00 54	b.ne	0xb3144
   b3134:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
   b3138:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
   b313c:	ff 03 01 91	add	sp, sp, #0x40
   b3140:	c0 03 5f d6	ret
   b3144:	de 80 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
   b3148:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
   b314c:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
   b3150:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
   b3154:	fd 83 00 91	add	x29, sp, #0x20
   b3158:	f3 03 02 aa	mov	x19, x2
   b315c:	f4 03 00 aa	mov	x20, x0
   b3160:	00 18 40 f9	ldr	x0, [x0, #0x30]
   b3164:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b3168:	01 21 44 f9	ldr	x1, [x8, #0x840] ; Objc selector ref: contentView
   b316c:	85 81 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b3170:	fd 03 1d aa	mov	x29, x29
   b3174:	9b 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b3178:	f5 03 00 aa	mov	x21, x0
   b317c:	60 00 00 b4	cbz	x0, 0xb3188
   b3180:	f6 03 15 aa	mov	x22, x21
   b3184:	0a 00 00 14	b	0xb31ac
   b3188:	80 1a 40 f9	ldr	x0, [x20, #0x30]
   b318c:	40 00 00 b5	cbnz	x0, 0xb3194
   b3190:	80 12 40 f9	ldr	x0, [x20, #0x20]
   b3194:	8a 81 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   b3198:	f6 03 00 aa	mov	x22, x0
   b319c:	e0 03 15 aa	mov	x0, x21
   b31a0:	84 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b31a4:	f5 03 16 aa	mov	x21, x22
   b31a8:	f6 01 00 b4	cbz	x22, 0xb31e4
   b31ac:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b31b0:	01 6d 40 f9	ldr	x1, [x8, #0xd8] ; Objc selector ref: multitaskingOverlay
   b31b4:	e0 03 14 aa	mov	x0, x20
   b31b8:	72 81 09 94	bl	0x313780 ; Objc message: -[x0 multitaskingOverlay]
   b31bc:	fd 03 1d aa	mov	x29, x29
   b31c0:	88 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b31c4:	f4 03 00 aa	mov	x20, x0
   b31c8:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b31cc:	01 71 40 f9	ldr	x1, [x8, #0xe0] ; Objc selector ref: showAppPickerForSlot:parentView:
   b31d0:	e2 03 13 aa	mov	x2, x19
   b31d4:	e3 03 15 aa	mov	x3, x21
   b31d8:	6a 81 09 94	bl	0x313780 ; Objc message: -[x0 showAppPickerForSlot:parentView:]
   b31dc:	e0 03 14 aa	mov	x0, x20
   b31e0:	74 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b31e4:	e0 03 16 aa	mov	x0, x22
   b31e8:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
   b31ec:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
   b31f0:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
   b31f4:	6f 81 09 14	b	0x3137b0 ; symbol stub for: _objc_release
   b31f8:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
   b31fc:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
   b3200:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
   b3204:	fd 83 00 91	add	x29, sp, #0x20
   b3208:	f3 03 00 aa	mov	x19, x0
   b320c:	00 18 40 f9	ldr	x0, [x0, #0x30]
   b3210:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b3214:	01 21 44 f9	ldr	x1, [x8, #0x840] ; Objc selector ref: contentView
   b3218:	5a 81 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b321c:	fd 03 1d aa	mov	x29, x29
   b3220:	70 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b3224:	f4 03 00 aa	mov	x20, x0
   b3228:	60 00 00 b4	cbz	x0, 0xb3234
   b322c:	f5 03 14 aa	mov	x21, x20
   b3230:	0a 00 00 14	b	0xb3258
   b3234:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b3238:	40 00 00 b5	cbnz	x0, 0xb3240
   b323c:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b3240:	5f 81 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   b3244:	f5 03 00 aa	mov	x21, x0
   b3248:	e0 03 14 aa	mov	x0, x20
   b324c:	59 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b3250:	f4 03 15 aa	mov	x20, x21
   b3254:	d5 01 00 b4	cbz	x21, 0xb328c
   b3258:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b325c:	01 6d 40 f9	ldr	x1, [x8, #0xd8] ; Objc selector ref: multitaskingOverlay
   b3260:	e0 03 13 aa	mov	x0, x19
   b3264:	47 81 09 94	bl	0x313780 ; Objc message: -[x0 multitaskingOverlay]
   b3268:	fd 03 1d aa	mov	x29, x29
   b326c:	5d 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b3270:	f3 03 00 aa	mov	x19, x0
   b3274:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b3278:	01 75 40 f9	ldr	x1, [x8, #0xe8] ; Objc selector ref: showLayoutChooserInParentView:
   b327c:	e2 03 14 aa	mov	x2, x20
   b3280:	40 81 09 94	bl	0x313780 ; Objc message: -[x0 showLayoutChooserInParentView:]
   b3284:	e0 03 13 aa	mov	x0, x19
   b3288:	4a 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b328c:	e0 03 15 aa	mov	x0, x21
   b3290:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
   b3294:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
   b3298:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
   b329c:	45 81 09 14	b	0x3137b0 ; symbol stub for: _objc_release
   b32a0:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
   b32a4:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
   b32a8:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
   b32ac:	fd 83 00 91	add	x29, sp, #0x20
   b32b0:	f3 03 00 aa	mov	x19, x0
   b32b4:	00 18 40 f9	ldr	x0, [x0, #0x30]
   b32b8:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b32bc:	01 21 44 f9	ldr	x1, [x8, #0x840] ; Objc selector ref: contentView
   b32c0:	30 81 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b32c4:	fd 03 1d aa	mov	x29, x29
   b32c8:	46 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b32cc:	f4 03 00 aa	mov	x20, x0
   b32d0:	60 00 00 b4	cbz	x0, 0xb32dc
   b32d4:	f5 03 14 aa	mov	x21, x20
   b32d8:	0a 00 00 14	b	0xb3300
   b32dc:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b32e0:	40 00 00 b5	cbnz	x0, 0xb32e8
   b32e4:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b32e8:	35 81 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   b32ec:	f5 03 00 aa	mov	x21, x0
   b32f0:	e0 03 14 aa	mov	x0, x20
   b32f4:	2f 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b32f8:	f4 03 15 aa	mov	x20, x21
   b32fc:	d5 01 00 b4	cbz	x21, 0xb3334
   b3300:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b3304:	01 6d 40 f9	ldr	x1, [x8, #0xd8] ; Objc selector ref: multitaskingOverlay
   b3308:	e0 03 13 aa	mov	x0, x19
   b330c:	1d 81 09 94	bl	0x313780 ; Objc message: -[x0 multitaskingOverlay]
   b3310:	fd 03 1d aa	mov	x29, x29
   b3314:	33 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b3318:	f3 03 00 aa	mov	x19, x0
   b331c:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b3320:	01 79 40 f9	ldr	x1, [x8, #0xf0] ; Objc selector ref: showRecentAppsInParentView:
   b3324:	e2 03 14 aa	mov	x2, x20
   b3328:	16 81 09 94	bl	0x313780 ; Objc message: -[x0 showRecentAppsInParentView:]
   b332c:	e0 03 13 aa	mov	x0, x19
   b3330:	20 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b3334:	e0 03 15 aa	mov	x0, x21
   b3338:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
   b333c:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
   b3340:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
   b3344:	1b 81 09 14	b	0x3137b0 ; symbol stub for: _objc_release
   b3348:	00 04 45 6d	ldp	d0, d1, [x0, #0x50]
   b334c:	02 0c 46 6d	ldp	d2, d3, [x0, #0x60]
   b3350:	c0 03 5f d6	ret
   b3354:	00 28 00 fd	str	d0, [x0, #0x50]
   b3358:	01 2c 00 fd	str	d1, [x0, #0x58]
   b335c:	02 30 00 fd	str	d2, [x0, #0x60]
   b3360:	03 34 00 fd	str	d3, [x0, #0x68]
   b3364:	c0 03 5f d6	ret
   b3368:	00 10 40 f9	ldr	x0, [x0, #0x20]
   b336c:	c0 03 5f d6	ret
   b3370:	e1 03 02 aa	mov	x1, x2
   b3374:	00 80 00 91	add	x0, x0, #0x20
   b3378:	26 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b337c:	00 14 40 f9	ldr	x0, [x0, #0x28]
   b3380:	c0 03 5f d6	ret
   b3384:	e1 03 02 aa	mov	x1, x2
   b3388:	00 a0 00 91	add	x0, x0, #0x28
   b338c:	21 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b3390:	00 18 40 f9	ldr	x0, [x0, #0x30]
   b3394:	c0 03 5f d6	ret
   b3398:	e1 03 02 aa	mov	x1, x2
   b339c:	00 c0 00 91	add	x0, x0, #0x30
   b33a0:	1c 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b33a4:	00 1c 40 f9	ldr	x0, [x0, #0x38]
   b33a8:	c0 03 5f d6	ret
   b33ac:	e1 03 02 aa	mov	x1, x2
   b33b0:	00 e0 00 91	add	x0, x0, #0x38
   b33b4:	17 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b33b8:	e1 03 02 aa	mov	x1, x2
   b33bc:	00 00 01 91	add	x0, x0, #0x40
   b33c0:	14 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b33c4:	e1 03 02 aa	mov	x1, x2
   b33c8:	00 20 01 91	add	x0, x0, #0x48
   b33cc:	11 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b33d0:	00 60 40 39	ldrb	w0, [x0, #0x18]
   b33d4:	c0 03 5f d6	ret
   b33d8:	02 60 00 39	strb	w2, [x0, #0x18]
   b33dc:	c0 03 5f d6	ret
   b33e0:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
   b33e4:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
   b33e8:	fd 43 00 91	add	x29, sp, #0x10
   b33ec:	f3 03 00 aa	mov	x19, x0
   b33f0:	00 20 01 91	add	x0, x0, #0x48
   b33f4:	01 00 80 d2	mov	x1, #0x0
   b33f8:	06 81 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b33fc:	60 02 01 91	add	x0, x19, #0x40
   b3400:	01 00 80 d2	mov	x1, #0x0
   b3404:	03 81 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b3408:	60 e2 00 91	add	x0, x19, #0x38
   b340c:	01 00 80 d2	mov	x1, #0x0
   b3410:	00 81 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b3414:	60 c2 00 91	add	x0, x19, #0x30
   b3418:	01 00 80 d2	mov	x1, #0x0
   b341c:	fd 80 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b3420:	60 a2 00 91	add	x0, x19, #0x28
   b3424:	01 00 80 d2	mov	x1, #0x0
   b3428:	fa 80 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b342c:	60 82 00 91	add	x0, x19, #0x20
   b3430:	01 00 80 d2	mov	x1, #0x0
~~~

### Original CBWindow::dealloc at 0xb30d0

~~~asm
   b30d0:	ff 03 01 d1	sub	sp, sp, #0x40
   b30d4:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
   b30d8:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
   b30dc:	fd c3 00 91	add	x29, sp, #0x30
   b30e0:	f3 03 00 aa	mov	x19, x0
   b30e4:	e8 15 00 b0	adrp	x8, 701 ; 0x370000
   b30e8:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
   b30ec:	08 01 40 f9	ldr	x8, [x8]
   b30f0:	e8 0f 00 f9	str	x8, [sp, #0x18]
   b30f4:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b30f8:	01 69 40 f9	ldr	x1, [x8, #0xd0] ; Objc selector ref: destroyWindows
   b30fc:	a1 81 09 94	bl	0x313780 ; Objc message: -[x0 destroyWindows]
   b3100:	a8 17 00 f0	adrp	x8, 759 ; 0x3aa000
   b3104:	08 e5 46 f9	ldr	x8, [x8, #0xdc8] ; Objc class ref: CBWindow
   b3108:	f3 a3 00 a9	stp	x19, x8, [sp, #0x8]
   b310c:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b3110:	01 d1 43 f9	ldr	x1, [x8, #0x7a0] ; Objc selector ref: dealloc
   b3114:	e0 23 00 91	add	x0, sp, #0x8
   b3118:	a0 81 09 94	bl	0x313798 ; Objc message: -[[x0 super] dealloc]
   b311c:	e8 0f 40 f9	ldr	x8, [sp, #0x18]
   b3120:	e9 15 00 b0	adrp	x9, 701 ; 0x370000
   b3124:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
   b3128:	29 01 40 f9	ldr	x9, [x9]
   b312c:	3f 01 08 eb	cmp	x9, x8
   b3130:	a1 00 00 54	b.ne	0xb3144
   b3134:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
   b3138:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
   b313c:	ff 03 01 91	add	sp, sp, #0x40
   b3140:	c0 03 5f d6	ret
   b3144:	de 80 09 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
   b3148:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
   b314c:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
   b3150:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
   b3154:	fd 83 00 91	add	x29, sp, #0x20
   b3158:	f3 03 02 aa	mov	x19, x2
   b315c:	f4 03 00 aa	mov	x20, x0
   b3160:	00 18 40 f9	ldr	x0, [x0, #0x30]
   b3164:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b3168:	01 21 44 f9	ldr	x1, [x8, #0x840] ; Objc selector ref: contentView
   b316c:	85 81 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b3170:	fd 03 1d aa	mov	x29, x29
   b3174:	9b 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b3178:	f5 03 00 aa	mov	x21, x0
   b317c:	60 00 00 b4	cbz	x0, 0xb3188
   b3180:	f6 03 15 aa	mov	x22, x21
   b3184:	0a 00 00 14	b	0xb31ac
   b3188:	80 1a 40 f9	ldr	x0, [x20, #0x30]
   b318c:	40 00 00 b5	cbnz	x0, 0xb3194
   b3190:	80 12 40 f9	ldr	x0, [x20, #0x20]
   b3194:	8a 81 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   b3198:	f6 03 00 aa	mov	x22, x0
   b319c:	e0 03 15 aa	mov	x0, x21
   b31a0:	84 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b31a4:	f5 03 16 aa	mov	x21, x22
   b31a8:	f6 01 00 b4	cbz	x22, 0xb31e4
   b31ac:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b31b0:	01 6d 40 f9	ldr	x1, [x8, #0xd8] ; Objc selector ref: multitaskingOverlay
   b31b4:	e0 03 14 aa	mov	x0, x20
   b31b8:	72 81 09 94	bl	0x313780 ; Objc message: -[x0 multitaskingOverlay]
   b31bc:	fd 03 1d aa	mov	x29, x29
   b31c0:	88 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b31c4:	f4 03 00 aa	mov	x20, x0
   b31c8:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b31cc:	01 71 40 f9	ldr	x1, [x8, #0xe0] ; Objc selector ref: showAppPickerForSlot:parentView:
   b31d0:	e2 03 13 aa	mov	x2, x19
   b31d4:	e3 03 15 aa	mov	x3, x21
   b31d8:	6a 81 09 94	bl	0x313780 ; Objc message: -[x0 showAppPickerForSlot:parentView:]
   b31dc:	e0 03 14 aa	mov	x0, x20
   b31e0:	74 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b31e4:	e0 03 16 aa	mov	x0, x22
   b31e8:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
   b31ec:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
   b31f0:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
   b31f4:	6f 81 09 14	b	0x3137b0 ; symbol stub for: _objc_release
   b31f8:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
   b31fc:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
   b3200:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
   b3204:	fd 83 00 91	add	x29, sp, #0x20
   b3208:	f3 03 00 aa	mov	x19, x0
   b320c:	00 18 40 f9	ldr	x0, [x0, #0x30]
   b3210:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b3214:	01 21 44 f9	ldr	x1, [x8, #0x840] ; Objc selector ref: contentView
   b3218:	5a 81 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b321c:	fd 03 1d aa	mov	x29, x29
   b3220:	70 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b3224:	f4 03 00 aa	mov	x20, x0
   b3228:	60 00 00 b4	cbz	x0, 0xb3234
   b322c:	f5 03 14 aa	mov	x21, x20
   b3230:	0a 00 00 14	b	0xb3258
   b3234:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b3238:	40 00 00 b5	cbnz	x0, 0xb3240
   b323c:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b3240:	5f 81 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   b3244:	f5 03 00 aa	mov	x21, x0
   b3248:	e0 03 14 aa	mov	x0, x20
   b324c:	59 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b3250:	f4 03 15 aa	mov	x20, x21
   b3254:	d5 01 00 b4	cbz	x21, 0xb328c
   b3258:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b325c:	01 6d 40 f9	ldr	x1, [x8, #0xd8] ; Objc selector ref: multitaskingOverlay
   b3260:	e0 03 13 aa	mov	x0, x19
   b3264:	47 81 09 94	bl	0x313780 ; Objc message: -[x0 multitaskingOverlay]
   b3268:	fd 03 1d aa	mov	x29, x29
   b326c:	5d 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b3270:	f3 03 00 aa	mov	x19, x0
   b3274:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b3278:	01 75 40 f9	ldr	x1, [x8, #0xe8] ; Objc selector ref: showLayoutChooserInParentView:
   b327c:	e2 03 14 aa	mov	x2, x20
   b3280:	40 81 09 94	bl	0x313780 ; Objc message: -[x0 showLayoutChooserInParentView:]
   b3284:	e0 03 13 aa	mov	x0, x19
   b3288:	4a 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b328c:	e0 03 15 aa	mov	x0, x21
   b3290:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
   b3294:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
   b3298:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
   b329c:	45 81 09 14	b	0x3137b0 ; symbol stub for: _objc_release
   b32a0:	f6 57 bd a9	stp	x22, x21, [sp, #-0x30]!
   b32a4:	f4 4f 01 a9	stp	x20, x19, [sp, #0x10]
   b32a8:	fd 7b 02 a9	stp	x29, x30, [sp, #0x20]
   b32ac:	fd 83 00 91	add	x29, sp, #0x20
   b32b0:	f3 03 00 aa	mov	x19, x0
   b32b4:	00 18 40 f9	ldr	x0, [x0, #0x30]
   b32b8:	a8 17 00 b0	adrp	x8, 757 ; 0x3a8000
   b32bc:	01 21 44 f9	ldr	x1, [x8, #0x840] ; Objc selector ref: contentView
   b32c0:	30 81 09 94	bl	0x313780 ; Objc message: -[x0 contentView]
   b32c4:	fd 03 1d aa	mov	x29, x29
   b32c8:	46 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b32cc:	f4 03 00 aa	mov	x20, x0
   b32d0:	60 00 00 b4	cbz	x0, 0xb32dc
   b32d4:	f5 03 14 aa	mov	x21, x20
   b32d8:	0a 00 00 14	b	0xb3300
   b32dc:	60 1a 40 f9	ldr	x0, [x19, #0x30]
   b32e0:	40 00 00 b5	cbnz	x0, 0xb32e8
   b32e4:	60 12 40 f9	ldr	x0, [x19, #0x20]
   b32e8:	35 81 09 94	bl	0x3137bc ; symbol stub for: _objc_retain
   b32ec:	f5 03 00 aa	mov	x21, x0
   b32f0:	e0 03 14 aa	mov	x0, x20
   b32f4:	2f 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b32f8:	f4 03 15 aa	mov	x20, x21
   b32fc:	d5 01 00 b4	cbz	x21, 0xb3334
   b3300:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b3304:	01 6d 40 f9	ldr	x1, [x8, #0xd8] ; Objc selector ref: multitaskingOverlay
   b3308:	e0 03 13 aa	mov	x0, x19
   b330c:	1d 81 09 94	bl	0x313780 ; Objc message: -[x0 multitaskingOverlay]
   b3310:	fd 03 1d aa	mov	x29, x29
   b3314:	33 81 09 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
   b3318:	f3 03 00 aa	mov	x19, x0
   b331c:	a8 17 00 d0	adrp	x8, 758 ; 0x3a9000
   b3320:	01 79 40 f9	ldr	x1, [x8, #0xf0] ; Objc selector ref: showRecentAppsInParentView:
   b3324:	e2 03 14 aa	mov	x2, x20
   b3328:	16 81 09 94	bl	0x313780 ; Objc message: -[x0 showRecentAppsInParentView:]
   b332c:	e0 03 13 aa	mov	x0, x19
   b3330:	20 81 09 94	bl	0x3137b0 ; symbol stub for: _objc_release
   b3334:	e0 03 15 aa	mov	x0, x21
   b3338:	fd 7b 42 a9	ldp	x29, x30, [sp, #0x20]
   b333c:	f4 4f 41 a9	ldp	x20, x19, [sp, #0x10]
   b3340:	f6 57 c3 a8	ldp	x22, x21, [sp], #0x30
   b3344:	1b 81 09 14	b	0x3137b0 ; symbol stub for: _objc_release
   b3348:	00 04 45 6d	ldp	d0, d1, [x0, #0x50]
   b334c:	02 0c 46 6d	ldp	d2, d3, [x0, #0x60]
   b3350:	c0 03 5f d6	ret
   b3354:	00 28 00 fd	str	d0, [x0, #0x50]
   b3358:	01 2c 00 fd	str	d1, [x0, #0x58]
   b335c:	02 30 00 fd	str	d2, [x0, #0x60]
   b3360:	03 34 00 fd	str	d3, [x0, #0x68]
   b3364:	c0 03 5f d6	ret
   b3368:	00 10 40 f9	ldr	x0, [x0, #0x20]
   b336c:	c0 03 5f d6	ret
   b3370:	e1 03 02 aa	mov	x1, x2
   b3374:	00 80 00 91	add	x0, x0, #0x20
   b3378:	26 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b337c:	00 14 40 f9	ldr	x0, [x0, #0x28]
   b3380:	c0 03 5f d6	ret
   b3384:	e1 03 02 aa	mov	x1, x2
   b3388:	00 a0 00 91	add	x0, x0, #0x28
   b338c:	21 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b3390:	00 18 40 f9	ldr	x0, [x0, #0x30]
   b3394:	c0 03 5f d6	ret
   b3398:	e1 03 02 aa	mov	x1, x2
   b339c:	00 c0 00 91	add	x0, x0, #0x30
   b33a0:	1c 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b33a4:	00 1c 40 f9	ldr	x0, [x0, #0x38]
   b33a8:	c0 03 5f d6	ret
   b33ac:	e1 03 02 aa	mov	x1, x2
   b33b0:	00 e0 00 91	add	x0, x0, #0x38
   b33b4:	17 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b33b8:	e1 03 02 aa	mov	x1, x2
   b33bc:	00 00 01 91	add	x0, x0, #0x40
   b33c0:	14 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b33c4:	e1 03 02 aa	mov	x1, x2
   b33c8:	00 20 01 91	add	x0, x0, #0x48
   b33cc:	11 81 09 14	b	0x313810 ; symbol stub for: _objc_storeStrong
   b33d0:	00 60 40 39	ldrb	w0, [x0, #0x18]
   b33d4:	c0 03 5f d6	ret
   b33d8:	02 60 00 39	strb	w2, [x0, #0x18]
   b33dc:	c0 03 5f d6	ret
   b33e0:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
   b33e4:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
   b33e8:	fd 43 00 91	add	x29, sp, #0x10
   b33ec:	f3 03 00 aa	mov	x19, x0
   b33f0:	00 20 01 91	add	x0, x0, #0x48
   b33f4:	01 00 80 d2	mov	x1, #0x0
   b33f8:	06 81 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b33fc:	60 02 01 91	add	x0, x19, #0x40
   b3400:	01 00 80 d2	mov	x1, #0x0
   b3404:	03 81 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b3408:	60 e2 00 91	add	x0, x19, #0x38
   b340c:	01 00 80 d2	mov	x1, #0x0
   b3410:	00 81 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b3414:	60 c2 00 91	add	x0, x19, #0x30
   b3418:	01 00 80 d2	mov	x1, #0x0
   b341c:	fd 80 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b3420:	60 a2 00 91	add	x0, x19, #0x28
   b3424:	01 00 80 d2	mov	x1, #0x0
   b3428:	fa 80 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b342c:	60 82 00 91	add	x0, x19, #0x20
   b3430:	01 00 80 d2	mov	x1, #0x0
   b3434:	f7 80 09 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
   b3438:	60 42 00 91	add	x0, x19, #0x10
   b343c:	01 00 80 d2	mov	x1, #0x0
~~~

### Original CBBridgedSplitApp::restoreSplitAnimated: at 0x10d40c

~~~asm
  10d40c:	fc 6f ba a9	stp	x28, x27, [sp, #-0x60]!
  10d410:	fa 67 01 a9	stp	x26, x25, [sp, #0x10]
  10d414:	f8 5f 02 a9	stp	x24, x23, [sp, #0x20]
  10d418:	f6 57 03 a9	stp	x22, x21, [sp, #0x30]
  10d41c:	f4 4f 04 a9	stp	x20, x19, [sp, #0x40]
  10d420:	fd 7b 05 a9	stp	x29, x30, [sp, #0x50]
  10d424:	fd 43 01 91	add	x29, sp, #0x50
  10d428:	ff 43 0b d1	sub	sp, sp, #0x2d0
  10d42c:	08 13 00 f0	adrp	x8, 611 ; 0x370000
  10d430:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
  10d434:	08 01 40 f9	ldr	x8, [x8]
  10d438:	a8 03 1a f8	stur	x8, [x29, #-0x60]
  10d43c:	e8 14 00 d0	adrp	x8, 670 ; 0x3ab000
  10d440:	08 75 81 b9	ldrsw	x8, [x8, #0x174]
  10d444:	09 68 68 38	ldrb	w9, [x0, x8]
  10d448:	69 20 00 35	cbnz	w9, 0x10d854
  10d44c:	fc 03 00 aa	mov	x28, x0
  10d450:	e2 0f 00 b9	str	w2, [sp, #0xc]
  10d454:	62 00 00 34	cbz	w2, 0x10d460
  10d458:	29 00 80 52	mov	w9, #0x1
  10d45c:	89 6b 28 38	strb	w9, [x28, x8]
  10d460:	e8 14 00 d0	adrp	x8, 670 ; 0x3ab000
  10d464:	08 51 81 b9	ldrsw	x8, [x8, #0x150]
  10d468:	09 00 80 92	mov	x9, #-0x1
  10d46c:	89 6b 28 f8	str	x9, [x28, x8]
  10d470:	00 e4 00 4f	movi.16b	v0, #0x0
  10d474:	a0 03 3b ad	stp	q0, q0, [x29, #-0xa0]
  10d478:	a0 03 3c ad	stp	q0, q0, [x29, #-0x80]
  10d47c:	e8 14 00 d0	adrp	x8, 670 ; 0x3ab000
  10d480:	08 5d 81 b9	ldrsw	x8, [x8, #0x15c]
  10d484:	80 6b 68 f8	ldr	x0, [x28, x8]
  10d488:	cd 18 08 94	bl	0x3137bc ; symbol stub for: _objc_retain
  10d48c:	f6 03 00 aa	mov	x22, x0
  10d490:	c8 14 00 f0	adrp	x8, 667 ; 0x3a8000
  10d494:	01 d5 41 f9	ldr	x1, [x8, #0x3a8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
  10d498:	a2 83 02 d1	sub	x2, x29, #0xa0
  10d49c:	e3 03 08 91	add	x3, sp, #0x200
  10d4a0:	e1 0f 00 f9	str	x1, [sp, #0x18]
  10d4a4:	04 02 80 52	mov	w4, #0x10
  10d4a8:	b6 18 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  10d4ac:	d3 14 00 f0	adrp	x19, 667 ; 0x3a8000
  10d4b0:	60 04 00 b4	cbz	x0, 0x10d53c
  10d4b4:	f7 03 00 aa	mov	x23, x0
  10d4b8:	a8 03 57 f8	ldur	x8, [x29, #-0x90]
  10d4bc:	15 01 40 f9	ldr	x21, [x8]
  10d4c0:	da 14 00 f0	adrp	x26, 667 ; 0x3a8000
  10d4c4:	1b 00 80 d2	mov	x27, #0x0
  10d4c8:	74 aa 44 f9	ldr	x20, [x19, #0x950]
  10d4cc:	58 17 44 f9	ldr	x24, [x26, #0x828]
  10d4d0:	a8 03 57 f8	ldur	x8, [x29, #-0x90]
  10d4d4:	08 01 40 f9	ldr	x8, [x8]
  10d4d8:	1f 01 15 eb	cmp	x8, x21
  10d4dc:	60 00 00 54	b.eq	0x10d4e8
  10d4e0:	e0 03 16 aa	mov	x0, x22
  10d4e4:	92 18 08 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  10d4e8:	a8 83 56 f8	ldur	x8, [x29, #-0x98]
  10d4ec:	19 79 7b f8	ldr	x25, [x8, x27, lsl #3]
  10d4f0:	e0 03 19 aa	mov	x0, x25
  10d4f4:	e1 03 14 aa	mov	x1, x20
  10d4f8:	02 00 80 52	mov	w2, #0x0
  10d4fc:	a1 18 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  10d500:	e0 03 19 aa	mov	x0, x25
  10d504:	e1 03 18 aa	mov	x1, x24
  10d508:	22 00 80 52	mov	w2, #0x1
  10d50c:	9d 18 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  10d510:	7b 07 00 91	add	x27, x27, #0x1
  10d514:	7f 03 17 eb	cmp	x27, x23
  10d518:	c3 fd ff 54	b.lo	0x10d4d0
  10d51c:	a2 83 02 d1	sub	x2, x29, #0xa0
  10d520:	e3 03 08 91	add	x3, sp, #0x200
  10d524:	e0 03 16 aa	mov	x0, x22
  10d528:	e1 0f 40 f9	ldr	x1, [sp, #0x18]
  10d52c:	04 02 80 52	mov	w4, #0x10
  10d530:	94 18 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  10d534:	f7 03 00 aa	mov	x23, x0
  10d538:	60 fc ff b5	cbnz	x0, 0x10d4c4
  10d53c:	e0 03 16 aa	mov	x0, x22
  10d540:	9c 18 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  10d544:	00 e4 00 4f	movi.16b	v0, #0x0
  10d548:	e0 03 0f ad	stp	q0, q0, [sp, #0x1e0]
  10d54c:	e0 03 0e ad	stp	q0, q0, [sp, #0x1c0]
  10d550:	e8 14 00 d0	adrp	x8, 670 ; 0x3ab000
  10d554:	08 61 81 b9	ldrsw	x8, [x8, #0x160]
  10d558:	80 6b 68 f8	ldr	x0, [x28, x8]
  10d55c:	98 18 08 94	bl	0x3137bc ; symbol stub for: _objc_retain
  10d560:	f6 03 00 aa	mov	x22, x0
  10d564:	e2 03 07 91	add	x2, sp, #0x1c0
  10d568:	e3 03 05 91	add	x3, sp, #0x140
  10d56c:	e1 0f 40 f9	ldr	x1, [sp, #0x18]
  10d570:	04 02 80 52	mov	w4, #0x10
  10d574:	83 18 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  10d578:	80 03 00 b4	cbz	x0, 0x10d5e8
  10d57c:	f4 03 00 aa	mov	x20, x0
  10d580:	e8 eb 40 f9	ldr	x8, [sp, #0x1d0]
  10d584:	15 01 40 f9	ldr	x21, [x8]
  10d588:	18 00 80 d2	mov	x24, #0x0
  10d58c:	77 aa 44 f9	ldr	x23, [x19, #0x950]
  10d590:	e8 eb 40 f9	ldr	x8, [sp, #0x1d0]
  10d594:	08 01 40 f9	ldr	x8, [x8]
  10d598:	1f 01 15 eb	cmp	x8, x21
  10d59c:	60 00 00 54	b.eq	0x10d5a8
  10d5a0:	e0 03 16 aa	mov	x0, x22
  10d5a4:	62 18 08 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  10d5a8:	e8 e7 40 f9	ldr	x8, [sp, #0x1c8]
  10d5ac:	00 79 78 f8	ldr	x0, [x8, x24, lsl #3]
  10d5b0:	e1 03 17 aa	mov	x1, x23
  10d5b4:	02 00 80 52	mov	w2, #0x0
  10d5b8:	72 18 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  10d5bc:	18 07 00 91	add	x24, x24, #0x1
  10d5c0:	1f 03 14 eb	cmp	x24, x20
  10d5c4:	63 fe ff 54	b.lo	0x10d590
  10d5c8:	e2 03 07 91	add	x2, sp, #0x1c0
  10d5cc:	e3 03 05 91	add	x3, sp, #0x140
  10d5d0:	e0 03 16 aa	mov	x0, x22
  10d5d4:	e1 0f 40 f9	ldr	x1, [sp, #0x18]
  10d5d8:	04 02 80 52	mov	w4, #0x10
  10d5dc:	69 18 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  10d5e0:	f4 03 00 aa	mov	x20, x0
  10d5e4:	20 fd ff b5	cbnz	x0, 0x10d588
  10d5e8:	e0 03 16 aa	mov	x0, x22
  10d5ec:	71 18 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  10d5f0:	e8 14 00 b0	adrp	x8, 669 ; 0x3aa000
  10d5f4:	00 81 45 f9	ldr	x0, [x8, #0xb00] ; Objc class ref: CBBridgeManager
  10d5f8:	c8 14 00 f0	adrp	x8, 667 ; 0x3a8000
  10d5fc:	01 51 41 f9	ldr	x1, [x8, #0x2a0] ; Objc selector ref: sharedInstance
  10d600:	e1 13 00 f9	str	x1, [sp, #0x20]
  10d604:	5f 18 08 94	bl	0x313780 ; Objc message: +[CBBridgeManager sharedInstance]
  10d608:	fd 03 1d aa	mov	x29, x29
  10d60c:	75 18 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10d610:	f4 03 00 aa	mov	x20, x0
  10d614:	e8 14 00 90	adrp	x8, 668 ; 0x3a9000
  10d618:	01 25 43 f9	ldr	x1, [x8, #0x648] ; Objc selector ref: saveBridgeStateToDisk
  10d61c:	59 18 08 94	bl	0x313780 ; Objc message: -[x0 saveBridgeStateToDisk]
  10d620:	e0 03 14 aa	mov	x0, x20
  10d624:	63 18 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  10d628:	00 e4 00 4f	movi.16b	v0, #0x0
  10d62c:	e0 03 09 ad	stp	q0, q0, [sp, #0x120]
  10d630:	e0 03 08 ad	stp	q0, q0, [sp, #0x100]
  10d634:	e8 14 00 d0	adrp	x8, 670 ; 0x3ab000
  10d638:	08 55 81 b9	ldrsw	x8, [x8, #0x154]
  10d63c:	fc 0b 00 f9	str	x28, [sp, #0x10]
  10d640:	80 6b 68 f8	ldr	x0, [x28, x8]
  10d644:	5e 18 08 94	bl	0x3137bc ; symbol stub for: _objc_retain
  10d648:	e2 03 04 91	add	x2, sp, #0x100
  10d64c:	e3 03 02 91	add	x3, sp, #0x80
  10d650:	e0 17 00 f9	str	x0, [sp, #0x28]
  10d654:	e1 0f 40 f9	ldr	x1, [sp, #0x18]
  10d658:	04 02 80 52	mov	w4, #0x10
  10d65c:	49 18 08 94	bl	0x313780 ; Objc message: -[x0 saveBridgeStateToDisk]
  10d660:	20 09 00 b4	cbz	x0, 0x10d784
  10d664:	f8 03 00 aa	mov	x24, x0
  10d668:	e8 8b 40 f9	ldr	x8, [sp, #0x110]
  10d66c:	16 01 40 f9	ldr	x22, [x8]
  10d670:	17 00 80 d2	mov	x23, #0x0
  10d674:	c8 14 00 f0	adrp	x8, 667 ; 0x3a8000
  10d678:	19 cd 40 f9	ldr	x25, [x8, #0x198] ; Objc selector ref: bundleIdentifier
  10d67c:	1f 20 03 d5	nop
  10d680:	1a 75 41 f9	ldr	x26, [x8, #0x2e8]
  10d684:	e8 14 00 90	adrp	x8, 668 ; 0x3a9000
  10d688:	1b 29 43 f9	ldr	x27, [x8, #0x650] ; Objc selector ref: sendStateToApp:shouldBridge:
  10d68c:	e8 8b 40 f9	ldr	x8, [sp, #0x110]
  10d690:	08 01 40 f9	ldr	x8, [x8]
  10d694:	1f 01 16 eb	cmp	x8, x22
  10d698:	60 00 00 54	b.eq	0x10d6a4
  10d69c:	e0 17 40 f9	ldr	x0, [sp, #0x28]
  10d6a0:	23 18 08 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  10d6a4:	e8 87 40 f9	ldr	x8, [sp, #0x108]
  10d6a8:	1c 79 77 f8	ldr	x28, [x8, x23, lsl #3]
  10d6ac:	e0 03 1c aa	mov	x0, x28
  10d6b0:	e1 03 19 aa	mov	x1, x25
  10d6b4:	33 18 08 94	bl	0x313780 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
  10d6b8:	fd 03 1d aa	mov	x29, x29
  10d6bc:	49 18 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10d6c0:	f4 03 00 aa	mov	x20, x0
  10d6c4:	60 04 00 b4	cbz	x0, 0x10d750
  10d6c8:	e0 03 1c aa	mov	x0, x28
  10d6cc:	e1 03 19 aa	mov	x1, x25
  10d6d0:	2c 18 08 94	bl	0x313780 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
  10d6d4:	fd 03 1d aa	mov	x29, x29
  10d6d8:	42 18 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10d6dc:	f3 03 00 aa	mov	x19, x0
  10d6e0:	e1 03 1a aa	mov	x1, x26
  10d6e4:	27 18 08 94	bl	0x313780 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
  10d6e8:	f5 03 00 aa	mov	x21, x0
  10d6ec:	e0 03 13 aa	mov	x0, x19
  10d6f0:	30 18 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  10d6f4:	e0 03 14 aa	mov	x0, x20
  10d6f8:	2e 18 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  10d6fc:	f5 02 00 b4	cbz	x21, 0x10d758
  10d700:	e8 14 00 b0	adrp	x8, 669 ; 0x3aa000
  10d704:	00 81 45 f9	ldr	x0, [x8, #0xb00] ; Objc class ref: CBBridgeManager
  10d708:	e1 13 40 f9	ldr	x1, [sp, #0x20]
  10d70c:	1d 18 08 94	bl	0x313780 ; Objc message: +[CBBridgeManager sendStateToApp:shouldBridge:]
  10d710:	fd 03 1d aa	mov	x29, x29
  10d714:	33 18 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10d718:	f4 03 00 aa	mov	x20, x0
  10d71c:	e0 03 1c aa	mov	x0, x28
  10d720:	e1 03 19 aa	mov	x1, x25
  10d724:	17 18 08 94	bl	0x313780 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
  10d728:	fd 03 1d aa	mov	x29, x29
  10d72c:	2d 18 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  10d730:	f3 03 00 aa	mov	x19, x0
  10d734:	e0 03 14 aa	mov	x0, x20
  10d738:	e1 03 1b aa	mov	x1, x27
  10d73c:	e2 03 13 aa	mov	x2, x19
  10d740:	23 00 80 52	mov	w3, #0x1
  10d744:	0f 18 08 94	bl	0x313780 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
  10d748:	e0 03 13 aa	mov	x0, x19
  10d74c:	19 18 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  10d750:	e0 03 14 aa	mov	x0, x20
  10d754:	17 18 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  10d758:	f7 06 00 91	add	x23, x23, #0x1
  10d75c:	ff 02 18 eb	cmp	x23, x24
  10d760:	63 f9 ff 54	b.lo	0x10d68c
  10d764:	e2 03 04 91	add	x2, sp, #0x100
  10d768:	e3 03 02 91	add	x3, sp, #0x80
  10d76c:	e0 17 40 f9	ldr	x0, [sp, #0x28]
  10d770:	e1 0f 40 f9	ldr	x1, [sp, #0x18]
  10d774:	04 02 80 52	mov	w4, #0x10
  10d778:	02 18 08 94	bl	0x313780 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
~~~

### Original CBBridgedSplitApp::closeSlot: at 0x112318

~~~asm
  112318:	e9 23 b9 6d	stp	d9, d8, [sp, #-0x70]!
  11231c:	fc 6f 01 a9	stp	x28, x27, [sp, #0x10]
  112320:	fa 67 02 a9	stp	x26, x25, [sp, #0x20]
  112324:	f8 5f 03 a9	stp	x24, x23, [sp, #0x30]
  112328:	f6 57 04 a9	stp	x22, x21, [sp, #0x40]
  11232c:	f4 4f 05 a9	stp	x20, x19, [sp, #0x50]
  112330:	fd 7b 06 a9	stp	x29, x30, [sp, #0x60]
  112334:	fd 83 01 91	add	x29, sp, #0x60
  112338:	ff 03 07 d1	sub	sp, sp, #0x1c0
  11233c:	e8 12 00 d0	adrp	x8, 606 ; 0x370000
  112340:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
  112344:	08 01 40 f9	ldr	x8, [x8]
  112348:	a8 03 19 f8	stur	x8, [x29, #-0x70]
  11234c:	e2 28 f8 b7	tbnz	x2, #0x3f, 0x112868
  112350:	f4 03 02 aa	mov	x20, x2
  112354:	f8 03 00 aa	mov	x24, x0
  112358:	c8 14 00 b0	adrp	x8, 665 ; 0x3ab000
  11235c:	13 55 81 b9	ldrsw	x19, [x8, #0x154]
  112360:	00 68 73 f8	ldr	x0, [x0, x19]
  112364:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112368:	15 d1 41 f9	ldr	x21, [x8, #0x3a0] ; Objc selector ref: count
  11236c:	e1 03 15 aa	mov	x1, x21
  112370:	04 05 08 94	bl	0x313780 ; Objc message: -[x0 count]
  112374:	1f 00 14 eb	cmp	x0, x20
  112378:	89 27 00 54	b.ls	0x112868
  11237c:	c8 14 00 b0	adrp	x8, 665 ; 0x3ab000
  112380:	19 5d 81 b9	ldrsw	x25, [x8, #0x15c]
  112384:	00 6b 79 f8	ldr	x0, [x24, x25]
  112388:	e1 03 15 aa	mov	x1, x21
  11238c:	fd 04 08 94	bl	0x313780 ; Objc message: -[x0 count]
  112390:	1f 00 14 eb	cmp	x0, x20
  112394:	a9 26 00 54	b.ls	0x112868
  112398:	c8 14 00 b0	adrp	x8, 665 ; 0x3ab000
  11239c:	08 51 81 b9	ldrsw	x8, [x8, #0x150]
  1123a0:	09 6b 68 f8	ldr	x9, [x24, x8]
  1123a4:	29 0f f8 b7	tbnz	x9, #0x3f, 0x112588
  1123a8:	f3 57 01 a9	stp	x19, x21, [sp, #0x10]
  1123ac:	f4 63 02 a9	stp	x20, x24, [sp, #0x20]
  1123b0:	09 00 80 92	mov	x9, #-0x1
  1123b4:	09 6b 28 f8	str	x9, [x24, x8]
  1123b8:	00 e4 00 4f	movi.16b	v0, #0x0
  1123bc:	a0 83 3b ad	stp	q0, q0, [x29, #-0x90]
  1123c0:	a0 83 3a ad	stp	q0, q0, [x29, #-0xb0]
  1123c4:	f9 07 00 f9	str	x25, [sp, #0x8]
  1123c8:	00 6b 79 f8	ldr	x0, [x24, x25]
  1123cc:	fc 04 08 94	bl	0x3137bc ; symbol stub for: _objc_retain
  1123d0:	f7 03 00 aa	mov	x23, x0
  1123d4:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  1123d8:	16 d5 41 f9	ldr	x22, [x8, #0x3a8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
  1123dc:	a2 c3 02 d1	sub	x2, x29, #0xb0
  1123e0:	e3 c3 03 91	add	x3, sp, #0xf0
  1123e4:	e1 03 16 aa	mov	x1, x22
  1123e8:	04 02 80 52	mov	w4, #0x10
  1123ec:	e5 04 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  1123f0:	bc 14 00 d0	adrp	x28, 662 ; 0x3a8000
  1123f4:	80 05 00 b4	cbz	x0, 0x1124a4
  1123f8:	f8 03 00 aa	mov	x24, x0
  1123fc:	a8 03 56 f8	ldur	x8, [x29, #-0xa0]
  112400:	13 01 40 f9	ldr	x19, [x8]
  112404:	08 10 6e 1e	fmov	d8, #1.00000000
  112408:	15 00 80 d2	mov	x21, #0x0
  11240c:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112410:	19 a9 44 f9	ldr	x25, [x8, #0x950] ; Objc selector ref: setHidden:
  112414:	f4 03 1c aa	mov	x20, x28
  112418:	9a 1f 45 f9	ldr	x26, [x28, #0xa38]
  11241c:	1f 20 03 d5	nop
  112420:	1b 15 44 f9	ldr	x27, [x8, #0x828]
  112424:	a8 03 56 f8	ldur	x8, [x29, #-0xa0]
  112428:	08 01 40 f9	ldr	x8, [x8]
  11242c:	1f 01 13 eb	cmp	x8, x19
  112430:	60 00 00 54	b.eq	0x11243c
  112434:	e0 03 17 aa	mov	x0, x23
  112438:	bd 04 08 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  11243c:	a8 83 55 f8	ldur	x8, [x29, #-0xa8]
  112440:	1c 79 75 f8	ldr	x28, [x8, x21, lsl #3]
  112444:	e0 03 1c aa	mov	x0, x28
  112448:	e1 03 19 aa	mov	x1, x25
  11244c:	02 00 80 52	mov	w2, #0x0
  112450:	cc 04 08 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
  112454:	e0 03 1c aa	mov	x0, x28
  112458:	e1 03 1a aa	mov	x1, x26
  11245c:	00 1d a8 4e	mov.16b	v0, v8
  112460:	c8 04 08 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
  112464:	e0 03 1c aa	mov	x0, x28
  112468:	e1 03 1b aa	mov	x1, x27
  11246c:	22 00 80 52	mov	w2, #0x1
  112470:	c4 04 08 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
  112474:	b5 06 00 91	add	x21, x21, #0x1
  112478:	bf 02 18 eb	cmp	x21, x24
  11247c:	43 fd ff 54	b.lo	0x112424
  112480:	a2 c3 02 d1	sub	x2, x29, #0xb0
  112484:	e3 c3 03 91	add	x3, sp, #0xf0
  112488:	e0 03 17 aa	mov	x0, x23
  11248c:	e1 03 16 aa	mov	x1, x22
  112490:	04 02 80 52	mov	w4, #0x10
  112494:	bb 04 08 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
  112498:	f8 03 00 aa	mov	x24, x0
  11249c:	fc 03 14 aa	mov	x28, x20
  1124a0:	40 fb ff b5	cbnz	x0, 0x112408
  1124a4:	e0 03 17 aa	mov	x0, x23
  1124a8:	c2 04 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  1124ac:	00 e4 00 4f	movi.16b	v0, #0x0
  1124b0:	e0 83 06 ad	stp	q0, q0, [sp, #0xd0]
  1124b4:	e0 83 05 ad	stp	q0, q0, [sp, #0xb0]
  1124b8:	c8 14 00 b0	adrp	x8, 665 ; 0x3ab000
  1124bc:	08 61 81 b9	ldrsw	x8, [x8, #0x160]
  1124c0:	e9 17 40 f9	ldr	x9, [sp, #0x28]
  1124c4:	20 69 68 f8	ldr	x0, [x9, x8]
  1124c8:	bd 04 08 94	bl	0x3137bc ; symbol stub for: _objc_retain
  1124cc:	f7 03 00 aa	mov	x23, x0
  1124d0:	e2 c3 02 91	add	x2, sp, #0xb0
  1124d4:	e3 c3 00 91	add	x3, sp, #0x30
  1124d8:	e1 03 16 aa	mov	x1, x22
  1124dc:	04 02 80 52	mov	w4, #0x10
  1124e0:	a8 04 08 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
  1124e4:	f5 0f 40 f9	ldr	x21, [sp, #0x18]
  1124e8:	80 04 00 b4	cbz	x0, 0x112578
  1124ec:	f8 03 00 aa	mov	x24, x0
  1124f0:	e8 63 40 f9	ldr	x8, [sp, #0xc0]
  1124f4:	13 01 40 f9	ldr	x19, [x8]
  1124f8:	08 10 6e 1e	fmov	d8, #1.00000000
  1124fc:	14 00 80 d2	mov	x20, #0x0
  112500:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112504:	19 a9 44 f9	ldr	x25, [x8, #0x950] ; Objc selector ref: setHidden:
  112508:	9a 1f 45 f9	ldr	x26, [x28, #0xa38]
  11250c:	e8 63 40 f9	ldr	x8, [sp, #0xc0]
  112510:	08 01 40 f9	ldr	x8, [x8]
  112514:	1f 01 13 eb	cmp	x8, x19
  112518:	60 00 00 54	b.eq	0x112524
  11251c:	e0 03 17 aa	mov	x0, x23
  112520:	83 04 08 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  112524:	e8 5f 40 f9	ldr	x8, [sp, #0xb8]
  112528:	1b 79 74 f8	ldr	x27, [x8, x20, lsl #3]
  11252c:	e0 03 1b aa	mov	x0, x27
  112530:	e1 03 19 aa	mov	x1, x25
  112534:	02 00 80 52	mov	w2, #0x0
  112538:	92 04 08 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
  11253c:	e0 03 1b aa	mov	x0, x27
  112540:	e1 03 1a aa	mov	x1, x26
  112544:	00 1d a8 4e	mov.16b	v0, v8
  112548:	8e 04 08 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
  11254c:	94 06 00 91	add	x20, x20, #0x1
  112550:	9f 02 18 eb	cmp	x20, x24
  112554:	c3 fd ff 54	b.lo	0x11250c
  112558:	e2 c3 02 91	add	x2, sp, #0xb0
  11255c:	e3 c3 00 91	add	x3, sp, #0x30
  112560:	e0 03 17 aa	mov	x0, x23
  112564:	e1 03 16 aa	mov	x1, x22
  112568:	04 02 80 52	mov	w4, #0x10
  11256c:	85 04 08 94	bl	0x313780 ; Objc message: -[x0 setHidden:]
  112570:	f8 03 00 aa	mov	x24, x0
  112574:	40 fc ff b5	cbnz	x0, 0x1124fc
  112578:	e0 03 17 aa	mov	x0, x23
  11257c:	8d 04 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112580:	f4 63 42 a9	ldp	x20, x24, [sp, #0x20]
  112584:	f9 cf 40 a9	ldp	x25, x19, [sp, #0x8]
  112588:	00 6b 73 f8	ldr	x0, [x24, x19]
  11258c:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112590:	1b b5 44 f9	ldr	x27, [x8, #0x968] ; Objc selector ref: objectAtIndexedSubscript:
  112594:	e1 03 1b aa	mov	x1, x27
  112598:	e2 03 14 aa	mov	x2, x20
  11259c:	79 04 08 94	bl	0x313780 ; Objc message: -[x0 objectAtIndexedSubscript:]
  1125a0:	fd 03 1d aa	mov	x29, x29
  1125a4:	8f 04 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1125a8:	f6 03 00 aa	mov	x22, x0
  1125ac:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  1125b0:	01 cd 40 f9	ldr	x1, [x8, #0x198] ; Objc selector ref: bundleIdentifier
  1125b4:	73 04 08 94	bl	0x313780 ; Objc message: -[x0 bundleIdentifier]
  1125b8:	fd 03 1d aa	mov	x29, x29
  1125bc:	89 04 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1125c0:	f7 03 00 aa	mov	x23, x0
  1125c4:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  1125c8:	01 25 42 f9	ldr	x1, [x8, #0x448] ; Objc selector ref: copy
  1125cc:	6d 04 08 94	bl	0x313780 ; Objc message: -[x0 copy]
  1125d0:	fa 03 00 aa	mov	x26, x0
  1125d4:	e0 03 17 aa	mov	x0, x23
  1125d8:	76 04 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  1125dc:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  1125e0:	01 95 47 f9	ldr	x1, [x8, #0xf28] ; Objc selector ref: dismiss
  1125e4:	e0 03 16 aa	mov	x0, x22
  1125e8:	66 04 08 94	bl	0x313780 ; Objc message: -[x0 dismiss]
  1125ec:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  1125f0:	01 29 45 f9	ldr	x1, [x8, #0xa50] ; Objc selector ref: removeFromSuperview
  1125f4:	f6 17 00 f9	str	x22, [sp, #0x28]
  1125f8:	e0 03 16 aa	mov	x0, x22
  1125fc:	61 04 08 94	bl	0x313780 ; Objc message: -[x0 removeFromSuperview]
  112600:	d6 14 00 90	adrp	x22, 664 ; 0x3aa000
  112604:	b7 14 00 d0	adrp	x23, 662 ; 0x3a8000
  112608:	7a 02 00 b4	cbz	x26, 0x112654
  11260c:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112610:	01 75 41 f9	ldr	x1, [x8, #0x2e8] ; Objc selector ref: length
  112614:	e0 03 1a aa	mov	x0, x26
  112618:	5a 04 08 94	bl	0x313780 ; Objc message: -[x0 length]
  11261c:	c0 01 00 b4	cbz	x0, 0x112654
  112620:	c0 82 45 f9	ldr	x0, [x22, #0xb00]
  112624:	e1 52 41 f9	ldr	x1, [x23, #0x2a0]
  112628:	56 04 08 94	bl	0x313780 ; Objc message: -[x0 length]
  11262c:	fd 03 1d aa	mov	x29, x29
  112630:	6c 04 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  112634:	f7 03 00 aa	mov	x23, x0
  112638:	a8 14 00 f0	adrp	x8, 663 ; 0x3a9000
  11263c:	01 29 43 f9	ldr	x1, [x8, #0x650] ; Objc selector ref: sendStateToApp:shouldBridge:
  112640:	e2 03 1a aa	mov	x2, x26
  112644:	03 00 80 52	mov	w3, #0x0
  112648:	4e 04 08 94	bl	0x313780 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
  11264c:	e0 03 17 aa	mov	x0, x23
  112650:	58 04 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112654:	fb eb 01 a9	stp	x27, x26, [sp, #0x18]
  112658:	00 6b 79 f8	ldr	x0, [x24, x25]
  11265c:	e1 03 1b aa	mov	x1, x27
  112660:	e2 03 14 aa	mov	x2, x20
  112664:	47 04 08 94	bl	0x313780 ; Objc message: -[x0 sendStateToApp:shouldBridge:]
  112668:	fd 03 1d aa	mov	x29, x29
  11266c:	5d 04 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  112670:	f9 03 00 aa	mov	x25, x0
  112674:	c8 14 00 90	adrp	x8, 664 ; 0x3aa000
  112678:	00 09 46 f9	ldr	x0, [x8, #0xc10] ; Objc class ref: CBBridgedUIAppView
  11267c:	0b 04 08 94	bl	0x3136a8 ; symbol stub for: _objc_alloc
  112680:	a8 14 00 f0	adrp	x8, 663 ; 0x3a9000
  112684:	01 45 42 f9	ldr	x1, [x8, #0x488] ; Objc selector ref: initWithBundleIdentifier:
~~~

### Original CBBridgedSplitApp::closeAllSlots at 0x1128a8

~~~asm
  1128a8:	ff c3 03 d1	sub	sp, sp, #0xf0
  1128ac:	fc 6f 09 a9	stp	x28, x27, [sp, #0x90]
  1128b0:	fa 67 0a a9	stp	x26, x25, [sp, #0xa0]
  1128b4:	f8 5f 0b a9	stp	x24, x23, [sp, #0xb0]
  1128b8:	f6 57 0c a9	stp	x22, x21, [sp, #0xc0]
  1128bc:	f4 4f 0d a9	stp	x20, x19, [sp, #0xd0]
  1128c0:	fd 7b 0e a9	stp	x29, x30, [sp, #0xe0]
  1128c4:	fd 83 03 91	add	x29, sp, #0xe0
  1128c8:	f3 03 00 aa	mov	x19, x0
  1128cc:	c8 14 00 b0	adrp	x8, 665 ; 0x3ab000
  1128d0:	08 51 81 b9	ldrsw	x8, [x8, #0x150]
  1128d4:	09 00 80 92	mov	x9, #-0x1
  1128d8:	09 68 28 f8	str	x9, [x0, x8]
  1128dc:	c8 14 00 b0	adrp	x8, 665 ; 0x3ab000
  1128e0:	16 55 81 b9	ldrsw	x22, [x8, #0x154]
  1128e4:	00 68 76 f8	ldr	x0, [x0, x22]
  1128e8:	b7 14 00 d0	adrp	x23, 662 ; 0x3a8000
  1128ec:	f5 d2 41 f9	ldr	x21, [x23, #0x3a0] ; Objc selector ref: count
  1128f0:	e1 03 15 aa	mov	x1, x21
  1128f4:	a3 03 08 94	bl	0x313780 ; Objc message: -[x0 count]
  1128f8:	80 19 00 b4	cbz	x0, 0x112c28
  1128fc:	14 00 80 d2	mov	x20, #0x0
  112900:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112904:	1a b5 44 f9	ldr	x26, [x8, #0x968] ; Objc selector ref: objectAtIndexedSubscript:
  112908:	1f 20 03 d5	nop
  11290c:	09 cd 40 f9	ldr	x9, [x8, #0x198]
  112910:	1f 20 03 d5	nop
  112914:	08 25 42 f9	ldr	x8, [x8, #0x448]
  112918:	a8 a7 39 a9	stp	x8, x9, [x29, #-0x68]
  11291c:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112920:	09 95 47 f9	ldr	x9, [x8, #0xf28] ; Objc selector ref: dismiss
  112924:	1f 20 03 d5	nop
  112928:	08 29 45 f9	ldr	x8, [x8, #0xa50]
  11292c:	e8 a7 06 a9	stp	x8, x9, [sp, #0x68]
  112930:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112934:	08 75 41 f9	ldr	x8, [x8, #0x2e8] ; Objc selector ref: length
  112938:	e8 33 00 f9	str	x8, [sp, #0x60]
  11293c:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112940:	19 51 41 f9	ldr	x25, [x8, #0x2a0] ; Objc selector ref: sharedInstance
  112944:	a8 14 00 f0	adrp	x8, 663 ; 0x3a9000
  112948:	09 29 43 f9	ldr	x9, [x8, #0x650] ; Objc selector ref: sendStateToApp:shouldBridge:
  11294c:	1f 20 03 d5	nop
  112950:	0a 45 42 f9	ldr	x10, [x8, #0x488]
  112954:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112958:	0b 85 43 f9	ldr	x11, [x8, #0x708] ; Objc selector ref: bounds
  11295c:	1f 20 03 d5	nop
  112960:	08 fd 43 f9	ldr	x8, [x8, #0x7f8]
  112964:	e8 af 04 a9	stp	x8, x11, [sp, #0x48]
  112968:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  11296c:	08 a9 44 f9	ldr	x8, [x8, #0x950] ; Objc selector ref: setHidden:
  112970:	e9 a3 03 a9	stp	x9, x8, [sp, #0x38]
  112974:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112978:	08 a5 43 f9	ldr	x8, [x8, #0x748] ; Objc selector ref: setAutoresizingMask:
  11297c:	e8 2b 02 a9	stp	x8, x10, [sp, #0x20]
  112980:	a8 14 00 f0	adrp	x8, 663 ; 0x3a9000
  112984:	09 4d 43 f9	ldr	x9, [x8, #0x698] ; Objc selector ref: insertSubview:atIndex:
  112988:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  11298c:	08 71 46 f9	ldr	x8, [x8, #0xce0] ; Objc selector ref: setObject:atIndexedSubscript:
  112990:	e8 27 01 a9	stp	x8, x9, [sp, #0x10]
  112994:	a8 14 00 d0	adrp	x8, 662 ; 0x3a8000
  112998:	c9 14 00 b0	adrp	x9, 665 ; 0x3ab000
  11299c:	08 fd 45 f9	ldr	x8, [x8, #0xbf8]
  1129a0:	e8 07 00 f9	str	x8, [sp, #0x8]
  1129a4:	fc d2 41 f9	ldr	x28, [x23, #0x3a0]
  1129a8:	28 5d 81 b9	ldrsw	x8, [x9, #0x15c]
  1129ac:	a8 83 1a f8	stur	x8, [x29, #-0x58]
  1129b0:	f9 1b 00 f9	str	x25, [sp, #0x30]
  1129b4:	fa 2f 00 f9	str	x26, [sp, #0x58]
  1129b8:	60 6a 76 f8	ldr	x0, [x19, x22]
  1129bc:	e1 03 1a aa	mov	x1, x26
  1129c0:	e2 03 14 aa	mov	x2, x20
  1129c4:	6f 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  1129c8:	fd 03 1d aa	mov	x29, x29
  1129cc:	85 03 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1129d0:	fb 03 00 aa	mov	x27, x0
  1129d4:	a1 03 5a f8	ldur	x1, [x29, #-0x60]
  1129d8:	6a 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  1129dc:	fd 03 1d aa	mov	x29, x29
  1129e0:	80 03 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  1129e4:	f8 03 00 aa	mov	x24, x0
  1129e8:	a1 83 59 f8	ldur	x1, [x29, #-0x68]
  1129ec:	65 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  1129f0:	f7 03 00 aa	mov	x23, x0
  1129f4:	e0 03 18 aa	mov	x0, x24
  1129f8:	6e 03 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  1129fc:	e0 03 1b aa	mov	x0, x27
  112a00:	e1 3b 40 f9	ldr	x1, [sp, #0x70]
  112a04:	5f 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112a08:	e0 03 1b aa	mov	x0, x27
  112a0c:	e1 37 40 f9	ldr	x1, [sp, #0x68]
  112a10:	5c 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112a14:	57 02 00 b4	cbz	x23, 0x112a5c
  112a18:	e0 03 17 aa	mov	x0, x23
  112a1c:	e1 33 40 f9	ldr	x1, [sp, #0x60]
  112a20:	58 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112a24:	c0 01 00 b4	cbz	x0, 0x112a5c
  112a28:	c8 14 00 90	adrp	x8, 664 ; 0x3aa000
  112a2c:	00 81 45 f9	ldr	x0, [x8, #0xb00] ; Objc class ref: CBBridgeManager
  112a30:	e1 03 19 aa	mov	x1, x25
  112a34:	53 03 08 94	bl	0x313780 ; Objc message: +[CBBridgeManager setObject:atIndexedSubscript:]
  112a38:	fd 03 1d aa	mov	x29, x29
  112a3c:	69 03 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  112a40:	f8 03 00 aa	mov	x24, x0
  112a44:	e1 1f 40 f9	ldr	x1, [sp, #0x38]
  112a48:	e2 03 17 aa	mov	x2, x23
  112a4c:	03 00 80 52	mov	w3, #0x0
  112a50:	4c 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112a54:	e0 03 18 aa	mov	x0, x24
  112a58:	56 03 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112a5c:	a8 83 5a f8	ldur	x8, [x29, #-0x58]
  112a60:	60 6a 68 f8	ldr	x0, [x19, x8]
  112a64:	e1 03 15 aa	mov	x1, x21
  112a68:	46 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112a6c:	9f 02 00 eb	cmp	x20, x0
  112a70:	42 0c 00 54	b.hs	0x112bf8
  112a74:	a8 83 5a f8	ldur	x8, [x29, #-0x58]
  112a78:	60 6a 68 f8	ldr	x0, [x19, x8]
  112a7c:	e1 03 1a aa	mov	x1, x26
  112a80:	e2 03 14 aa	mov	x2, x20
  112a84:	3f 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112a88:	fd 03 1d aa	mov	x29, x29
  112a8c:	55 03 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  112a90:	40 0b 00 b4	cbz	x0, 0x112bf8
  112a94:	f8 03 00 aa	mov	x24, x0
  112a98:	c8 14 00 90	adrp	x8, 664 ; 0x3aa000
  112a9c:	00 09 46 f9	ldr	x0, [x8, #0xc10] ; Objc class ref: CBBridgedUIAppView
  112aa0:	02 03 08 94	bl	0x3136a8 ; symbol stub for: _objc_alloc
  112aa4:	e1 17 40 f9	ldr	x1, [sp, #0x28]
  112aa8:	02 13 00 90	adrp	x2, 608 ; 0x372000
  112aac:	42 80 2f 91	add	x2, x2, #0xbe0 ; Objc cfstring ref: @""
  112ab0:	34 03 08 94	bl	0x313780 ; Objc message: +[CBBridgedUIAppView setObject:atIndexedSubscript:]
  112ab4:	f9 03 00 aa	mov	x25, x0
  112ab8:	e0 03 18 aa	mov	x0, x24
  112abc:	e1 2b 40 f9	ldr	x1, [sp, #0x50]
  112ac0:	30 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112ac4:	e0 03 19 aa	mov	x0, x25
  112ac8:	e1 27 40 f9	ldr	x1, [sp, #0x48]
  112acc:	2d 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112ad0:	e0 03 19 aa	mov	x0, x25
  112ad4:	e1 23 40 f9	ldr	x1, [sp, #0x40]
  112ad8:	22 00 80 52	mov	w2, #0x1
  112adc:	29 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112ae0:	e0 03 19 aa	mov	x0, x25
  112ae4:	e1 13 40 f9	ldr	x1, [sp, #0x20]
  112ae8:	42 02 80 52	mov	w2, #0x12
  112aec:	25 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112af0:	e0 03 18 aa	mov	x0, x24
  112af4:	e1 0f 40 f9	ldr	x1, [sp, #0x18]
  112af8:	e2 03 19 aa	mov	x2, x25
  112afc:	03 00 80 d2	mov	x3, #0x0
  112b00:	20 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112b04:	60 6a 76 f8	ldr	x0, [x19, x22]
  112b08:	e1 0b 40 f9	ldr	x1, [sp, #0x10]
  112b0c:	e2 03 19 aa	mov	x2, x25
  112b10:	e3 03 14 aa	mov	x3, x20
  112b14:	1b 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112b18:	c8 14 00 b0	adrp	x8, 665 ; 0x3ab000
  112b1c:	1a 59 81 b9	ldrsw	x26, [x8, #0x158]
  112b20:	60 6a 7a f8	ldr	x0, [x19, x26]
  112b24:	e1 03 15 aa	mov	x1, x21
  112b28:	16 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112b2c:	9f 02 00 eb	cmp	x20, x0
  112b30:	02 03 00 54	b.hs	0x112b90
  112b34:	60 6a 7a f8	ldr	x0, [x19, x26]
  112b38:	e1 2f 40 f9	ldr	x1, [sp, #0x58]
  112b3c:	e2 03 14 aa	mov	x2, x20
  112b40:	10 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112b44:	fd 03 1d aa	mov	x29, x29
  112b48:	26 03 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  112b4c:	fa 03 00 aa	mov	x26, x0
  112b50:	e0 03 18 aa	mov	x0, x24
  112b54:	e1 2b 40 f9	ldr	x1, [sp, #0x50]
  112b58:	0a 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112b5c:	e0 03 1a aa	mov	x0, x26
  112b60:	e1 27 40 f9	ldr	x1, [sp, #0x48]
  112b64:	07 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112b68:	e0 03 1a aa	mov	x0, x26
  112b6c:	e1 23 40 f9	ldr	x1, [sp, #0x40]
  112b70:	02 00 80 52	mov	w2, #0x0
  112b74:	03 03 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112b78:	e0 03 18 aa	mov	x0, x24
  112b7c:	e1 07 40 f9	ldr	x1, [sp, #0x8]
  112b80:	e2 03 1a aa	mov	x2, x26
  112b84:	ff 02 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112b88:	e0 03 1a aa	mov	x0, x26
  112b8c:	09 03 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112b90:	c8 14 00 b0	adrp	x8, 665 ; 0x3ab000
  112b94:	1a 65 81 b9	ldrsw	x26, [x8, #0x164]
  112b98:	60 6a 7a f8	ldr	x0, [x19, x26]
  112b9c:	e1 03 15 aa	mov	x1, x21
  112ba0:	f8 02 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112ba4:	9f 02 00 eb	cmp	x20, x0
  112ba8:	c2 01 00 54	b.hs	0x112be0
  112bac:	60 6a 7a f8	ldr	x0, [x19, x26]
  112bb0:	e1 2f 40 f9	ldr	x1, [sp, #0x58]
  112bb4:	e2 03 14 aa	mov	x2, x20
  112bb8:	f2 02 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112bbc:	fd 03 1d aa	mov	x29, x29
  112bc0:	08 03 08 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  112bc4:	f5 03 00 aa	mov	x21, x0
  112bc8:	e0 03 18 aa	mov	x0, x24
  112bcc:	e1 07 40 f9	ldr	x1, [sp, #0x8]
  112bd0:	e2 03 15 aa	mov	x2, x21
  112bd4:	eb 02 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
  112bd8:	e0 03 15 aa	mov	x0, x21
  112bdc:	f5 02 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112be0:	e0 03 19 aa	mov	x0, x25
  112be4:	f3 02 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112be8:	e0 03 18 aa	mov	x0, x24
  112bec:	f1 02 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112bf0:	f9 1b 40 f9	ldr	x25, [sp, #0x30]
  112bf4:	fa 2f 40 f9	ldr	x26, [sp, #0x58]
  112bf8:	e0 03 17 aa	mov	x0, x23
  112bfc:	ed 02 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112c00:	e0 03 1b aa	mov	x0, x27
  112c04:	eb 02 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  112c08:	94 06 00 91	add	x20, x20, #0x1
  112c0c:	60 6a 76 f8	ldr	x0, [x19, x22]
  112c10:	e1 03 1c aa	mov	x1, x28
  112c14:	db 02 08 94	bl	0x313780 ; Objc message: -[x0 setObject:atIndexedSubscript:]
~~~

### Original CBBridgedSplitApp::stop at 0x1136dc

~~~asm
  1136dc:	fc 6f ba a9	stp	x28, x27, [sp, #-0x60]!
  1136e0:	fa 67 01 a9	stp	x26, x25, [sp, #0x10]
  1136e4:	f8 5f 02 a9	stp	x24, x23, [sp, #0x20]
  1136e8:	f6 57 03 a9	stp	x22, x21, [sp, #0x30]
  1136ec:	f4 4f 04 a9	stp	x20, x19, [sp, #0x40]
  1136f0:	fd 7b 05 a9	stp	x29, x30, [sp, #0x50]
  1136f4:	fd 43 01 91	add	x29, sp, #0x50
  1136f8:	ff 43 0f d1	sub	sp, sp, #0x3d0
  1136fc:	f3 03 00 aa	mov	x19, x0
  113700:	e8 12 00 b0	adrp	x8, 605 ; 0x370000
  113704:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
  113708:	08 01 40 f9	ldr	x8, [x8]
  11370c:	a8 03 1a f8	stur	x8, [x29, #-0x60]
  113710:	a8 14 00 d0	adrp	x8, 662 ; 0x3a9000
  113714:	01 79 43 f9	ldr	x1, [x8, #0x6f0] ; Objc selector ref: stopBlinkingSession
  113718:	1a 00 08 94	bl	0x313780 ; Objc message: -[x0 stopBlinkingSession]
  11371c:	c8 14 00 90	adrp	x8, 664 ; 0x3ab000
  113720:	14 69 81 b9	ldrsw	x20, [x8, #0x168]
  113724:	60 6a 74 f8	ldr	x0, [x19, x20]
  113728:	b9 14 00 b0	adrp	x25, 661 ; 0x3a8000
  11372c:	c0 00 00 b4	cbz	x0, 0x113744
  113730:	21 2b 45 f9	ldr	x1, [x25, #0xa50]
  113734:	13 00 08 94	bl	0x313780 ; Objc message: -[x0 stopBlinkingSession]
  113738:	60 6a 74 f8	ldr	x0, [x19, x20]
  11373c:	7f 6a 34 f8	str	xzr, [x19, x20]
  113740:	1c 00 08 94	bl	0x3137b0 ; symbol stub for: _objc_release
  113744:	00 e4 00 4f	movi.16b	v0, #0x0
  113748:	a0 03 3c ad	stp	q0, q0, [x29, #-0x80]
  11374c:	a0 03 3b ad	stp	q0, q0, [x29, #-0xa0]
  113750:	c8 14 00 90	adrp	x8, 664 ; 0x3ab000
  113754:	18 55 81 b9	ldrsw	x24, [x8, #0x154]
  113758:	60 6a 78 f8	ldr	x0, [x19, x24]
  11375c:	18 00 08 94	bl	0x3137bc ; symbol stub for: _objc_retain
  113760:	f5 03 00 aa	mov	x21, x0
  113764:	a8 14 00 b0	adrp	x8, 661 ; 0x3a8000
  113768:	14 d5 41 f9	ldr	x20, [x8, #0x3a8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
  11376c:	a2 83 02 d1	sub	x2, x29, #0xa0
  113770:	e3 03 0c 91	add	x3, sp, #0x300
  113774:	e1 03 14 aa	mov	x1, x20
  113778:	04 02 80 52	mov	w4, #0x10
  11377c:	01 00 08 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  113780:	80 03 00 b4	cbz	x0, 0x1137f0
  113784:	f6 03 00 aa	mov	x22, x0
  113788:	a8 03 57 f8	ldur	x8, [x29, #-0x90]
  11378c:	1a 01 40 f9	ldr	x26, [x8]
  113790:	bb 14 00 b0	adrp	x27, 661 ; 0x3a8000
  113794:	1c 00 80 d2	mov	x28, #0x0
  113798:	77 97 47 f9	ldr	x23, [x27, #0xf28]
  11379c:	a8 03 57 f8	ldur	x8, [x29, #-0x90]
  1137a0:	08 01 40 f9	ldr	x8, [x8]
  1137a4:	1f 01 1a eb	cmp	x8, x26
  1137a8:	60 00 00 54	b.eq	0x1137b4
  1137ac:	e0 03 15 aa	mov	x0, x21
  1137b0:	df ff 07 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  1137b4:	a8 83 56 f8	ldur	x8, [x29, #-0x98]
  1137b8:	00 79 7c f8	ldr	x0, [x8, x28, lsl #3]
  1137bc:	e1 03 17 aa	mov	x1, x23
  1137c0:	f0 ff 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  1137c4:	9c 07 00 91	add	x28, x28, #0x1
  1137c8:	9f 03 16 eb	cmp	x28, x22
  1137cc:	83 fe ff 54	b.lo	0x11379c
  1137d0:	a2 83 02 d1	sub	x2, x29, #0xa0
  1137d4:	e3 03 0c 91	add	x3, sp, #0x300
  1137d8:	e0 03 15 aa	mov	x0, x21
  1137dc:	e1 03 14 aa	mov	x1, x20
  1137e0:	04 02 80 52	mov	w4, #0x10
  1137e4:	e7 ff 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  1137e8:	f6 03 00 aa	mov	x22, x0
  1137ec:	40 fd ff b5	cbnz	x0, 0x113794
  1137f0:	e0 03 15 aa	mov	x0, x21
  1137f4:	ef ff 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  1137f8:	60 6a 78 f8	ldr	x0, [x19, x24]
  1137fc:	a8 14 00 d0	adrp	x8, 662 ; 0x3a9000
  113800:	15 7d 42 f9	ldr	x21, [x8, #0x4f8] ; Objc selector ref: removeAllObjects
  113804:	e1 03 15 aa	mov	x1, x21
  113808:	de ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  11380c:	00 e4 00 4f	movi.16b	v0, #0x0
  113810:	e0 03 17 ad	stp	q0, q0, [sp, #0x2e0]
  113814:	e0 03 16 ad	stp	q0, q0, [sp, #0x2c0]
  113818:	c8 14 00 90	adrp	x8, 664 ; 0x3ab000
  11381c:	1a 59 81 b9	ldrsw	x26, [x8, #0x158]
  113820:	60 6a 7a f8	ldr	x0, [x19, x26]
  113824:	e6 ff 07 94	bl	0x3137bc ; symbol stub for: _objc_retain
  113828:	f6 03 00 aa	mov	x22, x0
  11382c:	e2 03 0b 91	add	x2, sp, #0x2c0
  113830:	e3 03 09 91	add	x3, sp, #0x240
  113834:	e1 03 14 aa	mov	x1, x20
  113838:	04 02 80 52	mov	w4, #0x10
  11383c:	d1 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  113840:	60 03 00 b4	cbz	x0, 0x1138ac
  113844:	f7 03 00 aa	mov	x23, x0
  113848:	e8 6b 41 f9	ldr	x8, [sp, #0x2d0]
  11384c:	1b 01 40 f9	ldr	x27, [x8]
  113850:	1c 00 80 d2	mov	x28, #0x0
  113854:	38 2b 45 f9	ldr	x24, [x25, #0xa50]
  113858:	e8 6b 41 f9	ldr	x8, [sp, #0x2d0]
  11385c:	08 01 40 f9	ldr	x8, [x8]
  113860:	1f 01 1b eb	cmp	x8, x27
  113864:	60 00 00 54	b.eq	0x113870
  113868:	e0 03 16 aa	mov	x0, x22
  11386c:	b0 ff 07 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  113870:	e8 67 41 f9	ldr	x8, [sp, #0x2c8]
  113874:	00 79 7c f8	ldr	x0, [x8, x28, lsl #3]
  113878:	e1 03 18 aa	mov	x1, x24
  11387c:	c1 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  113880:	9c 07 00 91	add	x28, x28, #0x1
  113884:	9f 03 17 eb	cmp	x28, x23
  113888:	83 fe ff 54	b.lo	0x113858
  11388c:	e2 03 0b 91	add	x2, sp, #0x2c0
  113890:	e3 03 09 91	add	x3, sp, #0x240
  113894:	e0 03 16 aa	mov	x0, x22
  113898:	e1 03 14 aa	mov	x1, x20
  11389c:	04 02 80 52	mov	w4, #0x10
  1138a0:	b8 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  1138a4:	f7 03 00 aa	mov	x23, x0
  1138a8:	40 fd ff b5	cbnz	x0, 0x113850
  1138ac:	e0 03 16 aa	mov	x0, x22
  1138b0:	c0 ff 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  1138b4:	60 6a 7a f8	ldr	x0, [x19, x26]
  1138b8:	e1 03 15 aa	mov	x1, x21
  1138bc:	b1 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  1138c0:	00 e4 00 4f	movi.16b	v0, #0x0
  1138c4:	e0 03 11 ad	stp	q0, q0, [sp, #0x220]
  1138c8:	e0 03 10 ad	stp	q0, q0, [sp, #0x200]
  1138cc:	c8 14 00 90	adrp	x8, 664 ; 0x3ab000
  1138d0:	1a 5d 81 b9	ldrsw	x26, [x8, #0x15c]
  1138d4:	60 6a 7a f8	ldr	x0, [x19, x26]
  1138d8:	b9 ff 07 94	bl	0x3137bc ; symbol stub for: _objc_retain
  1138dc:	f6 03 00 aa	mov	x22, x0
  1138e0:	e2 03 08 91	add	x2, sp, #0x200
  1138e4:	e3 03 06 91	add	x3, sp, #0x180
  1138e8:	e1 03 14 aa	mov	x1, x20
  1138ec:	04 02 80 52	mov	w4, #0x10
  1138f0:	a4 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  1138f4:	60 03 00 b4	cbz	x0, 0x113960
  1138f8:	f7 03 00 aa	mov	x23, x0
  1138fc:	e8 0b 41 f9	ldr	x8, [sp, #0x210]
  113900:	1b 01 40 f9	ldr	x27, [x8]
  113904:	1c 00 80 d2	mov	x28, #0x0
  113908:	38 2b 45 f9	ldr	x24, [x25, #0xa50]
  11390c:	e8 0b 41 f9	ldr	x8, [sp, #0x210]
  113910:	08 01 40 f9	ldr	x8, [x8]
  113914:	1f 01 1b eb	cmp	x8, x27
  113918:	60 00 00 54	b.eq	0x113924
  11391c:	e0 03 16 aa	mov	x0, x22
  113920:	83 ff 07 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  113924:	e8 07 41 f9	ldr	x8, [sp, #0x208]
  113928:	00 79 7c f8	ldr	x0, [x8, x28, lsl #3]
  11392c:	e1 03 18 aa	mov	x1, x24
  113930:	94 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  113934:	9c 07 00 91	add	x28, x28, #0x1
  113938:	9f 03 17 eb	cmp	x28, x23
  11393c:	83 fe ff 54	b.lo	0x11390c
  113940:	e2 03 08 91	add	x2, sp, #0x200
  113944:	e3 03 06 91	add	x3, sp, #0x180
  113948:	e0 03 16 aa	mov	x0, x22
  11394c:	e1 03 14 aa	mov	x1, x20
  113950:	04 02 80 52	mov	w4, #0x10
  113954:	8b ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  113958:	f7 03 00 aa	mov	x23, x0
  11395c:	40 fd ff b5	cbnz	x0, 0x113904
  113960:	e0 03 16 aa	mov	x0, x22
  113964:	93 ff 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  113968:	60 6a 7a f8	ldr	x0, [x19, x26]
  11396c:	e1 03 15 aa	mov	x1, x21
  113970:	84 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  113974:	00 e4 00 4f	movi.16b	v0, #0x0
  113978:	e0 03 0b ad	stp	q0, q0, [sp, #0x160]
  11397c:	e0 03 0a ad	stp	q0, q0, [sp, #0x140]
  113980:	c8 14 00 90	adrp	x8, 664 ; 0x3ab000
  113984:	1a 61 81 b9	ldrsw	x26, [x8, #0x160]
  113988:	60 6a 7a f8	ldr	x0, [x19, x26]
  11398c:	8c ff 07 94	bl	0x3137bc ; symbol stub for: _objc_retain
  113990:	f6 03 00 aa	mov	x22, x0
  113994:	e2 03 05 91	add	x2, sp, #0x140
  113998:	e3 03 03 91	add	x3, sp, #0xc0
  11399c:	e1 03 14 aa	mov	x1, x20
  1139a0:	04 02 80 52	mov	w4, #0x10
  1139a4:	77 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  1139a8:	60 03 00 b4	cbz	x0, 0x113a14
  1139ac:	f7 03 00 aa	mov	x23, x0
  1139b0:	e8 ab 40 f9	ldr	x8, [sp, #0x150]
  1139b4:	1b 01 40 f9	ldr	x27, [x8]
  1139b8:	1c 00 80 d2	mov	x28, #0x0
  1139bc:	38 2b 45 f9	ldr	x24, [x25, #0xa50]
  1139c0:	e8 ab 40 f9	ldr	x8, [sp, #0x150]
  1139c4:	08 01 40 f9	ldr	x8, [x8]
  1139c8:	1f 01 1b eb	cmp	x8, x27
  1139cc:	60 00 00 54	b.eq	0x1139d8
  1139d0:	e0 03 16 aa	mov	x0, x22
  1139d4:	56 ff 07 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  1139d8:	e8 a7 40 f9	ldr	x8, [sp, #0x148]
  1139dc:	00 79 7c f8	ldr	x0, [x8, x28, lsl #3]
  1139e0:	e1 03 18 aa	mov	x1, x24
  1139e4:	67 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  1139e8:	9c 07 00 91	add	x28, x28, #0x1
  1139ec:	9f 03 17 eb	cmp	x28, x23
  1139f0:	83 fe ff 54	b.lo	0x1139c0
  1139f4:	e2 03 05 91	add	x2, sp, #0x140
  1139f8:	e3 03 03 91	add	x3, sp, #0xc0
  1139fc:	e0 03 16 aa	mov	x0, x22
  113a00:	e1 03 14 aa	mov	x1, x20
  113a04:	04 02 80 52	mov	w4, #0x10
  113a08:	5e ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  113a0c:	f7 03 00 aa	mov	x23, x0
  113a10:	40 fd ff b5	cbnz	x0, 0x1139b8
  113a14:	e0 03 16 aa	mov	x0, x22
  113a18:	66 ff 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  113a1c:	60 6a 7a f8	ldr	x0, [x19, x26]
  113a20:	e1 03 15 aa	mov	x1, x21
  113a24:	57 ff 07 94	bl	0x313780 ; Objc message: -[x0 removeAllObjects]
  113a28:	00 e4 00 4f	movi.16b	v0, #0x0
  113a2c:	e0 03 05 ad	stp	q0, q0, [sp, #0xa0]
  113a30:	e0 03 04 ad	stp	q0, q0, [sp, #0x80]
  113a34:	c8 14 00 90	adrp	x8, 664 ; 0x3ab000
  113a38:	1a 65 81 b9	ldrsw	x26, [x8, #0x164]
  113a3c:	60 6a 7a f8	ldr	x0, [x19, x26]
  113a40:	5f ff 07 94	bl	0x3137bc ; symbol stub for: _objc_retain
  113a44:	f6 03 00 aa	mov	x22, x0
  113a48:	e2 03 02 91	add	x2, sp, #0x80
~~~

### Original CBBridgedSplitApp::stopBlinkingSession at 0x1276ec

~~~asm
  1276ec:	fc 6f ba a9	stp	x28, x27, [sp, #-0x60]!
  1276f0:	fa 67 01 a9	stp	x26, x25, [sp, #0x10]
  1276f4:	f8 5f 02 a9	stp	x24, x23, [sp, #0x20]
  1276f8:	f6 57 03 a9	stp	x22, x21, [sp, #0x30]
  1276fc:	f4 4f 04 a9	stp	x20, x19, [sp, #0x40]
  127700:	fd 7b 05 a9	stp	x29, x30, [sp, #0x50]
  127704:	fd 43 01 91	add	x29, sp, #0x50
  127708:	ff 43 08 d1	sub	sp, sp, #0x210
  12770c:	f3 03 00 aa	mov	x19, x0
  127710:	48 12 00 b0	adrp	x8, 585 ; 0x370000
  127714:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
  127718:	08 01 40 f9	ldr	x8, [x8]
  12771c:	a8 83 1a f8	stur	x8, [x29, #-0x58]
  127720:	08 14 00 f0	adrp	x8, 643 ; 0x3aa000
  127724:	00 bd 45 f9	ldr	x0, [x8, #0xb78] ; Objc class ref: _OBJC_CLASS_$_NSThread
  127728:	08 14 00 d0	adrp	x8, 642 ; 0x3a9000
  12772c:	01 3d 40 f9	ldr	x1, [x8, #0x78] ; Objc selector ref: isMainThread
  127730:	14 b0 07 94	bl	0x313780 ; Objc message: +[NSThread isMainThread]
  127734:	80 10 00 36	tbz	w0, #0x0, 0x127944
  127738:	f8 03 04 91	add	x24, sp, #0x100
  12773c:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127740:	14 7d 81 b9	ldrsw	x20, [x8, #0x17c]
  127744:	60 6a 74 f8	ldr	x0, [x19, x20]
  127748:	08 14 00 b0	adrp	x8, 641 ; 0x3a8000
  12774c:	01 c1 43 f9	ldr	x1, [x8, #0x780] ; Objc selector ref: invalidate
  127750:	0c b0 07 94	bl	0x313780 ; Objc message: -[x0 invalidate]
  127754:	60 6a 74 f8	ldr	x0, [x19, x20]
  127758:	7f 6a 34 f8	str	xzr, [x19, x20]
  12775c:	15 b0 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  127760:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127764:	08 71 81 b9	ldrsw	x8, [x8, #0x170]
  127768:	7f 6a 28 38	strb	wzr, [x19, x8]
  12776c:	00 e4 00 4f	movi.16b	v0, #0x0
  127770:	00 03 06 ad	stp	q0, q0, [x24, #0xc0]
  127774:	00 03 07 ad	stp	q0, q0, [x24, #0xe0]
  127778:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  12777c:	08 61 81 b9	ldrsw	x8, [x8, #0x160]
  127780:	60 6a 68 f8	ldr	x0, [x19, x8]
  127784:	0e b0 07 94	bl	0x3137bc ; symbol stub for: _objc_retain
  127788:	f5 03 00 aa	mov	x21, x0
  12778c:	08 14 00 b0	adrp	x8, 641 ; 0x3a8000
  127790:	14 d5 41 f9	ldr	x20, [x8, #0x3a8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
  127794:	a2 83 02 d1	sub	x2, x29, #0xa0
  127798:	e3 03 05 91	add	x3, sp, #0x140
  12779c:	e1 03 14 aa	mov	x1, x20
  1277a0:	04 02 80 52	mov	w4, #0x10
  1277a4:	f7 af 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  1277a8:	80 03 00 b4	cbz	x0, 0x127818
  1277ac:	f6 03 00 aa	mov	x22, x0
  1277b0:	a8 03 57 f8	ldur	x8, [x29, #-0x90]
  1277b4:	19 01 40 f9	ldr	x25, [x8]
  1277b8:	1a 14 00 d0	adrp	x26, 642 ; 0x3a9000
  1277bc:	1b 00 80 d2	mov	x27, #0x0
  1277c0:	57 83 43 f9	ldr	x23, [x26, #0x700]
  1277c4:	a8 03 57 f8	ldur	x8, [x29, #-0x90]
  1277c8:	08 01 40 f9	ldr	x8, [x8]
  1277cc:	1f 01 19 eb	cmp	x8, x25
  1277d0:	60 00 00 54	b.eq	0x1277dc
  1277d4:	e0 03 15 aa	mov	x0, x21
  1277d8:	d5 af 07 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  1277dc:	a8 83 56 f8	ldur	x8, [x29, #-0x98]
  1277e0:	00 79 7b f8	ldr	x0, [x8, x27, lsl #3]
  1277e4:	e1 03 17 aa	mov	x1, x23
  1277e8:	e6 af 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  1277ec:	7b 07 00 91	add	x27, x27, #0x1
  1277f0:	7f 03 16 eb	cmp	x27, x22
  1277f4:	83 fe ff 54	b.lo	0x1277c4
  1277f8:	a2 83 02 d1	sub	x2, x29, #0xa0
  1277fc:	e3 03 05 91	add	x3, sp, #0x140
  127800:	e0 03 15 aa	mov	x0, x21
  127804:	e1 03 14 aa	mov	x1, x20
  127808:	04 02 80 52	mov	w4, #0x10
  12780c:	dd af 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  127810:	f6 03 00 aa	mov	x22, x0
  127814:	40 fd ff b5	cbnz	x0, 0x1277bc
  127818:	e0 03 15 aa	mov	x0, x21
  12781c:	e5 af 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  127820:	00 e4 00 4f	movi.16b	v0, #0x0
  127824:	00 03 01 ad	stp	q0, q0, [x24, #0x20]
  127828:	00 03 00 ad	stp	q0, q0, [x24]
  12782c:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127830:	08 5d 81 b9	ldrsw	x8, [x8, #0x15c]
  127834:	60 6a 68 f8	ldr	x0, [x19, x8]
  127838:	e1 af 07 94	bl	0x3137bc ; symbol stub for: _objc_retain
  12783c:	f5 03 00 aa	mov	x21, x0
  127840:	e2 03 04 91	add	x2, sp, #0x100
  127844:	e3 03 02 91	add	x3, sp, #0x80
  127848:	e1 03 14 aa	mov	x1, x20
  12784c:	04 02 80 52	mov	w4, #0x10
  127850:	cc af 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  127854:	a0 03 00 b4	cbz	x0, 0x1278c8
  127858:	f6 03 00 aa	mov	x22, x0
  12785c:	e8 8b 40 f9	ldr	x8, [sp, #0x110]
  127860:	18 01 40 f9	ldr	x24, [x8]
  127864:	19 14 00 d0	adrp	x25, 642 ; 0x3a9000
  127868:	1a 00 80 d2	mov	x26, #0x0
  12786c:	37 87 43 f9	ldr	x23, [x25, #0x708]
  127870:	e8 8b 40 f9	ldr	x8, [sp, #0x110]
  127874:	08 01 40 f9	ldr	x8, [x8]
  127878:	1f 01 18 eb	cmp	x8, x24
  12787c:	60 00 00 54	b.eq	0x127888
  127880:	e0 03 15 aa	mov	x0, x21
  127884:	aa af 07 94	bl	0x31372c ; symbol stub for: _objc_enumerationMutation
  127888:	e8 87 40 f9	ldr	x8, [sp, #0x108]
  12788c:	02 79 7a f8	ldr	x2, [x8, x26, lsl #3]
  127890:	e0 03 13 aa	mov	x0, x19
  127894:	e1 03 17 aa	mov	x1, x23
  127898:	ba af 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  12789c:	5a 07 00 91	add	x26, x26, #0x1
  1278a0:	5f 03 16 eb	cmp	x26, x22
  1278a4:	63 fe ff 54	b.lo	0x127870
  1278a8:	e2 03 04 91	add	x2, sp, #0x100
  1278ac:	e3 03 02 91	add	x3, sp, #0x80
  1278b0:	e0 03 15 aa	mov	x0, x21
  1278b4:	e1 03 14 aa	mov	x1, x20
  1278b8:	04 02 80 52	mov	w4, #0x10
  1278bc:	b1 af 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  1278c0:	f6 03 00 aa	mov	x22, x0
  1278c4:	20 fd ff b5	cbnz	x0, 0x127868
  1278c8:	e0 03 15 aa	mov	x0, x21
  1278cc:	b9 af 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  1278d0:	08 14 00 f0	adrp	x8, 643 ; 0x3aa000
  1278d4:	00 71 45 f9	ldr	x0, [x8, #0xae0] ; Objc class ref: _OBJC_CLASS_$_UIView
  1278d8:	48 12 00 b0	adrp	x8, 585 ; 0x370000
  1278dc:	08 a1 40 f9	ldr	x8, [x8, #0x140] ; literal pool symbol address: __NSConcreteStackBlock
  1278e0:	f3 a3 02 a9	stp	x19, x8, [sp, #0x28]
  1278e4:	a9 10 00 b0	adrp	x9, 533 ; 0x33c000
  1278e8:	20 d9 44 fd	ldr	d0, [x9, #0x9b0]
  1278ec:	e0 1f 00 fd	str	d0, [sp, #0x38]
  1278f0:	09 07 00 10	adr	x9, #224
  1278f4:	1f 20 03 d5	nop
  1278f8:	4a 12 00 b0	adrp	x10, 585 ; 0x370000
  1278fc:	4a c1 2f 91	add	x10, x10, #0xbf0
  127900:	e9 2b 04 a9	stp	x9, x10, [sp, #0x40]
  127904:	f3 2b 00 f9	str	x19, [sp, #0x50]
  127908:	e8 07 00 f9	str	x8, [sp, #0x8]
  12790c:	28 0f 00 10	adr	x8, #484
  127910:	1f 20 03 d5	nop
  127914:	49 12 00 b0	adrp	x9, 585 ; 0x370000
  127918:	29 81 30 91	add	x9, x9, #0xc20
  12791c:	e0 0b 00 fd	str	d0, [sp, #0x10]
  127920:	e8 a7 01 a9	stp	x8, x9, [sp, #0x18]
  127924:	08 14 00 b0	adrp	x8, 641 ; 0x3a8000
  127928:	01 4d 44 f9	ldr	x1, [x8, #0x898] ; Objc selector ref: animateWithDuration:animations:completion:
  12792c:	a8 10 00 f0	adrp	x8, 535 ; 0x33e000
  127930:	00 01 43 fd	ldr	d0, [x8, #0x600]
  127934:	e2 c3 00 91	add	x2, sp, #0x30
  127938:	e3 23 00 91	add	x3, sp, #0x8
  12793c:	91 af 07 94	bl	0x313780 ; Objc message: +[UIView animateWithDuration:animations:completion:]
  127940:	11 00 00 14	b	0x127984
  127944:	48 12 00 b0	adrp	x8, 585 ; 0x370000
  127948:	08 a1 40 f9	ldr	x8, [x8, #0x140] ; literal pool symbol address: __NSConcreteStackBlock
  12794c:	e8 2f 00 f9	str	x8, [sp, #0x58]
  127950:	a8 10 00 b0	adrp	x8, 533 ; 0x33c000
  127954:	00 d9 44 fd	ldr	d0, [x8, #0x9b0]
  127958:	48 03 00 10	adr	x8, #104
  12795c:	1f 20 03 d5	nop
  127960:	e0 33 00 fd	str	d0, [sp, #0x60]
  127964:	49 12 00 b0	adrp	x9, 585 ; 0x370000
  127968:	29 c1 2f 91	add	x9, x9, #0xbf0
  12796c:	e8 a7 06 a9	stp	x8, x9, [sp, #0x68]
  127970:	f3 3f 00 f9	str	x19, [sp, #0x78]
  127974:	40 12 00 b0	adrp	x0, 585 ; 0x370000
  127978:	00 b4 40 f9	ldr	x0, [x0, #0x168] ; literal pool symbol address: __dispatch_main_q
  12797c:	e1 63 01 91	add	x1, sp, #0x58
  127980:	f6 ae 07 94	bl	0x313558 ; symbol stub for: _dispatch_async
  127984:	a8 83 5a f8	ldur	x8, [x29, #-0x58]
  127988:	49 12 00 b0	adrp	x9, 585 ; 0x370000
  12798c:	29 b1 40 f9	ldr	x9, [x9, #0x160] ; literal pool symbol address: ___stack_chk_guard
  127990:	29 01 40 f9	ldr	x9, [x9]
  127994:	3f 01 08 eb	cmp	x9, x8
  127998:	21 01 00 54	b.ne	0x1279bc
  12799c:	ff 43 08 91	add	sp, sp, #0x210
  1279a0:	fd 7b 45 a9	ldp	x29, x30, [sp, #0x50]
  1279a4:	f4 4f 44 a9	ldp	x20, x19, [sp, #0x40]
  1279a8:	f6 57 43 a9	ldp	x22, x21, [sp, #0x30]
  1279ac:	f8 5f 42 a9	ldp	x24, x23, [sp, #0x20]
  1279b0:	fa 67 41 a9	ldp	x26, x25, [sp, #0x10]
  1279b4:	fc 6f c6 a8	ldp	x28, x27, [sp], #0x60
  1279b8:	c0 03 5f d6	ret
  1279bc:	c0 ae 07 94	bl	0x3134bc ; symbol stub for: ___stack_chk_fail
  1279c0:	00 10 40 f9	ldr	x0, [x0, #0x20]
  1279c4:	08 14 00 d0	adrp	x8, 642 ; 0x3a9000
  1279c8:	01 79 43 f9	ldr	x1, [x8, #0x6f0] ; Objc selector ref: stopBlinkingSession
  1279cc:	6d af 07 14	b	0x313780 ; Objc message: -[x0 stopBlinkingSession]
  1279d0:	ff 83 04 d1	sub	sp, sp, #0x120
  1279d4:	fa 67 0d a9	stp	x26, x25, [sp, #0xd0]
  1279d8:	f8 5f 0e a9	stp	x24, x23, [sp, #0xe0]
  1279dc:	f6 57 0f a9	stp	x22, x21, [sp, #0xf0]
  1279e0:	f4 4f 10 a9	stp	x20, x19, [sp, #0x100]
  1279e4:	fd 7b 11 a9	stp	x29, x30, [sp, #0x110]
  1279e8:	fd 43 04 91	add	x29, sp, #0x110
  1279ec:	48 12 00 b0	adrp	x8, 585 ; 0x370000
  1279f0:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
  1279f4:	08 01 40 f9	ldr	x8, [x8]
  1279f8:	a8 83 1b f8	stur	x8, [x29, #-0x48]
  1279fc:	00 e4 00 4f	movi.16b	v0, #0x0
  127a00:	e0 03 04 ad	stp	q0, q0, [sp, #0x80]
  127a04:	e0 03 05 ad	stp	q0, q0, [sp, #0xa0]
  127a08:	08 10 40 f9	ldr	x8, [x0, #0x20]
  127a0c:	29 14 00 90	adrp	x9, 644 ; 0x3ab000
  127a10:	29 65 81 b9	ldrsw	x9, [x9, #0x164]
  127a14:	00 69 69 f8	ldr	x0, [x8, x9]
  127a18:	69 af 07 94	bl	0x3137bc ; symbol stub for: _objc_retain
  127a1c:	f3 03 00 aa	mov	x19, x0
  127a20:	08 14 00 b0	adrp	x8, 641 ; 0x3a8000
  127a24:	14 d5 41 f9	ldr	x20, [x8, #0x3a8] ; Objc selector ref: countByEnumeratingWithState:objects:count:
  127a28:	e2 03 02 91	add	x2, sp, #0x80
  127a2c:	e3 03 00 91	mov	x3, sp
  127a30:	e1 03 14 aa	mov	x1, x20
  127a34:	04 02 80 52	mov	w4, #0x10
  127a38:	52 af 07 94	bl	0x313780 ; Objc message: -[x0 countByEnumeratingWithState:objects:count:]
  127a3c:	a0 03 00 b4	cbz	x0, 0x127ab0
  127a40:	f5 03 00 aa	mov	x21, x0
  127a44:	e8 4b 40 f9	ldr	x8, [sp, #0x90]
  127a48:	17 01 40 f9	ldr	x23, [x8]
  127a4c:	18 14 00 b0	adrp	x24, 641 ; 0x3a8000
  127a50:	19 00 80 d2	mov	x25, #0x0
  127a54:	16 1f 45 f9	ldr	x22, [x24, #0xa38]
  127a58:	e8 4b 40 f9	ldr	x8, [sp, #0x90]
~~~

### Original CBBridgedSplitApp::stopContainerBorderBlinking: at 0x127e6c

~~~asm
  127e6c:	f8 5f bc a9	stp	x24, x23, [sp, #-0x40]!
  127e70:	f6 57 01 a9	stp	x22, x21, [sp, #0x10]
  127e74:	f4 4f 02 a9	stp	x20, x19, [sp, #0x20]
  127e78:	fd 7b 03 a9	stp	x29, x30, [sp, #0x30]
  127e7c:	fd c3 00 91	add	x29, sp, #0x30
  127e80:	f4 03 02 aa	mov	x20, x2
  127e84:	08 14 00 b0	adrp	x8, 641 ; 0x3a8000
  127e88:	15 e1 43 f9	ldr	x21, [x8, #0x7c0] ; Objc selector ref: layer
  127e8c:	e0 03 02 aa	mov	x0, x2
  127e90:	4b ae 07 94	bl	0x3137bc ; symbol stub for: _objc_retain
  127e94:	f3 03 00 aa	mov	x19, x0
  127e98:	e0 03 14 aa	mov	x0, x20
  127e9c:	e1 03 15 aa	mov	x1, x21
  127ea0:	38 ae 07 94	bl	0x313780 ; Objc message: -[x0 layer]
  127ea4:	fd 03 1d aa	mov	x29, x29
  127ea8:	4e ae 07 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  127eac:	f6 03 00 aa	mov	x22, x0
  127eb0:	08 14 00 d0	adrp	x8, 642 ; 0x3a9000
  127eb4:	01 a5 41 f9	ldr	x1, [x8, #0x348] ; Objc selector ref: removeAnimationForKey:
  127eb8:	82 13 00 f0	adrp	x2, 627 ; 0x39a000
  127ebc:	42 00 0d 91	add	x2, x2, #0x340 ; Objc cfstring ref: @"borderPulse"
  127ec0:	30 ae 07 94	bl	0x313780 ; Objc message: -[x0 removeAnimationForKey:]
  127ec4:	e0 03 16 aa	mov	x0, x22
  127ec8:	3a ae 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  127ecc:	08 14 00 f0	adrp	x8, 643 ; 0x3aa000
  127ed0:	00 0d 45 f9	ldr	x0, [x8, #0xa18] ; Objc class ref: _OBJC_CLASS_$_UIColor
  127ed4:	08 14 00 b0	adrp	x8, 641 ; 0x3a8000
  127ed8:	01 e5 41 f9	ldr	x1, [x8, #0x3c8] ; Objc selector ref: colorWithRed:green:blue:alpha:
  127edc:	a8 10 00 f0	adrp	x8, 535 ; 0x33e000
  127ee0:	00 c5 45 fd	ldr	d0, [x8, #0xb88]
  127ee4:	1f 20 03 d5	nop
  127ee8:	01 4d 43 fd	ldr	d1, [x8, #0x698]
  127eec:	a8 10 00 b0	adrp	x8, 533 ; 0x33c000
  127ef0:	02 05 44 fd	ldr	d2, [x8, #0x808]
  127ef4:	a8 10 00 f0	adrp	x8, 535 ; 0x33e000
  127ef8:	03 01 43 fd	ldr	d3, [x8, #0x600]
  127efc:	21 ae 07 94	bl	0x313780 ; Objc message: +[UIColor colorWithRed:green:blue:alpha:]
  127f00:	fd 03 1d aa	mov	x29, x29
  127f04:	37 ae 07 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  127f08:	30 ae 07 94	bl	0x3137c8 ; symbol stub for: _objc_retainAutorelease
  127f0c:	f6 03 00 aa	mov	x22, x0
  127f10:	08 14 00 b0	adrp	x8, 641 ; 0x3a8000
  127f14:	01 dd 43 f9	ldr	x1, [x8, #0x7b8] ; Objc selector ref: CGColor
  127f18:	1a ae 07 94	bl	0x313780 ; Objc message: -[x0 CGColor]
  127f1c:	f7 03 00 aa	mov	x23, x0
  127f20:	e0 03 14 aa	mov	x0, x20
  127f24:	e1 03 15 aa	mov	x1, x21
  127f28:	16 ae 07 94	bl	0x313780 ; Objc message: -[x0 CGColor]
  127f2c:	fd 03 1d aa	mov	x29, x29
  127f30:	2c ae 07 94	bl	0x3137e0 ; symbol stub for: _objc_retainAutoreleasedReturnValue
  127f34:	f4 03 00 aa	mov	x20, x0
  127f38:	e0 03 13 aa	mov	x0, x19
  127f3c:	1d ae 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  127f40:	08 14 00 b0	adrp	x8, 641 ; 0x3a8000
  127f44:	01 11 44 f9	ldr	x1, [x8, #0x820] ; Objc selector ref: setBorderColor:
  127f48:	e0 03 14 aa	mov	x0, x20
  127f4c:	e2 03 17 aa	mov	x2, x23
  127f50:	0c ae 07 94	bl	0x313780 ; Objc message: -[x0 setBorderColor:]
  127f54:	e0 03 14 aa	mov	x0, x20
  127f58:	16 ae 07 94	bl	0x3137b0 ; symbol stub for: _objc_release
  127f5c:	e0 03 16 aa	mov	x0, x22
  127f60:	fd 7b 43 a9	ldp	x29, x30, [sp, #0x30]
  127f64:	f4 4f 42 a9	ldp	x20, x19, [sp, #0x20]
  127f68:	f6 57 41 a9	ldp	x22, x21, [sp, #0x10]
  127f6c:	f8 5f c4 a8	ldp	x24, x23, [sp], #0x40
  127f70:	10 ae 07 14	b	0x3137b0 ; symbol stub for: _objc_release
  127f74:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127f78:	08 69 81 b9	ldrsw	x8, [x8, #0x168]
  127f7c:	00 68 68 f8	ldr	x0, [x0, x8]
  127f80:	c0 03 5f d6	ret
  127f84:	e1 03 02 aa	mov	x1, x2
  127f88:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127f8c:	08 69 81 b9	ldrsw	x8, [x8, #0x168]
  127f90:	00 00 08 8b	add	x0, x0, x8
  127f94:	1f ae 07 14	b	0x313810 ; symbol stub for: _objc_storeStrong
  127f98:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127f9c:	08 55 81 b9	ldrsw	x8, [x8, #0x154]
  127fa0:	00 68 68 f8	ldr	x0, [x0, x8]
  127fa4:	c0 03 5f d6	ret
  127fa8:	e1 03 02 aa	mov	x1, x2
  127fac:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127fb0:	08 55 81 b9	ldrsw	x8, [x8, #0x154]
  127fb4:	00 00 08 8b	add	x0, x0, x8
  127fb8:	16 ae 07 14	b	0x313810 ; symbol stub for: _objc_storeStrong
  127fbc:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127fc0:	08 59 81 b9	ldrsw	x8, [x8, #0x158]
  127fc4:	00 68 68 f8	ldr	x0, [x0, x8]
  127fc8:	c0 03 5f d6	ret
  127fcc:	e1 03 02 aa	mov	x1, x2
  127fd0:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127fd4:	08 59 81 b9	ldrsw	x8, [x8, #0x158]
  127fd8:	00 00 08 8b	add	x0, x0, x8
  127fdc:	0d ae 07 14	b	0x313810 ; symbol stub for: _objc_storeStrong
  127fe0:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127fe4:	08 5d 81 b9	ldrsw	x8, [x8, #0x15c]
  127fe8:	00 68 68 f8	ldr	x0, [x0, x8]
  127fec:	c0 03 5f d6	ret
  127ff0:	e1 03 02 aa	mov	x1, x2
  127ff4:	28 14 00 90	adrp	x8, 644 ; 0x3ab000
  127ff8:	08 5d 81 b9	ldrsw	x8, [x8, #0x15c]
  127ffc:	00 00 08 8b	add	x0, x0, x8
  128000:	04 ae 07 14	b	0x313810 ; symbol stub for: _objc_storeStrong
  128004:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128008:	08 61 81 b9	ldrsw	x8, [x8, #0x160]
  12800c:	00 68 68 f8	ldr	x0, [x0, x8]
  128010:	c0 03 5f d6	ret
  128014:	e1 03 02 aa	mov	x1, x2
  128018:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  12801c:	08 61 81 b9	ldrsw	x8, [x8, #0x160]
  128020:	00 00 08 8b	add	x0, x0, x8
  128024:	fb ad 07 14	b	0x313810 ; symbol stub for: _objc_storeStrong
  128028:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  12802c:	08 65 81 b9	ldrsw	x8, [x8, #0x164]
  128030:	00 68 68 f8	ldr	x0, [x0, x8]
  128034:	c0 03 5f d6	ret
  128038:	e1 03 02 aa	mov	x1, x2
  12803c:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128040:	08 65 81 b9	ldrsw	x8, [x8, #0x164]
  128044:	00 00 08 8b	add	x0, x0, x8
  128048:	f2 ad 07 14	b	0x313810 ; symbol stub for: _objc_storeStrong
  12804c:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128050:	08 49 81 b9	ldrsw	x8, [x8, #0x148]
  128054:	00 68 68 f8	ldr	x0, [x0, x8]
  128058:	c0 03 5f d6	ret
  12805c:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128060:	08 49 81 b9	ldrsw	x8, [x8, #0x148]
  128064:	02 68 28 f8	str	x2, [x0, x8]
  128068:	c0 03 5f d6	ret
  12806c:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128070:	08 4d 81 b9	ldrsw	x8, [x8, #0x14c]
  128074:	00 68 68 fc	ldr	d0, [x0, x8]
  128078:	c0 03 5f d6	ret
  12807c:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128080:	08 4d 81 b9	ldrsw	x8, [x8, #0x14c]
  128084:	00 68 28 fc	str	d0, [x0, x8]
  128088:	c0 03 5f d6	ret
  12808c:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128090:	08 51 81 b9	ldrsw	x8, [x8, #0x150]
  128094:	00 68 68 f8	ldr	x0, [x0, x8]
  128098:	c0 03 5f d6	ret
  12809c:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  1280a0:	08 51 81 b9	ldrsw	x8, [x8, #0x150]
  1280a4:	02 68 28 f8	str	x2, [x0, x8]
  1280a8:	c0 03 5f d6	ret
  1280ac:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  1280b0:	08 75 81 b9	ldrsw	x8, [x8, #0x174]
  1280b4:	00 68 68 38	ldrb	w0, [x0, x8]
  1280b8:	c0 03 5f d6	ret
  1280bc:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  1280c0:	08 75 81 b9	ldrsw	x8, [x8, #0x174]
  1280c4:	02 68 28 38	strb	w2, [x0, x8]
  1280c8:	c0 03 5f d6	ret
  1280cc:	f4 4f be a9	stp	x20, x19, [sp, #-0x20]!
  1280d0:	fd 7b 01 a9	stp	x29, x30, [sp, #0x10]
  1280d4:	fd 43 00 91	add	x29, sp, #0x10
  1280d8:	f3 03 00 aa	mov	x19, x0
  1280dc:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  1280e0:	08 65 81 b9	ldrsw	x8, [x8, #0x164]
  1280e4:	00 00 08 8b	add	x0, x0, x8
  1280e8:	01 00 80 d2	mov	x1, #0x0
  1280ec:	c9 ad 07 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
  1280f0:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  1280f4:	08 61 81 b9	ldrsw	x8, [x8, #0x160]
  1280f8:	60 02 08 8b	add	x0, x19, x8
  1280fc:	01 00 80 d2	mov	x1, #0x0
  128100:	c4 ad 07 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
  128104:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128108:	08 5d 81 b9	ldrsw	x8, [x8, #0x15c]
  12810c:	60 02 08 8b	add	x0, x19, x8
  128110:	01 00 80 d2	mov	x1, #0x0
  128114:	bf ad 07 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
  128118:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  12811c:	08 59 81 b9	ldrsw	x8, [x8, #0x158]
  128120:	60 02 08 8b	add	x0, x19, x8
  128124:	01 00 80 d2	mov	x1, #0x0
  128128:	ba ad 07 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
  12812c:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128130:	08 55 81 b9	ldrsw	x8, [x8, #0x154]
  128134:	60 02 08 8b	add	x0, x19, x8
  128138:	01 00 80 d2	mov	x1, #0x0
  12813c:	b5 ad 07 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
  128140:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128144:	08 69 81 b9	ldrsw	x8, [x8, #0x168]
  128148:	60 02 08 8b	add	x0, x19, x8
  12814c:	01 00 80 d2	mov	x1, #0x0
  128150:	b0 ad 07 94	bl	0x313810 ; symbol stub for: _objc_storeStrong
  128154:	08 14 00 f0	adrp	x8, 643 ; 0x3ab000
  128158:	08 7d 81 b9	ldrsw	x8, [x8, #0x17c]
  12815c:	60 02 08 8b	add	x0, x19, x8
  128160:	01 00 80 d2	mov	x1, #0x0
  128164:	fd 7b 41 a9	ldp	x29, x30, [sp, #0x10]
  128168:	f4 4f c2 a8	ldp	x20, x19, [sp], #0x20
  12816c:	a9 ad 07 14	b	0x313810 ; symbol stub for: _objc_storeStrong
  128170:	ff 03 05 d1	sub	sp, sp, #0x140
  128174:	fc 6f 11 a9	stp	x28, x27, [sp, #0x110]
  128178:	f4 4f 12 a9	stp	x20, x19, [sp, #0x120]
  12817c:	fd 7b 13 a9	stp	x29, x30, [sp, #0x130]
  128180:	fd c3 04 91	add	x29, sp, #0x130
  128184:	09 00 80 d2	mov	x9, #0x0
  128188:	48 12 00 90	adrp	x8, 584 ; 0x370000
  12818c:	08 b1 40 f9	ldr	x8, [x8, #0x160] ; literal pool symbol address: ___stack_chk_guard
  128190:	08 01 40 f9	ldr	x8, [x8]
  128194:	a8 83 1d f8	stur	x8, [x29, #-0x28]
  128198:	a8 10 00 f0	adrp	x8, 535 ; 0x33f000
  12819c:	08 81 17 91	add	x8, x8, #0x5e0
  1281a0:	8a 0d 80 52	mov	w10, #0x6c
  1281a4:	4a 5d 00 11	add	w10, w10, #0x17
  1281a8:	eb e7 02 b2	mov	x11, #-0x3333333333333334
  1281ac:	ab 99 99 f2	movk	x11, #0xcccd
  1281b0:	6c 05 80 52	mov	w12, #0x2b
  1281b4:	4d 0b 80 12	mov	w13, #-0x5b
  1281b8:	4e 15 80 52	mov	w14, #0xaa
  1281bc:	ef 03 00 91	mov	x15, sp
  1281c0:	30 7d cb 9b	umulh	x16, x9, x11
  1281c4:	10 fe 42 d3	lsr	x16, x16, #2
  1281c8:	10 0a 10 0b	add	w16, w16, w16, lsl #2
  1281cc:	31 29 0c 1b	madd	w17, w9, w12, w10
  1281d0:	00 69 69 38	ldrb	w0, [x8, x9]
  1281d4:	21 01 0d 4a	eor	w1, w9, w13
  1281d8:	22 00 00 2a	orr	w2, w1, w0
~~~

## Next analysis gate

Identify exact original 1.0.4 method IMPs from ObjC metadata; inspect disassembly and call ownership; compare with DFV12SceneHost close, DFCarPlaySplitCoordinator stop, QA shutdown. Do not modify Native12/Hub8. This report is not a build or a fix.
