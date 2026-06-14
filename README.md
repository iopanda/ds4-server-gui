# ds4-server-gui

A macOS menu bar application that embeds `ds4-server` and provides an OpenAI / Anthropic compatible local LLM API.

## Features

- Lives in the menu bar — no Dock icon
- Embeds `ds4-server` in-process and manages its lifecycle
- On first launch (or if the model file is missing / fails to load), prompts the user to select a model file
- Real-time log window
- Settings UI: port, context size, KV cache, CORS, GPU power, etc.

## API Endpoints

The server listens on `http://127.0.0.1:8000` by default:

- `GET  /v1/models`
- `POST /v1/chat/completions` (OpenAI compatible)
- `POST /v1/messages` (Anthropic compatible)
- `POST /v1/responses` (Responses API)

## Build

```bash
cd DS4MacOS
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project DS4.xcodeproj -scheme DS4 -configuration Release \
  -derivedDataPath ./build build
```

The built app will be at:

```
DS4MacOS/build/Build/Products/Release/ds4-server-gui.app
```

## Usage

Launch `ds4-server-gui.app`. On first launch you will be prompted to select a `.gguf` model file.

Once a model is selected the server starts automatically. You can also configure the server via **Settings…** in the menu bar icon.

### Use with Claude Code

```sh
#!/bin/sh
unset ANTHROPIC_API_KEY
export ANTHROPIC_BASE_URL="http://127.0.0.1:8000"
export ANTHROPIC_AUTH_TOKEN="ds4-local"
export ANTHROPIC_MODEL="deepseek-v4-flash"
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-flash"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
exec "$HOME/.local/bin/claude" "$@"
```

## Requirements

- macOS 13.5+, Apple Silicon
- A DeepSeek V4 Flash GGUF model file (e.g. from [antirez/deepseek-v4-gguf](https://huggingface.co/antirez/deepseek-v4-gguf))

## License

MIT
