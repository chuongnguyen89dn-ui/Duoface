#!/usr/bin/env python3
"""Recover *all* ARM64 __TEXT,__text instructions, not the first Capstone run.

Earlier static audit streamed md.disasm() over an entire section: it stopped
on the first undecodable word at 0x17a1c, silently omitting GOFA exported
helpers at 0x3e38c/0x3e93c. This walks LC_FUNCTION_STARTS individually and
skips only individual invalid 4-byte words, without ever executing vendor code.
"""
from __future__ import annotations
import argparse, gzip, json, struct
from pathlib import Path

def recover(thin: bytes, load: dict, starts: list[int]) -> tuple[str, dict]:
    from capstone import Cs,CS_ARCH_ARM64,CS_MODE_ARM
    sections=[x for x in load["sections"] if x["segment"]=="__TEXT" and x["section"]=="__text"]
    if len(sections)!=1:raise RuntimeError("ambiguous original __TEXT,__text section")
    sec=sections[0]
    lo,off,length=sec["addr"],sec["offset"],sec["size"]
    end=lo+length
    if lo<0 or off<0 or length<=0 or off+length>len(thin):raise RuntimeError("invalid thin section")
    starts=sorted(set(int(x) for x in starts if lo<=x<end))
    if not starts or starts[0]!=lo:raise RuntimeError("original function starts missing first __text")
    starts.append(end)
    md=Cs(CS_ARCH_ARM64,CS_MODE_ARM)
    instructions=0;invalid=0;out=[]
    for idx,(begin,finish) in enumerate(zip(starts,starts[1:])):
        position=begin
        while position<finish:
            byte_pos=off+position-lo
            # ARM64 fixed instruction width. The disassembler may stop at an
            # embedded constant or padding; never treat that as end of file.
            block=thin[byte_pos:off+finish-lo]
            found=list(md.disasm_lite(block,position))
            if not found:
                invalid+=1;position+=4;continue
            for address,size,mnemonic,operand in found:
                if address+size>finish:break
                raw=thin[off+address-lo:off+address-lo+size]
                out.append(f"{address:016x}\t{raw.hex()}\t{mnemonic}\t{operand}\n")
                instructions+=1
            position=found[-1][0]+found[-1][1]
    if not out or instructions<25000:raise RuntimeError(f"too few original full instructions: {instructions}")
    existing={int(x.split("\t",1)[0],16) for x in out}
    pivots=(254860,254864,256316,256320)
    missing=[hex(x) for x in pivots if x not in existing]
    if missing:raise RuntimeError("missing original GOFA exported function instructions "+repr(missing))
    metadata={"original_text_start":hex(lo),"original_text_end":hex(end),
              "original_text_size":length,"original_function_starts":len(starts)-1,
              "decoded_instructions":instructions,"undecodable_words":invalid,
              "pivot_addresses_present":[hex(x) for x in pivots],
              "old_audit_disassembly_was_truncated_at":"0x17a18",
              "not_runtime_test":True}
    return "".join(out), metadata

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--thin",type=Path,required=True)
    parser.add_argument("--load-commands",type=Path,required=True)
    parser.add_argument("--function-starts",type=Path,required=True)
    parser.add_argument("--out",type=Path,required=True)
    args=parser.parse_args()
    data=args.thin.read_bytes()
    if data[:4]!=b"\xcf\xfa\xed\xfe":raise RuntimeError("expected thin little-endian MachO64")
    text,meta=recover(data,json.loads(args.load_commands.read_text()),
                      json.loads(args.function_starts.read_text()))
    args.out.mkdir(parents=True,exist_ok=True)
    with gzip.open(args.out/"FULL_ORIGINAL_ARM64_DISASSEMBLY.txt.gz","wt",encoding="utf-8") as f:f.write(text)
    (args.out/"RECOVERY_SUMMARY.json").write_text(json.dumps(meta,indent=2)+"\n")
    print("QA166_FULL_ORIGINAL_GOFA_FUNCTION_DISASSEMBLY_RECOVERED",meta)
if __name__=="__main__":
    main()
