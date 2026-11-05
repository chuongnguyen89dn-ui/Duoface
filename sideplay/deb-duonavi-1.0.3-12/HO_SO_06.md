  0x100000000 S __mh_execute_header [__TEXT,__text]
  0x1000063ac S _main [__TEXT,__text]
undefined symbols:
  U _CFDataGetBytePtr
  U _CFDataGetLength
  U _CFDataGetTypeID
  U _CFGetTypeID
  U _CFNumberGetTypeID
  U _CFNumberGetValue
  U _CFRelease
  U _CFStringCreateWithCString
  U _CFStringGetCString
  U _CFStringGetTypeID
  U _IOObjectRelease
  U _IORegistryEntryCreateCFProperty
  U _IOServiceGetMatchingService
  U _IOServiceMatching
  U ___memcpy_chk
  U ___stack_chk_fail
  U ___stack_chk_guard
  U ___stderrp
  U _access
  U _fwrite
  U _kCFAllocatorDefault
  U _kIOMasterPortDefault
  U _mach_task_self_
  U _memcpy
  U _posix_spawn
  U _printf
  U _putchar
  U _setgid
  U _setuid
  U _snprintf
  U _strcmp
  U _strlen
  U _sysctlbyname
  U _vm_read_overwrite
  U _waitpid
  U dyld_stub_binder

OBJC imageinfo: None
OBJC classes: 0  +load classes: []  categories: 0  protocols: []
OBJC classrefs resolved: []
OBJC metadata digest: 230b658c01a0a7d751d60f1a585b8a9290df6dd5ce93a1315ca3772b7bf6ed4a

===== SLICE 1: arm64 sub=arm64e (raw subtype 0x2) filetype=EXECUTE flags=0x200085 off=98304 size=52224 =====
ncmds=26
load commands: LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_SEGMENT_64, LC_DYLD_CHAINED_FIXUPS, LC_DYLD_EXPORTS_TRIE, LC_SYMTAB, LC_DYSYMTAB, LC_LOAD_DYLINKER, LC_UUID, LC_BUILD_VERSION, LC_SOURCE_VERSION, LC_MAIN, LC_ENCRYPTION_INFO_64, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_LOAD_DYLIB, LC_RPATH(REQ), LC_RPATH(REQ), LC_RPATH(REQ), LC_RPATH(REQ), LC_FUNCTION_STARTS, LC_DATA_IN_CODE, LC_CODE_SIGNATURE
id_dylib: None
uuid: 5ba5e15bfda834aba9e8b1234ddd689a
build_version: ('iOS', '15.0.0', '16.5.0')  min_version: None  source_version: 0.0.0
encryption: (16384, 16384, 0)  main: (25632, 0)  rpaths: ['/var/jb/Library/Frameworks', '/var/jb/usr/lib', '@loader_path/.jbroot/Library/Frameworks', '@loader_path/.jbroot/usr/lib']
codesig: (51440, 784) chained_fixups=True dyld_info=False
linked libraries:
  [LC_LOAD_DYLIB] /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation cur=1971.0.0 compat=150.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/IOKit.framework/Versions/A/IOKit cur=275.0.0 compat=1.0.0
  [LC_LOAD_DYLIB] /System/Library/Frameworks/Security.framework/Security cur=60420.102.1 compat=1.0.0
  [LC_LOAD_DYLIB] /usr/lib/libSystem.B.dylib cur=1319.100.3 compat=1.0.0
segments/sections:
  __TEXT,__text addr=0x100006420 size=5872 off=25632 flags=0x80000400
  __TEXT,__auth_stubs addr=0x100007b10 size=480 off=31504 flags=0x80000408
  __TEXT,__const addr=0x100007cf0 size=540 off=31984 flags=0x0
  __TEXT,__cstring addr=0x100007f0c size=159 off=32524 flags=0x2
  __TEXT,__unwind_info addr=0x100007fac size=72 off=32684 flags=0x0
  __DATA_CONST,__auth_got addr=0x100008000 size=240 off=32768 flags=0x6
  __DATA_CONST,__got addr=0x1000080f0 size=56 off=33008 flags=0x6
  __DATA,__bss addr=0x10000c000 size=36 off=0 flags=0x1
signature blobs: [(0, '0xfade0c02', 604), ('CD ident', 'cboptimize_helper.d0920c2e.unsigned', 'ver=0x20400 flags=0x0'), (2, '0xfade0c01', 152)]
ENTITLEMENTS:
(none found)
symbols: defined=2 undefined=35 stab/other=1
exported (trie): 2
  EXP __mh_execute_header
  EXP _main
defined symbols:
  0x100000000 S __mh_execute_header [__TEXT,__text]
  0x100006420 S _main [__TEXT,__text]
undefined symbols:
  U _CFDataGetBytePtr
  U _CFDataGetLength
  U _CFDataGetTypeID
  U _CFGetTypeID
  U _CFNumberGetTypeID
  U _CFNumberGetValue
  U _CFRelease
  U _CFStringCreateWithCString
  U _CFStringGetCString
  U _CFStringGetTypeID
  U _IOObjectRelease
  U _IORegistryEntryCreateCFProperty
  U _IOServiceGetMatchingService
  U _IOServiceMatching
  U ___memcpy_chk
  U ___stack_chk_fail
  U ___stack_chk_guard
  U ___stderrp
  U _access
  U _fwrite
  U _kCFAllocatorDefault
  U _kIOMasterPortDefault
  U _mach_task_self_
  U _memcpy
  U _posix_spawn
  U _printf
  U _putchar
  U _setgid
  U _setuid
  U _snprintf
  U _strcmp
  U _strlen
  U _sysctlbyname
  U _vm_read_overwrite
  U _waitpid

