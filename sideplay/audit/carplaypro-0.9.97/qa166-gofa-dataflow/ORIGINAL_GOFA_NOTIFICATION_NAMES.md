# Original GOFA source event notification names — byte-accurate static trace

Original function 0x3ce1c registers observers with the
**proven** `addObserverForName:object:queue:usingBlock:` selector,
using array object 0x64568 and fixed CFString at 0x63968.
The original callback block target addresses 0x3cfb4 (alert) and
0x3d468 (speed) were verified from chained-fixup bytes.
This does NOT determine the event payload schema or confirm device delivery.

## Decoded static array
- array words: `['0x802000000000014b', '0x2', '0x100000000640f8']`
- candidate count: `2`
- candidate element-pointer array: `0x640f8`
- member 0: `notificationNextBoard` at `0x5e488`
- member 1: `notificationOtherBoard` at `0x5e4c8`

## Separate original Speed notification subscription
- `0x63968`: `notificationSpeedBoard`

## Functionality boundary
The original app may generate these notifications only while GOFA/route
is active. Neither a logged string nor an original notification means
DuoFace has live traffic alerts, camera distances, or next-turn instructions.
