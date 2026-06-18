# Nova Audio Listening QA

This checklist is generated from `data/audio_cues/*.json` and
`data/action_voice_lines/*.json` by
`tools/build_audio_listening_checklist.py`. It is a human listening aid, not an
automatic approval result.

Recommended technical gate before listening:

```sh
python3 tools/run_automated_tests.py --only audio-mix-audit
```

That gate checks files, Godot import metadata, duration ranges, and obvious
volume problems. This checklist covers the creative listening pass that still
requires human judgement.

Global acceptance:

- [ ] Listen with game-like volume, not only Finder preview volume.
- [ ] Check each scene once with music/ambience alone and once under action text.
- [ ] Confirm SFX do not become tiring after repeated movement/action triggers.
- [ ] Confirm generated voices are intelligible and match character direction.
- [ ] Record replacements or mastering notes before marking the scene done.

Coverage summary:

- Generated/listening assets: 151
- Planned or disabled assets skipped: 198
- `action_voice`: 28
- `ambience`: 2
- `music`: 35
- `sfx`: 60
- `stinger`: 1
- `voice_sample`: 25

## 00-prologue-lights-out - 序幕：灯未亮起的夜晚

- Assets to audition: 11

| Done | Asset | Type | Use | File status | Listening checks |
| --- | --- | --- | --- | --- | --- |
| [ ] | `AVL-00-001`<br>`assets/audio/generated/action_voices/00-prologue-lights-out/AVL-00-001.mp3` | action_voice | street.inspect.window / 自家窗户 / 纪子轩 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-00-002`<br>`assets/audio/generated/action_voices/00-prologue-lights-out/AVL-00-002.mp3` | action_voice | street.inspect.window / 自家窗户 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-00-003`<br>`assets/audio/generated/action_voices/00-prologue-lights-out/AVL-00-003.mp3` | action_voice | street.inspect.poster / 寻人启事 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AMB-00-001`<br>`assets/audio/generated/music/00-prologue-lights-out/AMB-00-001.mp3` | ambience | loop_under_exploration | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `AMB-00-002`<br>`assets/audio/generated/music/00-prologue-lights-out/AMB-00-002.mp3` | ambience | short_loop_until_home_entry | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `SFX-00-BLACKOUT`<br>`assets/audio/generated/sfx/00-prologue-lights-out/SFX-00-BLACKOUT.mp3` | sfx | success: bedroom | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-00-INSPECT-HOME`<br>`assets/audio/generated/sfx/00-prologue-lights-out/SFX-00-INSPECT-HOME.mp3` | sfx | interact: street, building, home, living_room, study | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-00-INSPECT-LETTER`<br>`assets/audio/generated/sfx/00-prologue-lights-out/SFX-00-INSPECT-LETTER.mp3` | sfx | interact: bedroom | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-00-STEP-INTERIOR`<br>`assets/audio/generated/sfx/00-prologue-lights-out/SFX-00-STEP-INTERIOR.mp3` | sfx | step: building, home, living_room, study, bedroom | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-00-STEP-STREET`<br>`assets/audio/generated/sfx/00-prologue-lights-out/SFX-00-STEP-STREET.mp3` | sfx | step: street | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `STG-00-001`<br>`assets/audio/generated/music/00-prologue-lights-out/STG-00-001.mp3` | stinger | one_shot_transition_to_moqi | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.

## 01-illiterate - 第一幕：不会写字的人

- Assets to audition: 16

| Done | Asset | Type | Use | File status | Listening checks |
| --- | --- | --- | --- | --- | --- |
| [ ] | `AVL-01-001`<br>`assets/audio/generated/action_voices/01-illiterate/AVL-01-001.mp3` | action_voice | mud_road.inspect.phone / 手机 / 纪子轩 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-01-002`<br>`assets/audio/generated/action_voices/01-illiterate/AVL-01-002.mp3` | action_voice | mud_road.inspect.phone / 手机 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-01-003`<br>`assets/audio/generated/action_voices/01-illiterate/AVL-01-003.mp3` | action_voice | mud_road.inspect.sign / 破损路牌 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-01-004`<br>`assets/audio/generated/action_voices/01-illiterate/AVL-01-004.mp3` | action_voice | mud_road.inspect.city / 燃烧的城 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-01-005`<br>`assets/audio/generated/action_voices/01-illiterate/AVL-01-005.mp3` | action_voice | mud_road.inspect.pen / 黑色钢笔 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `MUS-01-001`<br>`assets/audio/generated/music/01-illiterate/MUS-01-001.mp3` | music | loop_from_mud_road_to_camp | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-01-002`<br>`assets/audio/generated/music/01-illiterate/MUS-01-002.mp3` | music | loop_until_xiali_reveal | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-01-003`<br>`assets/audio/generated/music/01-illiterate/MUS-01-003.mp3` | music | loop_during_name_tutorial_battle | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `SFX-01-BLADE-HIT`<br>`assets/audio/generated/sfx/01-illiterate/SFX-01-BLADE-HIT.mp3` | sfx | attack: station | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-01-INK-WRITE`<br>`assets/audio/generated/sfx/01-illiterate/SFX-01-INK-WRITE.mp3` | sfx | write: station | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-01-PAPER-INTERACT`<br>`assets/audio/generated/sfx/01-illiterate/SFX-01-PAPER-INTERACT.mp3` | sfx | interact: mud_road, camp, chase, station | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-01-STEP-MUD`<br>`assets/audio/generated/sfx/01-illiterate/SFX-01-STEP-MUD.mp3` | sfx | step: mud_road, camp, chase | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-01-STEP-WOOD`<br>`assets/audio/generated/sfx/01-illiterate/SFX-01-STEP-WOOD.mp3` | sfx | step: station | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `DLG-01-SAMPLE-JZX`<br>`assets/audio/generated/voices/01-illiterate/DLG-01-SAMPLE-JZX.mp3` | voice_sample | jizi_xuan | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-01-SAMPLE-XL`<br>`assets/audio/generated/voices/01-illiterate/DLG-01-SAMPLE-XL.mp3` | voice_sample | xiali | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-01-SAMPLE-XY`<br>`assets/audio/generated/voices/01-illiterate/DLG-01-SAMPLE-XY.mp3` | voice_sample | xiaoyan | file+import | pronunciation, cadence, character fit, dialogue intelligibility |

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.

## 02-moqi-academy - 第二幕：墨颀书院

- Assets to audition: 20

| Done | Asset | Type | Use | File status | Listening checks |
| --- | --- | --- | --- | --- | --- |
| [ ] | `AVL-02-001`<br>`assets/audio/generated/action_voices/02-moqi-academy/AVL-02-001.mp3` | action_voice | academy.inspect.wensu / 闻素 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-02-002`<br>`assets/audio/generated/action_voices/02-moqi-academy/AVL-02-002.mp3` | action_voice | academy.inspect.baseline / 闻素的基线测试 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-02-003`<br>`assets/audio/generated/action_voices/02-moqi-academy/AVL-02-003.mp3` | action_voice | academy.inspect.name / 名 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-02-004`<br>`assets/audio/generated/action_voices/02-moqi-academy/AVL-02-004.mp3` | action_voice | academy.inspect.door / 门 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-02-005`<br>`assets/audio/generated/action_voices/02-moqi-academy/AVL-02-005.mp3` | action_voice | academy.inspect.fire / 火 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `MUS-02-001`<br>`assets/audio/generated/music/02-moqi-academy/MUS-02-001.mp3` | music | loop_while_learning_basic_glyphs | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-02-003`<br>`assets/audio/generated/music/02-moqi-academy/MUS-02-003.mp3` | music | loop_while_reading_dictionary_margins | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-02-004`<br>`assets/audio/generated/music/02-moqi-academy/MUS-02-004.mp3` | music | loop_until_first_node_repaired | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `SFX-02-CAST-DOOR`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-CAST-DOOR.mp3` | sfx | cast_door: archive, node | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-02-CAST-FIRE`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-CAST-FIRE.mp3` | sfx | cast_fire: village, node | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-02-CAST-NAME`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-CAST-NAME.mp3` | sfx | cast_name: village, node | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-02-CAST-STOP`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-CAST-STOP.mp3` | sfx | cast_stop: village, node | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-02-CONTRACT-ENGAGE`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-CONTRACT-ENGAGE.mp3` | sfx | engage: village, node | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-02-CONTRACT-HIT`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-CONTRACT-HIT.mp3` | sfx | attack: node | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-02-PAPER-INSPECT`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-PAPER-INSPECT.mp3` | sfx | interact: academy, village, archive, node | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-02-STEP-STONE`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-STEP-STONE.mp3` | sfx | step: academy, archive, node | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-02-STEP-VILLAGE`<br>`assets/audio/generated/sfx/02-moqi-academy/SFX-02-STEP-VILLAGE.mp3` | sfx | step: village | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `DLG-02-SAMPLE-MOM`<br>`assets/audio/generated/voices/02-moqi-academy/DLG-02-SAMPLE-MOM.mp3` | voice_sample | jizi_xuan_mother | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-02-SAMPLE-WS`<br>`assets/audio/generated/voices/02-moqi-academy/DLG-02-SAMPLE-WS.mp3` | voice_sample | wensu | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-02-SAMPLE-XL`<br>`assets/audio/generated/voices/02-moqi-academy/DLG-02-SAMPLE-XL.mp3` | voice_sample | xiali | file+import | pronunciation, cadence, character fit, dialogue intelligibility |

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.

## 03-dead-kingdom - 第三幕：死去的王国

- Assets to audition: 20

| Done | Asset | Type | Use | File status | Listening checks |
| --- | --- | --- | --- | --- | --- |
| [ ] | `AVL-03-001`<br>`assets/audio/generated/action_voices/03-dead-kingdom/AVL-03-001.mp3` | action_voice | outer_city.inspect.order / 死城秩序 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-03-002`<br>`assets/audio/generated/action_voices/03-dead-kingdom/AVL-03-002.mp3` | action_voice | outer_city.inspect.market / 没有买主的集市 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-03-003`<br>`assets/audio/generated/action_voices/03-dead-kingdom/AVL-03-003.mp3` | action_voice | outer_city.inspect.poster / 罪人告示 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-03-004`<br>`assets/audio/generated/action_voices/03-dead-kingdom/AVL-03-004.mp3` | action_voice | library.inspect.records / 改革文献 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-03-005`<br>`assets/audio/generated/action_voices/03-dead-kingdom/AVL-03-005.mp3` | action_voice | library.inspect.letters / 学生退回的信 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `MUS-03-001`<br>`assets/audio/generated/music/03-dead-kingdom/MUS-03-001.mp3` | music | loop_while_exploring_dead_outer_city | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-03-002`<br>`assets/audio/generated/music/03-dead-kingdom/MUS-03-002.mp3` | music | loop_while_resolving_book_route | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-03-003`<br>`assets/audio/generated/music/03-dead-kingdom/MUS-03-003.mp3` | music | loop_while_reading_lockdown_records | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-03-004`<br>`assets/audio/generated/music/03-dead-kingdom/MUS-03-004.mp3` | music | loop_while_reconstructing_fall_route | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-03-005`<br>`assets/audio/generated/music/03-dead-kingdom/MUS-03-005.mp3` | music | loop_until_statebook_core_opened | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `SFX-03-CAST-DOOR`<br>`assets/audio/generated/sfx/03-dead-kingdom/SFX-03-CAST-DOOR.mp3` | sfx | cast_door: hall | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-03-CAST-STOP`<br>`assets/audio/generated/sfx/03-dead-kingdom/SFX-03-CAST-STOP.mp3` | sfx | cast_stop: hall | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-03-RECORD-INSPECT`<br>`assets/audio/generated/sfx/03-dead-kingdom/SFX-03-RECORD-INSPECT.mp3` | sfx | interact: outer_city, library, hq, palace, hall | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-03-ROYAL-HIT`<br>`assets/audio/generated/sfx/03-dead-kingdom/SFX-03-ROYAL-HIT.mp3` | sfx | attack: hall | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-03-STEP-CITY`<br>`assets/audio/generated/sfx/03-dead-kingdom/SFX-03-STEP-CITY.mp3` | sfx | step: outer_city, hq | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-03-STEP-RUIN`<br>`assets/audio/generated/sfx/03-dead-kingdom/SFX-03-STEP-RUIN.mp3` | sfx | step: library, palace, hall | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-03-WRITE-NAME`<br>`assets/audio/generated/sfx/03-dead-kingdom/SFX-03-WRITE-NAME.mp3` | sfx | write: hall | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `DLG-03-SAMPLE-DAD`<br>`assets/audio/generated/voices/03-dead-kingdom/DLG-03-SAMPLE-DAD.mp3` | voice_sample | jizi_xuan_father | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-03-SAMPLE-MOM`<br>`assets/audio/generated/voices/03-dead-kingdom/DLG-03-SAMPLE-MOM.mp3` | voice_sample | jizi_xuan_mother | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-03-SAMPLE-XL`<br>`assets/audio/generated/voices/03-dead-kingdom/DLG-03-SAMPLE-XL.mp3` | voice_sample | xiali | file+import | pronunciation, cadence, character fit, dialogue intelligibility |

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.

## 04-continuation-institute - 第四幕：续文院

- Assets to audition: 22

| Done | Asset | Type | Use | File status | Listening checks |
| --- | --- | --- | --- | --- | --- |
| [ ] | `AVL-04-001`<br>`assets/audio/generated/action_voices/04-continuation-institute/AVL-04-001.mp3` | action_voice | institute.inspect.members / 第一批成员 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-04-002`<br>`assets/audio/generated/action_voices/04-continuation-institute/AVL-04-002.mp3` | action_voice | institute.inspect.charter / 续文院章程 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-04-003`<br>`assets/audio/generated/action_voices/04-continuation-institute/AVL-04-003.mp3` | action_voice | institute.inspect.noble_observer / 贵族旁听者 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-04-004`<br>`assets/audio/generated/action_voices/04-continuation-institute/AVL-04-004.mp3` | action_voice | institute.build.institute / institute / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-04-005`<br>`assets/audio/generated/action_voices/04-continuation-institute/AVL-04-005.mp3` | action_voice | institute.build.dictionary / dictionary / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `MUS-04-001`<br>`assets/audio/generated/music/04-continuation-institute/MUS-04-001.mp3` | music | loop_while_founding_institute | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-04-002`<br>`assets/audio/generated/music/04-continuation-institute/MUS-04-002.mp3` | music | loop_while_first_school_opens | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-04-003`<br>`assets/audio/generated/music/04-continuation-institute/MUS-04-003.mp3` | music | loop_while_repair_workflow | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-04-004`<br>`assets/audio/generated/music/04-continuation-institute/MUS-04-004.mp3` | music | loop_while_solving_mine_safety | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-04-005`<br>`assets/audio/generated/music/04-continuation-institute/MUS-04-005.mp3` | music | loop_while_restoring_comms | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-04-006`<br>`assets/audio/generated/music/04-continuation-institute/MUS-04-006.mp3` | music | loop_until_archive_tower_built | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `SFX-04-BUILD-CIVIC`<br>`assets/audio/generated/sfx/04-continuation-institute/SFX-04-BUILD-CIVIC.mp3` | sfx | build: institute, school, workshop, mine, tower, seal_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-04-CAST-STOP`<br>`assets/audio/generated/sfx/04-continuation-institute/SFX-04-CAST-STOP.mp3` | sfx | cast_stop: mine, seal_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-04-INSPECT-BOARD`<br>`assets/audio/generated/sfx/04-continuation-institute/SFX-04-INSPECT-BOARD.mp3` | sfx | interact: institute, school, workshop, mine, tower, seal_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-04-SEAL-HIT`<br>`assets/audio/generated/sfx/04-continuation-institute/SFX-04-SEAL-HIT.mp3` | sfx | attack: seal_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-04-STEP-CIVIC`<br>`assets/audio/generated/sfx/04-continuation-institute/SFX-04-STEP-CIVIC.mp3` | sfx | step: institute, school, tower, seal_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-04-STEP-WORK`<br>`assets/audio/generated/sfx/04-continuation-institute/SFX-04-STEP-WORK.mp3` | sfx | step: workshop, mine | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-04-WRITE-NAME`<br>`assets/audio/generated/sfx/04-continuation-institute/SFX-04-WRITE-NAME.mp3` | sfx | write: seal_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `DLG-04-SAMPLE-AT`<br>`assets/audio/generated/voices/04-continuation-institute/DLG-04-SAMPLE-AT.mp3` | voice_sample | atang | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-04-SAMPLE-WS`<br>`assets/audio/generated/voices/04-continuation-institute/DLG-04-SAMPLE-WS.mp3` | voice_sample | wensu | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-04-SAMPLE-XL`<br>`assets/audio/generated/voices/04-continuation-institute/DLG-04-SAMPLE-XL.mp3` | voice_sample | xiali | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-04-SAMPLE-XY`<br>`assets/audio/generated/voices/04-continuation-institute/DLG-04-SAMPLE-XY.mp3` | voice_sample | xiaoyan | file+import | pronunciation, cadence, character fit, dialogue intelligibility |

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.

## 05-century-continuation - 第五幕：百年续页

- Assets to audition: 24

| Done | Asset | Type | Use | File status | Listening checks |
| --- | --- | --- | --- | --- | --- |
| [ ] | `AVL-05-001`<br>`assets/audio/generated/action_voices/05-century-continuation/AVL-05-001.mp3` | action_voice | industry.inspect.teachers / 第一批教师 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-05-002`<br>`assets/audio/generated/action_voices/05-century-continuation/AVL-05-002.mp3` | action_voice | industry.inspect.wensu_book / 闻素教材 / 旁白 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-05-003`<br>`assets/audio/generated/action_voices/05-century-continuation/AVL-05-003.mp3` | action_voice | industry.inspect.wensu_absence / 闻素的空椅 / 纪子轩 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-05-004`<br>`assets/audio/generated/action_voices/05-century-continuation/AVL-05-004.mp3` | action_voice | industry.inspect.wensu_absence / 闻素的空椅 / 闻素 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `AVL-05-005`<br>`assets/audio/generated/action_voices/05-century-continuation/AVL-05-005.mp3` | action_voice | industry.inspect.wensu_absence / 闻素的空椅 / 纪子轩 | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `MUS-05-001`<br>`assets/audio/generated/music/05-century-continuation/MUS-05-001.mp3` | music | loop_while_text_industry_expands | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-05-002`<br>`assets/audio/generated/music/05-century-continuation/MUS-05-002.mp3` | music | loop_while_statebook_network_connects | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-05-003`<br>`assets/audio/generated/music/05-century-continuation/MUS-05-003.mp3` | music | loop_during_xiali_statebook_binding | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-05-004`<br>`assets/audio/generated/music/05-century-continuation/MUS-05-004.mp3` | music | loop_while_astral_engineering_tests | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-05-005`<br>`assets/audio/generated/music/05-century-continuation/MUS-05-005.mp3` | music | loop_while_viewing_modern_star_darkening | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-05-006`<br>`assets/audio/generated/music/05-century-continuation/MUS-05-006.mp3` | music | loop_until_silent_interference_stabilized | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `SFX-05-BEACON-FAIL`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-BEACON-FAIL.mp3` | sfx | interact: astral, star_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-05-BIND-XIALI`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-BIND-XIALI.mp3` | sfx | build: network | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-05-BUILD-SYSTEM`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-BUILD-SYSTEM.mp3` | sfx | build: industry, network, astral | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-05-CAST-STOP`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-CAST-STOP.mp3` | sfx | cast_stop: star_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-05-INSPECT-ARCHIVE`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-INSPECT-ARCHIVE.mp3` | sfx | interact: industry, network, astral, star_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-05-INTERFERENCE-HIT`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-INTERFERENCE-HIT.mp3` | sfx | attack: star_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-05-STEP-INDUSTRY`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-STEP-INDUSTRY.mp3` | sfx | step: industry | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-05-STEP-NODE`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-STEP-NODE.mp3` | sfx | step: network, astral, star_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-05-WRITE-NAME`<br>`assets/audio/generated/sfx/05-century-continuation/SFX-05-WRITE-NAME.mp3` | sfx | write: star_tower | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `DLG-05-SAMPLE-AT`<br>`assets/audio/generated/voices/05-century-continuation/DLG-05-SAMPLE-AT.mp3` | voice_sample | atang | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-05-SAMPLE-JZX`<br>`assets/audio/generated/voices/05-century-continuation/DLG-05-SAMPLE-JZX.mp3` | voice_sample | jizi_xuan | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-05-SAMPLE-WS`<br>`assets/audio/generated/voices/05-century-continuation/DLG-05-SAMPLE-WS.mp3` | voice_sample | wensu | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-05-SAMPLE-XL`<br>`assets/audio/generated/voices/05-century-continuation/DLG-05-SAMPLE-XL.mp3` | voice_sample | xiali | file+import | pronunciation, cadence, character fit, dialogue intelligibility |

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.

