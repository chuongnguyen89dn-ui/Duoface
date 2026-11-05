#!/usr/bin/env python3
"""Read every member of a DuoFace DEB without extracting or executing its payload.

Standard-library-only, bounded ar/tar/Mach-O inspection. CodeDirectory page hashes
and available special-slot hashes are checked; this is NOT an Apple trust-chain,
AMFI, installation, private-API, or physical-device acceptance test. All slices,
including FAT arm64e slices, are inspected. Unsupported signature hash layouts
and truncated structures fail closed. Uninterpreted load commands are retained
with their exact offsets and sizes for further review.

Format references (structures, not copied implementations):
  https://github.com/apple-oss-distributions/cctools/blob/main/include/mach-o/loader.h
  https://github.com/apple-oss-distributions/cctools/blob/main/include/mach-o/fat.h
  https://github.com/apple-oss-distributions/xnu/blob/main/osfmk/kern/cs_blobs.h
"""
from __future__ import annotations

import argparse
import base64
from collections import Counter
from dataclasses import dataclass
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import plistlib
import posixpath
import re
import struct
import sys
import tarfile
import zlib


MAX_ARCHIVE_BYTES = 512 * 1024 * 1024
MAX_EXPANDED_BYTES = 512 * 1024 * 1024
MAX_MEMBERS = 20000
MAX_SLICES = 32
MAX_COMMANDS = 16384
THIN_MAGICS = {
    b"\xce\xfa\xed\xfe": ("<", False), b"\xcf\xfa\xed\xfe": ("<", True),
    b"\xfe\xed\xfa\xce": (">", False), b"\xfe\xed\xfa\xcf": (">", True),
}
FAT_MAGICS = {
    b"\xca\xfe\xba\xbe": (">", False), b"\xca\xfe\xba\xbf": (">", True),
    b"\xbe\xba\xfe\xca": ("<", False), b"\xbf\xba\xfe\xca": ("<", True),
}
DOMAIN_PATTERNS = {
    "keyboard": r"keyboard|UIKB|keyplane|kbdiag|kbfit|kbstate|textEffects|referenceSize",
    "touch_and_logo": r"touch|hitTest|sendEvent|wakefix|wake.?gate|recall|pointer",
    "scene_and_owner": r"scene|workspace|foreground|background|hosting|SBAppView|RunningBoard",
    "native_map": r"native.?map|map.*pane|pane.*map|DBApplication|sceneFrameForAppInfo|deactivateSceneWithReasonMask|backgroundSceneWithCompletion",
    "disconnect_and_close": r"disconnect|teardown|close.*pid|terminate|reconnect|stopHosting|release.*owner",
    "runtime_interposition": r"dlopen|dlsym|MSHook|objc_getClass|class_getInstanceMethod|method_exchange|CFNotification",
    "network_and_process_markers": r"https?://|NSURLSession|CFNetwork|socket|posix_spawn|execve|^_system$",
}
DYLIB_COMMANDS = {0xC: "load", 0xD: "id", 0x18: "weak", 0x1F: "reexport", 0x20: "lazy", 0x23: "upward"}
PLATFORMS = {1: "macOS", 2: "iOS", 3: "tvOS", 4: "watchOS", 6: "MacCatalyst", 7: "iOSSimulator", 8: "tvOSSimulator", 9: "watchOSSimulator"}
SPECIAL_SLOTS = {1: "Info.plist", 2: "requirements", 3: "CodeResources", 4: "application", 5: "XML entitlements", 7: "DER entitlements"}


class AuditError(ValueError):
    """A bounded format or integrity check failed."""


def require(condition, message):
    if not condition:
        raise AuditError(message)


def checked(data, offset, length, label="range"):
    require(offset >= 0 and length >= 0 and offset + length <= len(data),
            f"{label} outside input: offset={offset}, length={length}, input={len(data)}")
    return data[offset:offset + length]


def unpack(fmt, data, offset=0):
    return struct.unpack(fmt, checked(data, offset, struct.calcsize(fmt), fmt))


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def textz(data, offset=0, end=None):
    end = len(data) if end is None else end
    require(0 <= offset < end <= len(data), "string offset outside enclosing structure")
    raw = data[offset:end]
    require(b"\0" in raw, "unterminated string in enclosing structure")
    return raw.split(b"\0", 1)[0].decode("utf-8", "replace")


def version(value):
    return f"{value >> 16}.{(value >> 8) & 255}.{value & 255}"


def json_value(value):
    if isinstance(value, bytes):
        return {"base64": base64.b64encode(value).decode("ascii")}
    if isinstance(value, plistlib.UID):
        return {"UID": value.data}
    if isinstance(value, dict):
        return {str(k): json_value(v) for k, v in value.items()}
    if isinstance(value, (tuple, list)):
        return [json_value(v) for v in value]
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return value


