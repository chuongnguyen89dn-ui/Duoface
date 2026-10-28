#!/usr/bin/env python3
"""Verify live DuoFace .89 Sileo APT + binary before updating existing handoff.

Run only inside an Actions checkout of the actual DuoFace project branch.
No device orientation/playback claim is inferred from publication.
"""
import hashlib
from pathlib import Path
import time
import urllib.request

SITE = "https://chuongnguyen89dn-ui.github.io/carplaydsp"
NAME = "com.duoface.jb.embedded"
VERSION = "0.0.89~splitscene1"
FILE = NAME + "_" + VERSION + "_iphoneos-arm64.deb"
SHA = "90f8a88fc00b6cadeefcc627e8675383acef1f96afd74dcc948cded587af7df2"
PUBLISHER_COMMIT = "e72ff5df2197439c00a64c912928382b632953a6"
PUBLISHER_RUN = "40663620210"
DUOFACE_SOURCE = "a50a81713641ddfd269239e7141fb511c969d605"
DUOFACE_ARCHIVE = "fbcbc01f483b5cffcb45e43ccd3bbcd996cb6d41"
DUOFACE_RUN = "40663132909"


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
                print("DUOFACE_089_LIVE_PUBLIC_APT_AND_DEB_SHA_VERIFIED", SHA)
                return
            print("Waiting for live Pages APT .89", attempt, entries)
        except Exception as exc:
            print("Live Pages pending", attempt, type(exc).__name__, str(exc))
        time.sleep(12)
    raise RuntimeError("Public Sileo .89 not proven; refusing handoff publication claim")


def main():
    verify()
    handoff = Path("sideplay/tiep tuc du an.md")
    if not handoff.is_file():
        raise FileNotFoundError(handoff)
    previous = handoff.read_text(encoding="utf-8")
    marker = "DUOFACE .89 SILEO PUBLIC VERIFIED — RUN " + PUBLISHER_RUN
    if marker in previous:
        print("DUOFACE_089_HANDOFF_ALREADY_PRESENT")
        return
    note = f"""## {marker} (2026-10-28)

- **ĐÃ XÁC MINH PHÁT HÀNH SILEO**: {SITE}/ có đúng một APT entry `{NAME}` phiên bản `{VERSION}`, tên file `debs/{FILE}`, SHA256 `{SHA}`; đã tải lại DEB công khai và đối chiếu SHA.
- Publisher repo `chuongnguyen89dn-ui/carplaydsp`: commit `{PUBLISHER_COMMIT}`, workflow `https://github.com/chuongnguyen89dn-ui/carplaydsp/actions/runs/{PUBLISHER_RUN}`.
- Repo thực thi `chuongnguyen89dn-ui/Duoface`; branch `feature/duoface-jb-embedded-appbridge-20261020`; source commit `{DUOFACE_SOURCE}`, integrated CI `https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/{DUOFACE_RUN}`, binary archive commit `{DUOFACE_ARCHIVE}`, path `sideplay/jb-embedded-appbridge/evidence/runs/{DUOFACE_RUN}/{FILE}`.
- Người dùng đã xác nhận **.88 DEVICE-FAIL** (video xoay sai khi chia hai ô). Device SceneHost thực tế xác nhận IPC đến YouTube, nhưng `sceneOrientation=1` vẫn có `rootViewController.interfaceOrientation=3` trong ACK 7238. Bản .89 mang state `isSplit` lấy trực tiếp từ Chrome, đọc chênh lệch client/server orientation và chỉ sau 120ms khi còn mismatch ở split mới yêu cầu một lần geometry update UIKit iOS16 cho chính YouTube scene. Không sửa Media Lifecycle .83, Maps, Dock, artwork, logo hoặc split layout. Binary .83/.86/.87/.88 giữ lại để rollback.
- **CHƯA KIỂM THỬ TRÊN THIẾT BỊ**: xem YouTube chia 2 ô, Zoom từng ô không bấm fullscreen app, thu nhỏ/phóng to, rồi fullscreen/restore; xác nhận không crash/Exit Safe Mode, Dock vẫn chuẩn, không thay đổi Maps. Trên iPhone X jailbreak iOS16 rootless dùng Sileo refresh repo, nâng cấp `DuoFace Independent (Integrated CarPlay Beta)` lên .89. Chỉ thao tác khi xe đỗ, giữ bản .83 để phục hồi. Lấy log `/var/mobile/Library/Logs/DuoFaceSceneHost.log` với `youtube-app-handshake-ack` (scene ID, windowsApplied, orientation và kích thước thực), crash IPS nếu phát sinh. Nếu còn sai xoay, kiểm tra ACK clientOrientation/serverOrientation/split/mismatch/geometry và lỗi geometry-request-rejected; không đoán góc landscape.
- Không kết luận bug xoay đã được sửa trên xe từ CI/đăng Sileo. Không thay đổi bản đồ trước khi có bằng chứng thực tế.

---
"""
    handoff.write_text(note + previous, encoding="utf-8")
    if handoff.read_text(encoding="utf-8") != note + previous:
        raise RuntimeError("Handoff byte-exact readback failed")
    print("DUOFACE_089_EXISTING_HANDOFF_PREPENDED_AND_READBACK_PASS", marker)


if __name__ == "__main__":
    main()
