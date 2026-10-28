#!/usr/bin/env python3
"""Verify live DuoFace .87 Sileo APT + binary before updating existing handoff.

Run only inside an Actions checkout of the actual DuoFace project branch.
No device orientation/playback claim is inferred from publication.
"""
import hashlib
from pathlib import Path
import time
import urllib.request

SITE = "https://chuongnguyen89dn-ui.github.io/carplaydsp"
NAME = "com.duoface.jb.embedded"
VERSION = "0.0.87~ythandshake1"
FILE = NAME + "_" + VERSION + "_iphoneos-arm64.deb"
SHA = "7b22d34f4bc2cf78d450dacde1c98369a0e33fdd2e248d3a8a630bec50f5f9e7"
PUBLISHER_COMMIT = "76ea6a307c84a99b88e96236c6532c5884724dbf"
PUBLISHER_RUN = "40652547608"
DUOFACE_SOURCE = "6aa383e6fdb20e9dddbf5cf271050ef2b1d831b1"
DUOFACE_ARCHIVE = "4f3c90d6006e8fc311e468eea09befdefc7ceeb7"
DUOFACE_RUN = "40651065971"


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
                print("DUOFACE_087_LIVE_PUBLIC_APT_AND_DEB_SHA_VERIFIED", SHA)
                return
            print("Waiting for live Pages APT .87", attempt, entries)
        except Exception as exc:
            print("Live Pages pending", attempt, type(exc).__name__, str(exc))
        time.sleep(12)
    raise RuntimeError("Public Sileo .87 not proven; refusing handoff publication claim")


def main():
    verify()
    handoff = Path("sideplay/tiep tuc du an.md")
    if not handoff.is_file():
        raise FileNotFoundError(handoff)
    previous = handoff.read_text(encoding="utf-8")
    marker = "DUOFACE .87 SILEO PUBLIC VERIFIED — RUN " + PUBLISHER_RUN
    if marker in previous:
        print("DUOFACE_087_HANDOFF_ALREADY_PRESENT")
        return
    note = f"""## {marker} (2026-10-28)

- **ĐÃ XÁC MINH PHÁT HÀNH SILEO**: {SITE}/ có đúng một APT entry `{NAME}` phiên bản `{VERSION}`, tên file `debs/{FILE}`, SHA256 `{SHA}`; đã tải lại DEB công khai và đối chiếu SHA.
- Publisher repo `chuongnguyen89dn-ui/carplaydsp`: commit `{PUBLISHER_COMMIT}`, workflow `https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/{PUBLISHER_RUN}`.
- Repo thực thi `chuongnguyen89dn-ui/Duoface`; branch `feature/duoface-jb-embedded-appbridge-20261020`; source commit `{DUOFACE_SOURCE}`, integrated CI `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/{DUOFACE_RUN}`, binary archive commit `{DUOFACE_ARCHIVE}`, path `sideplay/jb-embedded-appbridge/evidence/runs/{DUOFACE_RUN}/{FILE}`.
- Thay đổi duy nhất so với bản .86: áp dụng first-party YouTube host-to-app scene orientation handshake trong bản .87; Maps và Dock không sửa; baseline .83 lifecycle/video giữ nguyên. Bản cũ .86/.83/.84 vẫn có URL DEB cũ phục vụ rollback.
- **CHƯA KIỂM THỬ TRÊN THIẾT BỊ**: xem YouTube chia 2 ô, Zoom từng ô không bấm fullscreen app, thu nhỏ/phóng to, rồi fullscreen/restore; xác nhận không crash/Exit Safe Mode, Dock vẫn chuẩn, không thay đổi Maps. Trên iPhone X jailbreak iOS16 rootless dùng Sileo refresh repo, nâng cấp `DuoFace Independent (Integrated CarPlay Beta)` lên .87. Chỉ thao tác khi xe đỗ, giữ bản .83 để phục hồi. Lấy log `/var/mobile/Library/Logs/DuoFaceSceneHost.log` với `youtube-app-handshake-ack` (scene ID, windowsApplied, orientation và kích thước thực), crash IPS nếu phát sinh. Nếu sai xoay, không chỉnh zoom tuỳ ý mà phân tích ACK trước.
- Không kết luận bug xoay đã được sửa trên xe từ CI/đăng Sileo. Không thay đổi bản đồ trước khi có bằng chứng thực tế.

---
"""
    handoff.write_text(note + previous, encoding="utf-8")
    if handoff.read_text(encoding="utf-8") != note + previous:
        raise RuntimeError("Handoff byte-exact readback failed")
    print("DUOFACE_087_EXISTING_HANDOFF_PREPENDED_AND_READBACK_PASS", marker)


if __name__ == "__main__":
    main()
