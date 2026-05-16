# Continuity Pass

## 结论

主线因果现在可以成立：

1. 序幕用父母失踪、黑色钢笔和 `To be Continue ...` 建立现代端悬念。
2. 第一幕把纪子轩降到“事实文盲”，用“名”建立核心交互。
3. 第二幕把“文字是工程接口”做成学习、失败、复盘和第一个国书节点。
4. 第三幕证明墨颀不是缺王，而是缺公开学习、工程维护和可纠错制度。
5. 第四幕把前面得到的证据转成续文院、学塾、字典、工坊和档案塔。
6. 第五幕用百年续页展示制度能跨代延续，并只暴露静默干扰，不提前打掉第六幕的敌人登场。
7. 第六幕让静默探针第一次正面入侵，墨颀把文明成果转成归星救援能力。
8. 第七幕回到现代，把“灯未亮”闭环成“灯重新亮起”。

## 已修正的问题

### 第五幕不能提前打败第六幕的敌人

原先第五幕 playable JSON 让玩家 `defeated_silent_probe`，但第六幕文档写的是“熄星者首次正面登场”。这会让第六幕的戏剧功能失效。

修正后，第五幕只处理 `stabilized_silent_interference`：玩家在星象塔看见静默干扰，稳定观测窗口，确认现代星球正在变暗。第六幕仍然保留第一次静默探针入侵和正面战斗。

### 场景之间缺少继承事实

后续场景原本主要用能力 flags 做 `initial_flags`，没有显式继承上一幕的结尾事实。现在补上了关键继承，例如：

- 第一幕继承 `entered_moqi`。
- 第二幕继承 `defeated_nameless`。
- 第三幕继承 `viewed_parent_record` 和已学字根。
- 第六幕继承 `saw_modern_star_darkening`。
- 第七幕继承 `received_parent_truth` 和 `returned_to_modern_with_moqi`。

这些 flags 不是为了增加时长，而是为了让每幕作为独立 playable slice 时仍能带着正确叙事前史。

### 第三幕选择不能形成死路，也不能只停留在文本选项

第三幕藏书处理有四个选择，但开主国书核心原本只承认 `chose_public_books`。这会让非公开路线玩家卡住。

修正后，四个选择都会写入 `resolved_book_route`，主国书核心要求的是“藏书路线已解决”，而不是唯一公开路线。`data/story_scenes/03-dead-kingdom.json` 也新增 `branch_consequences`，记录四条路线对第四幕指标和第六幕支持度的影响。

当前 runtime 已经会把第三幕选择写入跨幕 carryover：后续幕加载时会移除默认路线 flag，加入真实选择路线，并把目标幕的 metrics delta 合进去。这个 carryover 会进入 `to_save_data()`，存档恢复后再进入第四幕或第六幕也能保留后果。

## 仍需后续补的连贯性

### 选择后果还需要视觉和目标反馈

第三幕的四个藏书选择现在不会卡死，且已能影响第四幕指标、第六幕支持度和关键交互文本。后续如果要让玩家在不打开日志的情况下读到差异，还需要给 `chose_royal_books`、`chose_engineer_books`、`chose_parent_books` 增加地点陈设、HUD 目标文案或视觉状态变化。

### 父母仍以记录和回声为主

父母线目前通过笔记、影像、节点批注、研究摘要、最终记录推进，逻辑成立。第七幕已补 `chose_city_before_parents`：纪子轩回到家后必须先选择救城市，再去实验室追父母线。后续仍可继续补真正面对面场景。

### 夏离的代价需要截图和演出支持

第五幕已经写了夏离逐渐国书化，并补了 `kept_xiali_private_anchor`：纪子轩用旧讲堂的椅子给夏离留一个私人锚点。后续视觉 pass 仍应给他单独的投影、延迟、多节点出现状态。

## 自动校验

新增 `tools/validate_story_continuity.py`，用于检查普通 smoke 不会覆盖的叙事风险：

- 后一幕“首次正面登场”的敌人不能在前一幕被打败。
- 每幕 `initial_flags` 应继承上一幕 `ending_flag`。
- `requires` 引用的 flag 必须能由本幕动作或初始状态提供。
- 第三幕所有非 canonical 藏书路线也必须能跑通。
- 第三幕每个 choice 都必须设置共同的 `resolved_book_route`，并有 `branch_consequences` 契约。
- 第四幕和第六幕必须给所有藏书路线提供 `route_texts`，否则 metrics 有变化但玩家读不到差异。

同时扩展 `--smoke-rpg-progression`，覆盖第三幕工程路线的 carryover：

- 已选择工程路线后，不能再改选公开路线。
- 存档恢复后进入第四幕，会保留 `chose_engineer_books`，移除默认 `chose_public_books`。
- 第四幕 `engineering/energy/literacy` 和第六幕 `support` 会按 `branch_consequences.next_scene_metrics` 调整。
- 第四幕“第一批成员”和第六幕“支持派”会输出工程路线专属文本，证明分支不只是后台数字。

## 下一轮建议

下一轮不要继续泛泛加字数，优先做三个具体补强：

- 分支线：给第三幕路线差异补第四幕地点陈设和 HUD 目标文案，而不是只让 metrics 与日志变化。
- 夏离线：给第五幕国书化状态补视觉和对白演出。
- 父母线：在最终结尾前补一次面对面或半面对面的父母互动。
