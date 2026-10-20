#!/usr/bin/env python3
"""Self-contained, original DuoFace Test app icon PNGs; no third-party assets."""
from pathlib import Path
import struct, zlib, sys
def png(path, size):
    # Navy gradient, split layout, center control and luminous accent.
    rows=[]
    for y in range(size):
        r=bytearray()
        for x in range(size):
            fx=x/size
            fy=y/size
            rr=int(13+10*fy);gg=int(28+18*fx);bb=int(54+35*(1-fy))
            # Rounded background and two equal CarPlay panes.
            px,py=x/size,y/size
            left=.14<=px<=.46 and .25<=py<=.76
            right=.54<=px<=.86 and .25<=py<=.76
            outline=(.12<=px<=.88 and (.20<=py<=.23 or .78<=py<=.81) or
                     .20<=py<=.81 and (.11<=px<=.14 or .86<=px<=.89))
            border=(abs(px-.5)<.012 and .25<py<.77)
            dot=((px-.5)**2+ (py-.16)**2)<(.045)**2
            if outline or border:rr,gg,bb=(96,220,220)
            elif left:rr,gg,bb=(40,116,206)
            elif right:rr,gg,bb=(27,185,158)
            if dot:rr,gg,bb=(238,247,254)
            r.extend((rr,gg,bb,255))
        rows.append(b'\0'+r)
    def chunk(kind,data):
        return struct.pack(">I",len(data))+kind+data+struct.pack(">I",zlib.crc32(kind+data)&0xffffffff)
    raw=b''.join(rows)
    encoded=(b'\x89PNG\r\n\x1a\n'
        +chunk(b'IHDR',struct.pack(">IIBBBBB",size,size,8,6,0,0,0))
        +chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
    path.write_bytes(encoded)
def main():
    root=Path(sys.argv[1]) if len(sys.argv)>1 else Path.cwd()
    root.mkdir(parents=True,exist_ok=True)
    png(root/'AppIcon60x60@2x.png',120)
    png(root/'AppIcon60x60@3x.png',180)
    print('Original DuoFace Test icon assets generated for 120pt and 180pt')
if __name__=='__main__': main()
