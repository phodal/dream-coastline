# Nova Full-Route Manual QA

This checklist is generated from `data/story_scenes/*.json` by
`tools/build_nova_manual_route_checklist.py`. It is a live-window QA aid for
issue #6, not a replacement for headless smoke tests.

Current entrypoint: `res://src/nova/main.tscn`

Recommended setup:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

Automated row-level visual evidence:

```sh
python3 tools/run_automated_tests.py --only route-full-screenshots --visual-style classic_dark
```

This produces `artifacts/scene-screenshots/route-full-latest/index.html` and a
manifest with one screenshot per walkthrough command. Use it to review row
evidence, but only tick the manual checkboxes after live-window observation.

Global acceptance:

- [ ] Start from the title splash and enter Nova with Enter/Space.
- [ ] First Dialogic payload advances and returns to the Nova action menu.
- [ ] Complete all 8 scenes in order without input deadlock.
- [ ] Save/continue works after at least one mid-route save.
- [ ] Pause/resume and return-to-title work during exploration.
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

| Step | Command | Expected live-window observation |
| ---: | --- | --- |
| 1 | `inspect window` | `window` dialogue/action resolves and any flags are reflected in status |
| 2 | `inspect poster` | `poster` dialogue/action resolves and any flags are reflected in status |
| 3 | `go building` | location changes to `building` and action menu regains focus |
| 4 | `inspect lamp` | `lamp` dialogue/action resolves and any flags are reflected in status |
| 5 | `go home` | location changes to `home` and action menu regains focus |
| 6 | `inspect lock` | `lock` dialogue/action resolves and any flags are reflected in status |
| 7 | `inspect air` | `air` dialogue/action resolves and any flags are reflected in status |
| 8 | `go living_room` | location changes to `living_room` and action menu regains focus |
| 9 | `inspect dinner` | `dinner` dialogue/action resolves and any flags are reflected in status |
| 10 | `inspect tv` | `tv` dialogue/action resolves and any flags are reflected in status |
| 11 | `inspect photo` | `photo` dialogue/action resolves and any flags are reflected in status |
| 12 | `go study` | location changes to `study` and action menu regains focus |
| 13 | `inspect glasses` | `glasses` dialogue/action resolves and any flags are reflected in status |
| 14 | `inspect note` | `note` dialogue/action resolves and any flags are reflected in status |
| 15 | `inspect phone` | `phone` dialogue/action resolves and any flags are reflected in status |
| 16 | `go living_room` | location changes to `living_room` and action menu regains focus |
| 17 | `go bedroom` | location changes to `bedroom` and action menu regains focus |
| 18 | `inspect window` | `window` dialogue/action resolves and any flags are reflected in status |
| 19 | `inspect letter` | `letter` dialogue/action resolves and any flags are reflected in status |
| 20 | `inspect pen` | `pen` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `entered_moqi` is reached before moving to the next scene.

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

| Step | Command | Expected live-window observation |
| ---: | --- | --- |
| 1 | `inspect phone` | `phone` dialogue/action resolves and any flags are reflected in status |
| 2 | `inspect sign` | `sign` dialogue/action resolves and any flags are reflected in status |
| 3 | `inspect city` | `city` dialogue/action resolves and any flags are reflected in status |
| 4 | `inspect pen` | `pen` dialogue/action resolves and any flags are reflected in status |
| 5 | `go camp` | location changes to `camp` and action menu regains focus |
| 6 | `inspect xiaoyan` | `xiaoyan` dialogue/action resolves and any flags are reflected in status |
| 7 | `inspect notice` | `notice` dialogue/action resolves and any flags are reflected in status |
| 8 | `inspect deer_tracks` | `deer_tracks` dialogue/action resolves and any flags are reflected in status |
| 9 | `go chase` | location changes to `chase` and action menu regains focus |
| 10 | `inspect soldiers` | `soldiers` dialogue/action resolves and any flags are reflected in status |
| 11 | `inspect gate` | `gate` dialogue/action resolves and any flags are reflected in status |
| 12 | `inspect xiali` | `xiali` dialogue/action resolves and any flags are reflected in status |
| 13 | `go station` | location changes to `station` and action menu regains focus |
| 14 | `inspect strokes` | `strokes` dialogue/action resolves and any flags are reflected in status |
| 15 | `inspect xiaoyan` | `xiaoyan` dialogue/action resolves and any flags are reflected in status |
| 16 | `write name` | combat action `write name` advances without losing input focus |
| 17 | `write name` | combat action `write name` advances without losing input focus |
| 18 | `write name` | combat action `write name` advances without losing input focus |
| 19 | `attack` | screen responds without input deadlock |
| 20 | `attack` | screen responds without input deadlock |
| 21 | `write name` | combat action `write name` advances without losing input focus |
| 22 | `attack` | screen responds without input deadlock |
| 23 | `attack` | screen responds without input deadlock |
| 24 | `inspect broken_nameplate` | `broken_nameplate` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `defeated_nameless` is reached before moving to the next scene.

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

