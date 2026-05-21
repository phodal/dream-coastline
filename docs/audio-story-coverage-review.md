# Audio Story Coverage Review

Last reviewed: 2026-05-18

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
- No missing voice trigger text was found after this pass. The existing voice sample set is 25 / 25 present in story text across scenes `01`-`07`.
- The prologue intentionally has no character voice sample. Its current audio language is environmental: exterior night ambience, stairwell/home ambience, blackout stinger, footstep, inspect, letter, and blackout one-shots.
- The prologue now has command-level review coverage in `data/chapter_illustrations.json` by reusing the six playable backdrops for street, stairwell, home, living room, study, and bedroom. `tools/validate_story_review_panels.py` now requires at least three non-transition prologue review panels so this does not regress.
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
- Current generated scope: 8 scene manifests, 187 playable actions, 199 planned voice lines.
- Validate with `python3 tools/validate_action_voice_manifest.py` or the `action-voice-lines` automated test step.

These action voice lines are production planning entries. `status: planned` means no final audio file is expected yet; only `status: generated` requires the referenced MP3 to exist.

## Prologue Audio Mix Notes

- `SFX-00-STEP-STREET` and `SFX-00-STEP-INTERIOR` were reduced by another `-6 dB` after `volumedetect`, because short footsteps still read too loud after loudnorm.
- Final checked levels for prologue SFX:
  - `SFX-00-STEP-STREET`: mean `-24.2 dB`, max `-14.8 dB`
  - `SFX-00-STEP-INTERIOR`: mean `-22.3 dB`, max `-14.9 dB`
  - `SFX-00-INSPECT-HOME`: mean `-26.4 dB`, max `-16.1 dB`
  - `SFX-00-INSPECT-LETTER`: mean `-41.3 dB`, max `-8.9 dB`
  - `SFX-00-BLACKOUT`: mean `-28.3 dB`, max `-7.8 dB`

## Next Useful Supplement

1. Generate selected `data/action_voice_lines` entries into `assets/audio/generated/action_voices/<scene-id>/` and mark only completed lines as `generated`.
2. Replace the prologue's reused playable backdrops with dedicated `assets/illustrations/story_review/00-prologue-lights-out/*` storyboard panels if the review UI needs a distinct storyboard style.
