#!/usr/bin/env python3
"""Repackage verified 1.0.3-11 with the uploaded artwork and SAME-RUN hook.
No code patching of the original app/dashboard; no Sileo deployment.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import tempfile
import zipfile
from PIL import Image, ImageChops, ImageOps

ROOT = Path(__file__).resolve().parents[1]
BASE_SHA = '100566ae52190f8b948c4acc2f4a9d4f10cfa155164efe457ad805a864ebedc7'
SOURCES = {
    '01_DuoFace_icon_original.jpeg': '01f1b3d68a3ce4b5fc224035542fb7c16475eec60c3a94950a2c4993ba44c238',
    '02_DuoFace_logo_layout_original.png': 'eb4646249ac0c2d05417d61013c68a76ffc5d7705d7823d5f570778cb45a5df9',
    '03_Swap_round_button_demo.png': 'cddc0985f514b64574cf2717245e17df1e602d28a0ec985865869ece8493adeb',
    '04_Fullscreen_button_design.png': '51c261268493393003eeb77636b4b9813abb908dba8a0359c56b41b5f371f125',
    '05_Picker_button.png': '16a959b71a0d3d8ef86e2ac9163024af457aec180770c757fe4b16d2b0a85f8a',
}
ASSET = 'var/jb/Library/Application Support/DuoFace/'
DYLIB = 'var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceVisualHook.dylib'
FILTER = DYLIB.replace('.dylib', '.plist')
APP = 'var/jb/Applications/DuoFaceUI.app/'
VERSION = '1.0.3-12~visualtest'
ORIGINAL_ID = 'com.duonavi.app'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def content_box(image):
    r,g,b = image.convert('RGB').split()
    mask = ImageChops.lighter(ImageChops.lighter(r,g),b).point(lambda x: 255 if x>24 else 0)
    box = mask.getbbox()
    if not box:
        raise ValueError('Empty source artwork')
    return image.crop(box), list(box)

def fitted(image, size):
    thumb = ImageOps.contain(image.convert('RGBA'), size, Image.Resampling.LANCZOS)
    out = Image.new('RGBA', size, (0,0,0,255))
    out.alpha_composite(thumb, ((size[0]-thumb.width)//2, (size[1]-thumb.height)//2))
    return out

def prepare(destination):
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=True)
    manifest = {'source_zip': 'DuoFace_5_images_REVIEW_before_upload.zip', 'sources': SOURCES, 'outputs': {}}
    images = {}
    with zipfile.ZipFile(ROOT / manifest['source_zip']) as z:
        assert z.testzip() is None
        for name, digest in SOURCES.items():
            data = z.read(name)
            assert sha(data) == digest, name
            with Image.open(io.BytesIO(data)) as im:
                images[name] = im.convert('RGBA')
        # Picker supplied at its final pixel size: preserve exact bytes.
        picker = destination / 'VisualAssets/duoface-picker.png'
        picker.parent.mkdir(parents=True, exist_ok=True)
        picker.write_bytes(z.read('05_Picker_button.png'))
    layout = images['02_DuoFace_logo_layout_original.png']
    assert layout.size == (1983,793)
    # Split the user's two-panel reference, excluding the panel divider/border.
    horizontal, hb = content_box(layout.crop((0,0,1256,793)))
    vertical, vb = content_box(layout.crop((1261,3,1980,790)))
    manifest['logo_panel_crops'] = {'horizontal': [0,0,1256,793], 'vertical': [1261,3,1980,790], 'horizontal_content': hb, 'vertical_content': vb}
    exports = {
        'duoface-icon.png': (images['01_DuoFace_icon_original.jpeg'], (256,256)),
        'duoface-logo.png': (horizontal, (960,240)),
        'duoface-logo-vert.png': (vertical, (640,640)),
        'VisualAssets/duoface-swap.png': (images['03_Swap_round_button_demo.png'], (120,120)),
        'VisualAssets/duoface-fullscreen.png': (images['04_Fullscreen_button_design.png'], (88,88)),
    }
    for name,(im,size) in exports.items():
        out = destination/name
        out.parent.mkdir(parents=True,exist_ok=True)
        fitted(im,size).save(out)
    for p in sorted(destination.rglob('*.png')):
        manifest['outputs'][str(p.relative_to(destination))] = {'pixels': list(Image.open(p).size), 'sha256': sha(p.read_bytes())}
    (destination/'asset-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    return manifest

def file_map(root):
    return {str(p.relative_to(root)):sha(p.read_bytes()) for p in root.rglob('*') if p.is_file() and not p.is_symlink()}

def build(hook, output):
    output.mkdir(parents=True,exist_ok=True)
    base = ROOT/'dist/main-export/com.duoface.app_1.0.3-11_integratedtest_iphoneos-arm64.deb'
    assert sha(base.read_bytes()) == BASE_SHA, 'Baseline DEB changed'
    hook_bytes = hook.read_bytes()
    assert hook_bytes[:4] in (bytes.fromhex('cffaedfe'), bytes.fromhex('cafebabe')), 'Not a Mach-O dylib'
    assert b'DuoFaceVisual12' in hook_bytes, 'Old hook rejected'
    for name in ('duoface-picker.png','duoface-fullscreen.png','duoface-swap.png','_logoImageView','_moveButtons','_dotViews'):
        assert name.encode() in hook_bytes, name
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)/'root'
        subprocess.run(['dpkg-deb','-R',str(base),str(root)],check=True)
        before = file_map(root)
        manifest = prepare(root/ASSET)
        shutil.copyfile(hook, root/DYLIB)
        bundles = ['com.apple.CarPlayApp','com.apple.CarPlay','com.apple.dashboard','com.apple.springboard','com.apple.SpringBoard','com.duoface.duofaceui']
        (root/FILTER).write_bytes(plistlib.dumps({'Filter': {'Bundles': bundles}}))
        # Regenerate installed app icons at their original exact pixel dimensions.
        with zipfile.ZipFile(ROOT/'DuoFace_5_images_REVIEW_before_upload.zip') as z:
            icon = Image.open(io.BytesIO(z.read('01_DuoFace_icon_original.jpeg'))).convert('RGBA')
        icons=[]
        for p in sorted((root/APP).glob('AppIcon*.png')):
            with Image.open(p) as im: size=im.size
            fitted(icon,size).convert('RGB').save(p)
            icons.append(str(p.relative_to(root)))
        ctl=root/'DEBIAN/control'
        control_lines = ctl.read_text().splitlines()
        control_lines = [('Package: '+ORIGINAL_ID) if line.startswith('Package: ') else (('Version: '+VERSION) if line.startswith('Version: ') else line) for line in control_lines]
        ctl.write_text(chr(10).join(control_lines)+chr(10))
        sync_path = root/'var/mobile/Library/Preferences/com.duonavi.sync.plist'
        sync_path.parent.mkdir(parents=True,exist_ok=True)
        sync_path.write_bytes(plistlib.dumps({'leaseSeconds':157766400,'expiresAt':1949370760,'actualExpireTimestamp':1949370760,'lastAttemptTimestamp':1791700039,'lastSyncTimestamp':1791604360,'status':'SUCCESS'}))
        if (root/'DEBIAN/md5sums').exists():
            lines=[]
            for p in sorted(root.rglob('*')):
                if p.is_file() and not p.is_symlink() and not str(p.relative_to(root)).startswith('DEBIAN/'):
                    lines.append(hashlib.md5(p.read_bytes()).hexdigest()+'  '+str(p.relative_to(root)))
            (root/'DEBIAN/md5sums').write_text('\n'.join(lines)+'\n')
        after=file_map(root)
        changed=sorted(k for k in before if before[k]!=after.get(k))
        allowed={DYLIB,FILTER,'DEBIAN/control','DEBIAN/md5sums',*icons}
        assert all(k in allowed or k.startswith(ASSET) for k in changed), changed
        assert set(before)<=set(after), 'Files unexpectedly removed'
        # Verify final installed assets against the exact generated manifest.
        for name,meta in manifest['outputs'].items():
            p=root/ASSET/name
            assert sha(p.read_bytes())==meta['sha256']
            assert list(Image.open(p).size)==meta['pixels']
        for rel in (APP+'DuoFaceUI','var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib'):
            assert before[rel]==after[rel], 'Native behavior binary changed'
        report={'package_id':ORIGINAL_ID,'five_year_sync_preference':'experimental_not_verified_activation','version':VERSION,'base_sha256':BASE_SHA,'hook_sha256':sha(hook_bytes),'changed_files':changed,'added_files':sorted(set(after)-set(before)),'unchanged_existing_files':len(before)-len(changed),'asset_manifest':manifest,'hook_filter':bundles,'native_app_and_dashboard_byte_identical':True,'runtime_device_test':'NOT_PERFORMED'}
        deb=output/'com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb'
        subprocess.run(['dpkg-deb','--build','--root-owner-group',str(root),str(deb)],check=True)
        check=Path(tmp)/'check'
        subprocess.run(['dpkg-deb','-x',str(deb),str(check)],check=True)
        for name,meta in manifest['outputs'].items():
            assert sha((check/ASSET/name).read_bytes())==meta['sha256']
        assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Version'],text=True).strip()==VERSION
        assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Package'],text=True).strip()==ORIGINAL_ID
        report['deb_sha256']=sha(deb.read_bytes())
        (output/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
        (output/'SHA256SUMS').write_text(report['deb_sha256']+'  '+deb.name+'\n')
        (output/'CONTENTS.txt').write_text(subprocess.check_output(['dpkg-deb','-c',str(deb)],text=True))
        (output/'INFO.txt').write_text(subprocess.check_output(['dpkg-deb','-I',str(deb)],text=True))
        (output/'README.txt').write_text('DuoFace full app 1.0.3-12 visual test. Current-run signed hook and uploaded artwork. Package verification passed; real iPhone/CarPlay testing pending. No Sileo publication.\n')
        shutil.copytree(root/ASSET,output/'assets',dirs_exist_ok=True)
        print(json.dumps({'package':str(deb),'sha256':report['deb_sha256'],'native_binaries_preserved':True,'device_test':'NOT_PERFORMED'}))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--prepare-only',type=Path)
    parser.add_argument('--hook',type=Path)
    parser.add_argument('--output',type=Path,default=ROOT/'dist/visual-1.0.3-12')
    args=parser.parse_args()
    if args.prepare_only:
        print(json.dumps(prepare(args.prepare_only),indent=2))
    else:
        if not args.hook:parser.error('--hook is required')
        build(args.hook,args.output)
, 'Package: '+ORIGINAL_ID, re.sub(r'^Version:.*
        if (root/'DEBIAN/md5sums').exists():
            lines=[]
            for p in sorted(root.rglob('*')):
                if p.is_file() and not p.is_symlink() and not str(p.relative_to(root)).startswith('DEBIAN/'):
                    lines.append(hashlib.md5(p.read_bytes()).hexdigest()+'  '+str(p.relative_to(root)))
            (root/'DEBIAN/md5sums').write_text('\n'.join(lines)+'\n')
        after=file_map(root)
        changed=sorted(k for k in before if before[k]!=after.get(k))
        allowed={DYLIB,FILTER,'DEBIAN/control','DEBIAN/md5sums',*icons}
        assert all(k in allowed or k.startswith(ASSET) for k in changed), changed
        assert set(before)<=set(after), 'Files unexpectedly removed'
        # Verify final installed assets against the exact generated manifest.
        for name,meta in manifest['outputs'].items():
            p=root/ASSET/name
            assert sha(p.read_bytes())==meta['sha256']
            assert list(Image.open(p).size)==meta['pixels']
        for rel in (APP+'DuoFaceUI','var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib'):
            assert before[rel]==after[rel], 'Native behavior binary changed'
        report={'version':VERSION,'base_sha256':BASE_SHA,'hook_sha256':sha(hook_bytes),'changed_files':changed,'added_files':sorted(set(after)-set(before)),'unchanged_existing_files':len(before)-len(changed),'asset_manifest':manifest,'hook_filter':bundles,'native_app_and_dashboard_byte_identical':True,'runtime_device_test':'NOT_PERFORMED'}
        deb=output/'com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb'
        subprocess.run(['dpkg-deb','--build','--root-owner-group',str(root),str(deb)],check=True)
        check=Path(tmp)/'check'
        subprocess.run(['dpkg-deb','-x',str(deb),str(check)],check=True)
        for name,meta in manifest['outputs'].items():
            assert sha((check/ASSET/name).read_bytes())==meta['sha256']
        assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Version'],text=True).strip()==VERSION
        assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Package'],text=True).strip()=='com.duoface.app'
        report['deb_sha256']=sha(deb.read_bytes())
        (output/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
        (output/'SHA256SUMS').write_text(report['deb_sha256']+'  '+deb.name+'\n')
        (output/'CONTENTS.txt').write_text(subprocess.check_output(['dpkg-deb','-c',str(deb)],text=True))
        (output/'INFO.txt').write_text(subprocess.check_output(['dpkg-deb','-I',str(deb)],text=True))
        (output/'README.txt').write_text('DuoFace full app 1.0.3-12 visual test. Current-run signed hook and uploaded artwork. Package verification passed; real iPhone/CarPlay testing pending. No Sileo publication.\n')
        shutil.copytree(root/ASSET,output/'assets',dirs_exist_ok=True)
        print(json.dumps({'package':str(deb),'sha256':report['deb_sha256'],'native_binaries_preserved':True,'device_test':'NOT_PERFORMED'}))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--prepare-only',type=Path)
    parser.add_argument('--hook',type=Path)
    parser.add_argument('--output',type=Path,default=ROOT/'dist/visual-1.0.3-12')
    args=parser.parse_args()
    if args.prepare_only:
        print(json.dumps(prepare(args.prepare_only),indent=2))
    else:
        if not args.hook:parser.error('--hook is required')
        build(args.hook,args.output)
, 'Version: '+VERSION, ctl.read_text(),flags=re.M), flags=re.M))
        # Experimental preference supplied in DuoNavi_1.0.3_5years_UNSIGNED_TEST(1).deb.
        # These fields are not an independently authenticated entitlement.
        sync_path = root/'var/mobile/Library/Preferences/com.duonavi.sync.plist'
        sync_path.parent.mkdir(parents=True,exist_ok=True)
        sync_path.write_bytes(plistlib.dumps({'leaseSeconds':157766400,'expiresAt':1949370760,'actualExpireTimestamp':1949370760,'lastAttemptTimestamp':1791700039,'lastSyncTimestamp':1791604360,'status':'SUCCESS'}))
        if (root/'DEBIAN/md5sums').exists():
            lines=[]
            for p in sorted(root.rglob('*')):
                if p.is_file() and not p.is_symlink() and not str(p.relative_to(root)).startswith('DEBIAN/'):
                    lines.append(hashlib.md5(p.read_bytes()).hexdigest()+'  '+str(p.relative_to(root)))
            (root/'DEBIAN/md5sums').write_text('\n'.join(lines)+'\n')
        after=file_map(root)
        changed=sorted(k for k in before if before[k]!=after.get(k))
        allowed={DYLIB,FILTER,'DEBIAN/control','DEBIAN/md5sums',*icons}
        assert all(k in allowed or k.startswith(ASSET) for k in changed), changed
        assert set(before)<=set(after), 'Files unexpectedly removed'
        # Verify final installed assets against the exact generated manifest.
        for name,meta in manifest['outputs'].items():
            p=root/ASSET/name
            assert sha(p.read_bytes())==meta['sha256']
            assert list(Image.open(p).size)==meta['pixels']
        for rel in (APP+'DuoFaceUI','var/jb/Library/MobileSubstrate/DynamicLibraries/DuoFaceDashboard.dylib'):
            assert before[rel]==after[rel], 'Native behavior binary changed'
        report={'version':VERSION,'base_sha256':BASE_SHA,'hook_sha256':sha(hook_bytes),'changed_files':changed,'added_files':sorted(set(after)-set(before)),'unchanged_existing_files':len(before)-len(changed),'asset_manifest':manifest,'hook_filter':bundles,'native_app_and_dashboard_byte_identical':True,'runtime_device_test':'NOT_PERFORMED'}
        deb=output/'com.duoface.app_1.0.3-12_visualtest_iphoneos-arm64.deb'
        subprocess.run(['dpkg-deb','--build','--root-owner-group',str(root),str(deb)],check=True)
        check=Path(tmp)/'check'
        subprocess.run(['dpkg-deb','-x',str(deb),str(check)],check=True)
        for name,meta in manifest['outputs'].items():
            assert sha((check/ASSET/name).read_bytes())==meta['sha256']
        assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Version'],text=True).strip()==VERSION
        assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Package'],text=True).strip()=='com.duoface.app'
        report['deb_sha256']=sha(deb.read_bytes())
        (output/'verification.json').write_text(json.dumps(report,indent=2)+'\n')
        (output/'SHA256SUMS').write_text(report['deb_sha256']+'  '+deb.name+'\n')
        (output/'CONTENTS.txt').write_text(subprocess.check_output(['dpkg-deb','-c',str(deb)],text=True))
        (output/'INFO.txt').write_text(subprocess.check_output(['dpkg-deb','-I',str(deb)],text=True))
        (output/'README.txt').write_text('DuoFace full app 1.0.3-12 visual test. Current-run signed hook and uploaded artwork. Package verification passed; real iPhone/CarPlay testing pending. No Sileo publication.\n')
        shutil.copytree(root/ASSET,output/'assets',dirs_exist_ok=True)
        print(json.dumps({'package':str(deb),'sha256':report['deb_sha256'],'native_binaries_preserved':True,'device_test':'NOT_PERFORMED'}))

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--prepare-only',type=Path)
    parser.add_argument('--hook',type=Path)
    parser.add_argument('--output',type=Path,default=ROOT/'dist/visual-1.0.3-12')
    args=parser.parse_args()
    if args.prepare_only:
        print(json.dumps(prepare(args.prepare_only),indent=2))
    else:
        if not args.hook:parser.error('--hook is required')
        build(args.hook,args.output)
