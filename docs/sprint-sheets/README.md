# Sprint Sheets

Sprint Sheets are implementation contracts generated from scene evidence, playable JSON, visual JSON, and runtime constraints.

The important rule is: do not ask AI to make something "more RPG" without telling it what the source scene must mean on screen. Every generated sheet must bind visual decisions to `five/scene/*.md` and must include screenshot states that can prove the implementation is aligned.

## AI Generation Workflow

Build an AI prompt from a scene ID:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate
```

Optionally write the prompt to a temporary file:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --output /tmp/01-sprint-prompt.md
```

Send that prompt to Codex, DeepSeek, or another model. The model output is only acceptable if it includes:

- `Source Scene Contract`: scene evidence mapped to screen meaning.
- `Visual Direction`: `Must Read As` and `Must Not Read As`.
- `UI Contract`: named states and data owners.
- `Implementation Tasks`: concrete file-level work.
- `Screenshot Review Gate`: title, first playable screen, first interaction, scene-specific state, menu overlay, mismatch check.
- `Acceptance`: Godot load, scene smoke, menu smoke or render smoke, and manual playtest.

## Existing Sheets

- `rpg-ui-style-pass.md`: scene-aligned pass for the prologue modern-silence RPG UI.
- `01-illiterate.md`: first act survival, illiteracy, and first glyph-learning pass.
- `02-moqi-academy.md`: academy, literacy engineering, and first repair pass.
- `03-dead-kingdom.md`: dead capital investigation and anti-restoration pass.
- `04-continuation-institute.md`: civilization-building and public knowledge pass.
- `05-century-continuation.md`: long-timescale civilization growth pass.
- `06-return-star-plan.md`: cross-world mobilization and silence-probe pass.
- `07-lights-on-again.md`: modern return, civilization merge, and final silence protocol pass.

## Review Rule

A generated Sprint Sheet is not ready just because it follows the headings. It must be reviewed against the source scene, the current visual props, and at least one screenshot or planned screenshot state.
