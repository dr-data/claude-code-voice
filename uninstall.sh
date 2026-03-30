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
if [ -f "$SETTINGS" ] && grep -q VOICE_STREAM_BASE_URL "$SETTINGS"; then
  python3 - << 'PYEOF'
import json, os
path = os.path.expanduser("~/.claude/settings.json")
with open(path) as f:
    s = json.load(f)
s.get("env", {}).pop("VOICE_STREAM_BASE_URL", None)
with open(path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
print("[✓] Removed VOICE_STREAM_BASE_URL from settings.json")
PYEOF
else
  echo "[–] settings.json already clean"
fi

# 3. Reset Speech Recognition permission
tccutil reset SpeechRecognition com.hebrew-voice.transcribe 2>/dev/null && \
  echo "[✓] Reset Speech Recognition permission" || \
  echo "[–] No Speech Recognition permission to reset"

# 4. Kill any running voice server
pkill -f "voice-server.js" 2>/dev/null && \
  echo "[✓] Stopped voice server process" || \
  echo "[–] No voice server running"

# 5. Remove install directory (if installed via curl|bash)
INSTALL_DIR="$HOME/.local/share/hebrew-voice"
if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  echo "[✓] Removed $INSTALL_DIR"
fi

echo ""
echo "=== Uninstall complete ==="
echo "Restart Claude Code for changes to take effect."
