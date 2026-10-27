# Build request .79 nativeocclusion1

User requests a new DEB based on the original Native12. Single host change: setIgnoresOcclusions:YES as verified in original start IMP at ae450; .78 used NO. This is a device-test candidate, not proof of foreground crash resolution. No foreground or lock setters added. Keep existing UI, media frame, logo and Dock. Build nativehost 0.1.88~nativeocclusion1 and integrated 0.0.79~nativeocclusion1, archive signed SHA and publish to Sileo after checks. No device test or automatic respring.
