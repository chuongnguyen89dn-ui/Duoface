# TRÍCH LOG QA180 — 3 CHU KỲ EXHAUSTED (phục vụ Bước 0 / P3 của WO QA181)

Nguồn: export `DuoFaceAudit.txt` trên nhánh main, commit `ed20760aa0` (xuất 03/11/2026 04:58 UTC), phiên build `0.0.180~kbcycle1`. Trích nguyên văn (đã bỏ tiền tố utc/uptime).

## Sự kiện sống còn của relay trong Waze (đối chiếu)
    [DFNative12Chrome] qa180-relay-alive bundle=com.waze.iphone stage=R1
    [DFNative12Chrome] qa180-relay-alive bundle=com.waze.iphone stage=R2 guards=ok listen=1 reg=1

## Chu kỳ applied (đối chứng — cyc=2, trúng ngay nhịp đầu)
    build=0.0.180~kbcycle1 pid=11462 process=SpringBoard run=F14ABD86-DA56-4700-9B74-73318BC32AED main=1 area=chrome qa179-kbfit bundle=com.google.Maps action=applied reason=- late=0 screen={{0, 0}, {414, 736}} key={{0, 0}, {595, 685}} kbBefore={{0, 0}, {414, 736}} kbAfter={{0, 0}, {595, 685}} subs=UIInputSetContainerView{{0, 0}, {414, 736}}>UIInputSetHostView{{0, 574}, {414, 162}};_UIReplicantView{{0, 0}, {595, 685}} refSize={414, 736} refWhen=pre cyc=2 try=1 foundAt=0 begin={{0, 736}, {414, 226}} end={{0, 561}, {414, 175}}

## 3 chu kỳ exhausted (cyc=3, 4, 7 — nhịp đầu try=1 và nhịp cuối try=4)
    build=0.0.180~kbcycle1 pid=11462 process=SpringBoard run=F14ABD86-DA56-4700-9B74-73318BC32AED main=1 area=chrome qa179-kbfit bundle=com.google.Maps action=skip reason=no-kb-window late=0 screen={{0, 0}, {414, 736}} key={{0, 0}, {595, 685}} kbBefore=? kbAfter=? subs= refSize=? refWhen=pre cyc=3 try=1 foundAt=-1 begin={{0, 736}, {414, 226}} end={{0, 561}, {414, 175}}
    build=0.0.180~kbcycle1 pid=11462 process=SpringBoard run=F14ABD86-DA56-4700-9B74-73318BC32AED main=1 area=chrome qa179-kbfit bundle=com.google.Maps action=skip reason=no-kb-window late=1 screen={{0, 0}, {414, 736}} key={{0, 0}, {595, 685}} kbBefore=? kbAfter=? subs= refSize=? refWhen=post cyc=3 try=4 foundAt=-1 begin={{0, 736}, {414, 226}} end={{0, 561}, {414, 175}}
    build=0.0.180~kbcycle1 pid=11462 process=SpringBoard run=F14ABD86-DA56-4700-9B74-73318BC32AED main=1 area=chrome qa179-kbfit bundle=com.google.Maps action=skip reason=no-kb-window late=0 screen={{0, 0}, {414, 736}} key={{0, 0}, {595, 685}} kbBefore=? kbAfter=? subs= refSize=? refWhen=pre cyc=4 try=1 foundAt=-1 begin={{0, 736}, {414, 175}} end={{0, 561}, {414, 175}}
    build=0.0.180~kbcycle1 pid=11462 process=SpringBoard run=F14ABD86-DA56-4700-9B74-73318BC32AED main=1 area=chrome qa179-kbfit bundle=com.google.Maps action=skip reason=no-kb-window late=1 screen={{0, 0}, {414, 736}} key={{0, 0}, {595, 685}} kbBefore=? kbAfter=? subs= refSize=? refWhen=post cyc=4 try=4 foundAt=-1 begin={{0, 736}, {414, 175}} end={{0, 561}, {414, 175}}
    build=0.0.180~kbcycle1 pid=11462 process=SpringBoard run=F14ABD86-DA56-4700-9B74-73318BC32AED main=1 area=chrome qa179-kbfit bundle=com.google.Maps action=skip reason=no-kb-window late=0 screen={{0, 0}, {414, 736}} key={{0, 0}, {595, 685}} kbBefore=? kbAfter=? subs= refSize=? refWhen=pre cyc=7 try=1 foundAt=-1 begin={{0, 517}, {414, 219}} end={{0, 561}, {414, 175}}
    build=0.0.180~kbcycle1 pid=11462 process=SpringBoard run=F14ABD86-DA56-4700-9B74-73318BC32AED main=1 area=chrome qa179-kbfit bundle=com.google.Maps action=skip reason=no-kb-window late=1 screen={{0, 0}, {414, 736}} key={{0, 0}, {595, 685}} kbBefore=? kbAfter=? subs= refSize=? refWhen=post cyc=7 try=4 foundAt=-1 begin={{0, 517}, {414, 219}} end={{0, 561}, {414, 175}}

## Đọc kết quả (đã đo, không suy đoán)
- Cả 3 chu kỳ exhausted: đủ 4 nhịp đánh giá (0 / +0,3 / +0,6 / +1,2s) đều `skip reason=no-kb-window`, `kbBefore=? kbAfter=?`, `refSize=?` — cửa sổ phím không tồn tại trong danh sách cửa sổ của process Maps ở bất kỳ nhịp nào (sự kiện hiện cửa sổ cũng không cứu được).
- Notification DidShow mang sẵn khung cuối của phím: `end={{0, 561}, {414, 175}}` — phím cao 175, neo tại y=561, đáy = 736 = chiều cao màn hình điện thoại; key window của app là `{595, 685}`. Đây là nửa đã đo của P3: neo đáy theo 736 trong khi app chỉ cao 685.
- Ở chu kỳ applied: `refSize={414, 736}` (pre) — kích thước tham chiếu của cửa sổ phím đúng bằng màn hình điện thoại, độc lập với khung app {595, 685}.
