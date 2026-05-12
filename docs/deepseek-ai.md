# DeepSeek AI Integration

This project uses a lightweight Godot `HTTPRequest` client in `scripts/deepseek_client.gd`.

The shape follows the same pattern as `godot-copilot`: keep the Godot UI local, collect the current editor/game context, and send a targeted request to an OpenAI-compatible chat-completions endpoint. DeepSeek works here because its API accepts OpenAI-style `POST /chat/completions` requests at `https://api.deepseek.com`.

## Configure

Do not commit API keys.

Preferred local shell setup:

```sh
export DEEPSEEK_API_KEY="your-key"
```

Alternative Godot-local setup:

```sh
cp deepseek.local.cfg.example deepseek.local.cfg
```

Then edit `deepseek.local.cfg`. The real file is ignored by Git.

## Current Game Hook

The playable scene adds an `AI 解读` button in the top bar. It sends the current scene title, source file, location description, metrics, and recent event log to DeepSeek, then appends a short Chinese design note to the in-game log.

This gives the project a first AI capability without coupling game logic to a specific UI. The same `DeepSeekClient` can later be reused for:

- NPC line drafting.
- scene beat suggestions.
- quest hint generation.
- design QA against the `five/scene` source documents.

## Defaults

- endpoint: `https://api.deepseek.com/chat/completions`
- model: `deepseek-v4-flash`
- thinking: disabled
- max tokens: `420`

Use `deepseek-v4-pro` and `thinking_enabled=true` only for heavier design analysis, because it will be slower and more expensive.
