import argparse,ast,pathlib,subprocess,yaml
p=argparse.ArgumentParser()
p.add_argument('--base',required=True);p.add_argument('--out',required=True)
p.add_argument('--sha',required=True);p.add_argument('--size',required=True,type=int);p.add_argument('--archive',required=True)
a=p.parse_args()
text=pathlib.Path(a.base).read_text()
oldver='0.0.182~b1nativemaps1';newver='0.0.185~admission1'
oldsha='a879bc6e617f72b51e2d763b216626f5240495d94a6c1da2abff30b60d0e9860'
oldfile='com.duoface.jb.embedded_'+oldver+'_iphoneos-arm64.deb'
newfile='com.duoface.jb.embedded_'+newver+'_iphoneos-arm64.deb'
oldcommit='4a9eef05d9ffa6a6d110ddc6babaf2713a58703c'
assert oldcommit in text and text.count("assert len(hits)==6,hits")==1
text=text.replace(oldver,newver).replace(oldsha,a.sha).replace(oldcommit,a.archive)
text=text.replace("= '1274984'","= '"+str(a.size)+"'")
text=text.replace('QA182','QA185').replace('selected182','selected185')
text=text.replace("str(info['CFBundleVersion'])=='182'","str(info['CFBundleVersion'])=='185'")
text=text.replace("assert len(hits)==6,hits","assert len(hits)==7,hits")
needle="'0.0.181~b0probe1','0.0.185~admission1'},hits"
assert needle in text
text=text.replace(needle,"'0.0.181~b0probe1','0.0.182~b1nativemaps1','0.0.185~admission1'},hits")
marker="          print('QA185_SIGNED_B1NATIVEMAPS1_STATIC_PACKAGE_PASS_DEVICE_UNTESTED')"
assert text.count(marker)==1
text=text.replace(marker,"""          for marker in (b'launch-identity-captured',b'identity-admitted',b'post-admission-visibility'):
              assert marker in b1,marker
          print('QA185_SIGNED_ADMISSION1_STATIC_PACKAGE_PASS_DEVICE_UNTESTED')""")
needle="          print('QA185_SIGNED_ADMISSION1_STATIC_PACKAGE_PASS_DEVICE_UNTESTED')\n          PY\n          cd repo"
rollback=f"""          print('QA185_SIGNED_ADMISSION1_STATIC_PACKAGE_PASS_DEVICE_UNTESTED')
          PY
          # Preserve the previous public QA182 exact signed bytes as nearest rollback.
          QA182_ROLLBACK_FILE='{oldfile}'
          curl -fLsS --retry 4 --max-time 140 'https://raw.githubusercontent.com/chuongnguyen89dn-ui/duoface-debs-/{oldcommit}/debs/{oldfile}' -o "$QA_DIR/debs/$QA182_ROLLBACK_FILE"
          printf '%s  %s\\n' '{oldsha}' "$QA_DIR/debs/$QA182_ROLLBACK_FILE" | shasum -a 256 -c -
          test "$(dpkg-deb -f "$QA_DIR/debs/$QA182_ROLLBACK_FILE" Version)" = '{oldver}'
          cd repo"""
assert needle in text
text=text.replace(needle,rollback)
text=text.replace('DUOFACE_QA185_SELECTED_ONE_INDEX_QA181_NEAREST_ROLLBACK_PASS','DUOFACE_QA185_SELECTED_ONE_INDEX_QA182_NEAREST_ROLLBACK_PASS')
text=text.replace('DuoFace QA178 H1 wake - signed app-touch wake and native-map ownership candidate. Live vehicle input, keyboard and map pixels remain unverified; QA177 is the nearest rollback.','DuoFace QA185 admission1 - native Maps launch-identity membership before view visibility. Vehicle pane commit, sustained ownership and correct touch remain unverified; QA182 is the previous public rollback.')
old='# QA181 is the nearest rollback: verify the original public bytes.'
assert old in text
new=f"""# QA182 is the nearest public rollback; preserve original signed bytes.
          OLD182='{oldfile}'
          curl -fLsS --retry 4 "$SITE/debs/$OLD182" -o "$RUNNER_TEMP/duoface-qa182-rollback.deb"
          printf '%s  %s\\n' '{oldsha}' "$RUNNER_TEMP/duoface-qa182-rollback.deb" | sha256sum -c -
          test "$(dpkg-deb -f "$RUNNER_TEMP/duoface-qa182-rollback.deb" Version)" = '{oldver}'
          echo 'DUOFACE_QA182_NEAREST_PUBLIC_ROLLBACK_BYTES_PRESERVED'
          # QA181 remains a historical rollback: verify its original public bytes."""
text=text.replace(old,new)
out=pathlib.Path(a.out);out.write_text(text)
workflow=yaml.safe_load(text)
count=0
for job in workflow['jobs'].values():
 for step in job.get('steps',[]):
  if 'run' not in step:continue
  shell=step['run']
  subprocess.run(['bash','-n'],input=shell,text=True,check=True)
  inpy=False;block=[]
  for line in shell.splitlines():
   if not inpy and "<<'PY'" in line:
    inpy=True;block=[];continue
   if inpy and line=='PY':
    ast.parse('\n'.join(block));count+=1;inpy=False;continue
   if inpy:block.append(line)
  assert not inpy,'unterminated Python heredoc'
assert text.count('assert len(hits)==7,hits')==1
assert newfile in text and oldfile in text
print('QA185_PUBLISHER_YAML_BASH_PYTHON_VALIDATED',count,'python blocks')
