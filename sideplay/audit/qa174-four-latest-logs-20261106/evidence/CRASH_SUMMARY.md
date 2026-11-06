# Three newly uploaded IPS files: event dates are not upload dates

Only the three IPS files in upload 3dc27f7d833709be04fc3406aa3bb7077b023f83 are read. No older repository log is opened.

## Crash-0-SpringBoard.diskwrites_resource-2026-11-04-210058 3.ips

L1: {"app_name":"SpringBoard","timestamp":"2026-11-04 21:00:58.00 +0700","app_version":"1.0","slice_uuid":"E1A4FE7D-29FF-3269-B3AB-50AED40C4495","build_version":"50","bundleID":"com.apple.springboard","duration_ms":"38512141","share_with_app_devs":0,"is_first_party":1,"bug_type":"145","os_version":"iPhone OS 16.7.16 (20H392)","roots_installed":0,"incident_id":"82985C43-3402-4DBF-968F-590252A509DA","name":"SpringBoard"}
L2: Date/Time:        2026-11-04 10:19:04.354 +0700
L3: End time:         2026-11-04 21:00:56.495 +0700
L4: OS Version:       iPhone OS 16.7.16 (Build 20H392)
L9: Data Source:      Microstackshots
L12: Command:          SpringBoard
L21: PID:              418
L23: Event:            disk writes
L24: Action taken:     none
L25: Writes:           1073.75 MB of file backed memory dirtied over 38512 seconds (27.88 KB per second average), exceeding limit of 12.43 KB per second over 86400 seconds
L26: Writes limit:     1073.74 MB
L28: Writes caused:    1073.75 MB
L29: Writes duration:  38512s
L30: Duration:         38512.14s
L31: Duration Sampled: 38449.05s
L34: Hardware model:   iPhone10,2

### Heaviest-stack excerpt

L49: Heaviest stack for the target process:
L50:   93  ??? (<444F5041-332E-302E-3900-AE6387A9FA9A> + 99140) [0x100aa4344]
L51:   93  ??? (SpringBoard + 636392) [0x1e2e815e8]
L52:   93  ??? (UIKitCore + 3608516) [0x1a670ffc4]
L53:   93  ??? (UIKitCore + 3609420) [0x1a671034c]
L54:   93  ??? (GraphicsServices + 6552) [0x1dc551998]
L55:   93  ??? (CoreFoundation + 498976) [0x1a447dd20]
L56:   93  ??? (CoreFoundation + 480840) [0x1a4479648]
L57:   93  ??? (CoreFoundation + 596396) [0x1a44959ac]
L58:   93  ??? (libdispatch.dylib + 285320) [0x1ab195a88]
L59:   91  ??? (libdispatch.dylib + 286052) [0x1ab195d64]
L60:   91  ??? (libdispatch.dylib + 317312) [0x1ab19d780]
L61:   91  ??? (libdispatch.dylib + 245064) [0x1ab18bd48]
L62:   91  ??? (libdispatch.dylib + 411520) [0x1ab1b4780]
L63:   91  ??? (<679D290B-EF8D-36CB-B69B-24B50C08264B> + 65000) [0x100d4bde8]
L64:   91  ??? (Foundation + 768824) [0x19e849b38]
L65:   78  ??? (Foundation + 422844) [0x19e7f53bc]
L66:   78  ??? (Foundation + 305756) [0x19e7d8a5c]
L67:   78  ??? (Foundation + 632640) [0x19e828740]
L68:   78  ??? (libsystem_kernel.dylib + 10384) [0x1dfc2e890]

### Image records for unresolved heaviest-stack UUIDs

L203:            0x100a8c000 -                ???  ???                            <444F5041-332E-302E-3900-AE6387A9FA9A>
L204:            0x100d3c000 -                ???  ???                            <679D290B-EF8D-36CB-B69B-24B50C08264B>
L246:            0x102234000 -                ???  ???                    <444F5041-332E-302E-3900-AE6387A9FA9A>

