# Hebrew Voice for Claude Code (macOS)

Adds native on-device speech-to-text to Claude Code's `/voice` command using Apple's `SFSpeechRecognizer`. No API keys, no cloud services, no binary patching — runs entirely on your Mac and survives Claude Code updates.

## Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/eladcandroid/claude-code-hebrew-voice/main/setup.sh | bash
```

## Requirements

- macOS (Apple Silicon or Intel)
- Xcode Command Line Tools (`xcode-select --install`)
- Claude Code with `/voice` support

## Usage

After install, restart Claude Code:

1. `/voice` to enable voice mode
2. Hold **Space** to record
3. Speak
4. Release — transcript appears

> **First run:** macOS will prompt for Speech Recognition permission — click **Allow**.

## Switching languages

Type `/config` in Claude Code to change the language. The voice server picks it up immediately — no restart needed.

### Supported languages

| Language | `/config` value |
|----------|----------------|
| English | `en` (default) |
| Hebrew | `he` |
| Spanish | `es` |
| French | `fr` |
| German | `de` |
| Japanese | `ja` |
| Korean | `ko` |
| Portuguese | `pt` |
| Italian | `it` |
| Russian | `ru` |
| Chinese | `zh` |
| Arabic | `ar` |
| Hindi | `hi` |
| Turkish | `tr` |
| Dutch | `nl` |
| Polish | `pl` |
| Ukrainian | `uk` |
| Greek | `el` |
| Czech | `cs` |
| Danish | `da` |
| Swedish | `sv` |
| Norwegian | `no` |

Any language supported by Apple's `SFSpeechRecognizer` works — these are just the ones with built-in mappings.

## How it works

Claude Code has an undocumented `VOICE_STREAM_BASE_URL` env var that redirects its voice WebSocket. This project runs a native macOS app on `localhost:19876` that receives the audio stream and transcribes it using Apple's on-device `SFSpeechRecognizer`.

```
┌─────────────┐    audio    ┌───────────────────────────────┐
│ Claude Code  │───chunks──▶│ HebrewVoice.app               │
│ /voice + ␣   │◀──text────│ WebSocket server + Apple STT  │
└─────────────┘             └───────────────────────────────┘
```

Everything is a single Swift binary — WebSocket server and speech recognition combined. No external runtimes needed.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/eladcandroid/claude-code-hebrew-voice/main/uninstall.sh | bash
```

## Project structure

```
├── setup.sh              # One-command install
├── uninstall.sh           # Full uninstall
└── scripts/
    └── server.swift       # WebSocket server + Apple STT (single file)
```
