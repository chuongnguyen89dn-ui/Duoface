"""Format/integrity regression tests. Fixtures are bytes, never executable code."""
import hashlib
import io
from pathlib import Path
import struct
import sys
import tarfile
import tempfile
import unittest
import zlib

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import audit_integrated_deb as audit


def signed_image(subtype=0):
    """Minimal 64-bit image with a single correctly hashed code page."""
    limit = 4096
    identifier = b"fixture\0"
    cd_length = 44 + len(identifier) + 32
    signature_length = 20 + cd_length
    header = struct.pack("<8I", 0xFEEDFACF, 0x100000C, subtype, 6, 1, 16, 0, 0)
    command = struct.pack("<4I", 0x1D, 16, limit, signature_length)
    code = (header + command).ljust(limit, b"\0")
    cd = struct.pack(">9I4BI", 0xFADE0C02, cd_length, 0x20001, 2,
                     44 + len(identifier), 44, 0, 1, limit, 32, 2, 0, 12, 0)
    cd += identifier + hashlib.sha256(code).digest()
    signature = struct.pack(">5I", 0xFADE0CC0, signature_length, 1, 0, 20) + cd
    return code + signature


def fat_image():
    first, second = signed_image(), signed_image(2)
    a = 4096
    b = (a + len(first) + 4095) // 4096 * 4096
    header = struct.pack(">II", 0xCAFEBABE, 2)
    header += struct.pack(">5I", 0x100000C, 0, a, len(first), 12)
    header += struct.pack(">5I", 0x100000C, 2, b, len(second), 12)
    data = header.ljust(a, b"\0") + first
    return data.ljust(b, b"\0") + second, b


def tar_bytes(entries):
    stream = io.BytesIO()
    with tarfile.open(fileobj=stream, mode="w:xz") as archive:
        for name, data, mode in entries:
            item = tarfile.TarInfo(name)
            item.mode = mode
            item.size = len(data)
            archive.addfile(item, io.BytesIO(data))
    return stream.getvalue()


def ar_bytes(entries):
    data = bytearray(b"!<arch>\n")
    for name, content in entries:
        header = f"{name + '/':<16}{0:<12}{0:<6}{0:<6}{'100644':<8}{len(content):<10}`\n".encode("ascii")
        assert len(header) == 60
        data.extend(header + content + (b"\n" if len(content) % 2 else b""))
    return bytes(data)


class IntegratedAuditTests(unittest.TestCase):
    def test_signed_image_detects_changed_code_byte(self):
        original = signed_image()
        report = audit.parse_macho(original)
        self.assertTrue(report["slices"][0]["code_signature"]["all_code_pages_match"])
        damaged = bytearray(original)
        damaged[200] ^= 1
        signature = audit.parse_macho(bytes(damaged))["slices"][0]["code_signature"]
        self.assertFalse(signature["all_code_pages_match"])
        self.assertEqual(signature["code_directories"][0]["mismatched_pages"], [0])

    def test_fat_scan_includes_and_verifies_second_architecture(self):
        original, second = fat_image()
        parsed = audit.parse_macho(original)
        self.assertEqual([s["architecture"] for s in parsed["slices"]], ["arm64", "arm64e"])
        damaged = bytearray(original)
        damaged[second + 200] ^= 1
        parsed = audit.parse_macho(bytes(damaged))
        self.assertTrue(parsed["slices"][0]["code_signature"]["all_code_pages_match"])
        self.assertFalse(parsed["slices"][1]["code_signature"]["all_code_pages_match"])

    def test_truncated_fat_slice_is_rejected(self):
        data, _ = fat_image()
        with self.assertRaises(audit.AuditError):
            audit.parse_macho(data[:-1])

    def test_load_command_cannot_escape_declared_region(self):
        data = bytearray(signed_image())
        struct.pack_into("<I", data, 36, 24)
        with self.assertRaisesRegex(audit.AuditError, "sizeofcmds"):
            audit.parse_macho(bytes(data))

    def test_tar_traversal_and_duplicate_normalized_paths_are_rejected(self):
        for entries in ([('../escape', b'x', 0o644)],
                        [('./file', b'x', 0o644), ('file', b'y', 0o644)]):
            with self.subTest(entries=entries), self.assertRaises(audit.AuditError):
                audit.read_tar(tar_bytes(entries), "payload")

    def test_duplicate_ar_member_is_rejected(self):
        with self.assertRaisesRegex(audit.AuditError, "duplicate ar"):
            audit.read_ar(ar_bytes([('data.tar', b'a'), ('data.tar', b'b')]))

    def test_png_chunk_corruption_is_detected(self):
        def chunk(kind, content):
            return struct.pack(">I", len(content)) + kind + content + struct.pack(">I", zlib.crc32(kind + content))
        data = b"\x89PNG\r\n\x1a\n"
        data += chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 0, 0, 0, 0))
        data += chunk(b"IDAT", zlib.compress(b"\0\xff")) + chunk(b"IEND", b"")
        self.assertEqual(audit.png_info(data)["width"], 1)
        damaged = bytearray(data)
        damaged[-1] ^= 1
        with self.assertRaisesRegex(audit.AuditError, "CRC"):
            audit.png_info(bytes(damaged))

    def test_archive_scan_never_runs_maintainer_script(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            marker = root / "must-not-exist"
            fields = b"Package: com.duoface.jb.embedded\nVersion: 0.0.1\nArchitecture: iphoneos-arm64\nMaintainer: Test\nDescription: Fixture\n"
            control = tar_bytes([("control", fields, 0o644),
                                 ("postinst", f"#!/bin/sh\ntouch '{marker}'\n".encode(), 0o755)])
            payload = tar_bytes([("./var/jb/test.txt", b"fixture", 0o644)])
            package = ar_bytes([("debian-binary", b"2.0\n"), ("control.tar.xz", control), ("data.tar.xz", payload)])
            deb = root / "fixture.deb"
            deb.write_bytes(package)
            result = audit.audit(deb, root / "report", hashlib.sha256(package).hexdigest())
            self.assertFalse(marker.exists())
            self.assertFalse(result["maintainer_scripts_executed"])
            self.assertEqual(result["counts"]["fully_analyzed_regular_files"], 3)
            self.assertTrue(result["static_integrity_pass"])
            with self.assertRaisesRegex(audit.AuditError, "new or empty"):
                audit.audit(deb, root / "report")

    def test_expected_artifact_digest_is_enforced(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            deb = root / "wrong.deb"
            deb.write_bytes(b"not the approved artifact")
            with self.assertRaisesRegex(audit.AuditError, "SHA256"):
                audit.audit(deb, root / "output", "0" * 64)
            self.assertFalse((root / "output").exists())


if __name__ == "__main__":
    unittest.main()
