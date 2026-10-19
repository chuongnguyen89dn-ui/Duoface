#!/usr/bin/env python3
"""Forensic Native12 Mach-O call graph, nonexecuting, ObjC dispatch uncertainty tagged.

Reads SHA-pinned method-index and extracted original DEB, never executes any
program from the DEB. LLVM Mach-O disassembly is assigned to LC_FUNCTION_STARTS
and exact Objective-C IMP. Selector matches are CANDIDATES, not proven receivers.
"""
import argparse,bisect,collections,gzip,hashlib,json,pathlib,re,subprocess,os
from native12_objc_stub_decoder import decode_objc_stubs
INSN=re.compile(r'^\s*([0-9a-fA-F]+):\s+(\w[\w.]*)\s*(.*)$')
OBJ=re.compile(r'Objc message:\s*([+-])\[([^\]]+?)\s+([^\]]+)\]')
BL=re.compile(r'^\s*(0x[0-9a-fA-F]+)')
SYM=re.compile(r'^\s*(_[A-Za-z_][A-Za-z0-9_.$]*)')
GROUPS={
'host/CarBridge':['BridgeManager','BridgedApp','BridgedUIApp','BridgeRequest','AppStateListener','CBWindow','DashboardShared'],
'split/ratio/gesture':['SplitApp','Divider','Slot','SplitView','SplitSplash','LogoGrip'],
'picker/menu/settings':['Picker','Settings','AppsManager','AppSection','AppSwitch','RootView','Menu'],
'CarPlay Dock/fullscreen':['Dock','Fullscreen','Zoom','Chrome'],
'HUD/speed/assistant':['Speed','HUD','Assistant','Metric','Monitor'],
'LICENSE - EXCLUDE':['License','Subscription','Checkout','VIP','HttpClient']}
def cat(name):
 for g,words in GROUPS.items():
  if any(w.lower() in name.lower() for w in words):return g
 return 'other'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def shell(*args):
 cmd=['xcrun','llvm-objdump',*args] if os.getenv('LLVM_USE_XCRUN')=='1' else ['llvm-objdump',*args]
 r=subprocess.run(cmd,text=True,encoding='utf-8',errors='replace',capture_output=True)
 if r.returncode:raise RuntimeError(' '.join(cmd)+' '+r.stderr[-500:])
 return r.stdout
def analyze(path,rec,selector_index):
 meth=rec['objc_methods'];imap=collections.defaultdict(list)
 for m in meth:imap[int(m['imp'],16)].append(m)
 starts=sorted(set(map(lambda s:int(s,16),rec['lc_function_starts']))|set(imap))
 sections=shell('-h',str(path))
 objc_stubs=[]
 for line in sections.splitlines():
  p=line.split()
  if len(p)>=4 and p[1]=='__objc_stubs':
   lo=int(p[3],16);objc_stubs.append((lo,lo+int(p[2],16)))
 resolved_stubs=decode_objc_stubs(path)
 parsed=collections.defaultdict(lambda:dict(objc=[],direct=[],external=collections.Counter(),
                      unresolved=0,indirect=0,insns=0,branches=0))
 for line in shell('--macho','--disassemble','--no-show-raw-insn',str(path)).splitlines():
  m=INSN.match(line)
  if not m:continue
  pc=int(m.group(1),16);opcode=m.group(2);operand=m.group(3)
  ix=bisect.bisect_right(starts,pc)-1
  if ix<0:continue
  k=starts[ix];d=parsed[k];d['insns']+=1
  if opcode in ('blr','blraa','blraab','blraaz'):d['indirect']+=1
  if opcode!='bl':continue
  d['branches']+=1
  o=OBJ.search(operand)
  if o:
   sig,recv,sel=o.groups()
   explicit=not re.fullmatch(r'[xw]\d+|fp|sp|self|super',recv)
   candidates=selector_index.get((sig,sel),[])
   if explicit:candidates=[c for c in candidates if c['class']==recv]
   d['objc'].append({'pc':hex(pc),'type':sig,'receiver':recv,'selector':sel,
      'certainty':'EXPLICIT_CLASS_SELECTOR_CANDIDATE' if explicit else 'DYNAMIC_RECEIVER_SELECTOR_CANDIDATE',
      'candidate_count':len(candidates),'candidate_methods':candidates[:24]})
   continue
  addr=BL.search(operand)
  if addr:
   target=int(addr.group(1),16)
   if target in resolved_stubs:
    stub=resolved_stubs[target]
    sel=stub['selector']
    # Exact selector from __objc_selrefs; receiver x0 remains dynamic.
    cands=[entry for key,entries in selector_index.items()
           if key[1]==sel for entry in entries]
    d['objc'].append({'pc':hex(pc),'type':'unknown +/-','receiver':'dynamic x0',
          'selector':sel,'certainty':'OPTIMIZED_STUB_SELECTOR_EXACT_RECEIVER_UNKNOWN',
          'objc_stub':stub,'candidate_count':len(cands),'candidate_methods':cands[:24]})
   elif any(lo<=target<hi for lo,hi in objc_stubs):
    d['unresolved']+=1
   if target in imap:
    d['direct'].append({'pc':hex(pc),'imp':hex(target),'methods':imap[target]})
   else:
    stub=re.search(r'symbol stub for:\s*(\S+)',operand)
    if stub:d['external'][stub.group(1)]+=1
  else:
   sm=SYM.search(operand)
   if sm:d['external'][sm.group(1)]+=1
 methods=[]
 for addr,methods_at in sorted(imap.items()):
  call=parsed[addr]
  for meth0 in methods_at:
   methods.append({'class':meth0['class'],'kind':meth0['kind'],
      'selector':meth0['selector'],'type':meth0['type'],'imp':hex(addr),
      'group':cat(meth0['class']),'instructions':call['insns'],
      'objc_callsites':call['objc'],'static_branch_methods':call['direct'],
      'unresolved_objc_stubs':call['unresolved'],'unresolved_indirect_calls':call['indirect'],
      'external_or_named_symbol_calls':dict(call['external'])})
 orphans=[{'address':hex(addr),'insns':d['insns'],'bl_calls':d['branches'],
           'objc_callsites':d['objc'][:120],'objc_stubs_unresolved':d['unresolved'],
           'external_symbol_calls':dict(d['external'])}
          for addr,d in sorted(parsed.items()) if addr not in imap and d['branches']]
 return {'binary':rec['filename'],'sha256':sha(path),'methods':methods,
   'function_starts':len(starts),'orphan_c_functions_with_calls':orphans,
   'stats':{'objc_methods':len(meth),'lc_function_starts':len(rec['lc_function_starts']),
    'objc_stub_selectors_resolved':len(resolved_stubs),
    'recognized_selector_calls_in_methods':sum(len(m['objc_callsites']) for m in methods),
    'recognized_selector_calls_in_orphan_functions':sum(len(x['objc_callsites']) for x in orphans),
    'unresolved_objc_stub_calls_in_methods':sum(m['unresolved_objc_stubs'] for m in methods),
    'unresolved_objc_stub_calls_in_orphans':sum(x['objc_stubs_unresolved'] for x in orphans)}}
