# Sprint Sheets

Sprint Sheets are implementation contracts generated from scene evidence, playable JSON, visual JSON, and runtime constraints.

The important rule is: do not ask AI to make something "more RPG" without telling it what the source scene must mean on screen. Every generated sheet must bind visual decisions to `five/scene/*.md` and must include screenshot states that can prove the implementation is aligned.

## AI Generation Workflow

Prefer a contract-first AI workflow:

1. Generate a `scene_sprint_map` JSON object from the scene and JSON data.
2. Validate and review the map, including stable IDs and Sprint Trace Map rows.
3. Turn the map into a Sprint Sheet or UI Implementation Brief.
4. For animation work, derive an `animation_sprint_map` from the selected
   `ANIM-*` row before generating assets.
5. Use the reviewed UI brief or Animation Sheet to build an implementation
   prompt for one named ID.
6. Review screenshots against the same map before accepting the implementation.

The map schema is documented in `scene-sprint-map-schema.md`.
The UI writing schema is documented in `ui-implementation-brief-schema.md`.
The animation map schema is documented in
`../animation-sheets/animation-sprint-map-schema.md`.

Build the intermediate map prompt:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode map --output /tmp/01-scene-map-prompt.md
```

After the AI returns JSON, validate it before converting it:

```sh
python3 tools/validate_scene_ai_contract.py \
  --scene-id 01-illiterate \
  --map /tmp/01-scene-map.json
```

Then build the final Sprint Sheet prompt from that map:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode sheet-from-map --map-input /tmp/01-scene-map.json
```

For implementation-facing UI work, build a UI brief prompt from the same map:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --mode ui-brief-from-map --map-input /tmp/01-scene-map.json
```

Validate the generated UI brief before implementation:

```sh
python3 tools/validate_scene_ai_contract.py \
  --scene-id 01-illiterate \
  --map /tmp/01-scene-map.json \
  --brief /tmp/01-ui-brief.md
```

Build a semi-automated implementation prompt from the reviewed map and brief:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode implementation-from-brief \
  --map-input /tmp/01-scene-map.json \
  --brief-input /tmp/01-ui-brief.md \
  --output /tmp/01-implementation-prompt.md
```

After implementation captures screenshots, build a screenshot-review prompt:

```sh
python3 tools/capture_scene_screenshots.py --scene 01-illiterate

python3 tools/build_sprint_sheet_prompt.py 01-illiterate \
  --mode screenshot-review-from-map \
  --map-input /tmp/01-scene-map.json \
  --screenshot-manifest artifacts/scene-screenshots/latest/manifest.json \
  --output /tmp/01-screenshot-review-prompt.md
```

Direct Sprint Sheet prompt generation remains available only when the mapping is already understood:

```sh
python3 tools/build_sprint_sheet_prompt.py 01-illiterate --output /tmp/01-sprint-prompt.md
```

Send that prompt to Codex, DeepSeek, or another model. The model output is only acceptable if it includes:

- `Source Scene Contract`: scene evidence mapped to screen meaning.
- `Visual Direction`: `Must Read As` and `Must Not Read As`.
- `UI Contract`: named states and data owners.
- `Implementation Tasks`: concrete file-level work.
- `Sprint Trace Map`: stable IDs mapped to runtime owners, screenshots, and gates.
- `Screenshot Review Gate`: title, first playable screen, first interaction, scene-specific state, menu overlay, mismatch check.
- `Acceptance`: Godot load, scene smoke, menu smoke or render smoke, and manual playtest.

## Existing Sheets

- `scene-sprint-map-schema.md`: intermediate AI mapping contract between scene evidence and Sprint Sheets.
- `ui-implementation-brief-schema.md`: file-level UI authoring contract generated from a reviewed map.
- `../animation-sheets/animation-sprint-map-schema.md`: asset-generation mapping contract for `ANIM-*` rows.
- `rpg-ui-style-pass.md`: scene-aligned pass for the prologue modern-silence RPG UI.
- `01-illiterate.md`: first act survival, illiteracy, and first glyph-learning pass.
- `01-illiterate-ui-brief.md`: file-level UI implementation brief for the first act.
- `02-moqi-academy.md`: academy, literacy engineering, and first repair pass.
- `03-dead-kingdom.md`: dead capital investigation and anti-restoration pass.
- `04-continuation-institute.md`: civilization-building and public knowledge pass.
- `05-century-continuation.md`: long-timescale civilization growth pass.
- `06-return-star-plan.md`: cross-world mobilization and silence-probe pass.
- `07-lights-on-again.md`: modern return, civilization merge, and final silence protocol pass.

## Review Rule

A generated Sprint Sheet is not ready just because it follows the headings. It must be reviewed against the source scene, the current visual props, and at least one screenshot or planned screenshot state.

For visual work, smoke tests are not enough. A change is accepted only after the screenshot review confirms the screen reads as the correct era, place, object semantics, and emotional state from the source scene.
