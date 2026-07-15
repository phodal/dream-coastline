# Nova Full-Route Manual QA

This checklist is generated from `data/story_scenes/*.json` by
`tools/build_nova_manual_route_checklist.py`. Manual progress is sourced from
`docs/nova-full-route-manual-progress.json`. It is a live-window QA aid for
issue #6, not a replacement for headless smoke tests.

Current entrypoint: `res://src/nova/main.tscn`

Manual QA progress:

- 2026-06-23 partial live-window refresh covered title entry, first action Dialogic/text playback, pause/resume, pause save, return-to-title, and keyboard continue from title. It also completed the prologue live route to `01-illiterate/mud_road`.
- 2026-07-14 resumed from an isolated Nova QA save and observed `01-illiterate` steps 1-18 through the live Godot window. The pass found and fixed final-Return action-menu input leakage, then confirmed the last Xiali line returns to the menu without reopening the first action. Steps 19-24 remain unobserved; Xiali still uses a full character reference sheet in dialogue, and Dialogic reports invalid `default` portraits for Xiaoyan.
- 2026-07-15 used an isolated Nova save to replay Xiaoyan and Xiali dialogue in the live Godot window. Dedicated portraits now render without the Xiaoyan invalid-portrait warning or Xiali model-sheet panels; this did not add any command-row observations, and first-act steps 19-24 remain unobserved.
- 2026-07-15 resumed an isolated post-identify combat save and observed `01-illiterate` steps 19-24 in the live Godot window. The route covered name-lock loss and recovery, supply restoration, victory, broken-nameplate payoff, and automatic transition to `02-moqi-academy`; first-act pause/save/return remains a separate unobserved acceptance item.

Recommended setup:

To update checked manual progress, edit
`docs/nova-full-route-manual-progress.json`, then regenerate this checklist.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Automated row-level visual evidence:

```sh
python3 tools/run_automated_tests.py --only route-full-screenshots --visual-style classic_dark
```

This produces `artifacts/scene-screenshots/route-full-latest/index.html` and a
manifest with one screenshot per walkthrough command. Use it to review row
evidence. The route table below includes a stable `route-full #NNN` key that
matches the manifest `command_index`. The `Live observed` column is sourced
from `command_observations` in the progress JSON; only mark rows after
live-window observation.

Global acceptance:

- [x] Start from the title splash and enter Nova with Enter/Space.
- [x] First Dialogic payload advances and returns to the Nova action menu.
- [ ] Complete all 8 scenes in order without input deadlock.
- [x] Save/continue works after at least one mid-route save.
- [x] Pause/resume and return-to-title work during exploration.
- [ ] No legacy `res://src/main.tscn` / DreamField/OpenRPG entry is used for this route.
- [ ] Record any visual, audio, or input issue against the scene and command step below.

Route summary:

- Scenes: 8
- Walkthrough commands: 257

## 00-prologue-lights-out - 序幕：灯未亮起的夜晚

- Start location: `street`
- Ending flag: `entered_moqi`
- Walkthrough commands: 20

Required flags:

- `noticed_dark_window`
- `checked_unlocked_door`
- `checked_cold_dinner`
- `checked_family_photo`
- `checked_glasses`
- `checked_mother_note`
- `checked_phone_signal`
- `read_continue_letter`
- `entered_moqi`

Live-window route:

| Step | Live observed | Route-full evidence key | Command | Expected live-window observation |
| ---: | --- | --- | --- | --- |
| 1 | [x] | `route-full #001` | `inspect window` | `window` dialogue/action resolves and any flags are reflected in status |
| 2 | [x] | `route-full #002` | `inspect poster` | `poster` dialogue/action resolves and any flags are reflected in status |
| 3 | [x] | `route-full #003` | `go building` | location changes to `building` and action menu regains focus |
| 4 | [x] | `route-full #004` | `inspect lamp` | `lamp` dialogue/action resolves and any flags are reflected in status |
| 5 | [x] | `route-full #005` | `go home` | location changes to `home` and action menu regains focus |
| 6 | [x] | `route-full #006` | `inspect lock` | `lock` dialogue/action resolves and any flags are reflected in status |
| 7 | [x] | `route-full #007` | `inspect air` | `air` dialogue/action resolves and any flags are reflected in status |
| 8 | [x] | `route-full #008` | `go living_room` | location changes to `living_room` and action menu regains focus |
| 9 | [x] | `route-full #009` | `inspect dinner` | `dinner` dialogue/action resolves and any flags are reflected in status |
| 10 | [x] | `route-full #010` | `inspect tv` | `tv` dialogue/action resolves and any flags are reflected in status |
| 11 | [x] | `route-full #011` | `inspect photo` | `photo` dialogue/action resolves and any flags are reflected in status |
| 12 | [x] | `route-full #012` | `go study` | location changes to `study` and action menu regains focus |
| 13 | [x] | `route-full #013` | `inspect glasses` | `glasses` dialogue/action resolves and any flags are reflected in status |
| 14 | [x] | `route-full #014` | `inspect note` | `note` dialogue/action resolves and any flags are reflected in status |
| 15 | [x] | `route-full #015` | `inspect phone` | `phone` dialogue/action resolves and any flags are reflected in status |
| 16 | [x] | `route-full #016` | `go living_room` | location changes to `living_room` and action menu regains focus |
| 17 | [x] | `route-full #017` | `go bedroom` | location changes to `bedroom` and action menu regains focus |
| 18 | [x] | `route-full #018` | `inspect window` | `window` dialogue/action resolves and any flags are reflected in status |
| 19 | [x] | `route-full #019` | `inspect letter` | `letter` dialogue/action resolves and any flags are reflected in status |
| 20 | [x] | `route-full #020` | `inspect pen` | `pen` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [x] Scene starts from the expected location after previous scene completion.
- [x] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [x] Action menu focus returns after each dialogue/action payload.
- [x] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [x] Ending flag `entered_moqi` is reached before moving to the next scene.

