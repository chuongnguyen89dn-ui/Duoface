# Actual .55 user CarPlay failure — original split-ratio regression

On 2026-10-23 user confirmed .55 global Zoom unresponsive, circular logo 3s movement nonfunctional, and split-ratio dragging lost. Treat .55 as physical FAIL even though packaging/Sileo checks PASS.

Proven source regression: .55 DFNative12Chrome gestureRecognizer:shouldReceiveTouch deliberately excludes the logo's 12pt extended hitbox from parent divider UIPan; .55 also deleted logo-originated prehold perpendicular ratio dragging present in historical .54. These two actions together block resize whenever the finger starts on the circular logo. Restored .54 cross-axis logic inside existing single UIButton touch owner without introducing a new recognizer; 3-second still-hold then along-bar logo movement remains separate. Restored ratio snap/persist and emit on finger lift. Log actual touch begin/end to isolate the still-unproven 3s failure. Do not claim hardware PASS.

Next root cause: Zoom has multiple native Dock listener processes sharing one command/ACK file, investigate ACK ordering and runtime owner class; do not fabricate successful Dock hide. No new DEB/Sileo from this source checkpoint.
