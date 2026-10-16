# DuoFace native13/native14 — tình trạng hai tính năng và giấy phép

**Ngày 16/10/2026.** Người dùng cho phép build và đưa Sileo test **nếu đã hoàn tất cả hai tính năng và xóa phần giấy phép còn lại**. Trạng thái thực tế: CHƯA publish Sileo, CHƯA device test.

## Mốc đã xác minh

- Source branch: feature/duoface-exact-payload-migration. Native12 immutable SHA256: 85d754ea887eb8dd0659f65a5b2e3425564f617983937579753bad1a69433bf7.
- Github Actions 38843479440 SUCCESS: Smart Connection 10s source hook compile/link. 38846229342 SUCCESS: in-Car Add App Logos source compile/link. Hai tính năng source-level PASS, CHƯA QA thiết bị.
- GitHub Actions 38847147300 SUCCESS: artifact candidate com.duoface.independent 0.1.0~native13, sha256 cff76573be10a73bfd423e988b803812e3375af4db6567a9229c1b04156f2cf3. Path: feature:dist/payload-migration/native13/com.duoface.independent_0.1.0~native13_iphoneos-arm64.deb.
- feature:dist/payload-migration/native13/BAO_CAO.json blob 42f76b0ee37313ae2846e4c63735ecb46ec46e49: both signed modules included, 39 baseline entries unchanged, five CarPlay/visual hosts byte-identical, old separate license hook absent. Existing license class metadata NOT removed, sileo_published=false, device_tested=false.
- carplaydsp/main remains Sileo native12 at checked commit 38cbd8c1e908ec9667d8a7b073a31d0206fec7bf; do NOT describe native13 as Sileo released.
- 38847024746 SUCCESS (ARM64 classref xrefs), 38847304041 SUCCESS (containing-method attribution): three static direct xrefs to two isolated license classes in DuoFaceUI.XXRootViewController.checkAndPresentLicenseModalIfNeeded; zero found in Dashboard. Dynamic ObjC liveness unproven.

## Physical-license-removal blocker in actual GitHub CI

- Current trial source: feature:migration/full_payload/native_test/build_native14_license_class_trial.py. This attempts unregister of 14 isolated classes / 249 ObjC methods, nulling 42 pointer slots, while preserving actual instructions and resigning hosts. It is an EXPERIMENTAL QA candidate, not a confirmed safe release.
- Run 38847590705 FAIL: AssertionError: ('CBSubscriptionCheckoutCell', 'remaining literal'). No DEB output.
- Run 38847893656 FAIL: ValueError: ('CBSubscriptionCheckoutCell', 695390, 'non terminated extra, refuse unsafe erase', '__objc_methname', '...T@"<CBSubscriptionCheckoutCellDelegate>",W,N,V_delegate...'). Extra name is embedded in a live Objective-C delegate protocol/type metadata string, not a standalone NUL-terminated class name. Blind erasure may corrupt type metadata; do NOT bypass assertion and falsely claim full cleanup.
- Physical unregistration, ABI/dynamic liveness, and all remaining license code/literals have NOT been verified complete. Native14 signed package does not exist yet.
- A second native14 CI workflow was mistakenly added while another workflow was already present. To avoid duplicate push builds, secondary .github/workflows/duoface-native14-license-excision-trial.yml was made workflow_dispatch-only in commit 5d28c8ae51a81ff1b5165f3ade50ee52590dcb89. Original duoface-native14-license-class-trial.yml remains automatic owner.
- Diagnostic source commit d09dbcec5bd291be25d814ef8a947258f441983e adds safe leftover-class-name auditing, no blind zeroing.

## Next action / release criteria

1. Resolve exactly the ObjC type-encoding/protocol string ownership and whether leftover embedded class names can remain as metadata. Verify static xref owners and any dynamic class lookup risk. Do not blindly patch actual method type signatures.
2. Re-run the existing native14 CI on source changes only; require signed package QA, classlist count regression, original CarPlay detector functions intact. Any leftover shared license method strings must be explicitly disclosed, never falsely labeled full removal.
3. Publish com.duoface.independent via carplaydsp/main build.yml only after the requested combined feature/license QA gate is honestly met. Keep native12 Sileo rollback and native13 unpublished candidate. No unauthorized unrelated package changes.
4. On-device CarPlay/Settings QA (10s disconnect, anti-duplicate, App Picker, persistence, startup) cannot be claimed completed from compile-only GitHub Actions.

**Checkpoint:** Two new features packaged in native13 offline candidate; license excision blocked by embedded protocol string and unresolved dynamic liveness; Sileo unchanged.