## 01-illiterate - 第一幕：不会写字的人

- Start location: `mud_road`
- Ending flag: `defeated_nameless`
- Walkthrough commands: 24

Required flags:

- `checked_phone_no_service`
- `checked_broken_sign`
- `saw_burning_city`
- `met_xiaoyan`
- `saw_lost_name_deer`
- `saw_molusi`
- `met_xiali`
- `learned_name_strokes`
- `named_beast`
- `defeated_nameless`
- `inspected_broken_nameplate`

Live-window route:

| Step | Live observed | Route-full evidence key | Command | Expected live-window observation |
| ---: | --- | --- | --- | --- |
| 1 | [x] | `route-full #021` | `inspect phone` | `phone` dialogue/action resolves and any flags are reflected in status |
| 2 | [x] | `route-full #022` | `inspect sign` | `sign` dialogue/action resolves and any flags are reflected in status |
| 3 | [x] | `route-full #023` | `inspect city` | `city` dialogue/action resolves and any flags are reflected in status |
| 4 | [x] | `route-full #024` | `inspect pen` | `pen` dialogue/action resolves and any flags are reflected in status |
| 5 | [x] | `route-full #025` | `go camp` | location changes to `camp` and action menu regains focus |
| 6 | [x] | `route-full #026` | `inspect xiaoyan` | `xiaoyan` dialogue/action resolves and any flags are reflected in status |
| 7 | [x] | `route-full #027` | `inspect notice` | `notice` dialogue/action resolves and any flags are reflected in status |
| 8 | [x] | `route-full #028` | `inspect deer_tracks` | `deer_tracks` dialogue/action resolves and any flags are reflected in status |
| 9 | [x] | `route-full #029` | `go chase` | location changes to `chase` and action menu regains focus |
| 10 | [x] | `route-full #030` | `inspect soldiers` | `soldiers` dialogue/action resolves and any flags are reflected in status |
| 11 | [x] | `route-full #031` | `inspect gate` | `gate` dialogue/action resolves and any flags are reflected in status |
| 12 | [x] | `route-full #032` | `inspect xiali` | `xiali` dialogue/action resolves and any flags are reflected in status |
| 13 | [x] | `route-full #033` | `go station` | location changes to `station` and action menu regains focus |
| 14 | [x] | `route-full #034` | `inspect strokes` | `strokes` dialogue/action resolves and any flags are reflected in status |
| 15 | [x] | `route-full #035` | `inspect xiaoyan` | `xiaoyan` dialogue/action resolves and any flags are reflected in status |
| 16 | [x] | `route-full #036` | `write name` | combat action `write name` advances without losing input focus |
| 17 | [x] | `route-full #037` | `write name` | combat action `write name` advances without losing input focus |
| 18 | [x] | `route-full #038` | `write name` | combat action `write name` advances without losing input focus |
| 19 | [x] | `route-full #039` | `attack` | screen responds without input deadlock |
| 20 | [x] | `route-full #040` | `attack` | screen responds without input deadlock |
| 21 | [x] | `route-full #041` | `write name` | combat action `write name` advances without losing input focus |
| 22 | [x] | `route-full #042` | `attack` | screen responds without input deadlock |
| 23 | [x] | `route-full #043` | `attack` | screen responds without input deadlock |
| 24 | [x] | `route-full #044` | `inspect broken_nameplate` | `broken_nameplate` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [x] Scene starts from the expected location after previous scene completion.
- [x] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [x] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [x] Ending flag `defeated_nameless` is reached before moving to the next scene.

## 02-moqi-academy - 第二幕：墨颀书院

- Start location: `academy`
- Ending flag: `viewed_parent_record`
- Walkthrough commands: 34

Required flags:

- `met_wensu`
- `passed_wensu_baseline`
- `learned_name`
- `learned_door`
- `learned_fire`
- `learned_stop`
- `cleared_contract_patrol`
- `owned_first_repair_failure`
- `read_ink_well_ray_feedback`
- `repaired_well`
- `got_basic_dictionary`
- `understood_dictionary_margins`
- `met_contract_hound`
- `defeated_contract_officer`
- `repaired_first_node`
- `read_mother_node_annotation`
- `viewed_parent_record`

