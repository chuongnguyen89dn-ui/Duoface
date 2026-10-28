#!/usr/bin/env python3
"""Verify live DuoFace .88 Sileo APT + binary before updating existing handoff.

Run only inside an Actions checkout of the actual DuoFace project branch.
No device orientation/playback claim is inferred from publication.
"""
import hashlib
from pathlib import Path
import time
import urllib.request

SITE = "https://chuongnguyen89dn-ui.github.io/carplaydsp"
NAME = "com.duoface.jb.embedded"
VERSION = "0.0.88~uikitreflow1"
FILE = NAME + "_" + VERSION + "_iphoneos-arm64.deb"
SHA = "9f04fb806d207e72e2fc3d5a2516747275b83ec03c7032d317b0fc8be8de6e06"
PUBLISHER_COMMIT = "0ed10efba80f420630854df3bda374b64b86fa82"
PUBLISHER_RUN = "40656863552"
DUOFACE_SOURCE = "f3bb72d15111fba6cd22f51122fa05cae05e58b2"
DUOFACE_ARCHIVE = "1184d01cdad6300adc6b2547f286fc7f70b137e7"
DUOFACE_RUN = "40656378728"


def fetch(suffix):
    with urllib.request.urlopen(SITE + suffix, timeout=45) as handle:
        return handle.read()


def verify():
    for attempt in range(1, 16):
        try:
            entries = []
            for stanza in fetch("/Packages").decode("utf-8").split("\n\n"):
                d = {}
                for line in stanza.splitlines():
                    if ": " in line and not line.startswith(" "):
                        key, value = line.split(": ", 1)
                        d[key] = value
                if d.get("Package") == NAME:
                    entries.append(d)
            required = {
                "Package": NAME,
                "Version": VERSION,
                "Architecture": "iphoneos-arm64",
                "Filename": "debs/" + FILE,
                "SHA256": SHA,
            }
            if len(entries) == 1 and all(entries[0].get(k) == v for k, v in required.items()):
                actual = hashlib.sha256(fetch("/debs/" + FILE)).hexdigest()
                if actual != SHA:
                    raise RuntimeError("live public DEB SHA mismatch: " + actual)
                print("DUOFACE_088_LIVE_PUBLIC_APT_AND_DEB_SHA_VERIFIED", SHA)
                return
            print("Waiting for live Pages APT .88", attempt, entries)
        except Exception as exc:
            print("Live Pages pending", attempt, type(exc).__name__, str(exc))
        time.sleep(12)
    raise RuntimeError("Public Sileo .88 not proven; refusing handoff publication claim")


def main():
    verify()
    handoff = Path("sideplay/tiep tuc du an.md")
    if not handoff.is_file():
        raise FileNotFoundError(handoff)
    previous = handoff.read_text(encoding="utf-8")
    marker = "DUOFACE .88 SILEO PUBLIC VERIFIED — RUN " + PUBLISHER_RUN
    if marker in previous:
        print("DUOFACE_088_HANDOFF_ALREADY_PRESENT")
        return
    note = f"""## {marker} (2026-10-28)

- **ĐÃ XÁC MINH PHÁT HÀNH SILEO**: {SITE}/ có đúng một APT entry `{NAME}` phiên bản `{VERSION}`, tên file `debs/{FILE}`, SHA256 `{SHA}`; đã tải lại DEB công khai và đối chiếu SHA.
- Publisher repo `chuongnguyen89dn-ui/carplaydsp`: commit `{PUBLISHER_COMMIT}`, workflow `https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/{PUBLISHER_RUN}`.
- Repo thực thi `chuongnguyen89dn-ui/Duoface`; branch `feature/duoface-jb-embedded-appbridge-20261020`; source commit `{DUOFACE_SOURCE}`, integrated CI `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/{DUOFACE_RUN}`, binary archive commit `{DUOFACE_ARCHIVE}`, path `sideplay/jb-embedded-appbridge/evidence/runs/{DUOFACE_RUN}/{FILE}`.
- Người dùng xác nhận .87 vẫn sai chiều ở chia đôi; phóng một ô hoặc vuốt từ trên xuống qua giao diện YouTube có thể khiến video tự quay đúng. .88 mở rộng enumerator UIWindow nội bộ theo original Native12 ARM64 0x2aa2e4, vẫn chỉ trong scene/owner/generation hiện tại; ACK đếm normal/internal window và UIKit layout, không suy đoán landscape hoặc tỷ lệ zoom. Maps/Dock và .83 lifecycle/video không đổi. Giữ binary .87/.86/.83 để rollback.
- **CHƯA KIỂM THỬ TRÊN THIẾT BỊ**: xem YouTube chia 2 ô, Zoom từng ô không bấm fullscreen app, thu nhỏ/phóng to, rồi fullscreen/restore; xác nhận không crash/Exit Safe Mode, Dock vẫn chuẩn, không thay đổi Maps. Trên iPhone X jailbreak iOS16 rootless dùng Sileo refresh repo, nâng cấp `DuoFace Independent (Integrated CarPlay Beta)` lên .88. Chỉ thao tác khi xe đỗ, giữ bản .83 để phục hồi. Lấy log `/var/mobile/Library/Logs/DuoFaceSceneHost.log` với `youtube-app-handshake-ack` (scene ID, windowsApplied, orientation và kích thước thực), crash IPS nếu phát sinh. Nếu sai xoay, không chỉnh zoom tuỳ ý mà phân tích ACK trước.
- Không kết luận bug xoay đã được sửa trên xe từ CI/đăng Sileo. Không thay đổi bản đồ trước khi có bằng chứng thực tế.

---
"""
    handoff.write_text(note + previous, encoding="utf-8")
    if handoff.read_text(encoding="utf-8") != note + previous:
        raise RuntimeError("Handoff byte-exact readback failed")
    print("DUOFACE_088_EXISTING_HANDOFF_PREPENDED_AND_READBACK_PASS", marker)


if __name__ == "__main__":
    main()