def write_json(path, value):
    path.write_text(json.dumps(json_value(value), ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


@dataclass
class ArMember:
    name: str
    offset: int
    data: bytes


def read_ar(data):
    require(data.startswith(b"!<arch>\n"), "not a Debian ar archive")
    require(len(data) <= MAX_ARCHIVE_BYTES, "archive exceeds bounded scan limit")
    members, offset, string_table = [], 8, b""
    while offset < len(data):
        require(len(members) < MAX_MEMBERS, "too many ar members")
        header = checked(data, offset, 60, "ar member header")
        require(header[58:] == b"`\n", "invalid ar member terminator")
        try:
            size = int(header[48:58].decode("ascii").strip())
            name = header[:16].decode("ascii").strip()
        except (ValueError, UnicodeError) as exc:
            raise AuditError(f"malformed ar member header: {exc}") from exc
        payload = checked(data, offset + 60, size, "ar member content")
        content_offset = offset + 60
        if name == "//":
            string_table = payload
        elif name.startswith("#1/"):
            n = int(name[3:])
            name = checked(payload, 0, n, "BSD ar filename").rstrip(b"\0").decode("utf-8")
            payload, content_offset = payload[n:], content_offset + n
        elif name.startswith("/") and name[1:].isdigit():
            begin = int(name[1:])
            require(begin < len(string_table), "GNU ar filename outside string table")
            name = string_table[begin:].split(b"\n", 1)[0].rstrip(b"/").decode("utf-8")
        else:
            name = name.rstrip("/")
        require(not any(m.name == name for m in members), f"duplicate ar member: {name}")
        members.append(ArMember(name, content_offset, payload))
        offset += 60 + size
        if size & 1:
            require(checked(data, offset, 1, "ar padding") == b"\n", "invalid ar padding")
            offset += 1
    return members


def safe_archive_path(name):
    require("\0" not in name and "\\" not in name, "NUL/backslash in archive path")
    p = PurePosixPath(name)
    require(not p.is_absolute() and ".." not in p.parts, f"unsafe archive path: {name}")
    return "/".join(x for x in p.parts if x not in ("", "."))


def read_tar(data, scope):
    inventory, contents, seen, total = [], {}, set(), 0
    with tarfile.open(fileobj=io.BytesIO(data), mode="r|*") as archive:
        for member in archive:
            require(len(inventory) < MAX_MEMBERS, f"too many {scope} tar members")
            path = safe_archive_path(member.name)
            require(path not in seen, f"duplicate {scope} tar path: {path}")
            seen.add(path)
            if not path:
                require(member.isdir(), "archive root is not a directory")
            total += member.size
            require(total <= MAX_EXPANDED_BYTES, f"{scope} exceeds expanded-size bound")
            kind = "regular" if member.isfile() else "directory" if member.isdir() else "symlink" if member.issym() else "hardlink" if member.islnk() else "special"
            row = {"scope": scope, "path": path, "archive_name": member.name,
                   "type": kind, "mode": f"{member.mode:04o}", "uid": member.uid,
                   "gid": member.gid, "uname": member.uname, "gname": member.gname,
                   "mtime_epoch": member.mtime, "size": member.size}
            if kind == "regular":
                stream = archive.extractfile(member)
                require(stream is not None, f"cannot read tar file {path}")
                payload = stream.read(member.size + 1)
                require(len(payload) == member.size, f"tar file size mismatch: {path}")
                row["sha256"] = sha256(payload)
                contents[path] = payload
            elif kind in ("symlink", "hardlink"):
                row["link_target"] = member.linkname
                row["resolved_target"] = posixpath.normpath(posixpath.join(posixpath.dirname(path) if kind == "symlink" else "", member.linkname))
            inventory.append(row)
    return inventory, contents


def parse_control(data):
    fields, current = {}, None
    for line in data.decode("utf-8").splitlines():
        if line[:1].isspace():
            require(current is not None, "orphan Debian control continuation")
            fields[current] += "\n" + line[1:]
        elif line:
            require(":" in line, "invalid Debian control field")
            current, value = line.split(":", 1)
            require(current not in fields, f"duplicate Debian control field {current}")
            fields[current] = value.lstrip()
    for key in ("Package", "Version", "Architecture", "Maintainer", "Description"):
        require(bool(fields.get(key)), f"missing Debian control field {key}")
    return fields


def decode_der(data, depth=0):
    """Decode the small DER property-list types used by embedded entitlements."""
    require(depth <= 32 and len(data) >= 2, "malformed/deep DER value")
    tag, first = data[0], data[1]
    header = 2
    if first & 0x80:
        n = first & 0x7F
        require(1 <= n <= 8, "indefinite/oversized DER length")
        length = int.from_bytes(checked(data, 2, n, "DER length"), "big")
        header += n
    else:
        length = first
    value = checked(data, header, length, "DER value")
    if tag & 0x20:
        children, pos = [], 0
        while pos < len(value):
            child, used = decode_der(value[pos:], depth + 1)
            children.append(child)
            pos += used
        if tag == 0x31 and all(isinstance(x, list) and len(x) == 2 and isinstance(x[0], str) for x in children):
            require(len({x[0] for x in children}) == len(children), "duplicate DER dictionary key")
            result = {x[0]: x[1] for x in children}
        else:
            result = children
    elif tag == 1:
        require(len(value) == 1, "malformed DER boolean")
        result = value != b"\0"
    elif tag == 2:
        result = int.from_bytes(value, "big", signed=True)
    elif tag in (0x0C, 0x13, 0x16):
        result = value.decode("utf-8")
    else:
        result = {"tag": hex(tag), "hex": value.hex()}
    return result, header + length


def parse_signature(binary, offset, size, external_slots):
    signature = checked(binary, offset, size, "LC_CODE_SIGNATURE")
    magic, length, count = unpack(">III", signature)
    require(magic == 0xFADE0CC0, "unsupported embedded signature magic")
    require(12 + 8 * count <= length <= len(signature), "invalid embedded signature table")
    require(count <= 1000, "too many signature sub-blobs")
    blobs, indices, ranges = {}, [], []
    for index in range(count):
        slot, start = unpack(">II", signature, 12 + index * 8)
        require(slot not in blobs, "duplicate signature slot")
        require(start >= 12 + 8 * count, "signature sub-blob overlaps index table")
        blob_magic, blob_length = unpack(">II", signature, start)
        require(blob_length >= 8 and start + blob_length <= length, "invalid signature sub-blob length")
        require(all(start + blob_length <= a or start >= b for a, b in ranges), "overlapping signature sub-blobs")
        ranges.append((start, start + blob_length))
        blobs[slot] = signature[start:start + blob_length]
        indices.append({"slot": hex(slot), "magic": hex(blob_magic), "size": blob_length,
                        "sha256": sha256(blobs[slot])})
    result = {"offset": offset, "size": size, "superblob_size": length,
              "sub_blobs": indices, "cms_present": 0x10000 in blobs,
              "apple_trust_chain_verified": False, "code_directories": []}
    if 5 in blobs:
        require(unpack(">I", blobs[5])[0] == 0xFADE7171, "wrong XML entitlement magic")
        result["entitlements"] = plistlib.loads(blobs[5][8:])
    if 7 in blobs:
        require(unpack(">I", blobs[7])[0] == 0xFADE7172, "wrong DER entitlement magic")
        decoded, used = decode_der(blobs[7][8:])
        require(used == len(blobs[7]) - 8, "trailing DER entitlement data")
        result["der_entitlements"] = decoded
        if "entitlements" in result:
            result["xml_der_entitlements_equal"] = decoded == result["entitlements"]
    for slot, cd in sorted(blobs.items()):
        if unpack(">I", cd)[0] != 0xFADE0C02:
            continue
        cd_version, flags, hash_offset, ident_offset, special_count, code_count, code_limit = unpack(">7I", cd, 8)
        hash_size, hash_type, platform, page_exp = unpack("4B", cd, 36)
        require(len(cd) >= 44 and page_exp <= 30, "invalid CodeDirectory header/page size")
        scatter = unpack(">I", cd, 44)[0] if cd_version >= 0x20100 else 0
        team_offset = unpack(">I", cd, 48)[0] if cd_version >= 0x20200 else 0
        limit64 = unpack(">Q", cd, 56)[0] if cd_version >= 0x20300 else 0
        if code_limit == 0xFFFFFFFF and limit64:
            code_limit = limit64
        require(scatter == 0, "scatter CodeDirectory is not supported; no false verification")
        require(0 < code_limit <= offset, "CodeDirectory code range is empty or overlaps signature/outside image")
        require(hash_type in (1, 2, 3, 4), f"unsupported CodeDirectory hash type {hash_type}")
        algorithm = {1: "sha1", 2: "sha256", 3: "sha256", 4: "sha384"}[hash_type]
        expected_hash_size = {1: 20, 2: 32, 3: 20, 4: 48}[hash_type]
        require(hash_size == expected_hash_size, "unexpected CodeDirectory digest size")
        require(special_count <= 1000, "too many CodeDirectory special slots")
        require(hash_offset >= special_count * hash_size, "special hashes underflow CodeDirectory")
        checked(cd, hash_offset - special_count * hash_size, (code_count + special_count) * hash_size, "CodeDirectory hashes")
        page_bytes = (1 << page_exp) if page_exp else max(code_limit, 1)
        expected_pages = (code_limit + page_bytes - 1) // page_bytes
        require(code_count == expected_pages, "CodeDirectory page count does not cover codeLimit")
        mismatches = []
        for index in range(code_count):
            actual = hashlib.new(algorithm, binary[index * page_bytes:min((index + 1) * page_bytes, code_limit)]).digest()[:hash_size]
            stored = cd[hash_offset + index * hash_size:hash_offset + (index + 1) * hash_size]
            if actual != stored:
                mismatches.append(index)
        special = []
        for index in range(1, special_count + 1):
            stored = cd[hash_offset - index * hash_size:hash_offset - (index - 1) * hash_size]
            entry = {"slot": index, "name": SPECIAL_SLOTS.get(index, "unknown"), "stored_hash": stored.hex()}
            material = blobs.get(index) if index not in (1, 3, 4) else external_slots.get(index)
            if not any(stored):
                entry["status"] = "not_sealed"
            elif material is None:
                entry["status"] = "unavailable_for_verification"
            else:
                actual = hashlib.new(algorithm, material).digest()[:hash_size]
                entry["status"] = "match" if actual == stored else "mismatch"
                entry["actual_hash"] = actual.hex()
            special.append(entry)
        directory = {"slot": hex(slot), "version": hex(cd_version), "flags": hex(flags),
                     "adhoc_flag": bool(flags & 2), "identifier": textz(cd, ident_offset),
                     "team_identifier": textz(cd, team_offset) if team_offset else None,
                     "hash_type": hash_type, "hash_algorithm": algorithm, "hash_size": hash_size,
                     "platform_byte": platform, "page_bytes": page_bytes, "code_limit": code_limit,
                     "unsigned_gap_before_signature": offset - code_limit,
                     "page_count": code_count, "verified_page_count": code_count - len(mismatches),
                     "mismatched_pages": mismatches, "special_slots": special,
                     "cdhash": hashlib.new(algorithm, cd).digest()[:20].hex()}
        if cd_version >= 0x20400:
            base, limit, executable_flags = unpack(">QQQ", cd, 64)
            directory["executable_segment"] = {"base": base, "limit": limit, "flags": hex(executable_flags)}
        result["code_directories"].append(directory)
    require(bool(result["code_directories"]), "no CodeDirectory in embedded signature")
    result["all_code_pages_match"] = all(not cd["mismatched_pages"] for cd in result["code_directories"])
    result["all_available_special_slots_match"] = all(slot["status"] != "mismatch" for cd in result["code_directories"] for slot in cd["special_slots"])
    return result


def architecture(cpu, subtype):
    kind = subtype & 0x00FFFFFF
    if cpu == 0x100000C:
        return "arm64e" if kind == 2 else "arm64" if kind == 0 else f"arm64-subtype-{kind}"
    return {12: "arm", 7: "i386", 0x1000007: "x86_64"}.get(cpu, f"cpu-{hex(cpu)}")


def parse_thin(data, external_slots):
    require(data[:4] in THIN_MAGICS, "fat slice does not contain a recognized Mach-O")
    endian, is64 = THIN_MAGICS[data[:4]]
    header_size = 32 if is64 else 28
    _, cpu, subtype, file_type, ncmds, sizeofcmds, flags = unpack(endian + "7I", data)
    require(ncmds <= MAX_COMMANDS, "too many Mach-O load commands")
    checked(data, header_size, sizeofcmds, "Mach-O load command region")
    result = {"architecture": architecture(cpu, subtype), "cpu_type": hex(cpu),
              "cpu_subtype": hex(subtype), "bits": 64 if is64 else 32,
              "endianness": "little" if endian == "<" else "big", "size": len(data),
              "sha256": sha256(data), "file_type": {2: "executable", 6: "dylib", 8: "bundle"}.get(file_type, str(file_type)),
              "flags": hex(flags), "pie": bool(flags & 0x200000),
              "allow_stack_execution": bool(flags & 0x20000), "load_commands": [],
              "dependencies": [], "rpaths": [], "segments": [], "sections": [],
              "build_versions": [], "encrypted": False}
    offset, symtab, signature, function_starts = header_size, None, None, None
    for _ in range(ncmds):
        cmd, size = unpack(endian + "II", data, offset)
        require(size >= 8 and size % (8 if is64 else 4) == 0, "invalid load command size/alignment")
        require(offset + size <= header_size + sizeofcmds, "load command exceeds sizeofcmds")
        raw = checked(data, offset, size, "load command")
        base = cmd & 0x7FFFFFFF
        item = {"command": hex(cmd), "offset": offset, "size": size}
        if base in DYLIB_COMMANDS:
            name_offset, timestamp, current, compat = unpack(endian + "4I", raw, 8)
            require(name_offset >= 24, "dylib name overlaps command header")
            item.update(kind=DYLIB_COMMANDS[base], name=textz(raw, name_offset),
                        timestamp=timestamp, current_version=version(current), compatibility_version=version(compat))
            if base == 0xD:
                result["install_name"] = item["name"]
            else:
                result["dependencies"].append({k: v for k, v in item.items() if k not in ("offset", "size")})
        elif base in (0x1C, 0xE, 0xF):
            name_offset = unpack(endian + "I", raw, 8)[0]
            require(name_offset >= 12, "path overlaps load command header")
            item["name"] = textz(raw, name_offset)
            if base == 0x1C:
                result["rpaths"].append(item["name"])
        elif base in (0x1, 0x19):
            seg64 = base == 0x19
            seg_header, sec_size = (72, 80) if seg64 else (56, 68)
            segname = raw[8:24].split(b"\0", 1)[0].decode("ascii", "replace")
            vmaddr, vmsize, fileoff, filesize = unpack(endian + ("4Q" if seg64 else "4I"), raw, 24)
            maxprot, initprot, nsects, segflags = unpack(endian + "4I", raw, 56 if seg64 else 40)
            require(seg_header + nsects * sec_size <= len(raw), "section table exceeds segment command")
            checked(data, fileoff, filesize, "segment file range")
            result["segments"].append({"name": segname, "vmaddr": hex(vmaddr), "vmsize": vmsize,
                                       "file_offset": fileoff, "file_size": filesize, "maxprot": maxprot,
                                       "initprot": initprot, "flags": hex(segflags)})
            for index in range(nsects):
                section = checked(raw, seg_header + index * sec_size, sec_size, "section")
                sectname = section[:16].split(b"\0", 1)[0].decode("ascii", "replace")
                segment = section[16:32].split(b"\0", 1)[0].decode("ascii", "replace")
                addr, length = unpack(endian + ("QQ" if seg64 else "II"), section, 32)
                sec_offset = 48 if seg64 else 40
                filepos, alignment, reloff, nreloc, secflags = unpack(endian + "5I", section, sec_offset)
                zerofill = (secflags & 0xFF) in (1, 0xC, 0x12)
                if not zerofill:
                    checked(data, filepos, length, "section file range")
                if nreloc:
                    checked(data, reloff, nreloc * 8, "section relocations")
                result["sections"].append({"name": sectname, "segment": segment, "address": hex(addr),
                                            "size": length, "file_offset": filepos, "alignment_power": alignment,
                                            "flags": hex(secflags), "zerofill": zerofill, "relocation_count": nreloc})
        elif base == 0x2:
            symtab = unpack(endian + "4I", raw, 8)
        elif base == 0x1D:
            require(signature is None, "duplicate LC_CODE_SIGNATURE")
            signature = unpack(endian + "II", raw, 8)
        elif base == 0x26:
            function_starts = unpack(endian + "II", raw, 8)
        elif base == 0x32:
            platform, minimum, sdk, count = unpack(endian + "4I", raw, 8)
            checked(raw, 24, count * 8, "build version tools")
            result["build_versions"].append({"platform": PLATFORMS.get(platform, str(platform)),
                                              "minimum_os": version(minimum), "minimum_os_raw": minimum,
                                              "sdk": version(sdk), "tools": [dict(zip(("tool", "version_raw"), unpack(endian + "II", raw, 24 + i * 8))) for i in range(count)]})
        elif base in (0x24, 0x25, 0x2F, 0x30):
            minimum, sdk = unpack(endian + "II", raw, 8)
            result["build_versions"].append({"platform": {0x24: "macOS", 0x25: "iOS", 0x2F: "tvOS", 0x30: "watchOS"}[base],
                                              "minimum_os": version(minimum), "minimum_os_raw": minimum, "sdk": version(sdk)})
        elif base in (0x21, 0x2C):
            cryptoff, cryptsize, cryptid = unpack(endian + "III", raw, 8)
            checked(data, cryptoff, cryptsize, "encrypted range")
            result["encrypted"] = bool(cryptid)
            result["encryption"] = {"offset": cryptoff, "size": cryptsize, "cryptid": cryptid}
        elif base == 0x1B:
            result["uuid"] = checked(raw, 8, 16, "UUID").hex()
        result["load_commands"].append(item)
        offset += size
    require(offset == header_size + sizeofcmds, "ncmds does not consume sizeofcmds")
    symbols = []
    if symtab:
        symoff, count, stroff, strsize = symtab
        table = checked(data, stroff, strsize, "symbol string table")
        stride = 16 if is64 else 12
        checked(data, symoff, count * stride, "symbol table")
        for index in range(count):
            name, kind, section, desc, value = unpack(endian + ("IBBHQ" if is64 else "IBBHI"), data, symoff + index * stride)
            require(name < len(table), "symbol name index outside string table")
            symbols.append({"name": textz(table, name), "type": hex(kind), "section": section,
                            "description": hex(desc), "value": hex(value), "undefined": (kind & 0x0E) == 0,
                            "external": bool(kind & 1), "debug": bool(kind & 0xE0)})
    result["symbols"] = symbols
    result["symbol_count"] = len(symbols)
    result["undefined_symbols"] = sorted({s["name"] for s in symbols if s["undefined"] and not s["debug"] and s["name"]})
    result["defined_symbol_count"] = sum(not s["undefined"] and not s["debug"] for s in symbols)
    if function_starts:
        values, current, shift, address = [], 0, 0, 0
        for byte in checked(data, *function_starts, "function starts"):
            current |= (byte & 0x7F) << shift
            require(shift <= 63, "oversized function-start ULEB128")
            if byte & 0x80:
                shift += 7
            else:
                if not current:
                    break
                address += current
                values.append(hex(address))
                current, shift = 0, 0
        require(shift == 0, "unterminated function-start ULEB128")
        result["function_start_count"] = len(values)
    records = [{"offset": match.start(), "text": match.group().decode("ascii"), "source": "ASCII scan"}
               for match in re.finditer(rb"[\x20-\x7e]{4,}", data)]
    for section in result["sections"]:
        if section["name"] not in ("__cstring", "__objc_methname", "__objc_classname", "__objc_methtype"):
            continue
        pos = section["file_offset"]
        for item in checked(data, pos, section["size"], "string section").split(b"\0"):
            if item:
                records.append({"offset": pos, "text": item.decode("utf-8", "replace"), "source": section["name"]})
            pos += len(item) + 1
    records.sort(key=lambda row: (row["offset"], row["source"], row["text"]))
    result["strings"] = records
    result["objc_selectors"] = sorted({s["text"] for s in records if s["source"] == "__objc_methname"})
    result["objc_class_names"] = sorted({s["text"] for s in records if s["source"] == "__objc_classname"})
    combined = sorted({s["text"] for s in records} | {s["name"] for s in symbols})
    result["domain_markers"] = {name: [s for s in combined if re.search(pattern, s, re.I)] for name, pattern in DOMAIN_PATTERNS.items()}
    result["code_signature"] = parse_signature(data, *signature, external_slots) if signature else None
    return result


def parse_macho(data, external_slots=None):
    external_slots = external_slots or {}
    if data[:4] in THIN_MAGICS:
        result = parse_thin(data, external_slots)
        result["container_offset"] = 0
        return {"container": "thin", "slices": [result]}
    require(data[:4] in FAT_MAGICS, "not a Mach-O image")
    endian, is64 = FAT_MAGICS[data[:4]]
    count = unpack(endian + "I", data, 4)[0]
    require(1 <= count <= MAX_SLICES, "invalid FAT slice count")
    stride = 32 if is64 else 20
    checked(data, 8, count * stride, "FAT architecture table")
    slices, intervals = [], []
    for index in range(count):
        fields = unpack(endian + ("IIQQII" if is64 else "IIIII"), data, 8 + index * stride)
        cpu, subtype, start, size, alignment = fields[:5]
        require(alignment <= 30 and start % (1 << alignment) == 0, "invalid FAT slice alignment")
        require(start >= 8 + count * stride, "FAT slice overlaps header")
        require(all(start + size <= a or start >= b for a, b in intervals), "overlapping FAT slices")
        intervals.append((start, start + size))
        info = parse_thin(checked(data, start, size, "FAT slice"), external_slots)
        require(info["cpu_type"] == hex(cpu) and info["cpu_subtype"] == hex(subtype), "FAT architecture does not match its Mach-O header")
        info["container_offset"] = start
        info["fat_alignment_power"] = alignment
        slices.append(info)
    return {"container": "fat64" if is64 else "fat32", "slices": slices}


def png_info(data):
    require(data.startswith(b"\x89PNG\r\n\x1a\n"), "invalid PNG signature")
    pos, chunks, info = 8, [], {}
    while pos < len(data):
        size, kind = unpack(">I4s", data, pos)
        payload = checked(data, pos + 8, size, "PNG chunk")
        crc = unpack(">I", data, pos + 8 + size)[0]
        require(zlib.crc32(kind + payload) & 0xFFFFFFFF == crc, "PNG chunk CRC mismatch")
        chunks.append(kind.decode("ascii", "replace"))
        if kind == b"IHDR":
            require(not info and size == 13, "invalid or duplicate PNG IHDR")
            w, h, depth, color, compression, filtering, interlace = unpack(">IIBBBBB", payload)
            require(w > 0 and h > 0, "zero PNG dimensions")
            info.update(width=w, height=h, bit_depth=depth, color_type=color, interlace=interlace)
        pos += 12 + size
        if kind == b"IEND":
            require(size == 0 and pos == len(data), "invalid PNG IEND/trailing bytes")
            break
    require(chunks and chunks[0] == "IHDR" and chunks[-1] == "IEND" and "IDAT" in chunks, "PNG chunk sequence is incomplete")
    return dict(info, chunks=chunks, crc_verified=True)


def classify(data, path):
    if data[:4] in THIN_MAGICS or data[:4] in FAT_MAGICS:
        return "mach-o"
    if path.endswith(".plist"):
        return "plist"
    if data.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if data.startswith(b"NIBArchive"):
        return "compiled-nib"
    if data.startswith(b"bplist"):
        return "binary-plist-resource"
    if data.startswith(b"#!"):
        return "script"
    return "opaque-resource"


def audit(deb, out, expected_sha256=None, provenance=None):
    data = deb.read_bytes()
    digest = sha256(data)
    require(expected_sha256 is None or digest == expected_sha256.lower(), "DEB SHA256 differs from expected artifact")
    require(not out.exists() or not any(out.iterdir()), "output directory must be new or empty")
    members = read_ar(data)
    by_name = {m.name: m for m in members}
    require(by_name.get("debian-binary") is not None and by_name["debian-binary"].data == b"2.0\n", "unsupported/missing debian-binary version")
    controls = [m for m in members if m.name.startswith("control.tar")]
    payloads = [m for m in members if m.name.startswith("data.tar")]
    require(len(controls) == len(payloads) == 1, "DEB must have exactly one control and data archive")
    require([m.name for m in members[:3]] == ["debian-binary", controls[0].name, payloads[0].name], "unexpected Debian ar member order")
    control_inventory, control_files = read_tar(controls[0].data, "control")
    payload_inventory, payload_files = read_tar(payloads[0].data, "payload")
    require("control" in control_files, "missing Debian control file")
    control = parse_control(control_files["control"])
    inventory = control_inventory + payload_inventory
    findings, observations, plists, binaries, resources, scripts = [], [], [], [], [], []

    def finding(severity, code, path, detail):
        findings.append({"severity": severity, "code": code, "path": path, "detail": detail})

    if control.get("Package") != "com.duoface.jb.embedded":
        finding("error", "unexpected_package", "control/control", "Not the expected integrated DuoFace package")
    if control.get("Architecture") != "iphoneos-arm64":
        finding("error", "architecture", "control/control", "Expected rootless iphoneos-arm64 architecture")
    for row in inventory:
        path, scope, kind = row["path"], row["scope"], row["type"]
        mode = int(row["mode"], 8)
        if scope == "payload" and path not in ("", "var", "var/jb") and not path.startswith("var/jb/"):
            finding("error", "non_rootless_path", path, "Payload is outside /var/jb")
        if mode & 0o6000:
            finding("error", "setuid_or_setgid", path, f"Unexpected privileged mode {row['mode']}")
        if mode & 0o002:
            finding("error", "world_writable", path, f"World-writable archive member {row['mode']}")
        if row["uid"] != 0 or row["gid"] != 0:
            finding("warning", "non_root_owner", path, f"Archive owner is {row['uid']}:{row['gid']}")
        if kind == "special":
            finding("error", "special_file", path, "Device/FIFO/unsupported archive entry")
        if kind in ("symlink", "hardlink"):
            resolved = row["resolved_target"].lstrip("/")
            if not resolved.startswith("var/jb/"):
                finding("error", "escaping_link", path, f"Link resolves outside /var/jb: {row['resolved_target']}")
        if kind != "regular":
            continue
        content = (control_files if scope == "control" else payload_files)[path]
        analysis = "debian-control" if scope == "control" and path == "control" else classify(content, path)
        row["analysis_type"] = analysis
        row["analysis_complete"] = True
        try:
            if scope == "control" and path in ("preinst", "postinst", "prerm", "postrm", "config"):
                script = content.decode("utf-8")
                scripts.append({"path": path, "mode": row["mode"], "content": script,
                                "executed": False, "registration_commands": [line for line in script.splitlines() if "uicache" in line or '"$CACHE"' in line]})
                if not mode & 0o111:
                    finding("error", "script_not_executable", "control/" + path, "Maintainer script is not executable")
                active_lines = "\n".join(line for line in script.splitlines() if not line.lstrip().startswith("#"))
                if re.search(r"\b(killall|reboot|respring|ldrestart|sbreload|launchctl|curl|wget|chmod\s+[467][0-7]{3})\b", active_lines):
                    finding("warning", "maintainer_script_review", "control/" + path, "Process/network/privilege-changing command requires explicit review")
            elif analysis in ("plist", "binary-plist-resource"):
                plists.append({"path": path, "format": "binary" if content.startswith(b"bplist") else "XML", "data": plistlib.loads(content)})
            elif analysis == "png":
                resources.append({"path": path, "analysis": png_info(content)})
            elif analysis == "mach-o":
                external = {}
                parent = posixpath.dirname(path)
                if parent.endswith(".app"):
                    for slot, relative in ((1, "Info.plist"), (3, "_CodeSignature/CodeResources")):
                        if parent + "/" + relative in payload_files:
                            external[slot] = payload_files[parent + "/" + relative]
                binary = dict(parse_macho(content, external), path=path)
                binaries.append(binary)
                if not mode & 0o111:
                    finding("error", "binary_not_executable", path, "Mach-O member lacks executable permission")
                if not any(s["architecture"] == "arm64" for s in binary["slices"]):
                    finding("error", "no_arm64_slice", path, "No generic arm64 slice for the intended iPhone X baseline")
                for s in binary["slices"]:
                    label = path + ":" + s["architecture"]
                    if s["encrypted"]:
                        finding("error", "encrypted_binary", label, "Encrypted Mach-O prevents complete static coverage")
                    if not s["build_versions"]:
                        finding("warning", "missing_minimum_os", label, "No recognized minimum-OS load command")
                    for build in s["build_versions"]:
                        if build["platform"] != "iOS" or build["minimum_os_raw"] > (16 << 16):
                            finding("error", "os_contract", label, f"{build['platform']} minimum {build['minimum_os']} does not meet advertised iOS16.0 minimum")
                    for segment in s["segments"]:
                        if segment["initprot"] & 6 == 6:
                            finding("warning", "writable_executable_segment", label, segment["name"])
                    sig = s["code_signature"]
                    if not sig:
                        finding("error", "missing_code_signature", label, "No embedded code signature")
                    elif not sig["all_code_pages_match"] or not sig["all_available_special_slots_match"] or sig.get("xml_der_entitlements_equal") is False:
                        finding("error", "signature_integrity", label, "Code pages, sealed metadata, or XML/DER entitlements do not match")
                    if sig and any(cd["unsigned_gap_before_signature"] for cd in sig["code_directories"]):
                        finding("warning", "unsigned_signature_gap", label, "CodeDirectory leaves bytes before LC_CODE_SIGNATURE outside its declared hash range")
                    if s.get("install_name", "").startswith(("/var/folders/", "/Users/", "/workspace/", "/tmp/")):
                        observations.append({"code": "temporary_install_name", "path": label, "detail": s["install_name"],
                                             "impact": "LC_ID_DYLIB contains a build-machine path. This is not a load dependency and by itself does not demonstrate a launch failure; a stable install name improves reproducibility and future linking."})
                    for dep in s["dependencies"]:
                        if dep["name"].startswith(("/Users/", "/workspace/", "/tmp/")):
                            finding("error", "build_machine_dependency", label, dep["name"])
            elif analysis == "opaque-resource":
                resources.append({"path": path, "analysis": {"format": "opaque", "prefix_hex": content[:32].hex(), "full_hash_recorded": True}})
                if path.endswith(".dylib"):
                    finding("error", "non_macho_dylib", path, "A .dylib does not contain a recognized Mach-O image")
            elif analysis == "compiled-nib":
                resources.append({"path": path, "analysis": {"format": "NIBArchive", "full_hash_recorded": True,
                                                              "strings": [m.group().decode("ascii") for m in re.finditer(rb"[\x20-\x7e]{4,}", content)]}})
        except (AuditError, ValueError, TypeError, OverflowError, struct.error) as exc:
            row["analysis_complete"] = False
            row["analysis_error"] = str(exc)
            finding("error", "member_analysis_failed", scope + "/" + path, str(exc))

    plist_by_path = {p["path"]: p["data"] for p in plists}
    filters, bundles = [], []
    for path, value in sorted(plist_by_path.items()):
        if "/DynamicLibraries/" in path and path.endswith(".plist"):
            declaration = value.get("Filter") if isinstance(value, dict) else None
            filters.append({"path": path, "filter": declaration})
            if not declaration or not isinstance(declaration, dict):
                finding("error", "empty_injection_filter", path, "Missing or empty Substrate Filter dictionary")
            else:
                for key, choices in declaration.items():
                    if not isinstance(choices, list) or not choices:
                        finding("warning", "nonstandard_filter", path, f"Review filter key {key}: {choices!r}")
                    elif any(x in ("*", "com.apple.UIKit") for x in choices):
                        finding("warning", "broad_injection_filter", path, f"Broad filter selector in {key}")
            if path[:-6] + ".dylib" not in payload_files:
                finding("error", "orphan_filter", path, "Filter has no packaged sibling .dylib")
        if path.endswith(".app/Info.plist") and isinstance(value, dict):
            parent = posixpath.dirname(path)
            executable = value.get("CFBundleExecutable", "")
            expected = parent + "/" + executable
            bundle = {"path": parent, "identifier": value.get("CFBundleIdentifier"),
                      "executable": executable, "build_version": value.get("CFBundleVersion"),
                      "short_version": value.get("CFBundleShortVersionString"), "executable_present": expected in payload_files}
            bundles.append(bundle)
            if not executable or expected not in payload_files:
                finding("error", "missing_bundle_executable", path, "CFBundleExecutable is absent from payload")
            storyboard = value.get("UILaunchStoryboardName")
            if storyboard and parent + "/" + storyboard + ".storyboardc/Info.plist" not in payload_files:
                finding("error", "missing_launch_storyboard", path, f"Compiled launch storyboard {storyboard} missing")
    for binary in binaries:
        path = binary["path"]
        if "/DynamicLibraries/" in path and path.endswith(".dylib") and path[:-6] + ".plist" not in plist_by_path:
            finding("error", "missing_filter", path, "Injected .dylib has no valid sibling filter plist")

    out.mkdir(parents=True, exist_ok=True)
    bin_dir = out / "binaries"
    bin_dir.mkdir()
    binary_index = []
    for index, binary in enumerate(binaries, 1):
        stem = f"{index:02d}-" + re.sub(r"[^A-Za-z0-9._-]", "_", posixpath.basename(binary["path"]))
        for s in binary["slices"]:
            slice_stem = stem + "-" + s["architecture"]
            symbols, strings = s.pop("symbols"), s.pop("strings")
            s["symbol_table_file"] = "binaries/" + slice_stem + ".symbols.json"
            s["strings_file"] = "binaries/" + slice_stem + ".strings.json"
            s["strings_count"] = len(strings)
            write_json(out / s["symbol_table_file"], symbols)
            write_json(out / s["strings_file"], strings)
        write_json(bin_dir / (stem + ".json"), binary)
        binary_index.append({"path": binary["path"], "report": "binaries/" + stem + ".json",
                             "container": binary["container"], "architectures": [s["architecture"] for s in binary["slices"]]})
    slices = [s for b in binaries for s in b["slices"]]
    cds = [cd for s in slices if s["code_signature"] for cd in s["code_signature"]["code_directories"]]
    summary = {
        "schema_version": 1, "package": control["Package"], "version": control["Version"],
        "deb_filename": deb.name, "deb_size": len(data), "deb_sha256": digest,
        "expected_sha256_verified": expected_sha256 is not None,
        "provenance": provenance or {},
        "ar_members": [{"name": m.name, "offset": m.offset, "size": len(m.data), "sha256": sha256(m.data)} for m in members],
        "counts": {"control_regular_files": len(control_files), "payload_regular_files": len(payload_files),
                   "payload_directories": sum(r["type"] == "directory" for r in payload_inventory),
                   "links": sum(r["type"] in ("symlink", "hardlink") for r in inventory),
                   "all_tar_entries": len(inventory), "fully_analyzed_regular_files": sum(r.get("analysis_complete", False) for r in inventory),
                   "mach_o_files": len(binaries), "mach_o_slices": len(slices), "code_directories": len(cds),
                   "verified_code_pages": sum(cd["verified_page_count"] for cd in cds),
                   "code_pages": sum(cd["page_count"] for cd in cds), "plists": len(plists),
                   "png_files": sum(r.get("analysis_type") == "png" for r in inventory),
                   "compiled_nibs": sum(r.get("analysis_type") == "compiled-nib" for r in inventory)},
        "analysis_types": dict(Counter(r.get("analysis_type") for r in inventory if r["type"] == "regular")),
        "findings": findings, "error_count": sum(f["severity"] == "error" for f in findings),
        "observations": observations,
        "warning_count": sum(f["severity"] == "warning" for f in findings),
        "static_integrity_pass": not any(f["severity"] == "error" for f in findings),
        "binaries": binary_index, "bundles": bundles, "injection_filters": filters,
        "maintainer_scripts_executed": False, "payload_binaries_executed": False,
        "device_tested": False, "apple_trust_chain_verified": False,
        "limits": ["Static archive and metadata integrity is not a physical CarPlay, touch, keyboard, lifecycle, private-API ABI, or AMFI acceptance test.",
                   "No binary rewriting, package installation, maintainer script execution, or network publication occurs.",
                   "String/symbol presence identifies candidate code paths; it does not prove those paths execute or behave correctly.",
                   "NIB resources are hashed and inventoried with their format/strings; UIKit does not instantiate them in this scan.",
                   "SHA256/SHA1 CodeDirectory digest checks establish internal integrity, not an Apple/CMS signer identity or permission to load on a device.",
                   "Source commit/run/artifact identifiers are caller-supplied provenance and must be cross-checked against the CI artifact receipt."]}
    write_json(out / "audit.json", summary)
    write_json(out / "inventory.json", inventory)
    write_json(out / "plists.json", plists)
    write_json(out / "resources.json", resources)
    write_json(out / "control.json", {"fields": control, "scripts": scripts})
    (out / "SHA256SUMS.txt").write_text(f"{digest}  {deb.name}\n" + "".join(f"{r['sha256']}  {r['scope']}/{r['path']}\n" for r in inventory if r["type"] == "regular"), encoding="utf-8")
    write_status(out, summary, control, binaries, scripts)
    return summary


def write_status(out, summary, control, binaries, scripts):
    c = summary["counts"]
    lines = ["# Whole-package static audit", "", f"**Package:** `{summary['package']} {summary['version']}`", "",
             f"**DEB:** `{summary['deb_filename']}` — {summary['deb_size']:,} bytes", "",
             f"**SHA256:** `{summary['deb_sha256']}`", "",
             f"**Result:** {'PASS' if summary['static_integrity_pass'] else 'FAIL'} for the implemented static archive/integrity checks; "
             f"{summary['error_count']} errors, {summary['warning_count']} warnings. **Device acceptance: not tested.**", "",
             "## Exact coverage", "",
             f"- All {c['all_tar_entries']} tar entries inventoried: {c['payload_regular_files']} payload files, "
             f"{c['control_regular_files']} control files, {c['payload_directories']} payload directories, {c['links']} links.",
             f"- {c['fully_analyzed_regular_files']} regular files read and hashed; {c['plists']} plists decoded; "
             f"{c['png_files']} PNGs checked through IEND with every chunk CRC; {c['compiled_nibs']} compiled NIBs hashed and string-inventoried.",
             f"- {c['mach_o_files']} Mach-O files / {c['mach_o_slices']} architecture slices parsed, including all FAT slices.",
             f"- {c['code_directories']} CodeDirectories; {c['verified_code_pages']}/{c['code_pages']} page hashes match. "
             "Available sealed special slots are compared; XML/DER entitlements are decoded and compared when both exist.",
             "- Every load command, dependency/rpath, minimum OS, segment/section, symbol table, Objective-C selector/class string section, "
             "and embedded-signature blob is recorded. Domain-marker lists cover keyboard, touch/logo, scene/owner, native maps, disconnect/close, and interposition.",
             "- Maintainer scripts and Mach-O files were **not executed**.", "", "## Package metadata and installation behavior", "",
             f"- Architecture: `{control.get('Architecture')}`; dependencies: `{control.get('Depends', '')}`.",
             f"- Conflicts: `{control.get('Conflicts', '')}`.", f"- Replaces: `{control.get('Replaces', '')}`.",
             "- Conflicts/Replaces are package-manager migration declarations; this scan does not install/remove any package.", "",
             "## Every executable image", "", "| File | Slices | Min OS | Page hashes | CMS |", "|---|---|---|---|---|"]
    for binary in binaries:
        arches = ", ".join(s["architecture"] for s in binary["slices"])
        minimums = ", ".join(sorted({v["platform"] + " " + v["minimum_os"] for s in binary["slices"] for v in s["build_versions"]}))
        hashes = all(s["code_signature"] and s["code_signature"]["all_code_pages_match"] for s in binary["slices"])
        cms = any(s["code_signature"] and s["code_signature"]["cms_present"] for s in binary["slices"])
        lines.append(f"| `{posixpath.basename(binary['path'])}` | {arches} | {minimums} | {'match' if hashes else 'FAIL/missing'} | {'present' if cms else 'absent'} |")
    lines += ["", "CMS absence is recorded as a property of the jailbreak-style signatures, not as a failed Apple identity verification. "
              "No Apple trust chain or on-device trust cache was checked.", "", "## Injection scopes", "",
              "| Filter | Exact declared values |", "|---|---|"]
    for entry in summary["injection_filters"]:
        lines.append(f"| `{posixpath.basename(entry['path'])}` | `{json.dumps(entry['filter'], ensure_ascii=False)}` |")
    lines += ["", "## Maintainer scripts (complete, read only)", ""]
    for script in scripts:
        lines += [f"### `{script['path']}` (mode {script['mode']})", "", "```sh", script["content"].rstrip(), "```", ""]
    lines += ["## Findings", ""]
    if summary["findings"]:
        for item in summary["findings"]:
            lines.append(f"- **{item['severity'].upper()} {item['code']}** — `{item['path']}`: {item['detail']}")
    else:
        lines.append("No archive/path/mode/format/integrity failure detected by the implemented checks. This does not certify runtime correctness.")
    if summary["observations"]:
        lines += ["", "## Additional observations", ""]
        for item in summary["observations"]:
            lines.append(f"- **{item['code']}** — `{item['path']}`: `{item['detail']}`. {item['impact']}")
    lines += ["", "## Provenance", "", "```json", json.dumps(summary["provenance"], indent=2, sort_keys=True), "```", "",
              "The complete records are in `audit.json`, `inventory.json`, `control.json`, `plists.json`, `resources.json`, "
              "`SHA256SUMS.txt`, and the per-slice reports under `binaries/`.", "", "## Limits", ""]
    lines += ["- " + x for x in summary["limits"]]
    (out / "STATUS.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--deb", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True, help="New or empty report directory")
    parser.add_argument("--expected-sha256", help="Exact independently obtained SHA256 of the input DEB")
    parser.add_argument("--source-sha", default="")
    parser.add_argument("--run-id", default="")
    parser.add_argument("--artifact-id", default="")
    args = parser.parse_args()
    try:
        result = audit(args.deb, args.out, args.expected_sha256,
                       {"source_repository": "chuongnguyen89dn-ui/Duoface", "source_commit": args.source_sha,
                        "github_actions_run_id": args.run_id, "github_artifact_id": args.artifact_id,
                        "audit_tool_sha256": sha256(Path(__file__).read_bytes())})
    except (AuditError, OSError, tarfile.TarError, ValueError) as exc:
        print(json.dumps({"error": str(exc), "static_integrity_pass": False}), file=sys.stderr)
        return 2
    print(json.dumps({k: result[k] for k in ("package", "version", "deb_sha256", "counts", "static_integrity_pass", "findings")}, indent=2))
    return 0 if result["static_integrity_pass"] else 1


if __name__ == "__main__":
    sys.exit(main())