Live-window route:

| Step | Live observed | Route-full evidence key | Command | Expected live-window observation |
| ---: | --- | --- | --- | --- |
| 1 | [ ] | `route-full #045` | `inspect wensu` | `wensu` dialogue/action resolves and any flags are reflected in status |
| 2 | [ ] | `route-full #046` | `inspect baseline` | `baseline` dialogue/action resolves and any flags are reflected in status |
| 3 | [ ] | `route-full #047` | `inspect name` | `name` dialogue/action resolves and any flags are reflected in status |
| 4 | [ ] | `route-full #048` | `inspect door` | `door` dialogue/action resolves and any flags are reflected in status |
| 5 | [ ] | `route-full #049` | `inspect fire` | `fire` dialogue/action resolves and any flags are reflected in status |
| 6 | [ ] | `route-full #050` | `inspect stop` | `stop` dialogue/action resolves and any flags are reflected in status |
| 7 | [ ] | `route-full #051` | `go village` | location changes to `village` and action menu regains focus |
| 8 | [ ] | `route-full #052` | `inspect well` | `well` dialogue/action resolves and any flags are reflected in status |
| 9 | [ ] | `route-full #053` | `inspect first_failure` | `first_failure` dialogue/action resolves and any flags are reflected in status |
| 10 | [ ] | `route-full #054` | `inspect ink_well_ray` | `ink_well_ray` dialogue/action resolves and any flags are reflected in status |
| 11 | [ ] | `route-full #055` | `inspect villagers` | `villagers` dialogue/action resolves and any flags are reflected in status |
| 12 | [ ] | `route-full #056` | `engage contract_patrol` | encounter `contract_patrol` starts and resolves through the authored branch |
| 13 | [ ] | `route-full #057` | `cast stop` | glyph `stop` resolves with readable feedback |
| 14 | [ ] | `route-full #058` | `cast fire` | glyph `fire` resolves with readable feedback |
| 15 | [ ] | `route-full #059` | `cast name` | glyph `name` resolves with readable feedback |
| 16 | [ ] | `route-full #060` | `go archive` | location changes to `archive` and action menu regains focus |
| 17 | [ ] | `route-full #061` | `inspect layers` | `layers` dialogue/action resolves and any flags are reflected in status |
| 18 | [ ] | `route-full #062` | `inspect margins` | `margins` dialogue/action resolves and any flags are reflected in status |
| 19 | [ ] | `route-full #063` | `inspect cabinet` | `cabinet` dialogue/action resolves and any flags are reflected in status |
| 20 | [ ] | `route-full #064` | `cast door` | glyph `door` resolves with readable feedback |
| 21 | [ ] | `route-full #065` | `go node` | location changes to `node` and action menu regains focus |
| 22 | [ ] | `route-full #066` | `inspect contract` | `contract` dialogue/action resolves and any flags are reflected in status |
| 23 | [ ] | `route-full #067` | `inspect contract_hound` | `contract_hound` dialogue/action resolves and any flags are reflected in status |
| 24 | [ ] | `route-full #068` | `write name` | combat action `write name` advances without losing input focus |
| 25 | [ ] | `route-full #069` | `cast door` | glyph `door` resolves with readable feedback |
| 26 | [ ] | `route-full #070` | `cast stop` | glyph `stop` resolves with readable feedback |
| 27 | [ ] | `route-full #071` | `attack` | screen responds without input deadlock |
| 28 | [ ] | `route-full #072` | `attack` | screen responds without input deadlock |
| 29 | [ ] | `route-full #073` | `attack` | screen responds without input deadlock |
| 30 | [ ] | `route-full #074` | `cast name` | glyph `name` resolves with readable feedback |
| 31 | [ ] | `route-full #075` | `cast stop` | glyph `stop` resolves with readable feedback |
| 32 | [ ] | `route-full #076` | `cast fire` | glyph `fire` resolves with readable feedback |
| 33 | [ ] | `route-full #077` | `inspect mother_annotation` | `mother_annotation` dialogue/action resolves and any flags are reflected in status |
| 34 | [ ] | `route-full #078` | `inspect record` | `record` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `viewed_parent_record` is reached before moving to the next scene.

## 03-dead-kingdom - 第三幕：死去的王国

- Start location: `outer_city`
- Ending flag: `read_parent_full_plan`
- Walkthrough commands: 29

Required flags:

- `saw_dead_city_order`
- `saw_market_without_buyers`
- `found_reform_records`
- `found_student_letters`
- `found_lockdown_logs`
- `read_trial_transcripts`
- `restored_fall_route`
- `resolved_book_route`
- `saw_burned_route_wall`
- `xiali_answered_without_throne`
- `met_statebook_remnant`
- `defeated_royal_shadow`
- `opened_main_core`
- `read_parent_full_plan`

Live-window route:

