# Dream Coastline

将遇到的问题，更新到这里，用一两句话，避免下次犯错。

- Sprint Sheet 如果只有叙事/愿景描述，AI 很难直接执行；需要补成“目标、输入、输出、验收、涉及文件、非目标”的任务契约。
- godot-rust 的集合与字符串参数常区分 ByRef/ByValue；写 `Dictionary`/`Json` 逻辑时，最好显式标注 `VarDictionary` 并传引用，能少踩很多编译坑。
