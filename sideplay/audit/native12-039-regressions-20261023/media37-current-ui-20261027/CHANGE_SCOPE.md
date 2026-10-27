# .74 media host, current UI retained
User corrected whole-.37 rollback: preserve current UI and restore only media host.
DFSceneHost sourced from exact .37 nativehost source 7cd4004d; retained current touch wake and deep logging, layout/commit reentry guards.
DFNative12Chrome.m unchanged blob 9e5772b9d6fef1e2c6f7c0baca23367bda03113a: four physical pane windows already present since .71. Earlier report that .73 shared one window was inaccurate.
Removed .73 app-process relay from build/distribution and remote orientation/IPC path from active host. Archived source-string tests for those retired paths; these are superseded contracts, not hardware results. Existing tests for other UI/input/geometry remain active.
No device success claimed. .37 portrait compatibility may retain historical orientation defects.
