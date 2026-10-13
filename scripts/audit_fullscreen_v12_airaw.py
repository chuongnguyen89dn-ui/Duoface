#!/usr/bin/env python3
"""Read-only audit for the user-supplied DuoFace v12 and Airaw DEB files."""
import argparse
import hashlib
import json
import pathlib
import subprocess
import tempfile

NEED = [
    "DBDockWindow", "DBApplicationViewController", "toggleFullscreen",
    "requestFullscreenToggle", "setNativeChromeHidden:", "savedRect",
    "savedEdgeInsets", "expandTapped:", "setFrame:", "setBounds:",
]


def audit(path):
    path = pathlib.Path(path)
    with tempfile.TemporaryDirectory() as root:
        subprocess.run(["dpkg-deb", "-x", str(path), root], check=True)
        matches = {}
        dylibs = list(pathlib.Path(root).rglob("*.dylib"))
        for dylib in dylibs:
            blob = dylib.read_bytes()
            found = [name for name in NEED if name.encode() in blob]
            if found:
                matches[dylib.name] = found
        def field(name):
            return subprocess.check_output(["dpkg-deb", "-f", str(path), name], text=True).strip()
        return {
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "package": field("Package"),
            "version": field("Version"),
            "dylibs": len(dylibs),
            "selector_matches": matches,
        }


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--v12", required=True)
    parser.add_argument("--airaw", required=True)
    args = parser.parse_args()
    print(json.dumps({"v12": audit(args.v12), "airaw": audit(args.airaw)}, indent=2))