| Step | Command | Expected live-window observation |
| ---: | --- | --- |
| 1 | `inspect wensu` | `wensu` dialogue/action resolves and any flags are reflected in status |
| 2 | `inspect baseline` | `baseline` dialogue/action resolves and any flags are reflected in status |
| 3 | `inspect name` | `name` dialogue/action resolves and any flags are reflected in status |
| 4 | `inspect door` | `door` dialogue/action resolves and any flags are reflected in status |
| 5 | `inspect fire` | `fire` dialogue/action resolves and any flags are reflected in status |
| 6 | `inspect stop` | `stop` dialogue/action resolves and any flags are reflected in status |
| 7 | `go village` | location changes to `village` and action menu regains focus |
| 8 | `inspect well` | `well` dialogue/action resolves and any flags are reflected in status |
| 9 | `inspect first_failure` | `first_failure` dialogue/action resolves and any flags are reflected in status |
| 10 | `inspect ink_well_ray` | `ink_well_ray` dialogue/action resolves and any flags are reflected in status |
| 11 | `inspect villagers` | `villagers` dialogue/action resolves and any flags are reflected in status |
| 12 | `engage contract_patrol` | encounter `contract_patrol` starts and resolves through the authored branch |
| 13 | `cast stop` | glyph `stop` resolves with readable feedback |
| 14 | `cast fire` | glyph `fire` resolves with readable feedback |
| 15 | `cast name` | glyph `name` resolves with readable feedback |
| 16 | `go archive` | location changes to `archive` and action menu regains focus |
| 17 | `inspect layers` | `layers` dialogue/action resolves and any flags are reflected in status |
| 18 | `inspect margins` | `margins` dialogue/action resolves and any flags are reflected in status |
| 19 | `inspect cabinet` | `cabinet` dialogue/action resolves and any flags are reflected in status |
| 20 | `cast door` | glyph `door` resolves with readable feedback |
| 21 | `go node` | location changes to `node` and action menu regains focus |
| 22 | `inspect contract` | `contract` dialogue/action resolves and any flags are reflected in status |
| 23 | `inspect contract_hound` | `contract_hound` dialogue/action resolves and any flags are reflected in status |
| 24 | `write name` | combat action `write name` advances without losing input focus |
| 25 | `cast door` | glyph `door` resolves with readable feedback |
| 26 | `cast stop` | glyph `stop` resolves with readable feedback |
| 27 | `attack` | screen responds without input deadlock |
| 28 | `attack` | screen responds without input deadlock |
| 29 | `attack` | screen responds without input deadlock |
| 30 | `cast name` | glyph `name` resolves with readable feedback |
| 31 | `cast stop` | glyph `stop` resolves with readable feedback |
| 32 | `cast fire` | glyph `fire` resolves with readable feedback |
| 33 | `inspect mother_annotation` | `mother_annotation` dialogue/action resolves and any flags are reflected in status |
| 34 | `inspect record` | `record` dialogue/action resolves and any flags are reflected in status |

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