| Step | Live observed | Route-full evidence key | Command | Expected live-window observation |
| ---: | --- | --- | --- | --- |
| 1 | [ ] | `route-full #079` | `inspect order` | `order` dialogue/action resolves and any flags are reflected in status |
| 2 | [ ] | `route-full #080` | `inspect market` | `market` dialogue/action resolves and any flags are reflected in status |
| 3 | [ ] | `route-full #081` | `inspect poster` | `poster` dialogue/action resolves and any flags are reflected in status |
| 4 | [ ] | `route-full #082` | `go library` | location changes to `library` and action menu regains focus |
| 5 | [ ] | `route-full #083` | `inspect records` | `records` dialogue/action resolves and any flags are reflected in status |
| 6 | [ ] | `route-full #084` | `inspect letters` | `letters` dialogue/action resolves and any flags are reflected in status |
| 7 | [ ] | `route-full #085` | `inspect ban` | `ban` dialogue/action resolves and any flags are reflected in status |
| 8 | [ ] | `route-full #086` | `choose public` | choice `public` resolves and returns to exploration |
| 9 | [ ] | `route-full #087` | `go hq` | location changes to `hq` and action menu regains focus |
| 10 | [ ] | `route-full #088` | `inspect logs` | `logs` dialogue/action resolves and any flags are reflected in status |
| 11 | [ ] | `route-full #089` | `inspect transcripts` | `transcripts` dialogue/action resolves and any flags are reflected in status |
| 12 | [ ] | `route-full #090` | `inspect names` | `names` dialogue/action resolves and any flags are reflected in status |
| 13 | [ ] | `route-full #091` | `go palace` | location changes to `palace` and action menu regains focus |
| 14 | [ ] | `route-full #092` | `inspect route` | `route` dialogue/action resolves and any flags are reflected in status |
| 15 | [ ] | `route-full #093` | `inspect ash_wall` | `ash_wall` dialogue/action resolves and any flags are reflected in status |
| 16 | [ ] | `route-full #094` | `inspect xiali` | `xiali` dialogue/action resolves and any flags are reflected in status |
| 17 | [ ] | `route-full #095` | `go hall` | location changes to `hall` and action menu regains focus |
| 18 | [ ] | `route-full #096` | `inspect question` | `question` dialogue/action resolves and any flags are reflected in status |
| 19 | [ ] | `route-full #097` | `inspect statebook_remnant` | `statebook_remnant` dialogue/action resolves and any flags are reflected in status |
| 20 | [ ] | `route-full #098` | `write name` | combat action `write name` advances without losing input focus |
| 21 | [ ] | `route-full #099` | `cast door` | glyph `door` resolves with readable feedback |
| 22 | [ ] | `route-full #100` | `cast stop` | glyph `stop` resolves with readable feedback |
| 23 | [ ] | `route-full #101` | `inspect answer` | `answer` dialogue/action resolves and any flags are reflected in status |
| 24 | [ ] | `route-full #102` | `attack` | screen responds without input deadlock |
| 25 | [ ] | `route-full #103` | `attack` | screen responds without input deadlock |
| 26 | [ ] | `route-full #104` | `attack` | screen responds without input deadlock |
| 27 | [ ] | `route-full #105` | `attack` | screen responds without input deadlock |
| 28 | [ ] | `route-full #106` | `cast door` | glyph `door` resolves with readable feedback |
| 29 | [ ] | `route-full #107` | `inspect plan` | `plan` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `read_parent_full_plan` is reached before moving to the next scene.

## 04-continuation-institute - 第四幕：续文院

- Start location: `institute`
- Ending flag: `archive_tower_built`
- Walkthrough commands: 33

Required flags:

- `founded_institute`
- `publicly_answered_noble_observer`
- `opened_first_school`
- `published_standard_dictionary`
- `repaired_workshop_flow`
- `solved_mine_safety`
- `installed_safety_board`
- `restored_communication_tower`
- `defeated_seal_tower`
- `archive_tower_built`

Live-window route:

| Step | Live observed | Route-full evidence key | Command | Expected live-window observation |
| ---: | --- | --- | --- | --- |
| 1 | [ ] | `route-full #108` | `inspect members` | `members` dialogue/action resolves and any flags are reflected in status |
| 2 | [ ] | `route-full #109` | `inspect charter` | `charter` dialogue/action resolves and any flags are reflected in status |
| 3 | [ ] | `route-full #110` | `inspect noble_observer` | `noble_observer` dialogue/action resolves and any flags are reflected in status |
| 4 | [ ] | `route-full #111` | `build institute` | build `institute` resolves with readable feedback |
| 5 | [ ] | `route-full #112` | `build dictionary` | build `dictionary` resolves with readable feedback |
| 6 | [ ] | `route-full #113` | `go school` | location changes to `school` and action menu regains focus |
| 7 | [ ] | `route-full #114` | `inspect class` | `class` dialogue/action resolves and any flags are reflected in status |
| 8 | [ ] | `route-full #115` | `inspect mistake` | `mistake` dialogue/action resolves and any flags are reflected in status |
| 9 | [ ] | `route-full #116` | `build school` | build `school` resolves with readable feedback |
| 10 | [ ] | `route-full #117` | `go workshop` | location changes to `workshop` and action menu regains focus |
| 11 | [ ] | `route-full #118` | `inspect atang` | `atang` dialogue/action resolves and any flags are reflected in status |
| 12 | [ ] | `route-full #119` | `inspect flood` | `flood` dialogue/action resolves and any flags are reflected in status |
| 13 | [ ] | `route-full #120` | `build workflow` | build `workflow` resolves with readable feedback |
| 14 | [ ] | `route-full #121` | `go mine` | location changes to `mine` and action menu regains focus |
| 15 | [ ] | `route-full #122` | `inspect hazard` | `hazard` dialogue/action resolves and any flags are reflected in status |
| 16 | [ ] | `route-full #123` | `cast stop` | glyph `stop` resolves with readable feedback |
| 17 | [ ] | `route-full #124` | `build safety` | build `safety` resolves with readable feedback |
| 18 | [ ] | `route-full #125` | `inspect safety_board` | `safety_board` dialogue/action resolves and any flags are reflected in status |
| 19 | [ ] | `route-full #126` | `go tower` | location changes to `tower` and action menu regains focus |
| 20 | [ ] | `route-full #127` | `inspect array` | `array` dialogue/action resolves and any flags are reflected in status |
| 21 | [ ] | `route-full #128` | `build comms` | build `comms` resolves with readable feedback |
| 22 | [ ] | `route-full #129` | `go seal_tower` | location changes to `seal_tower` and action menu regains focus |
| 23 | [ ] | `route-full #130` | `inspect students` | `students` dialogue/action resolves and any flags are reflected in status |
| 24 | [ ] | `route-full #131` | `inspect dictionary` | `dictionary` dialogue/action resolves and any flags are reflected in status |
| 25 | [ ] | `route-full #132` | `build protect` | build `protect` resolves with readable feedback |
| 26 | [ ] | `route-full #133` | `write name` | combat action `write name` advances without losing input focus |
| 27 | [ ] | `route-full #134` | `cast stop` | glyph `stop` resolves with readable feedback |
| 28 | [ ] | `route-full #135` | `attack` | screen responds without input deadlock |
| 29 | [ ] | `route-full #136` | `attack` | screen responds without input deadlock |
| 30 | [ ] | `route-full #137` | `write name` | combat action `write name` advances without losing input focus |
| 31 | [ ] | `route-full #138` | `attack` | screen responds without input deadlock |
| 32 | [ ] | `route-full #139` | `attack` | screen responds without input deadlock |
| 33 | [ ] | `route-full #140` | `build archive` | build `archive` resolves with readable feedback |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `archive_tower_built` is reached before moving to the next scene.

## 05-century-continuation - 第五幕：百年续页

- Start location: `industry`
- Ending flag: `saw_modern_star_darkening`
- Walkthrough commands: 33

Required flags:

- `built_text_industry`
- `witnessed_wensu_absence`
- `found_atang_last_blueprint`
- `saw_night_school_expansion`
- `bound_xiali_to_statebook`
- `saw_xiali_fading`
- `kept_xiali_private_anchor`
- `confirmed_remote_classrooms`
- `heard_xiaoyan_roll_call`
- `built_statebook_network`
- `standardized_star_coordinates`
- `logged_failed_signal`
- `identified_star_chart_moth`
- `completed_astral_tower`
- `saw_first_silent_frame`
- `stabilized_silent_interference`
- `saw_modern_star_darkening`

Live-window route:

| Step | Live observed | Route-full evidence key | Command | Expected live-window observation |
| ---: | --- | --- | --- | --- |
| 1 | [ ] | `route-full #141` | `inspect teachers` | `teachers` dialogue/action resolves and any flags are reflected in status |
| 2 | [ ] | `route-full #142` | `inspect wensu_book` | `wensu_book` dialogue/action resolves and any flags are reflected in status |
| 3 | [ ] | `route-full #143` | `inspect wensu_absence` | `wensu_absence` dialogue/action resolves and any flags are reflected in status |
| 4 | [ ] | `route-full #144` | `inspect night_school` | `night_school` dialogue/action resolves and any flags are reflected in status |
| 5 | [ ] | `route-full #145` | `build industry` | build `industry` resolves with readable feedback |
| 6 | [ ] | `route-full #146` | `inspect atang_blueprint` | `atang_blueprint` dialogue/action resolves and any flags are reflected in status |
| 7 | [ ] | `route-full #147` | `go network` | location changes to `network` and action menu regains focus |
| 8 | [ ] | `route-full #148` | `inspect xiali` | `xiali` dialogue/action resolves and any flags are reflected in status |
| 9 | [ ] | `route-full #149` | `inspect xiali_fading` | `xiali_fading` dialogue/action resolves and any flags are reflected in status |
| 10 | [ ] | `route-full #150` | `inspect private_anchor` | `private_anchor` dialogue/action resolves and any flags are reflected in status |
| 11 | [ ] | `route-full #151` | `build bind_xiali` | build `bind_xiali` resolves with readable feedback |
| 12 | [ ] | `route-full #152` | `inspect engineers` | `engineers` dialogue/action resolves and any flags are reflected in status |
| 13 | [ ] | `route-full #153` | `inspect remote_classrooms` | `remote_classrooms` dialogue/action resolves and any flags are reflected in status |
| 14 | [ ] | `route-full #154` | `inspect xiaoyan_roll_call` | `xiaoyan_roll_call` dialogue/action resolves and any flags are reflected in status |
| 15 | [ ] | `route-full #155` | `build network` | build `network` resolves with readable feedback |
| 16 | [ ] | `route-full #156` | `go astral` | location changes to `astral` and action menu regains focus |
| 17 | [ ] | `route-full #157` | `inspect star_map` | `star_map` dialogue/action resolves and any flags are reflected in status |
| 18 | [ ] | `route-full #158` | `inspect coordinate_standard` | `coordinate_standard` dialogue/action resolves and any flags are reflected in status |
| 19 | [ ] | `route-full #159` | `inspect beacon` | `beacon` dialogue/action resolves and any flags are reflected in status |
| 20 | [ ] | `route-full #160` | `inspect failed_signal` | `failed_signal` dialogue/action resolves and any flags are reflected in status |
| 21 | [ ] | `route-full #161` | `inspect star_chart_moth` | `star_chart_moth` dialogue/action resolves and any flags are reflected in status |
| 22 | [ ] | `route-full #162` | `build astral_tower` | build `astral_tower` resolves with readable feedback |
| 23 | [ ] | `route-full #163` | `go star_tower` | location changes to `star_tower` and action menu regains focus |
| 24 | [ ] | `route-full #164` | `inspect signal` | `signal` dialogue/action resolves and any flags are reflected in status |
| 25 | [ ] | `route-full #165` | `inspect silent_frame` | `silent_frame` dialogue/action resolves and any flags are reflected in status |
| 26 | [ ] | `route-full #166` | `write name` | combat action `write name` advances without losing input focus |
| 27 | [ ] | `route-full #167` | `cast stop` | glyph `stop` resolves with readable feedback |
| 28 | [ ] | `route-full #168` | `attack` | screen responds without input deadlock |
| 29 | [ ] | `route-full #169` | `attack` | screen responds without input deadlock |
| 30 | [ ] | `route-full #170` | `write name` | combat action `write name` advances without losing input focus |
| 31 | [ ] | `route-full #171` | `attack` | screen responds without input deadlock |
| 32 | [ ] | `route-full #172` | `attack` | screen responds without input deadlock |
| 33 | [ ] | `route-full #173` | `inspect city` | `city` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `saw_modern_star_darkening` is reached before moving to the next scene.

## 06-return-star-plan - 第六幕：归星计划

- Start location: `astral_tower`
- Ending flag: `returned_to_modern_with_moqi`
- Walkthrough commands: 34

Required flags:

- `confirmed_modern_disaster`
- `won_return_star_council`
- `reviewed_return_risk_ledger`
- `built_return_vessel`
- `marked_empty_seats`
- `bound_civilization_backups`
- `passed_backup_drill`
- `opened_return_gate`
- `heard_return_gate_farewell`
- `identified_invasion_probe`
- `recognized_probe_body`
- `defeated_invasion_probe`
- `received_parent_truth`
- `returned_to_modern_with_moqi`

Live-window route:

