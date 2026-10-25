#!/bin/sh
# DuoFace .62 read-only touch QA: record five labelled gesture groups and existing logs.
# NO tweak changes, preference writes, SpringBoard restart, or private API calls.
set -u
PATH="/var/jb/usr/bin:/var/jb/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PATH

SOURCE_DIR=${DF_QA_LOG_DIR:-/var/mobile/Library/Logs}
OUTPUT_BASE=${DF_QA_OUTPUT_DIR:-/var/mobile/Library/Logs/DuoFaceQA62}
DEEP="$SOURCE_DIR/DuoFaceDeepTrace.log"
TOUCH="$SOURCE_DIR/DuoFaceTouchOwner.log"
PACKAGE=com.duoface.jb.embedded

fail() { printf '\nLOI: %s\n' "$1" >&2; exit 1; }
command -v awk >/dev/null 2>&1 || fail 'Thieu awk; khong the doc log.'
command -v date >/dev/null 2>&1 || fail 'Thieu date.'

VERSION=unknown
if command -v dpkg-query >/dev/null 2>&1; then
  VERSION=$(dpkg-query -W -f='${Version}' "$PACKAGE" 2>/dev/null || printf 'unknown')
elif command -v dpkg >/dev/null 2>&1; then
  VERSION=$(dpkg -s "$PACKAGE" 2>/dev/null | awk '/^Version: / {print $2; exit}')
fi

if [ "${DF_QA_TEST_MODE:-0}" != 1 ]; then
  case "$VERSION" in
    *0.0.62\~rawgrip1*) : ;;
    *) fail "Ban dang cai khong xac nhan la 0.0.62~rawgrip1 (thuc te: $VERSION). Dung de tranh test sai ban." ;;
  esac
fi
[ -f "$DEEP" ] || fail "Khong tim thay $DEEP. Can kiem tra tweak da chay va tao log." 

mkdir -p "$OUTPUT_BASE" || fail "Khong tao duoc folder $OUTPUT_BASE"
STAMP=$(date -u '+%Y%m%dT%H%M%SZ')
SESSION="DuoFaceQA62_${STAMP}_$$"
DIR="$OUTPUT_BASE/$SESSION"
mkdir "$DIR" || fail "Khong tao duoc folder $DIR"

NOW=$(date +%s)
BASE_TOUCH=0
if [ -f "$TOUCH" ]; then
  BASE_TOUCH=$(wc -c < "$TOUCH" | tr -d '[:space:]')
fi
printf 'Session=%s\nPackage=%s\nInstalledVersion=%s\nDeviceStartEpoch=%s\nDeepTrace=%s\nTouchOwner=%s\nReadOnly=YES\n' \
  "$SESSION" "$PACKAGE" "$VERSION" "$NOW" "$DEEP" "$TOUCH" > "$DIR/manifest.txt"
printf 'group\tstart_epoch\tend_epoch\tobserved_success_of_3\n' > "$DIR/groups.tsv"

printf '\nDUOFACE TOUCH QA .62 -- KHONG SUA TWEAK\n'
printf 'Phien: %s\nPhien ban da kiem tra: %s\n' "$SESSION" "$VERSION"
printf 'Chi thu khi XE DO, CarPlay dang chia 2 o, logo hien, menu/popup da dong, startup ket thuc.\n'
printf 'Moi nhom 3 lan. Ket thuc nhom nhan Enter trong NewTerm, sau do nhap so lan THANH CONG (0-3).\n'
printf 'Khong can thay doi setting, go cai lai hoac respring.\n'

run_group() {
  GROUP="$1"; INSTRUCTION="$2"
  printf '\n[%s] %s\n' "$GROUP" "$INSTRUCTION"
  printf 'Nhan Enter de BAT DAU nhom... '
  IFS= read -r _unused || fail 'Khong nhan duoc nhan Enter.'
  BEGIN=$(date +%s)
  printf 'THUC HIEN 3 LAN. Nhan Enter ngay sau lan thu 3... '
  IFS= read -r _unused || fail 'Khong nhan duoc nhan Enter ket thuc.'
  END=$(date +%s)
  printf 'Bao nhieu lan thanh cong (0/1/2/3)? '
  IFS= read -r SUCCESS || fail 'Khong nhan duoc ket qua.'
  case "$SUCCESS" in 0|1|2|3) : ;; *) SUCCESS='?' ;; esac
  printf '%s\t%s\t%s\t%s\n' "$GROUP" "$BEGIN" "$END" "$SUCCESS" >> "$DIR/groups.tsv"
}

run_group 'hold_still' 'Cham TAM logo, GIU >3.5 giay, SAU DO keo doc thanh chia 1-2cm roi nha; 3 lan.'
run_group 'hold_jitter' 'Cham TAM, rung nhe ngang roi ve tam, tiep tuc GIU >3.5 giay, SAU DO keo doc; 3 lan.'
run_group 'ratio_immediate' 'Cham logo, keo VUONG GOC thanh chia de doi ty le NGAY; 3 lan.'
run_group 'ratio_delayed' 'Cham logo, cho 0.8-1 giay, roi keo VUONG GOC de doi ty le; 3 lan.'
run_group 'swap_tap' 'Cham NHANH logo (duoi 1 giay), xem 2 o co doi trai-phai; 3 lan.'