| Step | Command | Expected live-window observation |
| ---: | --- | --- |
| 1 | `inspect order` | `order` dialogue/action resolves and any flags are reflected in status |
| 2 | `inspect market` | `market` dialogue/action resolves and any flags are reflected in status |
| 3 | `inspect poster` | `poster` dialogue/action resolves and any flags are reflected in status |
| 4 | `go library` | location changes to `library` and action menu regains focus |
| 5 | `inspect records` | `records` dialogue/action resolves and any flags are reflected in status |
| 6 | `inspect letters` | `letters` dialogue/action resolves and any flags are reflected in status |
| 7 | `inspect ban` | `ban` dialogue/action resolves and any flags are reflected in status |
| 8 | `choose public` | choice `public` resolves and returns to exploration |
| 9 | `go hq` | location changes to `hq` and action menu regains focus |
| 10 | `inspect logs` | `logs` dialogue/action resolves and any flags are reflected in status |
| 11 | `inspect transcripts` | `transcripts` dialogue/action resolves and any flags are reflected in status |
| 12 | `inspect names` | `names` dialogue/action resolves and any flags are reflected in status |
| 13 | `go palace` | location changes to `palace` and action menu regains focus |
| 14 | `inspect route` | `route` dialogue/action resolves and any flags are reflected in status |
| 15 | `inspect ash_wall` | `ash_wall` dialogue/action resolves and any flags are reflected in status |
| 16 | `inspect xiali` | `xiali` dialogue/action resolves and any flags are reflected in status |
| 17 | `go hall` | location changes to `hall` and action menu regains focus |
| 18 | `inspect question` | `question` dialogue/action resolves and any flags are reflected in status |
| 19 | `inspect statebook_remnant` | `statebook_remnant` dialogue/action resolves and any flags are reflected in status |
| 20 | `write name` | combat action `write name` advances without losing input focus |
| 21 | `cast door` | glyph `door` resolves with readable feedback |
| 22 | `cast stop` | glyph `stop` resolves with readable feedback |
| 23 | `inspect answer` | `answer` dialogue/action resolves and any flags are reflected in status |
| 24 | `attack` | screen responds without input deadlock |
| 25 | `attack` | screen responds without input deadlock |
| 26 | `attack` | screen responds without input deadlock |
| 27 | `attack` | screen responds without input deadlock |
| 28 | `cast door` | glyph `door` resolves with readable feedback |
| 29 | `inspect plan` | `plan` dialogue/action resolves and any flags are reflected in status |

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

| Step | Command | Expected live-window observation |
| ---: | --- | --- |
| 1 | `inspect members` | `members` dialogue/action resolves and any flags are reflected in status |
| 2 | `inspect charter` | `charter` dialogue/action resolves and any flags are reflected in status |
| 3 | `inspect noble_observer` | `noble_observer` dialogue/action resolves and any flags are reflected in status |
| 4 | `build institute` | build `institute` resolves with readable feedback |
| 5 | `build dictionary` | build `dictionary` resolves with readable feedback |
| 6 | `go school` | location changes to `school` and action menu regains focus |
| 7 | `inspect class` | `class` dialogue/action resolves and any flags are reflected in status |
| 8 | `inspect mistake` | `mistake` dialogue/action resolves and any flags are reflected in status |
| 9 | `build school` | build `school` resolves with readable feedback |
| 10 | `go workshop` | location changes to `workshop` and action menu regains focus |
| 11 | `inspect atang` | `atang` dialogue/action resolves and any flags are reflected in status |
| 12 | `inspect flood` | `flood` dialogue/action resolves and any flags are reflected in status |
| 13 | `build workflow` | build `workflow` resolves with readable feedback |
| 14 | `go mine` | location changes to `mine` and action menu regains focus |
| 15 | `inspect hazard` | `hazard` dialogue/action resolves and any flags are reflected in status |
| 16 | `cast stop` | glyph `stop` resolves with readable feedback |
| 17 | `build safety` | build `safety` resolves with readable feedback |
| 18 | `inspect safety_board` | `safety_board` dialogue/action resolves and any flags are reflected in status |
| 19 | `go tower` | location changes to `tower` and action menu regains focus |
| 20 | `inspect array` | `array` dialogue/action resolves and any flags are reflected in status |
| 21 | `build comms` | build `comms` resolves with readable feedback |
| 22 | `go seal_tower` | location changes to `seal_tower` and action menu regains focus |
| 23 | `inspect students` | `students` dialogue/action resolves and any flags are reflected in status |
| 24 | `inspect dictionary` | `dictionary` dialogue/action resolves and any flags are reflected in status |
| 25 | `build protect` | build `protect` resolves with readable feedback |
| 26 | `write name` | combat action `write name` advances without losing input focus |
| 27 | `cast stop` | glyph `stop` resolves with readable feedback |
| 28 | `attack` | screen responds without input deadlock |
| 29 | `attack` | screen responds without input deadlock |
| 30 | `write name` | combat action `write name` advances without losing input focus |
| 31 | `attack` | screen responds without input deadlock |
| 32 | `attack` | screen responds without input deadlock |
| 33 | `build archive` | build `archive` resolves with readable feedback |

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