## Crash-1-CarPlay.diskwrites_resource-2026-11-02-140101 3.ips

L1: {"app_name":"CarPlay","timestamp":"2026-11-02 14:01:01.00 +0700","app_version":"1.0","slice_uuid":"B2E3FF82-BC1F-3E2C-916D-A11FCB4C58E4","build_version":"1","bundleID":"com.apple.CarPlayApp","duration_ms":"21689728","share_with_app_devs":0,"is_first_party":1,"bug_type":"145","os_version":"iPhone OS 16.7.16 (20H392)","roots_installed":0,"incident_id":"FD031546-E865-4689-8A0B-D6034ECDBA23","name":"CarPlay"}
L2: Date/Time:        2026-11-02 07:59:23.997 +0700
L3: End time:         2026-11-02 14:00:53.725 +0700
L4: OS Version:       iPhone OS 16.7.16 (Build 20H392)
L9: Data Source:      Microstackshots
L12: Command:          CarPlay
L20: PID:              7331
L22: Event:            disk writes
L23: Action taken:     none
L24: Writes:           1073.75 MB of file backed memory dirtied over 21690 seconds (49.51 KB per second average), exceeding limit of 12.43 KB per second over 86400 seconds
L25: Writes limit:     1073.74 MB
L27: Writes caused:    1073.75 MB
L28: Writes duration:  21690s
L29: Duration:         21689.73s
L30: Duration Sampled: 21686.15s
L33: Hardware model:   iPhone10,2

### Heaviest-stack excerpt

L40: Heaviest stack for the target process:
L41:   87  ??? (<444F5041-332E-302E-3900-AE6387A9FA9A> + 99140) [0x103214344]
L42:   87  ??? (UIKitCore + 3608516) [0x1c54c3fc4]
L43:   86  ??? (UIKitCore + 3609420) [0x1c54c434c]
L44:   86  ??? (GraphicsServices + 6552) [0x1fb305998]
L45:   86  ??? (CoreFoundation + 498976) [0x1c3231d20]
L46:   86  ??? (CoreFoundation + 480840) [0x1c322d648]
L47:   86  ??? (CoreFoundation + 596396) [0x1c32499ac]
L48:   86  ??? (libdispatch.dylib + 285320) [0x1c9f49a88]
L49:   86  ??? (libdispatch.dylib + 286052) [0x1c9f49d64]
L50:   86  ??? (libdispatch.dylib + 317312) [0x1c9f51780]
L51:   86  ??? (libdispatch.dylib + 245064) [0x1c9f3fd48]
L52:   86  ??? (libdispatch.dylib + 411520) [0x1c9f68780]
L53:   55  ??? (<8DB3FC92-BF11-39B3-B81C-DCAD032275C5> + 22524) [0x1030d97fc]
L54:   55  ??? (Foundation + 768824) [0x1bd5fdb38]
L55:   54  ??? (Foundation + 422844) [0x1bd5a93bc]
L56:   54  ??? (Foundation + 305756) [0x1bd58ca5c]
L57:   54  ??? (Foundation + 632640) [0x1bd5dc740]
L58:   54  ??? (libsystem_kernel.dylib + 10384) [0x1fe9e2890]

### Image records for unresolved heaviest-stack UUIDs

L173:            0x1030d4000 -                ???  ???                          <8DB3FC92-BF11-39B3-B81C-DCAD032275C5>
L174:            0x1031fc000 -                ???  ???                          <444F5041-332E-302E-3900-AE6387A9FA9A>
L1157:            0x10bdb8000 -                ???  ???                        <444F5041-332E-302E-3900-AE6387A9FA9A>
L2374:            0x100d88000 -                ???  ???                            <444F5041-332E-302E-3900-AE6387A9FA9A>

## Crash-2-SpringBoard.diskwrites_resource-2026-11-02-104439 3.ips

