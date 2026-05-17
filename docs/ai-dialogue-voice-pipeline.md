# AI Dialogue And Voice Pipeline

本流程用于把完整剧本资料转成三类可复用资产：

- 角色声音圣经：每个角色的性格、口吻、弧光、建议音色。
- 场景对白草稿：按 scene / location / flag 生成可落到 playable JSON 的对白。
- 语音制作提示：给 TTS 或配音选角使用的抽象音色与表演方向。

## Source Pack

生成时不要只喂某一幕剧情。至少包含这些证据：

- `five/project/seven-act-outline.md`
- `five/people/*.md`
- `five/scene/*.md`
- `five/script/*.md`
- `five/system/art-audio-direction.md`
- `data/story_scenes/*.json`

当前种子画像在 `data/character_voice_profiles.json`。它不是最终配音表，而是 AI 生成对白和语音时必须遵守的角色约束。

## Workflow

先生成或刷新角色声音圣经：

```sh
python3 tools/build_character_voice_prompt.py \
  --mode profiles \
  --output /tmp/dream-character-profiles-prompt.md
```

把模型返回的 JSON 写入 `data/character_voice_profiles.json` 后先校验：

```sh
python3 tools/validate_character_voice_profiles.py
```

再按单幕生成对白，不要一次生成全游戏对白：

```sh
python3 tools/build_character_voice_prompt.py \
  --mode dialogue \
  --scene-id 01-illiterate \
  --output /tmp/01-dialogue-prompt.md
```

对白确认后，再生成语音制作说明：

```sh
python3 tools/build_character_voice_prompt.py \
  --mode voice-casting \
  --scene-id 01-illiterate \
  --output /tmp/01-voice-casting-prompt.md
```

## Character Voice Profile Contract

每个角色必须有：

- `display_name`：游戏内显示名。
- `role`：叙事功能，不只写职业。
- `personality`：可指导台词的性格，不写抽象套话。
- `arc`：随章节变化的状态。
- `dialogue_rules`：句式、词库、禁忌。
- `voice_direction`：年龄感、音色、音高、速度、能量、表演注意点、TTS prompt。
- `sample_lines`：来自现有剧本或符合角色弧光的短句。
- `source_evidence`：画像依据的文件路径。

音色描述只能使用抽象表演参数。不要要求克隆真人、公众人物或具体配音演员。

## Dialogue Contract

后续对白数据建议落为 `data/dialogue_lines/<scene-id>.json`，每句使用稳定 ID：

```json
{
  "schema_version": 1,
  "scene_id": "01-illiterate",
  "lines": [
    {
      "id": "DLG-01-001",
      "location_id": "mud_road",
      "character_id": "jizi_xuan",
      "text": "……这是哪？",
      "intent": "玩家醒来后的第一句定位",
      "emotion": "困惑、紧张",
      "delivery": "低声，短暂停顿后抬头",
      "requires": [],
      "sets_flags": [],
      "source_evidence": [
        "five/script/chapter-01-opening.md"
      ]
    }
  ]
}
```

生成对白时必须覆盖 scene 的关键 flag、location 和战斗/调查节点，但不能把已有系统提示全部改成角色自言自语。

## Voice Asset Contract

语音资产建议后续按对白 ID 组织：

- `assets/voices/<scene-id>/<line-id>.ogg`
- `data/voice_line_manifest.json`

manifest 至少记录：

- `line_id`
- `character_id`
- `scene_id`
- `audio_path`
- `voice_direction_ref`
- `duration_seconds`
- `loudness_target`
- `status`

对白生成模型只负责文本和表演方向；TTS 或音频工具再负责实际音频。不要把 API key、供应商私有配置或临时音频缓存提交进仓库。

## Acceptance

- `python3 tools/validate_character_voice_profiles.py` 通过。
- AI 输出的每个角色都能追溯到 `five/people`、`five/script`、`five/scene` 或 `data/story_scenes`。
- 同一角色在不同章节的口吻变化能解释为弧光，不是随机换声线。
- 每个 TTS prompt 都是抽象音色描述，没有真人克隆、公众人物或具体演员引用。
- 每幕对白生成前先固定该幕 `scene_id`，避免一次性生成全剧导致设定漂移。

## Non-Goals

- 这里不实现实时语音合成。
- 这里不选择具体商业 TTS 服务。
- 这里不生成最终音频文件。
- 这里不替代剧情连贯性校验；改对白后仍要跑 `python3 tools/validate_story_continuity.py --verbose`。