## 06-return-star-plan - 第六幕：归星计划

- Assets to audition: 19

| Done | Asset | Type | Use | File status | Listening checks |
| --- | --- | --- | --- | --- | --- |
| [ ] | `MUS-06-001`<br>`assets/audio/generated/music/06-return-star-plan/MUS-06-001.mp3` | music | loop_while_confirming_modern_disaster | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-06-002`<br>`assets/audio/generated/music/06-return-star-plan/MUS-06-002.mp3` | music | loop_while_return_star_council_debates | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-06-003`<br>`assets/audio/generated/music/06-return-star-plan/MUS-06-003.mp3` | music | loop_while_building_return_vessel | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-06-004`<br>`assets/audio/generated/music/06-return-star-plan/MUS-06-004.mp3` | music | loop_while_binding_civilization_backups | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-06-005`<br>`assets/audio/generated/music/06-return-star-plan/MUS-06-005.mp3` | music | loop_while_opening_return_gate | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-06-006`<br>`assets/audio/generated/music/06-return-star-plan/MUS-06-006.mp3` | music | loop_until_invasion_probe_defeated | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `SFX-06-BACKUP-RESTORE`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-BACKUP-RESTORE.mp3` | sfx | cast_stop: core, rift | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-06-BUILD-RETURN`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-BUILD-RETURN.mp3` | sfx | build: council, dockyard, core | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-06-GATE-OPEN`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-GATE-OPEN.mp3` | sfx | build: gate, rift | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-06-INSPECT-LEDGER`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-INSPECT-LEDGER.mp3` | sfx | interact: astral_tower, council, dockyard, core, gate, rift | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-06-PROBE-ERASE`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-PROBE-ERASE.mp3` | sfx | engage: rift | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-06-PROBE-HIT`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-PROBE-HIT.mp3` | sfx | attack: rift | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-06-STEP-ASTRAL`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-STEP-ASTRAL.mp3` | sfx | step: astral_tower, core, gate, rift | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-06-STEP-CIVIC`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-STEP-CIVIC.mp3` | sfx | step: council, dockyard | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-06-WRITE-NAME`<br>`assets/audio/generated/sfx/06-return-star-plan/SFX-06-WRITE-NAME.mp3` | sfx | write: rift | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `DLG-06-SAMPLE-DAD`<br>`assets/audio/generated/voices/06-return-star-plan/DLG-06-SAMPLE-DAD.mp3` | voice_sample | jizi_xuan_father | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-06-SAMPLE-JZX`<br>`assets/audio/generated/voices/06-return-star-plan/DLG-06-SAMPLE-JZX.mp3` | voice_sample | jizi_xuan | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-06-SAMPLE-MOM`<br>`assets/audio/generated/voices/06-return-star-plan/DLG-06-SAMPLE-MOM.mp3` | voice_sample | jizi_xuan_mother | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-06-SAMPLE-XL`<br>`assets/audio/generated/voices/06-return-star-plan/DLG-06-SAMPLE-XL.mp3` | voice_sample | xiali | file+import | pronunciation, cadence, character fit, dialogue intelligibility |

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.