| Step | Live observed | Route-full evidence key | Command | Expected live-window observation |
| ---: | --- | --- | --- | --- |
| 1 | [ ] | `route-full #174` | `inspect disaster` | `disaster` dialogue/action resolves and any flags are reflected in status |
| 2 | [ ] | `route-full #175` | `inspect parents` | `parents` dialogue/action resolves and any flags are reflected in status |
| 3 | [ ] | `route-full #176` | `go council` | location changes to `council` and action menu regains focus |
| 4 | [ ] | `route-full #177` | `inspect supporters` | `supporters` dialogue/action resolves and any flags are reflected in status |
| 5 | [ ] | `route-full #178` | `inspect opposition` | `opposition` dialogue/action resolves and any flags are reflected in status |
| 6 | [ ] | `route-full #179` | `inspect risk_ledger` | `risk_ledger` dialogue/action resolves and any flags are reflected in status |
| 7 | [ ] | `route-full #180` | `build mandate` | build `mandate` resolves with readable feedback |
| 8 | [ ] | `route-full #181` | `go dockyard` | location changes to `dockyard` and action menu regains focus |
| 9 | [ ] | `route-full #182` | `inspect blueprint` | `blueprint` dialogue/action resolves and any flags are reflected in status |
| 10 | [ ] | `route-full #183` | `build vessel` | build `vessel` resolves with readable feedback |
| 11 | [ ] | `route-full #184` | `inspect empty_seats` | `empty_seats` dialogue/action resolves and any flags are reflected in status |
| 12 | [ ] | `route-full #185` | `go core` | location changes to `core` and action menu regains focus |
| 13 | [ ] | `route-full #186` | `inspect xiali` | `xiali` dialogue/action resolves and any flags are reflected in status |
| 14 | [ ] | `route-full #187` | `inspect backup` | `backup` dialogue/action resolves and any flags are reflected in status |
| 15 | [ ] | `route-full #188` | `build backups` | build `backups` resolves with readable feedback |
| 16 | [ ] | `route-full #189` | `inspect backup_drill` | `backup_drill` dialogue/action resolves and any flags are reflected in status |
| 17 | [ ] | `route-full #190` | `go gate` | location changes to `gate` and action menu regains focus |
| 18 | [ ] | `route-full #191` | `inspect calibration` | `calibration` dialogue/action resolves and any flags are reflected in status |
| 19 | [ ] | `route-full #192` | `build gate` | build `gate` resolves with readable feedback |
| 20 | [ ] | `route-full #193` | `inspect farewell` | `farewell` dialogue/action resolves and any flags are reflected in status |
| 21 | [ ] | `route-full #194` | `go rift` | location changes to `rift` and action menu regains focus |
| 22 | [ ] | `route-full #195` | `inspect probe` | `probe` dialogue/action resolves and any flags are reflected in status |
| 23 | [ ] | `route-full #196` | `inspect probe_body` | `probe_body` dialogue/action resolves and any flags are reflected in status |
| 24 | [ ] | `route-full #197` | `write name` | combat action `write name` advances without losing input focus |
| 25 | [ ] | `route-full #198` | `cast stop` | glyph `stop` resolves with readable feedback |
| 26 | [ ] | `route-full #199` | `attack` | screen responds without input deadlock |
| 27 | [ ] | `route-full #200` | `attack` | screen responds without input deadlock |
| 28 | [ ] | `route-full #201` | `write name` | combat action `write name` advances without losing input focus |
| 29 | [ ] | `route-full #202` | `attack` | screen responds without input deadlock |
| 30 | [ ] | `route-full #203` | `attack` | screen responds without input deadlock |
| 31 | [ ] | `route-full #204` | `write name` | combat action `write name` advances without losing input focus |
| 32 | [ ] | `route-full #205` | `attack` | screen responds without input deadlock |
| 33 | [ ] | `route-full #206` | `inspect truth` | `truth` dialogue/action resolves and any flags are reflected in status |
| 34 | [ ] | `route-full #207` | `build return` | build `return` resolves with readable feedback |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `returned_to_modern_with_moqi` is reached before moving to the next scene.

## 07-lights-on-again - 第七幕：灯重新亮起

- Start location: `home`
- Ending flag: `found_parent_bridge_trace`
- Walkthrough commands: 50

Required flags:

- `confirmed_home_silenced`
- `heard_parent_echo`
- `chose_city_before_parents`
- `confirmed_school_erasure`
- `found_missing_teacher`
- `lit_city_grid`
- `temporary_node_built`
- `saw_return_bridge_traveler`
- `saw_faceless_neighbors`
- `rescued_clerk_name`
- `recovered_receipt_name`
- `modern_node_stable`
- `read_parent_final_record`
- `survived_failed_bridge_test`
- `read_traveler_bridge_warning`
- `bridge_stable`
- `heard_xiaoyan_name_sample`
- `installed_atang_bridge_fuse`
- `found_wensu_margin_note`
- `identified_final_protocol`
- `heard_protocol_indictment`
- `saw_deleted_party_names`
- `answered_protocol_with_evidence`
- `restored_final_ui`
- `heard_civilization_response`
- `defeated_final_protocol`
- `rejected_silence_protocol`
- `found_parent_bridge_trace`

Live-window route:

