#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Kiểm tính khôi phục nguyên vẹn TAR staging DuoFace bằng manifest từng file.

Đọc trực tiếp TAR, KHÔNG giải nén/thi hành, KHÔNG patch mã và KHÔNG tạo gói cài.
"""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import tarfile
from pathlib import PurePosixPath

def check() -> None:
    arg=argparse.ArgumentParser()
    arg.add_argument("--archive",required=True,type=Path)
    arg.add_argument("--report",required=True,type=Path)
    arg.add_argument("--expected-sha256",required=True)
    x=arg.parse_args()
    data=x.archive.read_bytes()
    digest=hashlib.sha256(data).hexdigest()
    assert digest==x.expected_sha256, f"File TAR staging sai SHA: {digest}"
    expected=json.loads(x.report.read_text(encoding="utf-8"))
    assert expected["status"]=="EXACT_PAYLOAD_STAGED_LICENSE_CODE_EMBEDDED_NOT_INDEPENDENT"
    target=expected["all_staged_entries"]
    observed={}
    with tarfile.open(fileobj=None,name=x.archive,mode="r:gz") as archive:
        for member in archive.getmembers():
            path=PurePosixPath(member.name)
            assert not path.is_absolute() and ".." not in path.parts, "TAR có đường dẫn không an toàn"
            assert path.parts[0]=="duoface-exact-stage", f"Tên gốc TAR sai: {member.name}"
            if len(path.parts)==1: continue
            rel=PurePosixPath(*path.parts[1:]).as_posix()
            assert rel not in observed, f"Entry trùng lặp: {rel}"
            mode=oct(member.mode & 0o7777)
            if member.isfile():
                binary=archive.extractfile(member)
                assert binary is not None
                blob=binary.read()
                observed[rel]={
                    "kind":"file","size":len(blob),"mode":mode,
                    "sha256":hashlib.sha256(blob).hexdigest(),
                }
            elif member.isdir():
                observed[rel]={"kind":"directory","mode":mode}
            elif member.issym():
                observed[rel]={"kind":"symlink","target":member.linkname,"mode":mode}
            else:
                raise AssertionError(f"Unexpected TAR entry: {rel}, {member.type!r}")
    assert observed==target, (
        f"Archive và manifest không khớp. Missing={sorted(set(target)-set(observed))}, "
        f"Extra={sorted(set(observed)-set(target))}, "
        f"Different={[k for k in target.keys() & observed.keys() if target[k]!=observed[k]]}"
    )
    assert "var/mobile/Library/Preferences/com.duonavi.sync.plist" not in observed
    assert len([v for v in observed.values() if v["kind"]=="file"])==expected["copied_file_count"]
    print(json.dumps({
        "status":"STAGING_ARCHIVE_LOSSLESS_RECONSTRUCTION_PASS_NOT_LICENSE_INDEPENDENT",
        "archive_sha256":digest,
        "restored_entries":len(observed),
        "restored_regular_files":expected["copied_file_count"],
        "excluded_only":expected["excluded_only"],
        "independent_release_ready":False,
    },ensure_ascii=False,indent=2))

if __name__=="__main__":
    check()
