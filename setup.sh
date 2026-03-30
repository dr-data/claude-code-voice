#!/bin/bash
set -euo pipefail

# Hebrew Voice for Claude Code (macOS)
# No binary patching — uses VOICE_STREAM_BASE_URL to redirect to local Apple STT.

INSTALL_DIR="$HOME/.local/share/hebrew-voice"

# If running via curl|bash, clone the repo first
if [ ! -f "scripts/voice-server.js" ]; then
  echo "Downloading hebrew-voice..."
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 https://github.com/eladcandroid/claude-code-hebrew-voice.git "$INSTALL_DIR" 2>/dev/null
  cd "$INSTALL_DIR"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS="$SCRIPT_DIR/scripts"

echo "=== Hebrew Voice for Claude Code ==="
echo ""

# Check requirements
for cmd in bun swiftc codesign; do
  if ! command -v $cmd &>/dev/null; then
    echo "ERROR: $cmd not found."
    [ "$cmd" = "bun" ] && echo "  Install: brew install bun"
    [ "$cmd" = "swiftc" ] && echo "  Install: xcode-select --install"
    exit 1
  fi
done

# 1. Build the Apple STT app
echo "[1/2] Building Apple STT app..."
mkdir -p "$SCRIPTS/Transcribe.app/Contents/MacOS"

swiftc -O -o "$SCRIPTS/Transcribe.app/Contents/MacOS/transcribe" \
  "$SCRIPTS/transcribe.swift" \
  -framework Speech -framework Foundation -framework AppKit 2>/dev/null

cat > "$SCRIPTS/Transcribe.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleIdentifier</key><string>com.hebrew-voice.transcribe</string>
    <key>CFBundleName</key><string>Transcribe</string>
    <key>CFBundleExecutable</key><string>transcribe</string>
    <key>CFBundleVersion</key><string>1.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>Hebrew voice transcription for Claude Code</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Audio input for speech recognition</string>
</dict></plist>
EOF

cat > "$SCRIPTS/entitlements.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>com.apple.security.device.audio-input</key><true/>
</dict></plist>
EOF

codesign --force --sign - --entitlements "$SCRIPTS/entitlements.plist" \
  "$SCRIPTS/Transcribe.app" 2>/dev/null

echo "  Built and signed Transcribe.app"

# 2. Configure settings + install launch agent
echo "[2/2] Configuring..."

SETTINGS="$HOME/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  mkdir -p "$HOME/.claude"
  echo '{}' > "$SETTINGS"
fi

python3 - << 'PYEOF'
import json, os

path = os.path.expanduser("~/.claude/settings.json")
with open(path) as f:
    s = json.load(f)

s.setdefault("env", {})["VOICE_STREAM_BASE_URL"] = "ws://127.0.0.1:19876"

with open(path, "w") as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
print("  Updated settings.json")
PYEOF

# Install launch agent
PLIST="$HOME/Library/LaunchAgents/com.hebrew-voice.server.plist"
launchctl unload "$PLIST" 2>/dev/null || true
mkdir -p "$HOME/Library/LaunchAgents"

BUN_PATH="$(which bun)"
cat > "$PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>Label</key><string>com.hebrew-voice.server</string>
    <key>ProgramArguments</key><array>
        <string>$BUN_PATH</string>
        <string>run</string>
        <string>$SCRIPTS/voice-server.js</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>/tmp/hebrew-voice-server.log</string>
    <key>StandardErrorPath</key><string>/tmp/hebrew-voice-server.log</string>
</dict></plist>
EOF

launchctl load "$PLIST"
echo "  Voice server installed and started"

echo ""
echo "=== Done ==="
echo ""
echo "No binary patching. Survives Claude Code updates automatically."
echo "Restart Claude Code, enable /voice, and speak Hebrew."
echo ""
echo "First run: macOS will ask for Speech Recognition permission — click Allow."
echo ""
echo "To uninstall: $SCRIPT_DIR/uninstall.sh"
