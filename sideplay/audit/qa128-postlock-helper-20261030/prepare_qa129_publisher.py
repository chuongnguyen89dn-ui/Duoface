#!/usr/bin/env python3
"""Prepare existing publisher; preserve QA128 download, select unique signed QA129."""
import argparse,re
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--input',required=True);p.add_argument('--output',required=True);p.add_argument('--archive-sha',required=True);p.add_argument('--deb-sha',required=True);p.add_argument('--run',required=True);a=p.parse_args()
assert re.fullmatch('[0-9a-f]{40}',a.archive_sha)
assert re.fullmatch('[0-9a-f]{64}',a.deb_sha)
assert a.run.isdigit()
s=Path(a.input).read_text()
start=s.index('          # QA128 EXPERIMENTAL:');end=s.index('          cd repo\n',start)
old=s[start:end]
new=old.replace('128','129').replace('manualowner1','nativeowner1')
new=new.replace('signed manual callback ownership correction','native-owner lease and explicit Home cleanup')
new=new.replace('keep QA125 rollback binary','keep QA128 rollback binary')
new=new.replace('a19b59bd8f7a52af0659336575e8889aaa483d42e3dde503c11bfa885aa3b5e8',a.deb_sha)
new=new.replace('6f8d859a4bcde70c5c1efd56efdc99176499f197',a.archive_sha).replace('41025632714',a.run)
tail=s[end:]
tail=tail.replace('0.0.128~manualowner1','0.0.129~nativeowner1').replace('QA128','QA129')
tail=tail.replace('a19b59bd8f7a52af0659336575e8889aaa483d42e3dde503c11bfa885aa3b5e8',a.deb_sha)
assert tail.count('assert len(hits)==82,hits')==1
tail=tail.replace('assert len(hits)==82,hits','assert len(hits)==83,hits')
needle="'0.0.127~ownerreflow1','0.0.129~nativeowner1'"
assert tail.count(needle)==1
tail=tail.replace(needle,"'0.0.127~ownerreflow1','0.0.128~manualowner1','0.0.129~nativeowner1'")
tail=tail.replace('QA129 EXPERIMENTAL manual callback ownership correction; hardware crash, phone-lock Play and GOFA NOT VERIFIED. Same integrated DuoFace package; signed QA127 and QA125 remain downloadable.', 'QA129 EXPERIMENTAL native CarPlay owner retention and explicit Home cleanup; locked Play needs device validation. Same integrated package; signed QA128 remains downloadable.')
s=s[:end]+new+tail
assert old in s and 'DUOFACE_128_FILE=' in s
assert s.count('DUOFACE_129_FILE=')==1
assert 'QA128_SHA_PLACEHOLDER' not in s
Path(a.output).write_text(s)