| Step | Command | Expected live-window observation |
| ---: | --- | --- |
| 1 | `inspect teachers` | `teachers` dialogue/action resolves and any flags are reflected in status |
| 2 | `inspect wensu_book` | `wensu_book` dialogue/action resolves and any flags are reflected in status |
| 3 | `inspect wensu_absence` | `wensu_absence` dialogue/action resolves and any flags are reflected in status |
| 4 | `inspect night_school` | `night_school` dialogue/action resolves and any flags are reflected in status |
| 5 | `build industry` | build `industry` resolves with readable feedback |
| 6 | `inspect atang_blueprint` | `atang_blueprint` dialogue/action resolves and any flags are reflected in status |
| 7 | `go network` | location changes to `network` and action menu regains focus |
| 8 | `inspect xiali` | `xiali` dialogue/action resolves and any flags are reflected in status |
| 9 | `inspect xiali_fading` | `xiali_fading` dialogue/action resolves and any flags are reflected in status |
| 10 | `inspect private_anchor` | `private_anchor` dialogue/action resolves and any flags are reflected in status |
| 11 | `build bind_xiali` | build `bind_xiali` resolves with readable feedback |
| 12 | `inspect engineers` | `engineers` dialogue/action resolves and any flags are reflected in status |
| 13 | `inspect remote_classrooms` | `remote_classrooms` dialogue/action resolves and any flags are reflected in status |
| 14 | `inspect xiaoyan_roll_call` | `xiaoyan_roll_call` dialogue/action resolves and any flags are reflected in status |
| 15 | `build network` | build `network` resolves with readable feedback |
| 16 | `go astral` | location changes to `astral` and action menu regains focus |
| 17 | `inspect star_map` | `star_map` dialogue/action resolves and any flags are reflected in status |
| 18 | `inspect coordinate_standard` | `coordinate_standard` dialogue/action resolves and any flags are reflected in status |
| 19 | `inspect beacon` | `beacon` dialogue/action resolves and any flags are reflected in status |
| 20 | `inspect failed_signal` | `failed_signal` dialogue/action resolves and any flags are reflected in status |
| 21 | `inspect star_chart_moth` | `star_chart_moth` dialogue/action resolves and any flags are reflected in status |
| 22 | `build astral_tower` | build `astral_tower` resolves with readable feedback |
| 23 | `go star_tower` | location changes to `star_tower` and action menu regains focus |
| 24 | `inspect signal` | `signal` dialogue/action resolves and any flags are reflected in status |
| 25 | `inspect silent_frame` | `silent_frame` dialogue/action resolves and any flags are reflected in status |
| 26 | `write name` | combat action `write name` advances without losing input focus |
| 27 | `cast stop` | glyph `stop` resolves with readable feedback |
| 28 | `attack` | screen responds without input deadlock |
| 29 | `attack` | screen responds without input deadlock |
| 30 | `write name` | combat action `write name` advances without losing input focus |
| 31 | `attack` | screen responds without input deadlock |
| 32 | `attack` | screen responds without input deadlock |
| 33 | `inspect city` | `city` dialogue/action resolves and any flags are reflected in status |

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

