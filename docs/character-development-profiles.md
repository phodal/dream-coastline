# Character Development Profiles

`data/character_development_profiles.json` is the durable character bible for
story, storyboard, illustration, dialogue, and implementation work. It records
each character's personality core, motivation, wound, conflict style, growth
direction, relationship hooks, dialogue guardrails, and scene usage notes.

Use it before expanding any chapter or generating new story-review panels. It
answers what the character wants, what they fear, how they create conflict, and
what they must not become.

## Contract Stack

| File | Use |
| --- | --- |
| `data/character_development_profiles.json` | Personality, motivation, relationships, arc guardrails, scene usage. |
| `data/character_voice_profiles.json` | Dialogue shape, lexicon, performance notes, TTS prompt direction. |
| `data/character_visual_models.json` | Silhouette, palette, costume states, model-sheet prompts, asset targets. |

The development profile is intentionally upstream of the other two contracts.
When a new chapter needs an emotional beat, read the development profile first;
when the beat needs spoken lines, read the voice profile; when the beat needs
visual assets, read the visual model.

## Current Coverage

| Character | Development Function |
| --- | --- |
| 纪子轩 | Player viewpoint; modern method bridge; learns through failure, records, and verification. |
| 夏离 | Fallen prince; pressure between old royal legitimacy and civic guardianship. |
| 小砚 | First-act child guide; proof that education access is emotional, not abstract. |
| 闻素 | Exiled teacher; public education root; turns danger into learnable steps. |
| 阿棠 | Workshop engineer; forces ideas into materials, failures, and tests. |
| 陆峥 | Old military order; creates credible resistance to open education. |
| 司衡 | Human face of text-permission monopoly; makes the risk argument coherent. |
| 纪子轩父亲 | Modern-side signal and coordinate bridge; love expressed through records. |
| 纪子轩母亲 | Language and Continue bridge; leaves texts that let Zixuan keep moving. |
| 无名兽 | First-act name-loss embodiment; should feel like deleted identity, not a generic monster. |
| 熄星者 | Final system threat; protocol-like silence and coordinate deletion, not villain emotion. |

## Validation

Run this after changing any character contract:

```sh
python3 tools/run_automated_tests.py --only character-development-profiles,character-voice-profiles,character-visual-models
```

The development validator also checks that every voice-profile character has a
matching development profile. This keeps newly added characters from silently
missing personality and relationship notes.
