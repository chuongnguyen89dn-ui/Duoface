# One-shot DuoFace native admission trace — QUARANTINED development candidate

Current source versions: CarPlay admission 0.0.4~trace1, SpringBoard one-shot reader 0.0.2~target1, iPhone QA 0.1.6~trace1. Native Host unchanged 0.0.1~scenehost1.
**NO PUBLIC SILEO RELEASE. NO DEVICE PROOF.** Maintain released QA 0.1.5 and admission 0.0.3 until an explicit safety gate passes.

Architecture: one UUID request sent from iPhone QA to the existing CarPlay typed getter hooks (no new getter hooks) plus the existing SpringBoard read-only observer (no hooks in SpringBoard). In the audited CarPlay window, the original getter value is returned untouched; the log includes only the own-bundle method, key, class arguments, original return class, PID and clock, maximum 16 samples and 180 seconds. Same UUID in SpringBoard status queries the two original own-bundle entitlement getters after exact ABI and verified bundle ID; it cannot identify a cached-values receiver and it never edits entitlement values. The iPhone app offers a stop/disable action.

Stop immediately on missing consent or kill switch. No postinstall SpringBoard restart, no user navigation through Filza. A newly installed SpringBoard dylib **does not load into the running SpringBoard until the process naturally restarts**; because the user's phone previously had SpringBoard crash loops, this is a HARD BLOCKER to public deployment without proven rollback and positive readiness/loaded-version indication.

LIMITS: This run may identify a concrete typed getter argument mismatch. It does not prove the actual CarPlay library construction time, the exact owning process, SpringBoard cached-value receiver identity, or physical Dashboard icon membership. If no call samples appear, result is INDETERMINATE, not evidence for H1/H3. No more random entitlement spoofing builds.

Evidence needed before ONE parked-car trial: CI tests + built DEB files/hash readback; explicit no-restart recovery; on-phone QA ability to prove new SpringBoard observer has loaded before asking user to test. Real success requires physical car icon and system-issued native-carplay-scene-connected with real system Dock. Preserve QA6/QA11/native12/HUD8.

Offline parser: python3 sideplay/audit/carplay-open-source-20261020/analyze_consolidated_trace.py --trace CarPlayTrace.log --springboard SpringBoardAdmission.log --request-id UUID
Offline tests: python3 -m unittest discover -s sideplay/audit/carplay-open-source-20261020/consolidated_tests -p test_*.py -v

Research map: IOS16_ADMISSION_COVERAGE_MATRIX_20261020.md and IOS16_FIRSTPARTY_ADMISSION_MULTI_SOURCE_REVIEW_20261020.md. Third-party CarSurf code not copied.