| Step | Command | Expected live-window observation |
| ---: | --- | --- |
| 1 | `inspect disaster` | `disaster` dialogue/action resolves and any flags are reflected in status |
| 2 | `inspect parents` | `parents` dialogue/action resolves and any flags are reflected in status |
| 3 | `go council` | location changes to `council` and action menu regains focus |
| 4 | `inspect supporters` | `supporters` dialogue/action resolves and any flags are reflected in status |
| 5 | `inspect opposition` | `opposition` dialogue/action resolves and any flags are reflected in status |
| 6 | `inspect risk_ledger` | `risk_ledger` dialogue/action resolves and any flags are reflected in status |
| 7 | `build mandate` | build `mandate` resolves with readable feedback |
| 8 | `go dockyard` | location changes to `dockyard` and action menu regains focus |
| 9 | `inspect blueprint` | `blueprint` dialogue/action resolves and any flags are reflected in status |
| 10 | `build vessel` | build `vessel` resolves with readable feedback |
| 11 | `inspect empty_seats` | `empty_seats` dialogue/action resolves and any flags are reflected in status |
| 12 | `go core` | location changes to `core` and action menu regains focus |
| 13 | `inspect xiali` | `xiali` dialogue/action resolves and any flags are reflected in status |
| 14 | `inspect backup` | `backup` dialogue/action resolves and any flags are reflected in status |
| 15 | `build backups` | build `backups` resolves with readable feedback |
| 16 | `inspect backup_drill` | `backup_drill` dialogue/action resolves and any flags are reflected in status |
| 17 | `go gate` | location changes to `gate` and action menu regains focus |
| 18 | `inspect calibration` | `calibration` dialogue/action resolves and any flags are reflected in status |
| 19 | `build gate` | build `gate` resolves with readable feedback |
| 20 | `inspect farewell` | `farewell` dialogue/action resolves and any flags are reflected in status |
| 21 | `go rift` | location changes to `rift` and action menu regains focus |
| 22 | `inspect probe` | `probe` dialogue/action resolves and any flags are reflected in status |
| 23 | `inspect probe_body` | `probe_body` dialogue/action resolves and any flags are reflected in status |
| 24 | `write name` | combat action `write name` advances without losing input focus |
| 25 | `cast stop` | glyph `stop` resolves with readable feedback |
| 26 | `attack` | screen responds without input deadlock |
| 27 | `attack` | screen responds without input deadlock |
| 28 | `write name` | combat action `write name` advances without losing input focus |
| 29 | `attack` | screen responds without input deadlock |
| 30 | `attack` | screen responds without input deadlock |
| 31 | `write name` | combat action `write name` advances without losing input focus |
| 32 | `attack` | screen responds without input deadlock |
| 33 | `inspect truth` | `truth` dialogue/action resolves and any flags are reflected in status |
| 34 | `build return` | build `return` resolves with readable feedback |

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

