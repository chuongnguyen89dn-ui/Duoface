import datetime,gzip,hashlib,json,os,pathlib,subprocess,time,urllib.request
SITE='https://chuongnguyen89dn-ui.github.io/carplaydsp'
VERSION='0.0.185~admission1'
FILE='com.duoface.jb.embedded_'+VERSION+'_iphoneos-arm64.deb'
EXPECTED='4c4711ac9f048fa1dd63de6e7757a34c6abc59d30e76a5405d03393f96efde30'
def fetch(path):
 with urllib.request.urlopen(SITE+'/'+path,timeout=35) as response:return response.read()
def stanzas(data):
 out=[]
 for block in data.decode().split('\n\n'):
  d={}
  for line in block.splitlines():
   if ': ' in line and not line.startswith(' '):
    key,value=line.split(': ',1);d[key]=value
  if d:out.append(d)
 return out
def digest(data):return hashlib.sha256(data).hexdigest()
for attempt in range(1,41):
 try:
  packages=fetch('Packages');compressed=fetch('Packages.gz');release=fetch('Release')
  entries=stanzas(packages)
  hits=[d for d in entries if d.get('Package')=='com.duoface.jb.embedded']
  assert len(hits)==1,hits
  entry=hits[0]
  assert entry['Version']==VERSION,entry.get('Version')
  assert entry['SHA256']==EXPECTED
  assert entry['Size']=='1291416'
  assert entry['Architecture']=='iphoneos-arm64'
  assert entry['Filename']=='debs/'+FILE
  assert gzip.decompress(compressed)==packages
  rows={};inside=False
  for line in release.decode().splitlines():
   if line and not line.startswith(' '):inside=line=='SHA256:'
   elif inside and line.strip():
    sha,size,name=line.split();rows[name]=(sha,int(size))
  for name,data in [('Packages',packages),('Packages.gz',compressed)]:
   assert rows[name]==(digest(data),len(data)),name
  break
 except Exception as error:
  print('QA185_PUBLIC_WAIT',attempt,type(error).__name__,str(error)[:300],flush=True)
  if attempt==40:raise
  time.sleep(15)
data=fetch('debs/'+FILE)
assert len(data)==1291416 and digest(data)==EXPECTED
temp=pathlib.Path(os.environ['RUNNER_TEMP'])
deb=temp/FILE;deb.write_bytes(data)
assert subprocess.check_output(['dpkg-deb','-f',str(deb),'Version'],text=True).strip()==VERSION
old='com.duoface.jb.embedded_0.0.182~b1nativemaps1_iphoneos-arm64.deb'
rollback=fetch('debs/'+old)
assert digest(rollback)=='a879bc6e617f72b51e2d763b216626f5240495d94a6c1da2abff30b60d0e9860'
assert len(rollback)==1274984
receipt={'checkedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'site':SITE,'package':entry,'bytes':len(data),'sha256':digest(data),
 'packagesSHA256':digest(packages),'packagesGzipMatches':True,'releaseSHA256Matches':True,
 'rollback182SHA256':digest(rollback),'signedSource':'5bdf81e348f11e474ba2d1e39611e49c83b02dd0',
 'signedBuildRun':42343166133,'publisherCommit':'18868b4b324b8e90998b9fe4a27d2f23bcac9747',
 'independentVerifyRun':os.environ['GITHUB_RUN_ID'],'sileoPublished':True,'deviceTested':False}
(temp/'QA185_PUBLICATION_RECEIPT.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('QA185_PUBLIC_APT_GZIP_RELEASE_EXACT_SIGNED_DEB_AND_QA182_ROLLBACK_PASS',json.dumps(receipt),flush=True)
