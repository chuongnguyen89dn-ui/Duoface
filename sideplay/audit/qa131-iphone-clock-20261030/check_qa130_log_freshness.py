#!/usr/bin/env python3
"""Strict provenance check: latest uploaded logs predate QA130 public release.

No user-device or iOS runtime execution here. The 0.0.90 exporter tag is
hardcoded in DFDeepTrace; never treat it as the loaded tweak build.
"""
import argparse,datetime,hashlib,json,pathlib,re
ap=argparse.ArgumentParser()
ap.add_argument("--audit13",type=pathlib.Path,required=True)
ap.add_argument("--audit12",type=pathlib.Path,required=True)
ap.add_argument("--out",type=pathlib.Path,required=True)
a=ap.parse_args()
public=datetime.datetime(2026,10,30,12,14,16,tzinfo=datetime.timezone.utc)
rows={}
for label,path in (("DuoFaceAudit 12.txt",a.audit12),("DuoFaceAudit 13.txt",a.audit13)):
 data=path.read_bytes();head=data[:800].decode("utf-8","replace")
 match=re.search(r"Date:\s*(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) \+0000",head)
 if not match:raise SystemExit("missing exact export date: "+label)
 capture=datetime.datetime.strptime(match.group(1),"%Y-%m-%d %H:%M:%S").replace(tzinfo=datetime.timezone.utc)
 if not capture<public:raise SystemExit("unexpected NEW post-QA130 audit; re-evaluate: "+label)
 if b"qa131-iphone-display-clock-observed" in data:
  raise SystemExit("unexpected QA131 in pinned historical audit: "+label)
 rows[label]={"capture_utc":capture.isoformat(),"precedes_public_QA130":True,
              "bytes":len(data),"sha256":hashlib.sha256(data).hexdigest(),
              "has_QA131_frame_probe":False}
result={"source":"GitHub main sideplay/log, two latest user uploads (not from current handset)",
        "QA130_public_Sileo_verified_utc":public.isoformat(),
        "inputs":rows,
        "proves_QA130_lock_touch_cause":False,
        "does_not_contain_same_session_QA130_onscreen_offscreen_touch_or_play_ack":True,
        "QA131_diagnostic_needed_before_causal_claim":True,
        "permitted_inference":"Only latest available uploaded audits predate public QA130, not that a specific device BKS pathway fixes touch"}
a.out.parent.mkdir(parents=True,exist_ok=True)
a.out.write_text(json.dumps(result,indent=2,ensure_ascii=False)+"\n")
print("QA130_UPLOADED_AUDITS_PREDATE_PUBLIC_RELEASE_NO_SAME_SESSION_CAUSAL_PROOF")