| Step | Live observed | Route-full evidence key | Command | Expected live-window observation |
| ---: | --- | --- | --- | --- |
| 1 | [ ] | `route-full #208` | `inspect room` | `room` dialogue/action resolves and any flags are reflected in status |
| 2 | [ ] | `route-full #209` | `inspect parents_echo` | `parents_echo` dialogue/action resolves and any flags are reflected in status |
| 3 | [ ] | `route-full #210` | `inspect city_first` | `city_first` dialogue/action resolves and any flags are reflected in status |
| 4 | [ ] | `route-full #211` | `inspect contacts` | `contacts` dialogue/action resolves and any flags are reflected in status |
| 5 | [ ] | `route-full #212` | `go school` | location changes to `school` and action menu regains focus |
| 6 | [ ] | `route-full #213` | `inspect corridor` | `corridor` dialogue/action resolves and any flags are reflected in status |
| 7 | [ ] | `route-full #214` | `inspect missing_teacher` | `missing_teacher` dialogue/action resolves and any flags are reflected in status |
| 8 | [ ] | `route-full #215` | `inspect classmates` | `classmates` dialogue/action resolves and any flags are reflected in status |
| 9 | [ ] | `route-full #216` | `inspect xiaoyan_name_sample` | `xiaoyan_name_sample` dialogue/action resolves and any flags are reflected in status |
| 10 | [ ] | `route-full #217` | `go street` | location changes to `street` and action menu regains focus |
| 11 | [ ] | `route-full #218` | `inspect grid` | `grid` dialogue/action resolves and any flags are reflected in status |
| 12 | [ ] | `route-full #219` | `inspect neighbors` | `neighbors` dialogue/action resolves and any flags are reflected in status |
| 13 | [ ] | `route-full #220` | `build lights` | build `lights` resolves with readable feedback |
| 14 | [ ] | `route-full #221` | `inspect node_base` | `node_base` dialogue/action resolves and any flags are reflected in status |
| 15 | [ ] | `route-full #222` | `build node` | build `node` resolves with readable feedback |
| 16 | [ ] | `route-full #223` | `inspect bridge_traveler_reflection` | `bridge_traveler_reflection` dialogue/action resolves and any flags are reflected in status |
| 17 | [ ] | `route-full #224` | `inspect atang_bridge_fuse` | `atang_bridge_fuse` dialogue/action resolves and any flags are reflected in status |
| 18 | [ ] | `route-full #225` | `go store` | location changes to `store` and action menu regains focus |
| 19 | [ ] | `route-full #226` | `inspect clerk` | `clerk` dialogue/action resolves and any flags are reflected in status |
| 20 | [ ] | `route-full #227` | `cast name` | glyph `name` resolves with readable feedback |
| 21 | [ ] | `route-full #228` | `inspect receipt` | `receipt` dialogue/action resolves and any flags are reflected in status |
| 22 | [ ] | `route-full #229` | `go street` | location changes to `street` and action menu regains focus |
| 23 | [ ] | `route-full #230` | `go lab` | location changes to `lab` and action menu regains focus |
| 24 | [ ] | `route-full #231` | `inspect formula` | `formula` dialogue/action resolves and any flags are reflected in status |
| 25 | [ ] | `route-full #232` | `inspect beacon` | `beacon` dialogue/action resolves and any flags are reflected in status |
| 26 | [ ] | `route-full #233` | `build modern_node` | build `modern_node` resolves with readable feedback |
| 27 | [ ] | `route-full #234` | `inspect parents_record` | `parents_record` dialogue/action resolves and any flags are reflected in status |
| 28 | [ ] | `route-full #235` | `inspect wensu_margin_note` | `wensu_margin_note` dialogue/action resolves and any flags are reflected in status |
| 29 | [ ] | `route-full #236` | `inspect failed_bridge_test` | `failed_bridge_test` dialogue/action resolves and any flags are reflected in status |
| 30 | [ ] | `route-full #237` | `inspect traveler_warning` | `traveler_warning` dialogue/action resolves and any flags are reflected in status |
| 31 | [ ] | `route-full #238` | `build bridge` | build `bridge` resolves with readable feedback |
| 32 | [ ] | `route-full #239` | `go orbit` | location changes to `orbit` and action menu regains focus |
| 33 | [ ] | `route-full #240` | `inspect protocol` | `protocol` dialogue/action resolves and any flags are reflected in status |
| 34 | [ ] | `route-full #241` | `inspect protocol_indictment` | `protocol_indictment` dialogue/action resolves and any flags are reflected in status |
| 35 | [ ] | `route-full #242` | `inspect deleted_party_names` | `deleted_party_names` dialogue/action resolves and any flags are reflected in status |
| 36 | [ ] | `route-full #243` | `inspect counter_evidence` | `counter_evidence` dialogue/action resolves and any flags are reflected in status |
| 37 | [ ] | `route-full #244` | `build restore` | build `restore` resolves with readable feedback |
| 38 | [ ] | `route-full #245` | `inspect civilization_response` | `civilization_response` dialogue/action resolves and any flags are reflected in status |
| 39 | [ ] | `route-full #246` | `write name` | combat action `write name` advances without losing input focus |
| 40 | [ ] | `route-full #247` | `cast stop` | glyph `stop` resolves with readable feedback |
| 41 | [ ] | `route-full #248` | `attack` | screen responds without input deadlock |
| 42 | [ ] | `route-full #249` | `attack` | screen responds without input deadlock |
| 43 | [ ] | `route-full #250` | `write name` | combat action `write name` advances without losing input focus |
| 44 | [ ] | `route-full #251` | `attack` | screen responds without input deadlock |
| 45 | [ ] | `route-full #252` | `attack` | screen responds without input deadlock |
| 46 | [ ] | `route-full #253` | `write name` | combat action `write name` advances without losing input focus |
| 47 | [ ] | `route-full #254` | `attack` | screen responds without input deadlock |
| 48 | [ ] | `route-full #255` | `combine continue` | combo `continue` resolves with readable feedback |
| 49 | [ ] | `route-full #256` | `go lab` | location changes to `lab` and action menu regains focus |
| 50 | [ ] | `route-full #257` | `inspect parent_bridge_trace` | `parent_bridge_trace` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `found_parent_bridge_trace` is reached before moving to the next scene.
