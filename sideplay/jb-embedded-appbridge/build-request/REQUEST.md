# Build request: DuoFace .78 scene generation repair

User explicitly requests new DEB and Sileo publication, 2026-10-27.
Source fix b96e079aa9a038ff00f7477c98fffa08849ef5ee passed source iOS16 CI 40465674407.

Build current independent code with generation revocation on scene replacement, loss of hosting/window ownership and stop; recheck exact current hosted scene inside deferred frame callback. Keep existing media dimensions and Chrome controls. No new foreground/lock flags or third-party changes.

Versions: NativeHost 0.1.87~scenegeneration1; integrated 0.0.78~scenegeneration1.
Run existing full compile, signature, packaging and archival checks. Publish exact SHA-pinned artifact after success as requested. This fixes stale callbacks; does not establish the source of foreground NO or prove the Live/foreground assertion resolved. Real-device playback and crash acceptance remain untested. No automatic install/respring.
