#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Read-only DuoFace native9 license vs CarPlay boundary reconciliation.

The user's tested-good native9 is never modified. This is a source-report
reconciliation, NOT a patcher and NOT proof of all runtime callsites. It
cross-references native4's exact modified Objective-C methods, native5's
method ledger, native6's residual-string catalog, and native9's exact masks.

Intentionally preserves data keys, Objective-C dynamic-dispatch identifiers,
CarPlay/screen detection and lifecycle. Never performs substring-based
binary deletion, false license validation, or runtime hooking.

Run at the DuoFace repository root:
  python3 scripts/audit_duoface_native9_license_keep_vs_hide.py \
      --out audit/payload-migration/NATIVE9_LICENSE_KEEP_VS_HIDE_READONLY.json
"""
from __future__ import annotations

import argparse
import ast
from collections import Counter
from hashlib import sha256
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
R = "dist/payload-migration"
A = "audit/payload-migration"
FILES = {
    "method_edits": f"{R}/native4/BAO_CAO.json",
    "method_ledger": f"{R}/native5/DANH_SACH_CHO_XOA.json",
    "method_and_ui_staging": f"{R}/native5/BAO_CAO.json",
    "native6_zero_data": f"{R}/native6/BAO_CAO.json",
    "native6_inventory": f"{A}/NATIVE6_REMAINING_LICENSE_READONLY.json",
    "native9_package": f"{R}/native9/BAO_CAO.json",
    "native9_regression": f"{A}/NATIVE9_RESTORE_VISUAL_AND_GRIP_REGRESSION.json",
    "native9_brand": f"{R}/native9/BRAND_ZERO_AUDIT.json",
    "license_boundary": f"{A}/LICENSE_BOUNDARY_AUDIT.json",
    "list_39_display_labels": "migration/full_payload/native_test/build_native7.py",
    "grip_only_source": "src/DuoFaceLogoGripOnly.m",
}
NATIVE9_SHA = "e4e1122a494d32af6ec42c97c4288f6effb6716fbb81cb52b81b746280d4d97e"
NATIVE6_SHA = "88b0e9358c075e2131ddb9e6ac25689584765d1285120e2e3282ce8a5bb3df15"
CARPLAY = {
    "isCarPlayScreenConnected",
    "isCarPlayScreen:",
    "isCarPlayScreenConnectedExcludingScreen:",
}
LIFECYCLE = {"init", "sharedInstance", "dealloc", ".cxx_destruct"}
KEY_PREFIX = (
    "KEY_", "SUB_", "ROW_", "SECTION_", "MODAL_", "PLAN_",
)
DATA_TOKENS = (
    "actualexpire", "expire_at", "expiresat", "subscription_expires",
    "payment_url", "receipt", "license.sync", "activated",
)
OBJC_CLASS = re.compile(r"^CB[A-Z][A-Za-z0-9_]+$")
CARPLAY_WORDS = re.compile(r"carplay|dashboard|split|deactivat|bridgemanager|uiscene", re.I)


def load_json(path: str) -> dict:
    p = ROOT / path
    assert p.is_file(), path
    return json.loads(p.read_text(encoding="utf-8"))


def source_hash(path: str) -> str:
    return sha256((ROOT / path).read_bytes()).hexdigest()


def audited_display_labels() -> list[str]:
    tree = ast.parse((ROOT / FILES["list_39_display_labels"]).read_text(encoding="utf-8"))
    assignments = [
        node.value for node in tree.body
        if isinstance(node, ast.Assign)
        and any(isinstance(x, ast.Name) and x.id == "UI_COPY" for x in node.targets)
    ]
    assert len(assignments) == 1
    labels = ast.literal_eval(assignments[0])
    assert isinstance(labels, list) and len(labels) == len(set(labels)) == 39
    assert all(isinstance(s, str) and s for s in labels)
    return labels


def classify_residual(record: dict, already_hidden: set[str]) -> str:
    literal = record.get("display_literal")
    if literal is None:
        return "opaque_string_callsite_unknown_preserve"
    if literal in already_hidden:
        return "39_ui_literals_already_masked_in_native9"
    if literal == "Activate":
        # Do NOT automatically blank: needs proof this C string is a button
        # label, not an Objective-C selector/dynamic command or localization key.
        return "possible_visible_activate_label_unverified"
    if literal == "activate":
        return "ambiguous_action_value_preserve"
    if literal == "com.apple.DataActivation":
        return "apple_system_identifier_preserve"
    if literal.startswith("[") or literal.startswith("Failed writing"):
        return "diagnostic_log_preserve"
    if CARPLAY_WORDS.search(literal):
        return "carplay_or_scene_lifecycle_preserve"
    if literal.startswith(KEY_PREFIX):
        return "localization_lookup_key_preserve"
    if OBJC_CLASS.fullmatch(literal) or ":" in literal:
        return "objc_runtime_class_or_selector_preserve"
    if literal.startswith("com."):
        return "runtime_notification_identifier_preserve"
    if any(s in literal.lower() for s in DATA_TOKENS):
        return "license_protocol_or_state_key_preserve_until_reference_proof"
    return "unclassified_requires_reference_proof_preserve"


def method_identity(item: dict, origin: str) -> tuple[str, str, str]:
    if origin == "native4":
        return item["class"], item["selector"], item["original_type"]
    return item["class"], item["selector"], item["method_type"]


def run(out: Path) -> dict:
    data = {k: load_json(v) for k, v in FILES.items()
            if k not in ("list_39_display_labels", "grip_only_source")}
    labels = audited_display_labels()
    stage = data["native9_package"]
    native6 = data["native6_inventory"]
    audit4 = data["method_edits"]
    ledger = data["method_ledger"]
    boundary = data["license_boundary"]
    qa9 = data["native9_regression"]
    brand9 = data["native9_brand"]

    assert stage["deb_sha256"] == qa9["native9_sha256"] == brand9["sha256"] == NATIVE9_SHA
    assert stage["native6_base_sha256"] == native6["native6_sha256"] == NATIVE6_SHA
    assert stage["package"] == "com.duoface.independent"
    assert stage["version"] == "0.1.0~native9"
    assert qa9["native6_original_visual_dylib_byte_identical"]
    assert qa9["native_divider_pan_unhooked_by_new_module"]
    assert qa9["native_host_code_and_objc_metadata_unchanged"]
    assert stage["license_code_fully_removed"] is False
    assert data["native6_zero_data"]["zero_erased_presentation_literals"] == 26
    assert data["method_and_ui_staging"]["hidden_literal_count"] == 26
    assert data["method_and_ui_staging"]["new_expired_state_methods_neutralized"] == 2
    assert brand9["strict_byte_level_zero_matches"]
    assert boundary["license_subsystem_separable_by_file"] is False
    assert boundary["dynamic_dispatch_fully_resolved"] is False
    assert boundary["bounded_static_analysis_only"] is True

    method_counts: dict[str, int] = {}
    method_inventory = []
    all_methods = ledger["all_method_inventory"]
    assert len(all_methods) == 320
    for binary in ("DuoFaceUI", "DuoFaceDashboard"):
        records = [m for m in all_methods if m["binary"] == binary]
        disabled = [m for m in records
                    if m["state"] == "retained_compatibility_or_unverified"]
        patched = audit4["method_bodies"][binary]["patched_methods"]
        assert len(disabled) == len(patched) == audit4["method_bodies"][binary]["method_body_count"]
        # A single class can own identically named - and + methods. Retain
        # multiplicity by comparing multisets, not only selector-name sets.
        assert Counter(method_identity(m, "ledger") for m in disabled) == Counter(
            method_identity(m, "native4") for m in patched
        ), (binary, "native4 patch and native5 ledger mismatch")
        protected = [m for m in records if m["state"] == "retain_carplay_screen_detection"]
        assert len(protected) == 4
        assert all(m["selector"] in CARPLAY for m in protected)
        lifecycles = [m for m in records if m["state"] == "retain_runtime_lifecycle"]
        assert all(m["selector"] in LIFECYCLE for m in lifecycles)
        expired = [m for m in records if m["state"] == "temporarily_disabled_native5"]
        assert (len(expired) == 2) == (binary == "DuoFaceUI")
        method_counts[binary] = len(records)
        for m in records:
            state = m["state"]
            group = {
                "retained_compatibility_or_unverified":
                    "original_license_related_body_inert_since_native4_keep_ABI",
                "temporarily_disabled_native5":
                    "expired_modal_state_staged_inert_keep_ABI",
                "retain_carplay_screen_detection":
                    "CARPLAY_CRITICAL_KEEP_ORIGINAL_IMPLEMENTATION",
                "retain_runtime_lifecycle":
                    "OBJC_LIFECYCLE_KEEP_ORIGINAL_IMPLEMENTATION",
            }.get(state)
            assert group is not None, state
            method_inventory.append({
                "binary": binary, "class": m["class"],
                "selector": m["selector"], "signature": m["method_type"],
                "group": group,
                "next_action": "DO_NOT_REPATCH_OR_DELETE_ABI" if group !=
                  "original_license_related_body_inert_since_native4_keep_ABI"
                  else "NO_FURTHER_LICENSE_BODY_REMOVAL_NEEDED",
            })
    assert method_counts == {"DuoFaceUI": 269, "DuoFaceDashboard": 51}
    groups = Counter(m["group"] for m in method_inventory)
    assert groups["original_license_related_body_inert_since_native4_keep_ABI"] == 291
    assert groups["expired_modal_state_staged_inert_keep_ABI"] == 2
    assert groups["CARPLAY_CRITICAL_KEEP_ORIGINAL_IMPLEMENTATION"] == 8
    assert groups["OBJC_LIFECYCLE_KEEP_ORIGINAL_IMPLEMENTATION"] == 19

    original_strings = [
        x for binary, info in native6["binaries"].items()
        for x in info["strings"]
    ]
    assert len(original_strings) == native6["observed_residual_strings_count"] == 256
    masks = stage["masks"]
    assert len(masks) == 78 and len(labels) == 39
    exact_masks = Counter(
        (x["binary"], x["file_offset"], x["label"]) for x in masks
    )
    assert max(exact_masks.values()) == 1
    strings = []
    for rec in original_strings:
        group = classify_residual(rec, set(labels))
        literal = rec.get("display_literal")
        if group == "39_ui_literals_already_masked_in_native9":
            assert exact_masks[(rec["binary"], rec["file_offset"], literal)] == 1
        strings.append({
            "binary": rec["binary"],
            "file_offset": rec["file_offset"],
            "byte_count": rec["byte_count"],
            "original_sha256": rec["sha256"],
            "literal": literal,
            "group": group,
            "native9_action": (
                "MASKED_IN_PUBLISHED_NATIVE9"
                if group == "39_ui_literals_already_masked_in_native9"
                else "UNCHANGED_PROTECT_UNTIL_CALLSITE_PROOF"
            ),
        })
    sc = Counter(s["group"] for s in strings)
    assert sc["39_ui_literals_already_masked_in_native9"] == 78
    assert sc["opaque_string_callsite_unknown_preserve"] == 88
    assert sc["possible_visible_activate_label_unverified"] == 2
    assert sum(sc.values()) == 256
    assert sc["possible_visible_activate_label_unverified"] == 2
    assert set(x["binary"] for x in strings
               if x["group"] == "possible_visible_activate_label_unverified") == {
        "DuoFaceUI", "DuoFaceDashboard"
    }
    assert not set(rec["literal"] for rec in strings if rec["group"] ==
        "possible_visible_activate_label_unverified") - {"Activate"}

    # No claim that empty UI labels alone make the licensing subsystem dead.
    # All static categorization is reference-conservative by design.
    result = {
        "status": "NATIVE9_LICENSE_BOUNDARY_METHOD_AND_STRING_ACCOUNTING_PASS_READONLY",
        "scope": "STATIC_SOURCE_REPORT_RECONCILIATION_ONLY",
        "repository": "chuongnguyen89dn-ui/Duoface",
        "working_branch": "feature/duoface-exact-payload-migration",
        "native9_tested_good_by_user": True,
        "device_qa_context":
            "User confirms native9 every CarPlay action works and no license UI visible in iPhone app.",
        "native9_deb_sha256": NATIVE9_SHA,
        "native9_deb_version": "0.1.0~native9",
        "native9_binary_changed_by_this_audit": False,
        "sileo_changed_by_this_audit": False,
        "created_new_deb": False,
        "method_count": len(method_inventory),
        "method_counts": dict(groups),
        "method_rows": method_inventory,
        "string_count": len(strings),
        "string_counts": dict(sc),
        "string_rows": strings,
        "proven_already_masked_string_occurrences": len(masks),
        "proven_previously_zeroed_text_occurrences": 26,
        "additional_text_candidates_not_yet_masked": 2,
        "additional_text_candidate": "Activate",
        "additional_text_candidate_proven_presentation_only": False,
        "carplay_critical_method_count": 8,
        "objc_lifecycle_protected_method_count": 19,
        "native4_legacy_method_bodies_neutralized": 291,
        "native5_expired_modal_accessors_neutralized": 2,
        "dynamic_dispatch_fully_resolved": False,
        "all_license_metadata_or_runtime_removed": False,
        "license_subsystem_separable_by_file": False,
        "must_preserve": [
            "all CarPlay screen detection and bridge lifecycle",
            "native ratio handler CBDividerView.handlePan:",
            "native6 exact DuoFaceVisualHook.dylib, fullscreen, settings, images",
            "native9 isolated 0.30-second movable divider button and its injection filter",
            "all ObjC selectors/classes and state keys until caller graph is proven",
            "all exact existing verified-native9 paths and rollback files",
        ],
        "investigation_next": [
            "trace both exact Activate literal offsets through UIKit/localization and ensure they are display labels before any future mask",
            "map opaque 88 literals by safe hashed references, never blanket-zero them",
            "trace initializer/dynamic calls before any class, selector, data-key or lifecycle removal",
            "prepare only a staged presentation-only diff from native9 for the next user-authorized DEB",
        ],
        "source_sha256": {name: source_hash(path) for name,path in FILES.items()},
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n",
                   encoding="utf-8")
    return result


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()
    a = run(args.out)
    print(json.dumps({
        "status": a["status"],
        "native9_deb_sha256": a["native9_deb_sha256"],
        "method_counts": a["method_counts"],
        "string_counts": a["string_counts"],
        "created_new_deb": a["created_new_deb"],
        "sileo_changed_by_this_audit": a["sileo_changed_by_this_audit"],
    }, ensure_ascii=False, indent=2))
