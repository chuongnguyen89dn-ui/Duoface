# QA138 black CarPlay: confirmed recursive LS hook, not an assumed scene-size fault

## Actual user inputs
GitHub main upload dc147684b2a30dcef92f1e4d8f614dfa878d4c38 contains DuoFaceAudit18.txt (6,307,960 bytes, 24,423 lines, SHA25645cc113224b150b8ff5d5b74561b57213b98bb54ea3cdf702bb0be64aacb5243) and THREE new CarPlay .ips reports at10:18:02,10:18:13,10:18:24+0700. This new evidence supersedes prior unknown-cause checkpoint. Existing Log17 CarPlayTemplateUIHost SIGABRT is a different incident.

## Direct result
All three new reports are real CarPlay process, main thread, EXC_BAD_ACCESS/SIGSEGV KERN_PROTECTION_FAILURE in STACK GUARD. Each captured511 frames, dominated by repeating DF138Answer -> DF138Entitlement3 -> DFFirstPartyAdmission forwarding frames (>100 repeated triples). Crash PIDs89740,89741,89744 occur in Home138 startup log. All three loaded DFCarPlayDockOwner UUID26f13ecd-22fa-3fe0-8350-fc80dc45c526, EXACT match to public QA138 signed archive f85cdecc, run41162732197 QA138_MACHO_UUIDS.txt. Thus this is the published QA138, not a historical wrong build.

Home138 startup log shows20 distinct CarPlay PIDs89719..89744 between10:15:11 and10:18:22, all hooks armed with Home switch1. ZERO selected-LS-inclusion/policy/declaration/factory-return messages. This supports crash/relaunch during initial native LS inclusion before successful Home startup. Old geometry/fatal export entries are historical and must not be used to claim current138 GOFA or scene frame activity.

## Responsible source path
DFHomeAdmission138.m: DF138Answer calls its saved original TWO-argument getter again to inspect CARCapableApp/SBStarkCapable. On the actual iOS16 forwarding chain, the saved existing admission wrapper eventually dispatches the THREE-argument getter, which is also hooked by138. That reenters DF138Answer, repeats the native-capability query and overflows the main-thread stack. Calling a saved original IMP is not a cross-selector reentrancy guard. Top CF plist parsing frames reflect config reads within the recursive path, not proof of a corrupted plist.

The earlier mock tests returned nil directly from the saved getter, so they did not model real two-to-three-argument forwarding and did not expose the bug. Before any future Home code ships, add a behavioral cross-getter forwarding/reentry case and eliminate recursive native checks or guard the whole typed-query chain per thread. Do not simply re-enable138 based on exact method encodings or build success. GOFA layout receiver is absent from the crashing stack; its original boxed-view cause remains unproven.

## Recovery and reproduction
QA139 signed source46a138c2f5e92514abcd244d8d25eb570c456386 restores exact QA137 runtime, removes the offending138 module and GOFA receiver from shipped code, retains source for audit. CI verified exact source bytes, signing and package absence markers. Public139 SHAdea8ede6af005f6b3160a032ddae885f79844e8300d06b0f84b5eafa22596090. Device UI recovery requires user confirmation after139 install and respring; it is not inferred from public release success.

Actually executed from isolated Duoface-recovery139 root:
`python sideplay/audit/qa139-black-screen-recovery-20261031/analyze_log18_recursion.py --log /tmp/duoface-log18.txt --ips /tmp/Crash-0-CarPlay-2026-10-31-101825.ips /tmp/Crash-1-CarPlay-2026-10-31-101814.ips /tmp/Crash-2-CarPlay-2026-10-31-101803.ips --out sideplay/audit/qa139-black-screen-recovery-20261031/LOG18_RECURSION_RESULT.json`
All three real IPS recursive-pattern/STACK GUARD/QA138 UUID/PID assertions PASS. To restore input paths, `git show dc147684b2a30dcef92f1e4d8f614dfa878d4c38:sideplay/log/<exact filename>` to the listed /tmp paths. JSON records hashes and sample frames; source files already persist under main/sideplay/log, no duplicate raw6MB copy required.
