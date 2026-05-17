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
  three first-pass voice samples.
- `data/audio_generation_manifest.json` records generated assets, models,
  sanitized prompt/text summaries, output paths, and MiniMax trace IDs. It must
  never contain `MINIMAX_API_KEY`.

First-pass sample targets:

- `MUS-01-001`: first-act mud-road to refugee-camp BGM.
- `DLG-01-SAMPLE-JZX`: Ji Zixuan, "......zhe shi na?"
- `DLG-01-SAMPLE-XY`: Xiaoyan, unreadable urgent child line.
- `DLG-01-SAMPLE-XL`: Xiali, cold first entrance line.

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

Generate the three voice samples:

```sh
node tools/minimax_audio_generate.mjs \
  --type voice \
  --scene-id 01-illiterate \
  --limit-samples
```

Music is written under `assets/audio/generated/music/<scene-id>/`. Voice samples
are written under `assets/audio/generated/voices/<scene-id>/`.

## Validation

Run these checks before committing cue or tooling changes:

```sh
python3 tools/validate_character_voice_profiles.py
python3 tools/validate_audio_cues.py
node --check tools/minimax_audio_generate.mjs
node tools/minimax_audio_generate.mjs --scene-id 01-illiterate --dry-run --limit-samples
```

If real samples were generated, also confirm that the generated files are
non-empty and that `git status --short` does not list `.env`.
