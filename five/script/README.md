# Script Drafts

`script/` 放正式剧本样稿和剧本扩写 pass。它和 `scene/` 的职责不同：

- `scene/` 说明每幕的目标、流程、玩法接口和角色推进。
- `script/` 把其中的关键段落写成可直接落到对白、调查文本、演出和 playable JSON 的剧本。

## 当前文件

- `prologue-fragment.md`：序幕“灯没有亮”的线性脚本。
- `chapter-01-opening.md`：第一章进入墨颀、遇见小砚和夏离的脚本。
- `chapter-01-name-tutorial-battle.md`：第一章“名”字教学战脚本。
- `pacing-expansion-pass.md`：针对当前时长体感不足的第一轮补强，覆盖第二、三、五、七幕的具体扩写点。
- `continuity-pass.md`：整体连贯性复查，记录已修正的因果、继承 flag、敌人登场和选择死路问题。

## 验证

剧本连贯性改动后，除了 scene smoke，还要跑：

```sh
python3 tools/validate_story_continuity.py --verbose
/Applications/Godot.app/Contents/MacOS/Godot --path . --headless --quit-after 100 --log-file godot-progression.log -- --smoke-rpg-progression
```

## 写作规则

补剧本时不要只增加解释性旁白。每个新增段落至少承担一个职责：

- 让角色关系发生变化。
- 让玩家亲手经历一次失败、复盘或代价。
- 让系统规则以可玩动作出现，而不是只被说明。
- 让后续章节的情绪或机制提前埋下可回收的证据。
