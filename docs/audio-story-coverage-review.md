# Audio Story Coverage Review

Last reviewed: 2026-06-18

## Scope

This pass checks the current playable story scenes against visual scene data, story review imagery, MiniMax audio cue sheets, generated audio assets, and voice-sample trigger text.

## Coverage Matrix

| Scene | Story locations | Visual locations | Generated music | Generated SFX | Voice samples in story text | Story review imagery |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `00-prologue-lights-out` | 6 | 6 | 3 / 3 | 5 / 5 | 0 / 0 | 1 chapter transition + 6 command panels |
| `01-illiterate` | 4 | 4 | 3 / 3 | 5 / 5 | 3 / 3 | 5 scene review images |
| `02-moqi-academy` | 4 | 4 | 4 / 4 | 9 / 9 | 3 / 3 | 2 scene review images |
| `03-dead-kingdom` | 5 | 5 | 5 / 5 | 7 / 7 | 3 / 3 | 3 scene review images |
| `04-continuation-institute` | 6 | 6 | 6 / 6 | 7 / 7 | 4 / 4 | 5 scene review images |
| `05-century-continuation` | 4 | 4 | 6 / 6 | 9 / 9 | 4 / 4 | 5 scene review images |
| `06-return-star-plan` | 6 | 6 | 6 / 6 | 9 / 9 | 4 / 4 | 5 scene review images |
| `07-lights-on-again` | 6 | 6 | 6 / 6 | 9 / 9 | 4 / 4 | 6 scene review images |

## Findings

- No missing generated audio asset was found for the current sample-generation scope. All `sample_generation: true` music and SFX entries have MP3 files and Godot import metadata.
- `python3 tools/run_automated_tests.py --only audio-mix-audit` passes for
  151 generated/loaded MP3 assets. It skips planned and `sample_generation:
  false` targets, and now records 0 long-form hot-peak warnings after
  mastering 36 music/ambience/stinger MP3 files with
  `tools/master_audio_hot_peaks.py --apply`.
- No missing voice trigger text was found after this pass. The existing voice sample set is 25 / 25 present in story text across scenes `01`-`07`.
- The prologue intentionally has no character voice sample. Its current audio language is environmental: exterior night ambience, stairwell/home ambience, blackout stinger, footstep, inspect, letter, and blackout one-shots.
- The prologue now has command-level review coverage in `data/chapter_illustrations.json` with six dedicated story-review panels under `assets/illustrations/story_review/00-prologue-lights-out/` for street, stairwell, home, living room, study, and bedroom. `tools/validate_story_review_panels.py` now requires at least three non-transition prologue review panels so this does not regress.
- The runtime now treats item interactions that grant a scene ending flag as a `success` event, so the prologue bedroom pen can use the blackout SFX instead of the generic inspect sound.
- `MUS-02-002` remains generated but is marked `runtime_enabled: false` so it can stay in the asset archive without being selected by runtime background-music rotation.

## Dialogue Status

The current pass fills earlier sample-line gaps by embedding the exact generated voice lines into story text:

- `03-dead-kingdom`: parent plan line now contains the full mother continuation.
- `04-continuation-institute`: Xiaoyan's first complete-name line is explicit.
- `05-century-continuation`: Wensu, Atang, and Jizi Xuan sample lines are explicit.
- `06-return-star-plan`: Jizi Xuan and parent truth sample lines are explicit.
- `07-lights-on-again`: Xiali's civilization-response line is explicit.

The remaining limitation is now represented as a separate data contract instead of being overloaded into `voice_samples`.

- Key-line VO remains in `data/audio_cues/<scene-id>.json#voice_samples`.
- Full playable-action VO planning now lives in `data/action_voice_lines/<scene-id>.json`.
- The manifests cover every `inspect`, `choice`, `glyph`, `build`, `encounter`, `combo`, and narrative combat identify/spell/resolve action.
- Current generated scope: 8 scene manifests, 187 playable actions, 28 generated voice lines, 194 planned voice lines.
- Selected planned lines can now be generated with `node tools/minimax_audio_generate.mjs --type action-voice --scene-id <scene-id> --cue-id <line-id>`.
- Validate with `python3 tools/validate_action_voice_manifest.py` or the `action-voice-lines` automated test step.

