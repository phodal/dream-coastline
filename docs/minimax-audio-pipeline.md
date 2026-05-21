# MiniMax Audio Pipeline

This pipeline turns the first playable scenes into MiniMax-ready music cues and
voice samples without committing provider secrets or generated scratch state.

## Local Configuration

Do not commit API keys. Keep MiniMax credentials in `.env`:

```sh
MINIMAX_API_KEY="your-key"
MINIMAX_TTS_MODEL="speech-2.8-hd"
MINIMAX_MUSIC_MODEL="music-2.6-free"
```

`.env` is ignored by Git. Use `music-2.6-free` for the first sample pass unless
the account is confirmed for the paid `music-2.6` model.

## Contracts

- `data/audio_cues/00-prologue-lights-out.json` is cue-sheet only for the
  modern silent prologue.
- `data/audio_cues/01-illiterate.json` contains first-act music cues and the
  three first-pass voice samples, plus short gameplay `event_sounds` for the
  OpenRPG field loop.
- `data/action_voice_lines/<scene-id>.json` contains playable action voice
  queues for Nova/Dialogic-era field actions. These are generated only through
  the explicit `action-voice` type, never through `--type all`.
- `data/audio_generation_manifest.json` records generated assets, models,
  sanitized prompt/text summaries, output paths, and MiniMax trace IDs. It must
  never contain `MINIMAX_API_KEY`.

First-pass sample targets:

- `MUS-01-001`: first-act mud-road to refugee-camp BGM.
- `MUS-01-002`: chase and Xiali entrance BGM.
- `MUS-01-003`: abandoned station name-tutorial battle BGM.
- `DLG-01-SAMPLE-JZX`: Ji Zixuan, "......zhe shi na?"
- `DLG-01-SAMPLE-XY`: Xiaoyan, unreadable urgent child line.
- `DLG-01-SAMPLE-XL`: Xiali, cold first entrance line.
- `SFX-01-*`: local one-shot footsteps, paper/ink interaction, writing, and
  blade-hit effects generated through the MiniMax music API and trimmed into
  one-shots.

## Generate

Dry-run the selected jobs first:

```sh
node tools/minimax_audio_generate.mjs \
  --scene-id 01-illiterate \
  --dry-run \
  --limit-samples
```

Generate only the first BGM sample:

```sh
node tools/minimax_audio_generate.mjs \
  --type music \
  --scene-id 01-illiterate \
  --cue-id MUS-01-001
```

Generate a specific later BGM cue:

```sh
node tools/minimax_audio_generate.mjs \
  --type music \
  --scene-id 01-illiterate \
  --cue-id MUS-01-003
```

Generate the three voice samples:

```sh
node tools/minimax_audio_generate.mjs \
  --type voice \
  --scene-id 01-illiterate \
  --limit-samples
```

Music is written under `assets/audio/generated/music/<scene-id>/`. Voice samples
are written under `assets/audio/generated/voices/<scene-id>/`.

Generate a selected playable action line:

```sh
node tools/minimax_audio_generate.mjs \
  --type action-voice \
  --scene-id 00-prologue-lights-out \
  --cue-id AVL-00-001
```

Or generate one action queue:

```sh
node tools/minimax_audio_generate.mjs \
  --type action-voice \
  --scene-id 00-prologue-lights-out \
  --action-id street.inspect.window
```

Action voices are written under
`assets/audio/generated/action_voices/<scene-id>/`. On success the tool marks
the matching `data/action_voice_lines/<scene-id>.json` line as `generated`, so
`validate_action_voice_manifest.py` can enforce that generated lines have real
files. `--type action-voice` requires `--cue-id`, `--action-id`, or
`--limit-samples` to avoid accidental full-scene generation.

Short gameplay SFX use the MiniMax music endpoint, then the tool trims and
normalizes the result into game-ready one-shots:

```sh
node tools/minimax_audio_generate.mjs \
  --type sfx \
  --scene-id 01-illiterate
```

These are written under `assets/audio/generated/sfx/<scene-id>/` and recorded in
the manifest as MiniMax assets with ffmpeg post-processing metadata.

## Validation

Run these checks before committing cue or tooling changes:

```sh
python3 tools/validate_character_voice_profiles.py
python3 tools/validate_audio_cues.py
python3 tools/validate_action_voice_manifest.py
node --check tools/minimax_audio_generate.mjs
node tools/minimax_audio_generate.mjs --scene-id 01-illiterate --dry-run --limit-samples
node tools/minimax_audio_generate.mjs --type action-voice --scene-id 00-prologue-lights-out --cue-id AVL-00-001 --dry-run
```

If real samples were generated, also confirm that the generated files are
non-empty and that `git status --short` does not list `.env`.
