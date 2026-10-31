#!/usr/bin/env python3
"""Pin and locate readiness/startup boundaries, without claiming a device cause."""
import argparse,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,required=True);a=p.parse_args()
root=a.repo/'sideplay/duoface-native-scene-host'
pins={'DFSceneHost.m':'ec2924c145be4edaaa27b7320bb869b18de12c6b',
'DFHomeStandalone144.m':'63b12c0577c0384b779004a216d4782ee7d7661c',
'DFHostedMapRenderSize.h':'dabd6784d94cb7ad5b9f4ad56c123bbd695c22aa',
'DFYouTubeOrientationRelay.plist':'bb8042a571c2580aa6e84108eee8ed14ba4fb3db',
'build.sh':'172f9d2b9740367c66582d1e976889e828059410'}
sources={}
for name,pin in pins.items():
 b=(root/name).read_bytes();assert hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==pin,name
 sources[name]=b.decode()
def line(name,needle):
 s=sources[name];assert s.count(needle)==1,(name,needle,s.count(needle))
 return s[:s.index(needle)].count('\n')+1
loc={
'factory_loads_view':line('DFSceneHost.m','[controller loadViewIfNeeded];'),
'start_adds_view':line('DFSceneHost.m','[self addSubview:appView];'),
'start_sets_lifecycle':line('DFSceneHost.m','DFHostBool(self.appController, @"setAutomatesLifecycle:", NO);'),
'commit_requires_ready':line('DFSceneHost.m','if (self.stopped || self.committingSceneGeometry || !self.window || !self.appController ||'),
'host_emits_ready':line('DFSceneHost.m','postNotificationName:DFSceneHostDidBecomeReadyNotification'),
'owner_ready_callback':line('DFHomeStandalone144.m','- (void)sceneReady:(NSNotification *)notice'),
'owner_requires_verified_pid':line('DFHomeStandalone144.m','if(!pid || self.emittedHosted)return;'),
'owner_adds_surface':line('DFHomeStandalone144.m','[root.view addSubview:v];'),
'owner_pending_after_attach':line('DFHomeStandalone144.m','[self reply:@"pending-scene" reason:'),
'owner_registers_ready_observer':line('DFHomeStandalone144.m','selector:@selector(sceneReady:) name:DFSceneHostDidBecomeReadyNotification')}
assert loc['start_adds_view']<loc['start_sets_lifecycle']
assert loc['owner_adds_surface']<loc['owner_pending_after_attach']
assert sources['DFSceneHost.m'].count('postNotificationName:DFSceneHostDidBecomeReadyNotification')==1
assert sources['DFHomeStandalone144.m'].count('verifiedPIDForHostedView:')==2
assert 'round(pane.width*2.0)' in sources['DFHostedMapRenderSize.h']
print(json.dumps(dict(source_head='5d068755742134b9dfb55ccb7d30a73c837d1d77',git_blob_pins=pins,line_locations=loc,
 observations=['Factory loads controller view before surface start.',
 'Startup adds host view before occlusion/lifecycle flags.',
 'Reference commit requires ready; readiness notification emitted on transition only.',
 'Standalone ready callback requires verified PID. Reply also reads PID, but does not promote pending into ready; no readiness retry is scheduled.',
 'Begin continues after addSubview, even if nested failure already tore down owner.',
 'First-party logical render size already doubles slot bounds; a blanket scale doubling is not justified.'],
 exact_failed_ready_predicate_measured=False,late_pid_causation_proven=False,
 original_runtime_equivalence_proven=False),indent=2))