These action voice lines are production planning entries. `status: planned` means no final audio file is expected yet; only `status: generated` requires the referenced MP3 to exist.

## Action VO Production Batch

First produced batch: `2026-05-22-prologue-street-01`

| Line | Action | Duration | Mean volume | Max volume | Status |
| --- | --- | ---: | ---: | ---: | --- |
| `AVL-00-001` | `street.inspect.window` | 3.420s | -24.0 dB | -6.2 dB | generated |
| `AVL-00-002` | `street.inspect.window` | 5.364s | -23.9 dB | -8.2 dB | generated |
| `AVL-00-003` | `street.inspect.poster` | 6.912s | -23.8 dB | -5.9 dB | generated |

The batch was generated through `node tools/minimax_audio_generate.mjs --type action-voice --scene-id 00-prologue-lights-out --limit-samples 3`. It updated `data/action_voice_lines/00-prologue-lights-out.json`, `data/audio_generation_manifest.json`, and Godot-imported MP3 assets under `assets/audio/generated/action_voices/00-prologue-lights-out/`. Technical checks used `ffprobe`, `ffmpeg -af volumedetect`, and `python3 tools/validate_action_voice_manifest.py data/action_voice_lines/00-prologue-lights-out.json`.

Second produced batch: `2026-05-26-illiterate-mud-road-01`

| Line | Action | Duration | Mean volume | Max volume | Status |
| --- | --- | ---: | ---: | ---: | --- |
| `AVL-01-001` | `mud_road.inspect.phone` | 1.188s | -24.8 dB | -8.4 dB | generated |
| `AVL-01-002` | `mud_road.inspect.phone` | 9.036s | -23.3 dB | -6.0 dB | generated |
| `AVL-01-003` | `mud_road.inspect.sign` | 6.912s | -24.4 dB | -5.3 dB | generated |
| `AVL-01-004` | `mud_road.inspect.city` | 6.876s | -24.1 dB | -5.1 dB | generated |
| `AVL-01-005` | `mud_road.inspect.pen` | 7.668s | -23.5 dB | -7.2 dB | generated |

The batch was generated through `node tools/minimax_audio_generate.mjs --type action-voice --scene-id 01-illiterate --limit-samples 5`. It updated `data/action_voice_lines/01-illiterate.json`, `data/audio_generation_manifest.json`, and Godot-imported MP3 assets under `assets/audio/generated/action_voices/01-illiterate/`.

Third produced batch: `2026-05-26-moqi-academy-01`

| Line | Action | Duration | Mean volume | Max volume | Status |
| --- | --- | ---: | ---: | ---: | --- |
| `AVL-02-001` | `academy.inspect.wensu` | 8.676s | -24.0 dB | -5.4 dB | generated |
| `AVL-02-002` | `academy.inspect.baseline` | 13.212s | -23.9 dB | -6.1 dB | generated |
| `AVL-02-003` | `academy.inspect.name` | 5.832s | -23.8 dB | -6.5 dB | generated |
| `AVL-02-004` | `academy.inspect.door` | 9.144s | -24.1 dB | -5.6 dB | generated |
| `AVL-02-005` | `academy.inspect.fire` | 6.912s | -24.6 dB | -5.2 dB | generated |

The batch was generated through `node tools/minimax_audio_generate.mjs --type action-voice --scene-id 02-moqi-academy --limit-samples 5`. It updated `data/action_voice_lines/02-moqi-academy.json`, `data/audio_generation_manifest.json`, and Godot-imported MP3 assets under `assets/audio/generated/action_voices/02-moqi-academy/`.

Fourth produced batch: `2026-05-26-dead-kingdom-01`

