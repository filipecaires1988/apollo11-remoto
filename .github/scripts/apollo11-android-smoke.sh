#!/usr/bin/env bash
set -euo pipefail

apk="$1"
evidence="$2"
package=com.apollo11.remoto
component="$package/com.carriez.flutter_hbb.MainActivity"
mkdir -p "$evidence"

collect_evidence() {
    adb logcat -d -v threadtime > "$evidence/logcat.txt" || true
    adb shell dumpsys activity activities > "$evidence/activities.txt" || true
    adb exec-out screencap -p > "$evidence/home.png" || true
}
trap collect_evidence EXIT

adb wait-for-device
adb shell cmd uimode night no
adb shell input keyevent KEYCODE_WAKEUP
adb shell input keyevent KEYCODE_MENU
adb install -r "$apk" | tee "$evidence/install.txt"
adb logcat -c
adb shell am start -W -n "$component" | tee "$evidence/launch.txt"
if ! grep -q 'Status: ok' "$evidence/launch.txt"; then
    echo 'A atividade principal não abriu.' >&2
    exit 1
fi

# Allow startup to settle; the captured screen is reviewed separately for Flutter UI.
sleep 15
process_id="$(adb shell pidof "$package" | tr -d '\r')"
if [ -z "$process_id" ]; then
    echo 'O aplicativo encerrou durante a abertura.' >&2
    exit 1
fi
adb logcat --pid="$process_id" -d -v threadtime > "$evidence/app-logcat.txt"
if grep -E 'FATAL EXCEPTION|Fatal signal|UnsatisfiedLinkError|Unhandled Exception' "$evidence/app-logcat.txt"; then
    echo 'O aplicativo registrou uma falha durante a abertura.' >&2
    exit 1
fi
adb shell dumpsys activity activities > "$evidence/activities.txt"
if ! grep -E 'mResumedActivity|topResumedActivity' "$evidence/activities.txt" | grep -Fq "$component"; then
    echo 'A tela principal não permaneceu em primeiro plano.' >&2
    exit 1
fi
adb shell dumpsys package "$package" > "$evidence/package.txt"
adb shell getconf PAGE_SIZE > "$evidence/page-size.txt"
adb shell cmd uimode night > "$evidence/system-theme.txt"
