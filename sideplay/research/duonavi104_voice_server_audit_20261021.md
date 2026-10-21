# DuoNavi 1.0.4 Voice AI / server verification — 2026-10-21

## Scope and evidence

- **Source:** `dist/com.duonavi.app_1.0.4_iphoneos-arm64.deb` (original, preserved).
- **Verified SHA-256:** `f3f911de5db461d487ce91249aed1bb25d44f076e7ff5fb89e54b658569328dd`.
- **Read-only workflow:** [Run 39574435016](https://github.com/chuongnguyen89dn-ui/Duoface/actions/runs/39574435016); job 119136319844 **completed successfully**.
- **Artifact:** `duonavi104-voice-server-static-audit`, artifact ID `12333661440`, containing `static-voice-server.md` and `static-voice-server.json`.
- **Script:** `sideplay/tools/duonavi_voice_static_audit.py`.
- **Scope:** 50 files extracted, 8 executable/configuration files scanned. No requests to vendor/API endpoints. **No DEB build, Sileo publish, or device test.**

## Verified static results

Hostnames in shipped strings: `duonavi.com` (4 references), `com.apple.tv` (4), `springboard.app` (1), `subject.cn` (7), `www.apple.com` (4). These may represent marketing URLs, framework identifiers, certificate/configuration literals; **none is verified as a Voice AI backend**.

Markers detected:
- `CBVoiceSTTCloudStreamingProvider`: 10
- `CBVoiceSTTAppleOnDeviceProvider`: 28
- Apple Speech symbols: 14
- `CBVoiceAudioCapture`: 48
- `CBVoiceDirectiveDispatcher`: 8
- `CBAIBubbleView`: 8
- General network API markers: 82

Not found by exact-marker search: OpenAI, ChatGPT, GPT provider, Gemini, DeepSeek, Anthropic/Claude, Qwen, OpenRouter, Groq, Whisper, ElevenLabs, Azure Speech or Google Cloud Speech.

**Meaning:** The shipped application implements speech capture/recognition and directive processing. There is not enough evidence to identify a remote voice endpoint, its active provider, any conversational LLM, or the developer's per-usage cloud costs. Apple Speech may route recognition to Apple servers when on-device recognition is unavailable/not required. It is unsafe to conclude that DuoNavi operates entirely offline from these strings alone.

## Cost interpretation, separate from server forensic work

DuoNavi official pricing page https://duonavi.com/pricing advertises Voice AI included in its 7-day trial, US$10 six-month license and US$25 lifetime license, without a separately advertised voice-AI usage charge. This does **not** prove backend operations are free to the developer or that unlimited general-purpose AI conversations are provided.

A DuoFace assistant relying on local/native speech recognition, rule-based command routing and on-device speech output can avoid a per-token commercial LLM bill; a general-purpose remote AI conversation service or hosted speech service may incur usage fees and/or server cost.

## Limitations / next evidence needed

1. `CBVoiceSTTCloudStreamingProvider` exists, but its vendor configuration/call targets are not identified.
2. Full compiled code, dynamic/obfuscated endpoints, TLS runtime requests and remote config cannot be proven from strings alone.
3. To identify a real host, obtain consented on-device diagnostics from the user's own DuoNavi 1.0.4 session; log **hostnames only** (no contents, credentials or other users' traffic), and separately capture the voice-session state so licensing connections aren't mistaken for STT.
4. Do not connect to third-party private endpoints, replay unknown requests or use extracted secrets.
5. Preserve all existing DuoFace release branches, source and Sileo metadata. This branch is research-only.
