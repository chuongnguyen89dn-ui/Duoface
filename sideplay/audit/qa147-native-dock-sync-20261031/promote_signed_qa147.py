#!/usr/bin/env python3
"""Strict publisher metadata patch; keep immutable QA146 rollback and select QA147."""
import argparse,pathlib,re
OLD='0.0.146~native-home-release1';NEW='0.0.147~native-dock-sync1'
OLD_SHA='1785d5d6bef53337033f5664d5acfc573dabe20892bd629649fab5730b04e078'
def patch(s,commit,run,sha):
 assert re.fullmatch('[a-f0-9]{40}',commit) and re.fullmatch('[a-f0-9]{64}',sha)
 assert str(run).isdigit() and 'DUOFACE_147_FILE=' not in s
 anchor='          cd repo\n          dpkg-scanpackages -m debs /dev/null > Packages'
 assert s.count(anchor)==1
 start=s.index('          # QA146 signed direct-Home exit repair')
 end=s.index(anchor,start)
 oldblock=s[start:end]
 assert 'DUOFACE_146_FILE=' in oldblock
 block=oldblock.replace('146','147').replace(OLD,NEW).replace('0.0.147~native-home-release1',NEW).replace(OLD_SHA,sha)
 oldurl=re.search("DUOFACE_147_URL='([^']+)'",block).group(1)
 file='com.duoface.jb.embedded_'+NEW+'_iphoneos-arm64.deb'
 url=f'https://raw.githubusercontent.com/chuongnguyen89dn-ui/Duoface/{commit}/sideplay/jb-embedded-appbridge/evidence/runs/{run}/{file}'
 block=block.replace(oldurl,url).replace('qa147-native-home-standalone-stop-notified','qa146-native-home-standalone-stop-notified')
 block=block.replace("          print('QA147_SIGNED_NATIVE_HOME_STANDALONE_STOP_RECEIVER_PRESENT_DEVICE_UNTESTED')", "          assert b'qa147-native-dock-active' in car\n          assert b'qa147-native-dock-result-consumer-installed' in car\n          assert b'VerifiedPID' in spring\n          print('QA147_SIGNED_NATIVE_DOCK_LIFECYCLE_COMPONENTS_VERIFIED_DEVICE_PENDING')")
 # Verify cloned download block contains the new exact version and hash.
 assert NEW in block and sha in block and url in block
 tail=s[end:].replace(OLD,NEW).replace(OLD_SHA,sha)
 assert tail.count('assert len(hits)==97,hits')==1
 tail=tail.replace('assert len(hits)==97,hits','assert len(hits)==98,hits')
 ending="'0.0.142~homeabi1','"+NEW+"'},hits"
 assert tail.count(ending)==1
 tail=tail.replace(ending,"'0.0.142~homeabi1','"+OLD+"','"+NEW+"'},hits")
 out=s[:end]+block+tail
 assert out.count('DUOFACE_146_FILE=')==1 and out.count('DUOFACE_147_FILE=')==1
 assert '0.0.2~dockabi2' in out # observer untouched
 return out
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--workflow',type=pathlib.Path,required=True)
 p.add_argument('--artifact-commit',required=True);p.add_argument('--run-id',required=True);p.add_argument('--sha256',required=True)
 p.add_argument('--output',type=pathlib.Path,required=True);a=p.parse_args()
 out=patch(a.workflow.read_text(),a.artifact_commit,a.run_id,a.sha256)
 a.output.write_text(out);print('QA147_STRICT_PUBLISHER_PATCH_PASS',a.sha256)
