# Character Visual Models

`data/character_visual_models.json` is the visual counterpart to
`data/character_voice_profiles.json` and
`data/character_development_profiles.json`. The development profile owns
personality, motivation, wounds, conflict style, relationship hooks, and scene
usage; this visual file turns those decisions into silhouette, palette, costume
state, and image-generation prompts. Together they keep Ji Zixuan, Xiali,
Wensu, Atang, and Xiaoyan from drifting between story-review illustrations.

## Role Slots

| Slot | Character | Function |
| --- | --- | --- |
| `male_lead_1` | 纪子轩 | Player viewpoint and modern-method bridge. |
| `male_lead_2` | 夏离 | Fallen prince, reformer, and civic guardian. |
| `female_lead_1` | 闻素 | Teacher and public-education root. |
| `female_lead_2` | 阿棠 | Craftsperson and engineering practice lead. |
| `guide_child` | 小砚 | First-act guide and emotional proof of education access. |

The slots are production labels, not romance labels. Xiaoyan is intentionally
tracked outside the numbered lead slots because the character is a child guide
and payoff anchor.

## Workflow

1. Update the model contract first: silhouette, palette, costume states,
   expression set, and `imagen_prompt`.
2. If the change affects personality, motivation, relationships, or scene
   function, update `data/character_development_profiles.json` first.
3. Validate it:

```sh
python3 tools/run_automated_tests.py --only character-development-profiles,character-voice-profiles,character-visual-models
```

4. Generate or replace one character sheet at a time under
   `assets/characters/main/<character_id>/`.
5. Import through Godot once after adding PNGs, then review screenshots or
   story-review recordings before using the character broadly in chapter art.

## Asset Targets

Each character reserves three future image outputs:

- `model_sheet.png`: full model sheet, expression row, and key pose.
- `portrait.png`: dialogue or menu portrait.
- `story_review_cutout.png`: transparent or easy-to-cut character layer for
  manga-style story review panels.

The validator only checks the contract and target paths. It does not require the
PNG files to exist yet, so the team can review and refine the model before
spending generation time.