| Line | Action | Duration | Mean volume | Max volume | Status |
| --- | --- | ---: | ---: | ---: | --- |
| `AVL-03-001` | `outer_city.inspect.order` | 7.128s | -23.7 dB | -6.0 dB | generated |
| `AVL-03-002` | `outer_city.inspect.market` | 9.576s | -23.8 dB | -5.9 dB | generated |
| `AVL-03-003` | `outer_city.inspect.poster` | 7.128s | -23.8 dB | -5.7 dB | generated |
| `AVL-03-004` | `library.inspect.records` | 9.612s | -23.6 dB | -6.7 dB | generated |
| `AVL-03-005` | `library.inspect.letters` | 9.576s | -23.4 dB | -6.4 dB | generated |

The batch was generated through `node tools/minimax_audio_generate.mjs --type action-voice --scene-id 03-dead-kingdom --limit-samples 5`. It updated `data/action_voice_lines/03-dead-kingdom.json`, `data/audio_generation_manifest.json`, and Godot-imported MP3 assets under `assets/audio/generated/action_voices/03-dead-kingdom/`.

Fifth produced batch: `2026-05-27-continuation-institute-01`

| Line | Action | Duration | Mean volume | Max volume | Status |
| --- | --- | ---: | ---: | ---: | --- |
| `AVL-04-001` | `institute.inspect.members` | 12.744s | -23.7 dB | -4.8 dB | generated |
| `AVL-04-002` | `institute.inspect.charter` | 10.800s | -23.6 dB | -4.7 dB | generated |
| `AVL-04-003` | `institute.inspect.noble_observer` | 11.160s | -23.2 dB | -4.3 dB | generated |
| `AVL-04-004` | `institute.build.institute` | 6.876s | -23.7 dB | -6.6 dB | generated |
| `AVL-04-005` | `institute.build.dictionary` | 6.876s | -23.3 dB | -5.9 dB | generated |

The batch was generated through `node tools/minimax_audio_generate.mjs --type action-voice --scene-id 04-continuation-institute --limit-samples 5`. It updated `data/action_voice_lines/04-continuation-institute.json`, `data/audio_generation_manifest.json`, and Godot-imported MP3 assets under `assets/audio/generated/action_voices/04-continuation-institute/`.

Sixth produced batch: `2026-05-27-century-continuation-01`

| Line | Action | Duration | Mean volume | Max volume | Status |
| --- | --- | ---: | ---: | ---: | --- |
| `AVL-05-001` | `industry.inspect.teachers` | 5.976s | -23.5 dB | -7.3 dB | generated |
| `AVL-05-002` | `industry.inspect.wensu_book` | 7.056s | -23.2 dB | -6.6 dB | generated |
| `AVL-05-003` | `industry.inspect.wensu_absence` | 2.664s | -25.1 dB | -8.5 dB | generated |
| `AVL-05-004` | `industry.inspect.wensu_absence` | 8.568s | -23.9 dB | -7.3 dB | generated |
| `AVL-05-005` | `industry.inspect.wensu_absence` | 2.520s | -25.9 dB | -10.0 dB | generated |

The batch was generated through `node tools/minimax_audio_generate.mjs --type action-voice --scene-id 05-century-continuation --limit-samples 5`. It updated `data/action_voice_lines/05-century-continuation.json`, `data/audio_generation_manifest.json`, and Godot-imported MP3 assets under `assets/audio/generated/action_voices/05-century-continuation/`.

## Prologue Audio Mix Notes

- `SFX-00-STEP-STREET` and `SFX-00-STEP-INTERIOR` were reduced by another `-6 dB` after `volumedetect`, because short footsteps still read too loud after loudnorm.
- Final checked levels for prologue SFX:
  - `SFX-00-STEP-STREET`: mean `-24.2 dB`, max `-14.8 dB`
  - `SFX-00-STEP-INTERIOR`: mean `-22.3 dB`, max `-14.9 dB`
  - `SFX-00-INSPECT-HOME`: mean `-26.4 dB`, max `-16.1 dB`
  - `SFX-00-INSPECT-LETTER`: mean `-41.3 dB`, max `-8.9 dB`
  - `SFX-00-BLACKOUT`: mean `-28.3 dB`, max `-7.8 dB`

## Next Useful Supplement

1. Generate a first playable-action VO batch with `--type action-voice`, then review pacing and loudness before marking broader batches as production-ready.
2. Record a fresh story-review movie pass after the first generated action-voice batch is approved.