| Step | Command | Expected live-window observation |
| ---: | --- | --- |
| 1 | `inspect room` | `room` dialogue/action resolves and any flags are reflected in status |
| 2 | `inspect parents_echo` | `parents_echo` dialogue/action resolves and any flags are reflected in status |
| 3 | `inspect city_first` | `city_first` dialogue/action resolves and any flags are reflected in status |
| 4 | `inspect contacts` | `contacts` dialogue/action resolves and any flags are reflected in status |
| 5 | `go school` | location changes to `school` and action menu regains focus |
| 6 | `inspect corridor` | `corridor` dialogue/action resolves and any flags are reflected in status |
| 7 | `inspect missing_teacher` | `missing_teacher` dialogue/action resolves and any flags are reflected in status |
| 8 | `inspect classmates` | `classmates` dialogue/action resolves and any flags are reflected in status |
| 9 | `inspect xiaoyan_name_sample` | `xiaoyan_name_sample` dialogue/action resolves and any flags are reflected in status |
| 10 | `go street` | location changes to `street` and action menu regains focus |
| 11 | `inspect grid` | `grid` dialogue/action resolves and any flags are reflected in status |
| 12 | `inspect neighbors` | `neighbors` dialogue/action resolves and any flags are reflected in status |
| 13 | `build lights` | build `lights` resolves with readable feedback |
| 14 | `inspect node_base` | `node_base` dialogue/action resolves and any flags are reflected in status |
| 15 | `build node` | build `node` resolves with readable feedback |
| 16 | `inspect bridge_traveler_reflection` | `bridge_traveler_reflection` dialogue/action resolves and any flags are reflected in status |
| 17 | `inspect atang_bridge_fuse` | `atang_bridge_fuse` dialogue/action resolves and any flags are reflected in status |
| 18 | `go store` | location changes to `store` and action menu regains focus |
| 19 | `inspect clerk` | `clerk` dialogue/action resolves and any flags are reflected in status |
| 20 | `cast name` | glyph `name` resolves with readable feedback |
| 21 | `inspect receipt` | `receipt` dialogue/action resolves and any flags are reflected in status |
| 22 | `go street` | location changes to `street` and action menu regains focus |
| 23 | `go lab` | location changes to `lab` and action menu regains focus |
| 24 | `inspect formula` | `formula` dialogue/action resolves and any flags are reflected in status |
| 25 | `inspect beacon` | `beacon` dialogue/action resolves and any flags are reflected in status |
| 26 | `build modern_node` | build `modern_node` resolves with readable feedback |
| 27 | `inspect parents_record` | `parents_record` dialogue/action resolves and any flags are reflected in status |
| 28 | `inspect wensu_margin_note` | `wensu_margin_note` dialogue/action resolves and any flags are reflected in status |
| 29 | `inspect failed_bridge_test` | `failed_bridge_test` dialogue/action resolves and any flags are reflected in status |
| 30 | `inspect traveler_warning` | `traveler_warning` dialogue/action resolves and any flags are reflected in status |
| 31 | `build bridge` | build `bridge` resolves with readable feedback |
| 32 | `go orbit` | location changes to `orbit` and action menu regains focus |
| 33 | `inspect protocol` | `protocol` dialogue/action resolves and any flags are reflected in status |
| 34 | `inspect protocol_indictment` | `protocol_indictment` dialogue/action resolves and any flags are reflected in status |
| 35 | `inspect deleted_party_names` | `deleted_party_names` dialogue/action resolves and any flags are reflected in status |
| 36 | `inspect counter_evidence` | `counter_evidence` dialogue/action resolves and any flags are reflected in status |
| 37 | `build restore` | build `restore` resolves with readable feedback |
| 38 | `inspect civilization_response` | `civilization_response` dialogue/action resolves and any flags are reflected in status |
| 39 | `write name` | combat action `write name` advances without losing input focus |
| 40 | `cast stop` | glyph `stop` resolves with readable feedback |
| 41 | `attack` | screen responds without input deadlock |
| 42 | `attack` | screen responds without input deadlock |
| 43 | `write name` | combat action `write name` advances without losing input focus |
| 44 | `attack` | screen responds without input deadlock |
| 45 | `attack` | screen responds without input deadlock |
| 46 | `write name` | combat action `write name` advances without losing input focus |
| 47 | `attack` | screen responds without input deadlock |
| 48 | `combine continue` | combo `continue` resolves with readable feedback |
| 49 | `go lab` | location changes to `lab` and action menu regains focus |
| 50 | `inspect parent_bridge_trace` | `parent_bridge_trace` dialogue/action resolves and any flags are reflected in status |

Scene acceptance:

- [ ] Scene starts from the expected location after previous scene completion.
- [ ] Dialogic text can be advanced with Enter/Space or click when dialogue is active.
- [ ] Action menu focus returns after each dialogue/action payload.
- [ ] Pause, resume, save, and return-to-title do not corrupt the current scene.
- [ ] Ending flag `found_parent_bridge_trace` is reached before moving to the next scene.

