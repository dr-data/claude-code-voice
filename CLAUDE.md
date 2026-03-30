# Hebrew Voice Support for Claude Code

Adds Hebrew to Claude Code's `/voice` command using Apple's native on-device `SFSpeechRecognizer`. No binary patching, no API keys — survives Claude Code updates automatically.

## How it works

Claude Code's voice streams audio via WebSocket. The `VOICE_STREAM_BASE_URL` env var redirects it to a local server (`localhost:19876`) that transcribes Hebrew via Apple's `SFSpeechRecognizer` instead of Anthropic's server.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/eladcandroid/claude-code-hebrew-voice/main/setup.sh | bash
```

After setup, restart Claude Code. `/voice` (spacebar push-to-talk) transcribes Hebrew.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/eladcandroid/claude-code-hebrew-voice/main/uninstall.sh | bash
```
