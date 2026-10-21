#!/usr/bin/env python3
"""Read-only inspection of a local original DuoNavi 1.0.4 DEB, no network."""
import argparse
import collections
import hashlib
import json
import pathlib
import re
import subprocess
from urllib.parse import urlsplit

URL = re.compile(r"\b(?:https?|wss?)://[^\s\x00<>\"'\x60\\]+", re.I)
HOST = re.compile(r"(?<![\w.@-])(?:[a-z0-9-]+\.)+(?:com|org|net|io|ai|app|dev|cloud|co|vn|cn|info|tech|xyz|me|tv|cc|ru)(?![\w.-])", re.I)
PATTERNS = {
    "openai": r"(?<![a-z])openai(?![a-z])|chatgpt|api\.openai",
    "gemini": r"(?<![a-z])gemini(?![a-z])|generativelanguage\.googleapis",
    "anthropic": r"anthropic|claude",
    "deepseek": r"deepseek",
    "qwen": r"(?<![a-z])qwen(?![a-z])|dashscope",
    "openrouter": r"openrouter", "groq": r"(?<![a-z])groq(?![a-z])",
    "whisper": r"whisper", "elevenlabs": r"elevenlabs",
    "azure_speech": r"azure.*speech|speech\.microsoft",
    "google_speech": r"speech\.googleapis|cloudspeech",
    "apple_speech": r"SFSpeechRecognizer|requiresOnDeviceRecognition|Speech\.framework",
    "cloud_stt_class": r"CBVoiceSTTCloudStreamingProvider",
    "local_stt_class": r"CBVoiceSTTAppleOnDeviceProvider",
    "audio_capture_class": r"CBVoiceAudioCapture",
    "voice_dispatch_class": r"CBVoiceDirectiveDispatcher",
    "ai_bubble_class": r"CBAIBubbleView",
    "network_api": r"NSURLSession|NSURLConnection|CFHTTP|websocket",
}
REGEXES = {k: re.compile(v, re.I) for k, v in PATTERNS.items()}

def strings(data):
    for m in re.finditer(rb"[\x20-\x7e]{5,}", data):
        yield m.start(), m.group().decode("ascii", "ignore")
    for m in re.finditer(rb"(?:[\x20-\x7e]\x00){5,}", data):
        yield m.start(), m.group().decode("utf-16le", "ignore")

def hostname(value):
    try:
        h = urlsplit(value.strip().rstrip(".,);]}")).hostname
        if h and len(h) < 160 and re.fullmatch(r"[a-z0-9.:-]+", h, re.I):
            return h.lower()
    except ValueError:
        pass
    return None

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--deb", required=True, type=pathlib.Path)
    p.add_argument("--out", required=True, type=pathlib.Path)
    a = p.parse_args()
    a.out.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256(a.deb.read_bytes()).hexdigest()
    root = a.out / "extracted"
    root.mkdir(exist_ok=True)
    subprocess.run(["dpkg-deb", "-x", str(a.deb), str(root)], check=True)
    files = sorted(p for p in root.rglob("*") if p.is_file())
    hosts, markers = collections.defaultdict(list), collections.defaultdict(list)
    scanned = 0
    for f in files:
        rel = str(f.relative_to(root))
        if f.suffix.lower() in {".png",".jpg",".jpeg",".webp",".ttf",".otf",".mp4",".mp3",".wav",".caf",".m4a",".aiff",".gif",".pdf"}:
            continue
        if f.stat().st_size > 25000000:
            continue
        scanned += 1
        for off, s in strings(f.read_bytes()):
            for m in URL.finditer(s):
                h = hostname(m.group())
                if h:
                    hosts[h].append({"file":rel,"offset_hex":hex(off+m.start()),"source":"full_url"})
            for m in HOST.finditer(s):
                hosts[m.group().lower()].append({"file":rel,"offset_hex":hex(off+m.start()),"source":"hostname_literal"})
            if len(s) > 2048:
                continue
            for name, pat in REGEXES.items():
                if pat.search(s):
                    markers[name].append({"file":rel,"offset_hex":hex(off)})
    def dedup(entries, limit=10):
        result, seen = [], set()
        for e in entries:
            k = (e["file"], e["offset_hex"], e.get("source"))
            if k not in seen:
                result.append(e)
                seen.add(k)
            if len(result) >= limit:
                break
        return result
    report = {
        "scope":"Static local analysis only; no remote endpoint called",
        "limitations":"Strings do not prove runtime service, usage, credentials, or cost",
        "deb_sha256":digest, "total_files":len(files), "scanned_files":scanned,
        "hostnames":{h:{"references":len(v),"examples":dedup(v)} for h,v in sorted(hosts.items())},
        "markers":{k:{"references":len(v),"examples":dedup(v)} for k,v in sorted(markers.items())}
    }
    (a.out/"static-voice-server.json").write_text(json.dumps(report, indent=2, ensure_ascii=False)+"\n")
    lines = ["# DuoNavi 1.0.4 voice and server static audit", "",
        "No network requests. Hostnames only; no credential, path, query string or token is recorded.",
        "Source SHA-256: "+digest,
        "Files extracted: "+str(len(files))+"; scanned: "+str(scanned), "",
        "## Hostnames embedded in files", "", "| Hostname | Count | Example file |",
        "|---|---:|---|"]
    for h,v in sorted(hosts.items()):
        lines.append("| "+h+" | "+str(len(v))+" | "+v[0]["file"]+" |")
    lines += ["", "## Voice and model-provider markers", "", "| Marker | Count | Example file |",
        "|---|---:|---|"]
    for k,v in sorted(markers.items()):
        lines.append("| "+k+" | "+str(len(v))+" | "+v[0]["file"]+" |")
    lines += ["", "## Interpretation", "",
        "A domain or provider marker in a binary is not evidence of an active runtime connection.",
        "A cloud STT class does not prove an LLM exists; remote runtime configuration may not be visible in static strings.",
        "Do not use this report to infer operating costs or claim successful voice sessions.", ""]
    (a.out/"static-voice-server.md").write_text("\n".join(lines))
    print("=== STATIC FINDINGS ===")
    print("DEB_SHA256", digest)
    print("HOSTNAMES", json.dumps(sorted(hosts)))
    print("MARKERS", json.dumps({k:len(v) for k,v in markers.items()},sort_keys=True))
    print("NO_NETWORK_REQUESTS")

if __name__ == "__main__":
    main()