FINAL=$(date +%s)
printf 'DeviceEndEpoch=%s\n' "$FINAL" >> "$DIR/manifest.txt"

# DeepTrace rotates at 2MiB. Include only our chrome and logo-control events in test time window.
# This intentionally omits unrelated app content and any full system log.
: > "$DIR/deeptrace-labelled.log"
for FILE in "$DEEP.previous" "$DEEP"; do
  if [ -f "$FILE" ]; then
    awk -v begin="$NOW" -v end="$FINAL" '
      match($0, /utc=[0-9]+[.][0-9]+/) {
        t=substr($0,RSTART+4,RLENGTH-4)+0;
        if(t >= begin && t <= end+1 && ($0 ~ /area=logo-control / || $0 ~ /area=chrome /))print;
      }
    ' "$FILE" >> "$DIR/deeptrace-labelled.log"
  fi
done

# TouchOwner has no timestamps. Preserve only appended data during test if file was not truncated.
: > "$DIR/touchowner-new.log"
if [ -f "$TOUCH" ]; then
  AFTER_TOUCH=$(wc -c < "$TOUCH" | tr -d '[:space:]')
  if [ "$AFTER_TOUCH" -ge "$BASE_TOUCH" ]; then
    tail -c "+$((BASE_TOUCH+1))" "$TOUCH" > "$DIR/touchowner-new.log" 2>/dev/null || \
      printf 'TouchOwner tail not supported; use DeepTrace only.\n' >> "$DIR/manifest.txt"
  else
    printf 'TouchOwner log shrank / rotated: offset not reliable.\n' >> "$DIR/manifest.txt"
  fi
fi

awk -F '\t' 'NR>1{print $1"|"$2"|"$3"|"$4}' "$DIR/groups.tsv" | \
while IFS='|' read -r GROUP BEGIN END SUCCESS; do
  awk -v group="$GROUP" -v begin="$BEGIN" -v end="$END" -v observed="$SUCCESS" '
    BEGIN{raw=0;ended=0;cancelled=0;pending=0;hold=0;moved=0;ratio=0;timer_supp=0;swap=0;tracking=0}
    match($0, /utc=[0-9]+[.][0-9]+/) {
      t=substr($0,RSTART+4,RLENGTH-4)+0;
      if(t<begin || t>end+1)next;
      if(index($0,"area=logo-control raw-began")>0)raw++;
      if(index($0,"area=logo-control raw-ended")>0)ended++;
      if(index($0,"area=logo-control raw-cancelled")>0)cancelled++;
      if(index($0,"logo-native-longpress-3s-pending")>0)pending++;
      if(index($0,"logo-3s-hold-began-real-touch")>0)hold++;
      if(index($0,"logo-3s-moved-position")>0)moved++;
      if(index($0,"logo-quick-ratio-drag-began-restored-v056")>0)ratio++;
      if(index($0,"logo-3s-timer-suppressed")>0)timer_supp++;
      if(index($0,"swap-button")>0)swap++;
      if(index($0,"logo-tracking-ended")>0)tracking++;
    }
    END{printf "%s: observed=%s/3 raw=%d ended=%d cancelled=%d hold=%d moved=%d ratio=%d suppressed=%d swap=%d tracking=%d pending=%d\n", group,observed,raw,ended,cancelled,hold,moved,ratio,timer_supp,swap,tracking,pending}
  ' "$DIR/deeptrace-labelled.log" >> "$DIR/summary.txt"
done
if ! grep -F 'build=0.0.62~rawgrip1' "$DIR/deeptrace-labelled.log" >/dev/null 2>&1; then
  printf 'WARNING: No runtime .62 DeepTrace marker observed in test window; do not interpret zero counts as device failure.\n' >> "$DIR/summary.txt"
fi
printf '\nLOG COUNTS ARE BY GROUP ONLY, NOT PROOF OF EXACT PER-TOUCH CAUSALITY.\n' >> "$DIR/summary.txt"
printf 'If raw events are missing, check active installed build, startup, menu, focus and window hit-route before fixing timer.\n' >> "$DIR/summary.txt"

ARCHIVE="$OUTPUT_BASE/$SESSION.tar.gz"
if command -v tar >/dev/null 2>&1 && tar -czf "$ARCHIVE" -C "$OUTPUT_BASE" "$SESSION" 2>/dev/null; then
  printf '\nDA HOAN TAT. Goi log: %s\n' "$ARCHIVE"
else
  printf '\nDA HOAN TAT. Thu muc log: %s\n' "$DIR"
fi
cat "$DIR/summary.txt"
printf '\nChia se file .tar.gz (hoac folder QA) vao chat de GPT doc. Khong tu dong gui du lieu ra ngoai.\n'