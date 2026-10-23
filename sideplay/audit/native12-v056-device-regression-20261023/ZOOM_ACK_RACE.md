# Device .55 global Zoom multi-process ACK race

DFCarPlayDockOwner.plist injects CarPlay, CarPlayApp, dashboard; all observe one dockzoom command and share one ACK file. Before this patch first negative ACK aborted DFDockZoomToggle. On head-unit one non-owner process can reply faster than actual owner, yielding false rejection. Coordinator now retains negative reason and waits bounded 3 seconds for same-request verified positive Dock owner ACK. Receiver guards against negative clobbering a matching real positive ACK. This cannot fake a successful Dock hide or host fullscreen geometry. Actual .55 Zoom remains user-confirmed FAIL. Device logs needed if new build still fails.

Ratio resize deterministic regression fixed in previous commit 3b3be376: .55 removed perpendicular drag from circular grip while parent pan excludes grip touches. 3.0s long hold for logo movement still requires device confirmation. No DEB/Sileo artifacts from this source-only commit.
