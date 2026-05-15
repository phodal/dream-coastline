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

## Sprint Sheet Prompt Builder

Sprint Sheets should be generated from scene evidence rather than a generic UI request. Use the local prompt builder to package the source scene, story JSON, visual JSON, art direction, and Sprint Sheet architecture into one model-ready prompt:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode map --output /tmp/01-scene-map-prompt.md
```

Review the generated `scene_sprint_map` first. It should map source evidence to screen meaning, prop risks, screenshot states, and implementation tasks before asking a model to write a full Sprint Sheet.

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode sheet-from-map --map-input /tmp/01-scene-map.json --output /tmp/01-sheet-from-map-prompt.md
```

For UI implementation work, generate a UI brief prompt instead of a broad Sprint Sheet prompt:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode ui-brief-from-map --map-input /tmp/01-scene-map.json --output /tmp/01-ui-brief-prompt.md
```

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --output /tmp/01-sprint-prompt.md
```

Send either generated prompt to Codex, DeepSeek, or another model. Review the output against `docs/sprint-sheets/README.md` and `docs/sprint-sheets/scene-sprint-map-schema.md` before committing it.

## Defaults

- endpoint: `https://api.deepseek.com/chat/completions`
- model: `deepseek-v4-flash`
- thinking: disabled
- max tokens: `420`

Use `deepseek-v4-pro` and `thinking_enabled=true` only for heavier design analysis, because it will be slower and more expensive.
