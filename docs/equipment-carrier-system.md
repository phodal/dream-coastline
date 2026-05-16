# Equipment Carrier System

## Status

Contract-only. This document records the equipment direction, data contract, and
balance envelope, but the runtime is not integrated yet.

Related contract files:

- `data/equipment_catalog.json`
- `scripts/core/equipment_catalog.gd`
- `tools/validate_equipment_catalog.py`

## Why It Is Not Traditional Equipment

Dream Coastline should not turn equipment into generic attack and defense
numbers. The existing story and runtime point to a different role:

- The core loop is exploration, glyph learning, problem solving, civilization
  building, and main story progression.
- Current combat already works as "write name, reveal the rule, then attack".
- Later scenes fight silence, deletion, missing names, broken coordinates, and
  lost observability, not ordinary monsters.
- Civilization metrics such as `literacy`, `engineering`, `stability`,
  `star_observation`, and `modern_observability` are more important than a
  personal damage curve.

The equipment system should therefore be a carrier system: objects carry glyphs,
names, backups, observability, and civilization support.

## Design Goals

1. Preserve the story identity. Equipment should read as writing media, anchors,
   dictionaries, beacons, or civilization modules.
2. Keep the numeric surface small. A single item normally changes a resource by
   `1`, a glyph mastery by `1`, or a civilization metric by `5-30`.
3. Make equipment useful without grinding. Acquisition should come from existing
   flags and scene beats, not random drops.
4. Keep support modules separate from manual equipment. Standard dictionaries,
   archive towers, statebook networks, and modern beacons are civilization
   infrastructure, not personal loot.
5. Avoid runtime mutation for now. The catalog is authored and validated, but no
   `GameSession` state or HUD behavior reads it yet.

## Slots

| Slot | Role | Equip Mode |
| --- | --- | --- |
| `pen_core` | The continuation pen and its later execution authority. | Fixed story slot. |
| `glyph_page` | A carried page, dictionary fragment, or formula that stabilizes glyph use. | Manual, later limited to 2. |
| `anchor` | Nameplate, personal anchor, or beacon shard that resists namelessness. | Manual, later limited to 1. |
| `tool` | Ink pouch, rule, measuring tool, or engineering implement. | Manual, later limited to 1. |
| `support_module` | Civilization support unlocked by flags and metrics. | Automatic, not manually equipped. |

## Numeric Envelope

The current RPG slice starts small: `ink=4`, `focus=3`, `stability=2/3`, and
chapter boss HP is usually `3-5`. Equipment must stay within that scale.

Recommended caps before full balance work:

- Personal resources: early chapter max `6`, late chapter max `8`.
- Glyph mastery: `0-3`.
- Manual item stat modifier: normally `+1`, rarely `+2`.
- Manual item glyph modifier: only `+1`.
- Combat modifier: at most `+1` to `lose_name_every`, lock duration, or recovery.
- Resistance modifier: `5-25`.
- Support module metric modifier: `+5` to `+30`, because it represents
  infrastructure rather than personal gear.

Avoid direct `attack` and `defense` stats. Damage should stay gated by name
locking, rule cracking, glyph preparation, and civilization backup.

## Item Families

### Continuation Core

The `continuation_pen` is the fixed core item. It does not add damage. It gives
permission to write, save, continue, and later execute the final Continue
formula.

### Glyph Carriers

Glyph carriers improve understanding or stability:

- `basic_dictionary_fragment`: early dictionary support for `名`, `门`, `火`,
  and `止`.
- `final_continue_formula`: final sequence carrier for `名`, `门`, `星`, `归`,
  and `续`.

These should mostly affect glyph mastery, UI decoding, and requirements for
advanced combinations.

### Anchors

Anchors resist deletion of identity:

- `broken_nameplate`: first anchor from the nameless beast fight.
- `modern_beacon`: late anchor from the parents' lab and modern signal layer.

They should affect name locking, namelessness resistance, and observability.

### Tools

Tools tune the small personal resource loop:

- `old_ink_pouch`: raises or restores ink.
- `stop_glyph_rule`: improves stability and reduces forgetting risk.
- `star_map_calibrator`: improves star-coordinate work.

### Civilization Modules

Support modules are automatically available once their story flags exist:

- `standard_dictionary`
- `public_archive_tower`
- `mobile_statebook_core`

They should become the answer to late-game deletion attacks: restored skill
names, recovered maps, recovered party names, and backed-up civilization state.

## Implementation Contract

The catalog lives in `data/equipment_catalog.json`.

Each item must define:

- `name`
- `scene_id`
- `slot`
- `kind`
- `acquisition.source_flags`
- `effects`
- `balance`

Effect buckets are intentionally narrow:

- `stat_modifiers`
- `glyph_mastery_modifiers`
- `metric_modifiers`
- `combat_modifiers`
- `resistances`
- `support_actions`
- `unlock_actions`
- `notes`

The standalone `EquipmentCatalog` GDScript loader can read and validate the
catalog, but nothing instantiates it yet. The Python validator is the current
acceptance gate.

## Deferred Runtime Work

When integration starts, do it in this order:

1. Add save-state fields: `inventory` and `equipped`.
2. Add a derived effect calculation path instead of mutating `player_stats`
   permanently.
3. Apply derived effects to `stat_value`, `glyph_mastery_value`, and selected
   combat checks.
4. Add a small HUD panel for carriers after the data is proven.
5. Add smoke coverage for equip, save/load, and one chapter-two combat effect.

## Non-goals

- No inventory UI in this contract slice.
- No `RustGameSession` behavior change yet.
- No automatic item grant during scene walkthroughs yet.
- No random loot, rarity economy, or upgrade materials.
- No direct attack/defense stat system.