L1: {"app_name":"SpringBoard","timestamp":"2026-11-02 10:44:39.00 +0700","app_version":"1.0","slice_uuid":"E1A4FE7D-29FF-3269-B3AB-50AED40C4495","build_version":"50","bundleID":"com.apple.springboard","duration_ms":"38659108","share_with_app_devs":0,"is_first_party":1,"bug_type":"145","os_version":"iPhone OS 16.7.16 (20H392)","roots_installed":0,"incident_id":"B77E9A72-E0B7-41DE-9599-E8C2BEE6B332","name":"SpringBoard"}
L2: Date/Time:        2026-11-02 00:00:14.687 +0700
L3: End time:         2026-11-02 10:44:33.795 +0700
L4: OS Version:       iPhone OS 16.7.16 (Build 20H392)
L9: Data Source:      Microstackshots
L12: Command:          SpringBoard
L20: PID:              7330
L22: Event:            disk writes
L23: Action taken:     none
L24: Writes:           1073.75 MB of file backed memory dirtied over 38659 seconds (27.77 KB per second average), exceeding limit of 12.43 KB per second over 86400 seconds
L25: Writes limit:     1073.74 MB
L27: Writes caused:    1073.75 MB
L28: Writes duration:  38659s
L29: Duration:         38659.11s
L30: Duration Sampled: 35738.12s
L33: Hardware model:   iPhone10,2

### Heaviest-stack excerpt

L40: Heaviest stack for the target process:
L41:   31  ??? (<444F5041-332E-302E-3900-AE6387A9FA9A> + 99140) [0x10421c344]
L42:   31  ??? (SpringBoard + 636392) [0x201c355e8]
L43:   31  ??? (UIKitCore + 3608516) [0x1c54c3fc4]
L44:   29  ??? (UIKitCore + 3609420) [0x1c54c434c]
L45:   29  ??? (GraphicsServices + 6552) [0x1fb305998]
L46:   29  ??? (CoreFoundation + 498976) [0x1c3231d20]
L47:   28  ??? (CoreFoundation + 480840) [0x1c322d648]
L48:   28  ??? (CoreFoundation + 596396) [0x1c32499ac]
L49:   28  ??? (libdispatch.dylib + 285320) [0x1c9f49a88]
L50:   23  ??? (libdispatch.dylib + 286052) [0x1c9f49d64]
L51:   23  ??? (libdispatch.dylib + 317312) [0x1c9f51780]
L52:   23  ??? (libdispatch.dylib + 245064) [0x1c9f3fd48]
L53:   23  ??? (libdispatch.dylib + 411520) [0x1c9f68780]
L54:   11  ??? (<65C1F971-5283-3544-ADA9-7089ED133751> + 31356) [0x1045aba7c]
L55:   11  ??? (Foundation + 768824) [0x1bd5fdb38]
L56:   10  ??? (Foundation + 422844) [0x1bd5a93bc]
L57:   10  ??? (Foundation + 305756) [0x1bd58ca5c]
L58:   10  ??? (Foundation + 632640) [0x1bd5dc740]
L59:   10  ??? (libsystem_kernel.dylib + 10384) [0x1fe9e2890]

### Image records for unresolved heaviest-stack UUIDs

L296:            0x104204000 -                ???  ???                            <444F5041-332E-302E-3900-AE6387A9FA9A>
L297:            0x1045a4000 -                ???  ???                            <65C1F971-5283-3544-ADA9-7089ED133751>
L751:            0x10bdb8000 -                ???  ???                        <444F5041-332E-302E-3900-AE6387A9FA9A>
L1541:            0x100d88000 -                ???  ???                            <444F5041-332E-302E-3900-AE6387A9FA9A>
L2055:            0x1031fc000 -                ???  ???                          <444F5041-332E-302E-3900-AE6387A9FA9A>
L2392:            0x102754000 -                ???  ???                     <444F5041-332E-302E-3900-AE6387A9FA9A>