OBJC imageinfo: None
OBJC classes: 0  +load classes: []  categories: 0  protocols: []
OBJC classrefs resolved: []
OBJC metadata digest: 230b658c01a0a7d751d60f1a585b8a9290df6dd5ce93a1315ca3772b7bf6ed4a
```


---

## 10. Chưa xác định được (trung thực — không suy đoán thay số liệu)

1. **Tên và thân các hàm C nội bộ của DuoFaceDashboard**: symtab của dylib này bị strip sạch symbol định nghĩa (0 symbol). Chỉ biết: tổng số hàm máy theo LC_FUNCTION_STARTS (1.526 ở arm64 / 1.528 ở arm64e), 2 địa chỉ constructor (0x6258, 0x2a803c — không có tên, không tách được vai trò từng cái), và vài tên hàm C còn sót trong chuỗi log (`CBUpdateApplicationLibrary`, `CBBundleIDForIconView`, `CBDumpViewHierarchy`, `CBExtractBundleIDFromScene`). Đợt quét này **không dịch ngược lệnh máy (disassembly) từng thân hàm** — hồ sơ dừng ở mức metadata Objective-C + symbol + chuỗi + cấu trúc Mach-O.
2. **URL backend đầy đủ của license/subscription**: dạng rõ chỉ có host `duoface.com` và các tên hàm phân giải (`resolvedBackendBaseURL`, `currentServerBaseURL`, `formatBaseURLString:`). Đường path endpoint, cách ghép URL và định dạng JSON request/response **không** nằm dạng literal trong bảng chuỗi đã trích. Tương tự, URL Google speech có tham số `key=%@` — giá trị API key thực không xuất hiện dạng rõ.
3. **Tên Darwin notification literal của `NOTIFY_APP_STATE` / `NOTIFY_APP_REQUEST`**: hai định danh này chỉ xuất hiện bên trong chuỗi log (dạng tên macro). Tên reverse-DNS tương ứng nếu có thì không nằm trong các chuỗi đã trích; chỉ xác định chắc chắn được 3 kênh `com.duoface.fullscreen.command.v1` / `.state.v1` / `.picker.v1` và các tên thông báo hệ thống ở Mục 5.3.
4. **Thuật toán hardware hash của helper**: khóa IOKit cụ thể (tên dịch vụ cho `IOServiceMatching`, tên property cho `IORegistryEntryCreateCFProperty`) và hàm băm sử dụng **không** nằm trong bảng chuỗi của helper (chỉ có 149 chuỗi, phần lớn là tên section/symbol). Muốn xác định phải dịch ngược thân `_main` — ngoài phạm vi đợt này. Hai mảnh chuỗi `subject.CN` và `radr://5614542` không đủ căn cứ gán ý nghĩa; riêng `radr://5614542` xuất hiện trong nhiều binary arm64e khác nhau nên được coi là nhiễu dữ liệu vùng hằng số, không phải endpoint.
5. **Đường đăng ký callback giữa VisualHook và Dashboard**: VisualHook phơi sẵn các ô `_DFNative*` và hàm `_DFInstall`/`_DFInstallBorderRunner`, nhưng binary nào gọi chúng và qua kênh nào (gọi trực tiếp liên dylib, qua Darwin notify, hay qua class dùng chung) không hiện trực tiếp trong dữ liệu tĩnh đã đọc.
6. **Mục đích cụ thể của việc đọc TCC.db trong Dashboard**: xác định được nó liên kết libsqlite3 và chứa 3 đường dẫn TCC.db, nhưng dịch vụ TCC/app nào được truy vấn thì không ghi trong chuỗi.
7. **Một mục export không tên của Dashboard slice arm64e**: exports trie của slice này có 1 mục mà parser không khôi phục được tên (slice arm64 không có mục export nào). Không ảnh hưởng bảng class/method.
8. **Các file postinst tham chiếu nhưng không thuộc gói này**: `CarBridgeDashboard.plist` và `/var/jb/etc/sudoers.d/carbridge` không nằm trong data.tar của deb này (khả năng thuộc gói legacy họ CarBridge) — hành vi của chúng ngoài phạm vi hồ sơ này. Tương tự file nguồn ảnh `DuoFace_5_images_REVIEW_before_upload.zip` ghi trong asset-manifest không nằm trong gói.
9. **Đối chiếu superclass phía slice arm64 (LC_DYLD_INFO)**: parser bind-opcode khôi phục được một phần (nhóm NSObject và class nội bộ — khớp với arm64e), phần còn lại lấy từ slice arm64e. Việc áp dụng cho cả hai slice dựa trên kiểm chứng bảng class/method/property/ivar của hai slice giống hệt nhau 100% (Mục 4) — nhưng bản thân các bản ghi bind phía arm64 cho từng class view-controller không được liệt kê riêng trong hồ sơ này.
10. **Hành vi thực tế trên thiết bị**: hồ sơ này là kết quả quét tĩnh. Mọi mô tả cơ chế đều dựa trên metadata/chuỗi/symbol/plist/script như đã ghi mức bằng chứng từng mục; không có bước chạy thử trên máy trong phạm vi nhiệm vụ, nên thứ tự thực thi thực tế và các nhánh điều kiện chỉ suy ra được tới mức các chuỗi log và cấu trúc class cho phép.

---

*Hết hồ sơ. Đối tượng duy nhất của hồ sơ: `com.duonavi.app_1.0.3-12_border-focus-red3_iphoneos-arm64.deb`, SHA256 `3e32825ccab63ce06f2ba02f4d629ad86d96a7d801e29858954a378c3bb35915`. Dữ liệu quét thô (dump parser, bảng chuỗi đầy đủ, script phân tích) được giữ tại thư mục làm việc `work/` cạnh hồ sơ này.*