def main():
 a=argparse.ArgumentParser()
 for x in ['payload','method-index','output']:a.add_argument('--'+x,required=True)
 v=a.parse_args();root=pathlib.Path(v.payload);out=pathlib.Path(v.output)
 out.mkdir(parents=True,exist_ok=True)
 index=json.loads(pathlib.Path(v.method_index).read_text())
 index=index['native12']
 bysel=collections.defaultdict(list)
 for b in index:
  for m in b['objc_methods']:
   bysel[('+' if m['kind']=='class' else '-',m['selector'])].append({
     'binary':b['filename'],'class':m['class'],'selector':m['selector'],'kind':m['kind'],'imp':m['imp']})
 lookup={p.name:p for p in root.rglob('*') if p.is_file()}
 summaries=[];focus=[]
 for rec in index:
  name=rec['filename'];path=lookup[name]
  if sha(path)!=rec['sha256']:raise RuntimeError('Mach-O SHA mismatch '+name)
  data=analyze(path,rec,bysel)
  output=out/(name+'.json.gz')
  with gzip.open(output,'wt',encoding='utf8',compresslevel=8) as f:
   json.dump(data,f,ensure_ascii=False,separators=(',',':'))
  stats=data['stats']
  summaries.append({'binary':name,'sha256':data['sha256'],'file':output.name,
                    'function_starts':data['function_starts'],**stats,
                    'unresolved_indirect':'potentially not fully resolved'})
  for m in data['methods']:
   if any(k in m['class'] for k in ('BridgeManager','BridgedSplitApp','Window',
       'DashboardShared','Divider','Picker','Settings','Fullscreen','Speed','HUD',
       'Visual','XXApp','CBAppManager','CBSplitViewController','Assistant','Dock')):
    focus.append({'binary':name,**m})
  print('NATIVE12_AUDIT',name,stats,flush=True)
 with gzip.open(out/'FOCUSED_METHODS.json.gz','wt',encoding='utf8',compresslevel=8) as f:
  json.dump(focus,f,ensure_ascii=False,separators=(',',':'))
 (out/'SUMMARY.json').write_text(json.dumps({'static_not_runtime':True,
      'source_deb_sha256':'2fe8892c5ef8762e1e83b0fd6c4a029e25fc11758cc98fdbbb851bf6637e68ad',
      'selector_edges_are_candidates':True,'binaries':summaries},
      ensure_ascii=False,indent=2)+'\n')
 assert len(summaries)==8 and sum(x['objc_methods'] for x in summaries)==1385
 print('NATIVE12_8_BINARIES_1385_METHODS_STATIC_AUDIT_PASS')
if __name__=='__main__':main()
