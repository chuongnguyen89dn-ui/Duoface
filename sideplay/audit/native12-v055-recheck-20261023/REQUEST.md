# Request: ACTUAL BINARY AUDIT ONLY, no package build/no Sileo
Date: 2026-10-23.
Source baseline: 8a5c976179a322ba6769c6d2e16e2e33248165dc
GitHub Actions: .github/workflows/native12-v055-actual-deb-audit.yml
Inputs: SHA-pinned Native12 Speed8Compact, existing published .54, staged signed .55.
Purpose: verify real DEB package metadata/Mach-O and source/selector parity limits, without loading vendor binaries, without touching licensing, without any publishing or iPhone install.
