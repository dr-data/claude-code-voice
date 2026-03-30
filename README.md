# Hebrew Voice for Claude Code (macOS)

Adds Hebrew speech-to-text to Claude Code's `/voice` command using Apple's native on-device `SFSpeechRecognizer`. No API keys, no cloud services, no binary patching — runs entirely on your Mac and survives Claude Code updates.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/eladcandroid/claude-code-hebrew-voice/main/setup.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/eladcandroid/claude-code-hebrew-voice.git
cd claude-code-hebrew-voice
./setup.sh
```

## How it works

Claude Code has an undocumented `VOICE_STREAM_BASE_URL` env var that redirects its voice WebSocket to a custom server. This project runs a local server on `localhost:19876` that receives Claude Code's audio stream and transcribes it using Apple's `SFSpeechRecognizer` for Hebrew.

```
┌─────────────┐    audio    ┌──────────────┐   WAV file   ┌─────────────────┐
│ Claude Code  │───chunks──▶│ voice-server │────────────▶│ Transcribe.app  │
│ /voice + ␣   │◀──text────│ (localhost)   │◀───text────│ (Apple STT)     │
└─────────────┘             └──────────────┘              └─────────────────┘
```

## Requirements

- macOS (Apple Silicon or Intel)
- [Bun](https://bun.sh) runtime (`brew install bun`)
- Xcode Command Line Tools (`xcode-select --install`)
- Claude Code with `/voice` support

## Usage

After install, restart Claude Code:

1. `/voice` to enable voice mode
2. Hold **Space** to record
3. Speak Hebrew
4. Release — transcript appears

> **First run:** macOS will prompt for Speech Recognition permission — click **Allow**.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/eladcandroid/claude-code-hebrew-voice/main/uninstall.sh | bash
```

Or if cloned locally:

```bash
./uninstall.sh
```

## Project structure

```
├── setup.sh                    # One-command install
├── uninstall.sh                # Full uninstall
├── scripts/
│   ├── voice-server.js         # Local WebSocket voice server (Bun)
│   ├── transcribe.swift        # Apple SFSpeechRecognizer wrapper
│   ├── entitlements.plist      # macOS entitlements for audio access
│   └── Transcribe.app/         # Signed app bundle (built by setup.sh)
├── CLAUDE.md
└── README.md
```
