# Audio Story Coverage Review

Last reviewed: 2026-05-18

## Scope

This pass checks the current playable story scenes against visual scene data, story review imagery, MiniMax audio cue sheets, generated audio assets, and voice-sample trigger text.

## Coverage Matrix

| Scene | Story locations | Visual locations | Generated music | Generated SFX | Voice samples in story text | Story review imagery |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| `00-prologue-lights-out` | 6 | 6 | 3 / 3 | 5 / 5 | 0 / 0 | Chapter transition image only |
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
- The prologue still does not have multi-panel `assets/illustrations/story_review/00-prologue-lights-out/*` imagery. It is covered by the chapter transition image in `data/chapter_illustrations.json`. If the prologue needs the same storyboard-style review UI as later scenes, add 3-4 story review panels for street, stairwell, home/study, and bedroom blackout.
- The runtime now treats item interactions that grant a scene ending flag as a `success` event, so the prologue bedroom pen can use the blackout SFX instead of the generic inspect sound.
- `MUS-02-002` remains generated but is marked `runtime_enabled: false` so it can stay in the asset archive without being selected by runtime background-music rotation.

## Dialogue Status

The current pass fills earlier sample-line gaps by embedding the exact generated voice lines into story text:

- `03-dead-kingdom`: parent plan line now contains the full mother continuation.
- `04-continuation-institute`: Xiaoyan's first complete-name line is explicit.
- `05-century-continuation`: Wensu, Atang, and Jizi Xuan sample lines are explicit.
- `06-return-star-plan`: Jizi Xuan and parent truth sample lines are explicit.
- `07-lights-on-again`: Xiali's civilization-response line is explicit.

The remaining limitation is not a missing sample; it is scope. Current VO is key-line coverage, not full voiced dialogue for every inspect/build/combat action. A full-VO pass should add a separate per-action dialogue manifest and playback queue instead of overloading `voice_samples`.

## Prologue Audio Mix Notes

- `SFX-00-STEP-STREET` and `SFX-00-STEP-INTERIOR` were reduced by another `-6 dB` after `volumedetect`, because short footsteps still read too loud after loudnorm.
- Final checked levels for prologue SFX:
  - `SFX-00-STEP-STREET`: mean `-24.2 dB`, max `-14.8 dB`
  - `SFX-00-STEP-INTERIOR`: mean `-22.3 dB`, max `-14.9 dB`
  - `SFX-00-INSPECT-HOME`: mean `-26.4 dB`, max `-16.1 dB`
  - `SFX-00-INSPECT-LETTER`: mean `-41.3 dB`, max `-8.9 dB`
  - `SFX-00-BLACKOUT`: mean `-28.3 dB`, max `-7.8 dB`

## Next Useful Supplement

1. Add prologue story-review panels if the review UI should show more than the chapter transition image.
2. Split key-line VO and full action VO into separate data contracts before generating hundreds of lines.
3. Add a small runtime check that reports missing playable audio targets per scene before story review playback starts.