## 07-lights-on-again - 第七幕：灯重新亮起

- Assets to audition: 19

| Done | Asset | Type | Use | File status | Listening checks |
| --- | --- | --- | --- | --- | --- |
| [ ] | `MUS-07-001`<br>`assets/audio/generated/music/07-lights-on-again/MUS-07-001.mp3` | music | loop_while_home_is_half_silenced | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-07-002`<br>`assets/audio/generated/music/07-lights-on-again/MUS-07-002.mp3` | music | loop_while_school_memory_erases | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-07-003`<br>`assets/audio/generated/music/07-lights-on-again/MUS-07-003.mp3` | music | loop_while_city_grid_and_node_recover | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-07-004`<br>`assets/audio/generated/music/07-lights-on-again/MUS-07-004.mp3` | music | loop_while_rescuing_clerk_name | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-07-005`<br>`assets/audio/generated/music/07-lights-on-again/MUS-07-005.mp3` | music | loop_while_stabilizing_return_bridge | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `MUS-07-006`<br>`assets/audio/generated/music/07-lights-on-again/MUS-07-006.mp3` | music | loop_until_silence_protocol_rejected | file+import | loop/entry/exit, mood fit, fatigue, no hot peak |
| [ ] | `SFX-07-BUILD-NODE`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-BUILD-NODE.mp3` | sfx | build: street, lab, orbit | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-07-CAST-NAME`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-CAST-NAME.mp3` | sfx | cast_name: store | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-07-CAST-STOP`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-CAST-STOP.mp3` | sfx | cast_stop: orbit | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-07-CONTINUE`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-CONTINUE.mp3` | sfx | continue: orbit | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-07-INSPECT-MODERN`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-INSPECT-MODERN.mp3` | sfx | interact: home, school, street, store, lab, orbit | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-07-PROTOCOL-HIT`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-PROTOCOL-HIT.mp3` | sfx | attack: orbit | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-07-STEP-MODERN`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-STEP-MODERN.mp3` | sfx | step: home, school, store, lab | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-07-STEP-STREET`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-STEP-STREET.mp3` | sfx | step: street, orbit | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `SFX-07-WRITE-NAME`<br>`assets/audio/generated/sfx/07-lights-on-again/SFX-07-WRITE-NAME.mp3` | sfx | write: orbit | file+import | trigger timing, shortness, repetition, mix under dialogue |
| [ ] | `DLG-07-SAMPLE-DAD`<br>`assets/audio/generated/voices/07-lights-on-again/DLG-07-SAMPLE-DAD.mp3` | voice_sample | jizi_xuan_father | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-07-SAMPLE-JZX`<br>`assets/audio/generated/voices/07-lights-on-again/DLG-07-SAMPLE-JZX.mp3` | voice_sample | jizi_xuan | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-07-SAMPLE-MOM`<br>`assets/audio/generated/voices/07-lights-on-again/DLG-07-SAMPLE-MOM.mp3` | voice_sample | jizi_xuan_mother | file+import | pronunciation, cadence, character fit, dialogue intelligibility |
| [ ] | `DLG-07-SAMPLE-XL`<br>`assets/audio/generated/voices/07-lights-on-again/DLG-07-SAMPLE-XL.mp3` | voice_sample | xiali | file+import | pronunciation, cadence, character fit, dialogue intelligibility |

Scene acceptance:

- [ ] Music/ambience supports the scene mood without masking action text.
- [ ] Repeated SFX remain useful after several menu/action repetitions.
- [ ] Generated voices fit speaker intent and do not fight the UI reading pace.
- [ ] Any rejected file is recorded with asset id, problem, and replacement plan.

