#!/bin/bash
set -euo pipefail

echo "=== Uninstalling Hebrew Voice for Claude Code ==="
echo ""

# 1. Stop and remove launch agent
PLIST="$HOME/Library/LaunchAgents/com.hebrew-voice.server.plist"
if [ -f "$PLIST" ]; then
  launchctl unload "$PLIST" 2>/dev/null || true
  rm -f "$PLIST"
  echo "[✓] Removed voice server launch agent"
else
  echo "[–] No launch agent found"
fi

# 2. Remove VOICE_STREAM_BASE_URL from settings.json
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  python3 - << 'PYEOF'
import json, os

path = os.path.expanduser("~/.claude/settings.json")
with open(path) as f:
    s = json.load(f)

changed = False
if "VOICE_STREAM_BASE_URL" in s.get("env", {}):
    del s["env"]["VOICE_STREAM_BASE_URL"]
    changed = True

if changed:
    with open(path, "w") as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
    print("[✓] Removed VOICE_STREAM_BASE_URL from settings.json")
else:
    print("[–] settings.json already clean")
PYEOF
else
  echo "[–] No settings.json found"
fi

# 3. Reset Speech Recognition permission for our app
tccutil reset SpeechRecognition com.hebrew-voice.transcribe 2>/dev/null && \
  echo "[✓] Reset Speech Recognition permission" || \
  echo "[–] No Speech Recognition permission to reset"

# 4. Kill any running voice server
pkill -f "voice-server.js" 2>/dev/null && \
  echo "[✓] Stopped voice server process" || \
  echo "[–] No voice server running"

echo ""
echo "=== Uninstall complete ==="
echo "Restart Claude Code for changes to take effect."
echo "/voice will use Anthropic's default server again."
