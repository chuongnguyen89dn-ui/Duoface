#!/usr/bin/env python3
"""Read-only, reproducible audit of committed DuoFace visual inputs and DEBs."""
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
def sha(data):
    return hashlib.sha256(data).hexdigest()

def inspect_deb(path, destination):
    subprocess.run(['dpkg-deb', '-x', str(path), str(destination)], check=True)
    images = []
    binaries = []
    for p in sorted(destination.rglob('*')):
        if not p.is_file():
            continue
        data = p.read_bytes()
        if p.suffix.lower() == '.png':
            with Image.open(io.BytesIO(data)) as im:
                images.append({'path': str(p.relative_to(destination)), 'pixels': list(im.size), 'sha256': sha(data)})
        if p.name in ('DuoFaceUI', 'DuoFaceDashboard.dylib'):
            strings = re.findall(rb'[ -~]{5,}', data)
            selected = sorted({s.decode() for s in strings if b'logo.png' in s or b'logo-vert.png' in s or s in (b'handleDividerSwapPressed:', b'moveButtonTouchDown:', b'moveButtonTouchUp:', b'expandTapped:', b'restoreTapped:', b'TWO SCREENS. ZERO LIMITS.', b'WORKS WITH APPLE CARPLAY', b'TWO FACES ONE SCREEN')})
            binaries.append({'path': str(p.relative_to(destination)), 'sha256': sha(data), 'selected_strings': selected, 'duonavi_case_insensitive_occurrences': data.lower().count(b'duonavi')})
    return {'sha256': sha(path.read_bytes()), 'images': images, 'binaries': binaries}

def main():
    review = ROOT / 'DuoFace_5_images_REVIEW_before_upload.zip'
    result = {'review_zip_sha256': sha(review.read_bytes()), 'review_images': [], 'limitations': ['Static audit only; no iPhone/CarPlay runtime verification.', 'Selector strings do not establish the target-action wiring.', 'Review ZIP is not evidence of approval for all five images.']}
    with zipfile.ZipFile(review) as z:
        assert z.testzip() is None
        result['review_readme'] = z.read('README_SHA256.txt').decode()
        for n in z.namelist():
            if n.endswith(('.png', '.jpeg')):
                data = z.read(n)
                with Image.open(io.BytesIO(data)) as im:
                    result['review_images'].append({'path': n, 'pixels': list(im.size), 'sha256': sha(data)})
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        with zipfile.ZipFile(ROOT / 'DuoFace_FULL_HANDOFF_2026-10-11.zip') as z:
            member = 'files/com.duonavi.app_1.0.3_iphoneos-arm64(2).deb'
            original = tmp / 'original.deb'
            original.write_bytes(z.read(member))
            result['original_archive_member'] = member
        result['original'] = inspect_deb(original, tmp / 'original')
        result['integrated_1_0_3_11'] = inspect_deb(ROOT / 'dist/main-export/com.duoface.app_1.0.3-11_integratedtest_iphoneos-arm64.deb', tmp / 'integrated')
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
