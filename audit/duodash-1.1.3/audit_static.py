#!/usr/bin/env python3
"""Read-only inventory of DuoDash 1.1.3 DEB. Does not execute package scripts or binaries."""
import pathlib,struct,re,plistlib,json,hashlib
r=pathlib.Path('/mnt/data/duodash_audit_113/root')
out=pathlib.Path('/mnt/data/duodash_audit_113')
fat_paths={'prefs':'var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/DuoDashPrefs','tweak':'var/jb/usr/lib/TweakInject/DuoDash.dylib','app':'var/jb/Applications/DuoDash.app/DuoDash'}
report={'binary':{},'plist':{},'matched_pref_strings':{},'license_indicators':{},'urls':{}}
for alias,path in fat_paths.items():
  b=(r/path).read_bytes()
  magic=struct.unpack('>I',b[:4])[0]
  assert magic in (0xcafebabe,0xcafebabf),hex(magic)
  is64=magic==0xcafebabf
  n=struct.unpack('>I',b[4:8])[0]
  arches=[]
  for i in range(n):
    fmt='>IIQQII' if is64 else '>IIIII'
    start=8+i*struct.calcsize(fmt)
    v=struct.unpack(fmt,b[start:start+struct.calcsize(fmt)])
    cputype,cpusub,off,size,align=v[:5]
    label='arm64' if (cpusub&0xffffff)==0 else 'arm64e' if (cpusub&0xffffff)==2 else str(cpusub)
    slices=out/'machos';slices.mkdir(exist_ok=True)
    fname=slices/f'{alias}_{label}.macho';fname.write_bytes(b[off:off+size]);arches.append({'arch':label,'file':str(fname),'slice_offset':off,'size':size})
  report['binary'][alias]={'path':path,'arches':arches,'sha256':hashlib.sha256(b).hexdigest()}
  b=(out/'machos'/f'{alias}_arm64.macho').read_bytes()
  pattern=rb'[\x20-\x7e]{4,}'
  raw=[(m.start(),m.group().decode('ascii','replace')) for m in re.finditer(pattern,b)]
  terms=['license','licence','trial','purchase','receipt','activation','activate','verification','verify','expired','expiry','subscription','auth','token','licensekey','license_key','pair','firmware','permission','paid','entitl','billing','status','plan','revoke','serial','keychain','api','http']
  report['license_indicators'][alias]=[{'offset':hex(o),'value':s} for o,s in raw if any(x in s.lower() for x in terms) and len(s)<260]
  report['matched_pref_strings'][alias]=[{'offset':hex(o),'value':s} for o,s in raw if 'prefs.' in s.lower() or re.search('^(hud_|deepsleep_|perf_tweak_|pane_unload_|appbridge_|disconnect_|duodash_|splash_|navbubble_|voicecmd_|headunit_)',s,re.I)]
  report['urls'][alias]=[{'offset':hex(o),'value':s} for o,s in raw if re.search('https?://|wss?://',s,re.I) and len(s)<500]
for name in ['var/jb/Library/PreferenceLoader/Preferences/DuoDashPrefs.plist','var/jb/Library/PreferenceBundles/DuoDashPrefs.bundle/Root.plist']:
  j=plistlib.loads((r/name).read_bytes());report['plist'][pathlib.Path(name).name+'@'+('Loader' if '/PreferenceLoader/' in name else 'Root')]={'path':name,'count':len(j['items']),'items':[{'i':i,'type':item.get('cell'),'label':item.get('label'),'key':item.get('key'),'default':item.get('default'),'notification':item.get('PostNotification'),'action':item.get('action'),'valid_values':item.get('validValues'),'valid_titles':item.get('validTitles'),'footer':item.get('footerText')} for i,item in enumerate(j['items'])]}
(out/'audit_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
print('BINARY',[(k,[(x['arch'],x['size']) for x in v['arches']]) for k,v in report['binary'].items()]);print('PLIST',[(k,v['count']) for k,v in report['plist'].items()]);print('MATCHED_PREF_COUNTS',{k:len(v) for k,v in report['matched_pref_strings'].items()});print('LICENSE_INDICATOR_COUNTS',{k:len(v) for k,v in report['license_indicators'].items()});print('URL_COUNTS',{k:len(v) for k,v in report['urls'].items()})
for alias in ('prefs','tweak','app'):
  print('\n====',alias,'LICENSE/ACTIVATION EXACT STRINGS')
  print('\n'.join(x['value'] for x in report['license_indicators'][alias] if re.search(r'licen[sc]|trial|subscription|receipt|expir|purchase|register|activat|verif|entitl|billing|serial|keychain',x['value'],re.I))[:11000])
  print('\nURLs:','\n'.join(x['value'] for x in report['urls'][alias][:45]))
