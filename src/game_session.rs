use std::collections::HashSet;

use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;

use crate::dict_helpers::*;
use crate::scene_database::RustSceneDatabase;

// ── Struct definition ────────────────────────────────────────────────────────

#[derive(GodotClass)]
pub struct RustGameSession {
    #[var]
    pub(crate) scene_id: GString,
    #[var]
    pub(crate) location_id: GString,
    #[var]
    scene_index: i32,
    #[var]
    scene: VarDictionary,
    #[var]
    enemy_hp: i32,
    #[var]
    elapsed_seconds: i32,
    #[var]
    event_log: Array<GString>,

    database: Option<Gd<RustSceneDatabase>>,
    player_hp: i32,
    name_attempts: i32,
    attacks_since_name: i32,
    flags: HashSet<String>,
    metrics: VarDictionary,
}

#[godot_api]
impl IRefCounted for RustGameSession {
    fn init(_base: Base<RefCounted>) -> Self {
        Self {
            scene_id: GString::new(),
            location_id: GString::new(),
            scene_index: 0,
            scene: VarDictionary::new(),
            enemy_hp: 0,
            elapsed_seconds: 0,
            event_log: Array::new(),
            database: None,
            player_hp: 5,
            name_attempts: 0,
            attacks_since_name: 0,
            flags: HashSet::new(),
            metrics: VarDictionary::new(),
        }
    }
}

// ── Public Godot API ─────────────────────────────────────────────────────────

#[godot_api]
impl RustGameSession {
    #[func]
    fn set_database(&mut self, db: Gd<RustSceneDatabase>) {
        self.database = Some(db);
    }

    #[func]
    fn load_scene(&mut self, index: i32) {
        let Some(db) = self.database.as_ref() else {
            return;
        };
        let db_v = db.to_variant();
        let count = db_v.call("count", &[]).try_to::<i32>().unwrap_or(0);
        self.scene_index = index.clamp(0, (count - 1).max(0));

        let idx_v = self.scene_index.to_variant();
        self.scene_id = db_v
            .call("scene_id_at", &[idx_v.clone()])
            .try_to::<GString>()
            .unwrap_or_default();
        let scene_var = db_v.call("scene_at", &[idx_v]);
        self.scene = scene_var.try_to::<VarDictionary>().unwrap_or_default();

        let start = dict_str(&self.scene, "start", "");
        self.location_id = GString::from(start.as_str());

        self.flags.clear();
        let initial_flags = dict_value_as_array(&self.scene, "initial_flags");
        for flag_var in initial_flags.iter_shared() {
            let flag = flag_var.stringify().to_string();
            if !flag.is_empty() {
                self.flags.insert(flag);
            }
        }

        // Shallow clone is fine – modified copy is tracked independently
        self.metrics = dict_value_as_dict(&self.scene, "metrics").clone();

        self.elapsed_seconds = 0;
        self.enemy_hp = 0;
        self.player_hp = 5;
        self.name_attempts = 0;
        self.attacks_since_name = 0;
        self.event_log.clear();

        self.enter_combat_if_needed();
        let title = dict_str(&self.scene, "title", "");
        self.log_internal(&format!("开始：{}", title));
    }

    #[func]
    fn scene_count(&self) -> i32 {
        self.database
            .as_ref()
            .and_then(|db| db.to_variant().call("count", &[]).try_to::<i32>().ok())
            .unwrap_or(0)
    }

    #[func]
    pub(crate) fn current_location(&self) -> Variant {
        self.current_location_dict().to_variant()
    }

    #[func]
    fn action_groups(&self) -> Variant {
        let location = self.current_location_dict();
        let mut groups = VarArray::new();

        // Move actions
        let exits = dict_value_as_dict(&location, "exits");
        let mut move_actions = VarArray::new();
        for key_var in exits.keys_array().iter_shared() {
            let exit_id = key_var.stringify();
            let exit_name = exits
                .get(&key_var)
                .and_then(|v| v.try_to::<GString>().ok())
                .unwrap_or_else(|| exit_id.clone());
            let label = GString::from(format!("去：{}", exit_name).as_str());
            let verb = GString::from("go");
            let mut a = VarDictionary::new();
            a.set("label", &label.to_variant());
            a.set("verb", &verb.to_variant());
            a.set("arg", &exit_id.to_variant());
            let av = a.to_variant();
            move_actions.push(&av);
        }
        push_group(&mut groups, "移动", move_actions);

        // Inspect actions
        let items = dict_value_as_dict(&location, "items");
        let mut inspect_actions = VarArray::new();
        for key_var in items.keys_array().iter_shared() {
            let item_id = key_var.stringify();
            let item = dict_value_as_dict(&items, &item_id.to_string());
            let item_name = item
                .get("name")
                .and_then(|v| v.try_to::<GString>().ok())
                .unwrap_or_else(|| item_id.clone());
            let label = GString::from(format!("查：{}", item_name).as_str());
            let verb = GString::from("inspect");
            let mut a = VarDictionary::new();
            a.set("label", &label.to_variant());
            a.set("verb", &verb.to_variant());
            a.set("arg", &item_id.to_variant());
            let av = a.to_variant();
            inspect_actions.push(&av);
        }
        push_group(&mut groups, "调查", inspect_actions);

        // Cast actions
        let mut cast_actions = VarArray::new();
        for glyph in self.available_casts() {
            let label = GString::from(format!("写/施：{}", glyph).as_str());
            let verb = GString::from("cast");
            let arg = GString::from(glyph.as_str());
            let mut a = VarDictionary::new();
            a.set("label", &label.to_variant());
            a.set("verb", &verb.to_variant());
            a.set("arg", &arg.to_variant());
            let av = a.to_variant();
            cast_actions.push(&av);
        }
        push_group(&mut groups, "字根", cast_actions);

        // Build actions
        let build_map = dict_value_as_dict(&location, "build_actions");
        let mut build_actions = VarArray::new();
        for key_var in build_map.keys_array().iter_shared() {
            let project = key_var.stringify();
            let label = GString::from(format!("建：{}", project).as_str());
            let verb = GString::from("build");
            let mut a = VarDictionary::new();
            a.set("label", &label.to_variant());
            a.set("verb", &verb.to_variant());
            a.set("arg", &project.to_variant());
            let av = a.to_variant();
            build_actions.push(&av);
        }
        push_group(&mut groups, "建设", build_actions);

        // Choice actions
        let choices = dict_value_as_dict(&location, "choices");
        let mut choice_actions = VarArray::new();
        for key_var in choices.keys_array().iter_shared() {
            let route = key_var.stringify();
            let label = GString::from(format!("选：{}", route).as_str());
            let verb = GString::from("choose");
            let mut a = VarDictionary::new();
            a.set("label", &label.to_variant());
            a.set("verb", &verb.to_variant());
            a.set("arg", &route.to_variant());
            let av = a.to_variant();
            choice_actions.push(&av);
        }
        push_group(&mut groups, "选择", choice_actions);

        // Combat actions
        if location.contains_key("combat") {
            let mut combat_actions = VarArray::new();
            for (lbl, vb) in [("写：名", "write"), ("攻击", "attack"), ("防御", "guard")] {
                let l = GString::from(lbl);
                let v = GString::from(vb);
                let e = GString::new();
                let mut a = VarDictionary::new();
                a.set("label", &l.to_variant());
                a.set("verb", &v.to_variant());
                a.set("arg", &e.to_variant());
                let av = a.to_variant();
                combat_actions.push(&av);
            }
            push_group(&mut groups, "战斗", combat_actions);
        }

        // Combo actions
        let combos = dict_value_as_dict(&location, "combos");
        let mut combo_actions = VarArray::new();
        for key_var in combos.keys_array().iter_shared() {
            let combo = key_var.stringify();
            let label = GString::from(format!("组合：{}", combo).as_str());
            let verb = GString::from("combine");
            let mut a = VarDictionary::new();
            a.set("label", &label.to_variant());
            a.set("verb", &verb.to_variant());
            a.set("arg", &combo.to_variant());
            let av = a.to_variant();
            combo_actions.push(&av);
        }
        push_group(&mut groups, "组合", combo_actions);

        groups.to_variant()
    }

    #[func]
    pub(crate) fn apply_action(&mut self, action: Variant) {
        let Ok(action_dict) = action.try_to::<VarDictionary>() else {
            return;
        };
        let verb = dict_str(&action_dict, "verb", "");
        let arg = dict_str(&action_dict, "arg", "");
        self.dispatch_action(&verb, &arg);
    }

    #[func]
    fn status_text(&self) -> GString {
        let required_arr = dict_value_as_array(&self.scene, "required_flags");
        let mut found = 0i32;
        let mut required_total = 0i32;
        for flag_var in required_arr.iter_shared() {
            required_total += 1;
            let flag = flag_var.stringify().to_string();
            if self.has_flag_internal(&flag) {
                found += 1;
            }
        }

        let mut text = format!("目标覆盖 {}/{}", found, required_total);

        if self.scene.contains_key("min_minutes") {
            let min_minutes = dict_f64(&self.scene, "min_minutes", 0.0);
            text += &format!("  最低时长 {:.1} 分钟", min_minutes);
        }

        let combat = dict_value_as_dict(&self.current_location_dict(), "combat");
        if !combat.is_empty() {
            let lock_flag = dict_str(&combat, "lock_flag", "");
            let enemy_name = if self.has_flag_internal(&lock_flag) {
                if combat.contains_key("revealed_name") {
                    dict_str(&combat, "revealed_name", "敌人")
                } else {
                    dict_str(&combat, "hidden_name", "敌人")
                }
            } else {
                dict_str(&combat, "hidden_name", "???")
            };
            let max_hp = dict_i32(&combat, "enemy_hp", 0);
            text += &format!(
                "\n敌人 {} HP {}/{}  我方 HP {}",
                enemy_name, self.enemy_hp, max_hp, self.player_hp
            );
        }

        let ending_flag = dict_str(&self.scene, "ending_flag", "");
        if self.has_flag_internal(&ending_flag) {
            text += "\n章节完成，可以切到下一幕。";
        }

        GString::from(text.as_str())
    }

    #[func]
    fn metrics_text(&self) -> GString {
        if self.metrics.is_empty() {
            return GString::new();
        }
        let mut parts: Vec<String> = Vec::new();
        for key_var in self.metrics.keys_array().iter_shared() {
            let key = key_var.stringify().to_string();
            let val = self
                .metrics
                .get(&key_var)
                .map(|v| v.stringify().to_string())
                .unwrap_or_default();
            parts.push(format!("{}={}", key, val));
        }
        GString::from(format!("指标  {}", parts.join("  ").as_str()).as_str())
    }

    #[func]
    fn format_time(&self) -> GString {
        GString::from(
            format!(
                "{:02}:{:02}",
                self.elapsed_seconds / 60,
                self.elapsed_seconds % 60
            )
            .as_str(),
        )
    }

    #[func]
    fn visible_log(&self, max_lines: i32) -> GString {
        let total = self.event_log.len() as i32;
        let start = (total - max_lines).max(0) as usize;
        let mut lines: Vec<String> = Vec::new();
        for i in start..total as usize {
            lines.push(
                self.event_log
                    .get(i)
                    .map(|s| s.to_string())
                    .unwrap_or_default(),
            );
        }
        GString::from(lines.join("\n").as_str())
    }

    #[func]
    fn to_save_data(&self) -> Variant {
        let mut flags_arr: Array<GString> = Array::new();
        for flag in &self.flags {
            flags_arr.push(&GString::from(flag.as_str()));
        }

        let loc_id_v = self.location_id.to_variant();
        let flags_v = flags_arr.to_variant();
        let metrics_v = self.metrics.to_variant();
        let log_v = self.event_log.to_variant();

        let mut payload = VarDictionary::new();
        payload.set("scene_index", &self.scene_index.to_variant());
        payload.set("location_id", &loc_id_v);
        payload.set("flags", &flags_v);
        payload.set("metrics", &metrics_v);
        payload.set("elapsed_seconds", &self.elapsed_seconds.to_variant());
        payload.set("enemy_hp", &self.enemy_hp.to_variant());
        payload.set("player_hp", &self.player_hp.to_variant());
        payload.set("name_attempts", &self.name_attempts.to_variant());
        payload.set("attacks_since_name", &self.attacks_since_name.to_variant());
        payload.set("event_log", &log_v);
        payload.to_variant()
    }

    #[func]
    fn load_save_data(&mut self, data: Variant) {
        let Ok(data_dict) = data.try_to::<VarDictionary>() else {
            return;
        };
        let Some(db) = self.database.as_ref() else {
            return;
        };
        let db_v = db.to_variant();
        let count = db_v.call("count", &[]).try_to::<i32>().unwrap_or(0);
        let raw_index = dict_i32(&data_dict, "scene_index", 0);
        self.scene_index = raw_index.clamp(0, (count - 1).max(0));

        let idx_v = self.scene_index.to_variant();
        self.scene_id = db_v
            .call("scene_id_at", &[idx_v.clone()])
            .try_to::<GString>()
            .unwrap_or_default();
        let scene_var = db_v.call("scene_at", &[idx_v]);
        self.scene = scene_var.try_to::<VarDictionary>().unwrap_or_default();

        let default_start = dict_str(&self.scene, "start", "");
        let loc = dict_str(&data_dict, "location_id", &default_start);
        self.location_id = GString::from(loc.as_str());

        self.flags.clear();
        let flags_arr = dict_value_as_array(&data_dict, "flags");
        for flag_var in flags_arr.iter_shared() {
            let flag = flag_var.stringify().to_string();
            if !flag.is_empty() {
                self.flags.insert(flag);
            }
        }

        self.metrics = dict_value_as_dict(&data_dict, "metrics").clone();
        self.elapsed_seconds = dict_i32(&data_dict, "elapsed_seconds", 0);
        self.enemy_hp = dict_i32(&data_dict, "enemy_hp", 0);
        self.player_hp = dict_i32(&data_dict, "player_hp", 5);
        self.name_attempts = dict_i32(&data_dict, "name_attempts", 0);
        self.attacks_since_name = dict_i32(&data_dict, "attacks_since_name", 0);

        self.event_log.clear();
        let log_arr = dict_value_as_array(&data_dict, "event_log");
        for line_var in log_arr.iter_shared() {
            self.event_log.push(&line_var.stringify());
        }
    }

    #[func]
    fn run_smoke_verification(&mut self) -> bool {
        let count = self.scene_count();
        let mut all_ok = true;
        for i in 0..count {
            self.load_scene(i);
            let ok = self.verify_current_scene();
            all_ok = all_ok && ok;
        }
        all_ok
    }

    #[func]
    fn has_flag(&self, flag: GString) -> bool {
        self.has_flag_internal(flag.to_string().as_str())
    }

    #[func]
    pub(crate) fn append_event_log(&mut self, text: GString) {
        self.log_internal(text.to_string().as_str());
    }
}

// ── Private helpers ──────────────────────────────────────────────────────────

impl RustGameSession {
    pub(crate) fn current_location_dict(&self) -> VarDictionary {
        let locations = dict_value_as_dict(&self.scene, "locations");
        let loc_key = Variant::from(self.location_id.clone());
        locations
            .get(&loc_key)
            .and_then(|v| v.try_to::<VarDictionary>().ok())
            .unwrap_or_default()
    }

    fn has_flag_internal(&self, flag: &str) -> bool {
        !flag.is_empty() && self.flags.contains(flag)
    }

    fn log_internal(&mut self, text: &str) {
        let trimmed = text.trim();
        if !trimmed.is_empty() {
            self.event_log.push(&GString::from(trimmed));
        }
    }

    fn dispatch_action(&mut self, verb: &str, arg: &str) {
        match verb {
            "go" => self.move_to(arg),
            "inspect" => self.inspect_item(arg),
            "cast" => self.cast_glyph(arg),
            "write" => self.write_name(),
            "attack" => self.attack(),
            "guard" => self.guard(),
            "choose" => self.choose_route(arg),
            "build" => self.build_project(arg),
            "combine" => self.combine_words(arg),
            _ => self.log_internal(&format!("未知行动：{}", verb)),
        }
    }

    fn apply_text_command_internal(&mut self, command: &str) {
        let parts: Vec<&str> = command.split(' ').filter(|s| !s.is_empty()).collect();
        if parts.is_empty() {
            return;
        }
        let verb = parts[0];
        let arg = if parts.len() > 1 { parts[1] } else { "" };
        self.dispatch_action(verb, arg);
    }

    fn requirements_met(&self, required: &VarArray) -> bool {
        for flag_var in required.iter_shared() {
            let flag = flag_var.stringify().to_string();
            if !self.has_flag_internal(&flag) {
                return false;
            }
        }
        true
    }

    fn add_flags_from_array(&mut self, arr: &VarArray) {
        for flag_var in arr.iter_shared() {
            let flag = flag_var.stringify().to_string();
            if !flag.is_empty() {
                self.flags.insert(flag);
            }
        }
    }

    fn apply_metrics(&mut self, delta: &VarDictionary) {
        for key_var in delta.keys_array().iter_shared() {
            let key = key_var.stringify().to_string();
            let delta_val = delta
                .get(&key_var)
                .and_then(|v| v.try_to_relaxed::<i32>().ok())
                .unwrap_or(0);
            let current_val = self
                .metrics
                .get(key.as_str())
                .and_then(|v| v.try_to_relaxed::<i32>().ok())
                .unwrap_or(0);
            let new_val = (current_val + delta_val).to_variant();
            self.metrics.set(key.as_str(), &new_val);
        }
    }

    fn available_casts(&self) -> Vec<String> {
        let location = self.current_location_dict();
        let mut casts: Vec<String> = Vec::new();

        let glyph_actions = dict_value_as_dict(&location, "glyph_actions");
        for key in glyph_actions.keys_array().iter_shared() {
            let glyph = key.stringify().to_string();
            if !casts.contains(&glyph) {
                casts.push(glyph);
            }
        }

        let combat = dict_value_as_dict(&location, "combat");
        let spells = dict_value_as_dict(&combat, "spells");
        for key in spells.keys_array().iter_shared() {
            let glyph = key.stringify().to_string();
            if !casts.contains(&glyph) {
                casts.push(glyph);
            }
        }

        casts
    }

    fn enter_combat_if_needed(&mut self) {
        let combat = dict_value_as_dict(&self.current_location_dict(), "combat");
        if combat.is_empty() {
            return;
        }
        let win_flag = dict_str(&combat, "win_flag", "");
        if self.enemy_hp > 0 || self.has_flag_internal(&win_flag) {
            return;
        }
        self.enemy_hp = dict_i32(&combat, "enemy_hp", 1);
        self.player_hp = dict_i32(&combat, "player_hp", 5);
        self.name_attempts = 0;
        self.attacks_since_name = 0;
    }

    fn combat_active(&self) -> bool {
        let combat = dict_value_as_dict(&self.current_location_dict(), "combat");
        if combat.is_empty() {
            return false;
        }
        let win_flag = dict_str(&combat, "win_flag", "");
        self.enemy_hp > 0 && !self.has_flag_internal(&win_flag)
    }

    fn move_to(&mut self, exit_id: &str) {
        let location = self.current_location_dict();
        let exits = dict_value_as_dict(&location, "exits");
        if !exits.contains_key(exit_id) {
            self.log_internal("这里不能去那里。");
            return;
        }
        self.location_id = GString::from(exit_id);
        self.elapsed_seconds += 20;
        self.enter_combat_if_needed();
        let dest_name = self
            .current_location_dict()
            .get("name")
            .and_then(|v| v.try_to::<GString>().ok())
            .map(|s| s.to_string())
            .unwrap_or_else(|| exit_id.to_string());
        self.log_internal(&format!("前往：{}", dest_name));
    }

    fn inspect_item(&mut self, item_id: &str) {
        let location = self.current_location_dict();
        let items = dict_value_as_dict(&location, "items");
        let item = dict_value_as_dict(&items, item_id);
        if item.is_empty() {
            self.log_internal("这里没有这个调查对象。");
            return;
        }
        let requires = dict_value_as_array(&item, "requires");
        if !self.requirements_met(&requires) {
            self.log_internal("前置条件不足。");
            return;
        }
        self.elapsed_seconds += dict_i32(&item, "time_seconds", 30);
        let flags_arr = dict_value_as_array(&item, "flags");
        self.add_flags_from_array(&flags_arr);
        let text = dict_str(&item, "text", "");
        self.log_internal(&text);
    }

    fn cast_glyph(&mut self, glyph: &str) {
        let combat_active = self.combat_active();
        if (glyph == "name" || glyph == "名") && combat_active {
            self.write_name();
            return;
        }

        let location = self.current_location_dict();
        let combat = dict_value_as_dict(&location, "combat");
        let spells = dict_value_as_dict(&combat, "spells");
        let glyph_actions = dict_value_as_dict(&location, "glyph_actions");

        let action = if combat_active {
            let a = dict_value_as_dict(&spells, glyph);
            if a.is_empty() {
                dict_value_as_dict(&glyph_actions, glyph)
            } else {
                a
            }
        } else {
            let a = dict_value_as_dict(&glyph_actions, glyph);
            if a.is_empty() {
                dict_value_as_dict(&spells, glyph)
            } else {
                a
            }
        };

        if action.is_empty() {
            self.log_internal("这个字根现在派不上用场。");
            return;
        }
        let requires = dict_value_as_array(&action, "requires");
        if !self.requirements_met(&requires) {
            self.log_internal("术式前置条件不足。");
            return;
        }
        self.elapsed_seconds += dict_i32(&action, "time_seconds", 45);
        let flags_arr = dict_value_as_array(&action, "flags");
        self.add_flags_from_array(&flags_arr);
        let metrics = dict_value_as_dict(&action, "metrics");
        self.apply_metrics(&metrics);
        let text = dict_str(&action, "text", "");
        self.log_internal(&text);
    }

    fn build_project(&mut self, project: &str) {
        let location = self.current_location_dict();
        let build_actions = dict_value_as_dict(&location, "build_actions");
        let action = dict_value_as_dict(&build_actions, project);
        if action.is_empty() {
            self.log_internal("这里不能建设这个项目。");
            return;
        }
        let requires = dict_value_as_array(&action, "requires");
        if !self.requirements_met(&requires) {
            self.log_internal("建设条件不足。");
            return;
        }
        self.elapsed_seconds += dict_i32(&action, "time_seconds", 60);
        let flags_arr = dict_value_as_array(&action, "flags");
        self.add_flags_from_array(&flags_arr);
        let metrics = dict_value_as_dict(&action, "metrics");
        self.apply_metrics(&metrics);
        let text = dict_str(&action, "text", "");
        self.log_internal(&text);
    }

    fn choose_route(&mut self, route: &str) {
        let location = self.current_location_dict();
        let choices = dict_value_as_dict(&location, "choices");
        let choice = dict_value_as_dict(&choices, route);
        if choice.is_empty() {
            self.log_internal("这里没有这个选择。");
            return;
        }
        let requires = dict_value_as_array(&choice, "requires");
        if !self.requirements_met(&requires) {
            self.log_internal("选择条件不足。");
            return;
        }
        self.elapsed_seconds += dict_i32(&choice, "time_seconds", 45);
        let flags_arr = dict_value_as_array(&choice, "flags");
        self.add_flags_from_array(&flags_arr);
        let text = dict_str(&choice, "text", "");
        self.log_internal(&text);
    }

    fn combine_words(&mut self, combo: &str) {
        let location = self.current_location_dict();
        let combos = dict_value_as_dict(&location, "combos");
        let action = dict_value_as_dict(&combos, combo);
        if action.is_empty() {
            self.log_internal("这里不能组合这组字。");
            return;
        }
        let requires = dict_value_as_array(&action, "requires");
        if !self.requirements_met(&requires) {
            self.log_internal("字义还不稳定，组合会碎掉。");
            return;
        }
        self.elapsed_seconds += dict_i32(&action, "time_seconds", 90);
        let flags_arr = dict_value_as_array(&action, "flags");
        self.add_flags_from_array(&flags_arr);
        let text = dict_str(&action, "text", "");
        self.log_internal(&text);
    }

    fn write_name(&mut self) {
        let combat = dict_value_as_dict(&self.current_location_dict(), "combat");
        if combat.is_empty() {
            self.log_internal("现在不需要写“名”。");
            return;
        }
        let learn_flag = dict_str(&combat, "learn_flag", "");
        if !learn_flag.is_empty() && !self.has_flag_internal(&learn_flag) {
            self.log_internal("你还没有理解“名”的笔画。");
            return;
        }

        self.elapsed_seconds += dict_i32(&combat, "write_seconds", 45);
        self.name_attempts += 1;
        if self.name_attempts < dict_i32(&combat, "success_attempt", 1) {
            self.player_hp -= 1;
            let failure_flags = dict_value_as_array(&combat, "failure_flags");
            self.add_flags_from_array(&failure_flags);
            self.log_internal("符文碎开。敌人继续逼近，UI 上的名字短暂变成□□。");
        } else {
            let lock_flag = dict_str(&combat, "lock_flag", "");
            if !lock_flag.is_empty() {
                self.flags.insert(lock_flag);
            }
            let success_flags = dict_value_as_array(&combat, "success_flags");
            self.add_flags_from_array(&success_flags);
            self.attacks_since_name = 0;
            let revealed_name = dict_str(&combat, "revealed_name", "敌人");
            self.log_internal(&format!("“名”字亮起。目标显形：{}。", revealed_name));
        }
    }

    fn attack(&mut self) {
        let combat = dict_value_as_dict(&self.current_location_dict(), "combat");
        if combat.is_empty() {
            self.log_internal("这里没有敌人。");
            return;
        }
        let lock_flag = dict_str(&combat, "lock_flag", "");
        if !self.has_flag_internal(&lock_flag) {
            self.elapsed_seconds += 25;
            self.player_hp -= 1;
            self.log_internal("无法锁定目标，攻击穿过空白。");
            return;
        }
        let required_flags = dict_value_as_array(&combat, "required_attack_flags");
        if !self.requirements_met(&required_flags) {
            self.elapsed_seconds += 25;
            self.log_internal("目标已显形，但战场规则还没破解。");
            return;
        }

        self.elapsed_seconds += dict_i32(&combat, "attack_seconds", 35);
        self.enemy_hp -= 1;
        self.attacks_since_name += 1;

        if self.enemy_hp <= 0 {
            let win_flag = dict_str(&combat, "win_flag", "");
            if !win_flag.is_empty() {
                self.flags.insert(win_flag);
            }
            let reward_flags = dict_value_as_array(&combat, "reward_flags");
            self.add_flags_from_array(&reward_flags);
            let revealed_name = dict_str(&combat, "revealed_name", "敌人");
            self.log_internal(&format!("{} 被击退。", revealed_name));
        } else if self.attacks_since_name >= dict_i32(&combat, "lose_name_every", 2) {
            let lock_flag = dict_str(&combat, "lock_flag", "");
            self.flags.remove(&lock_flag);
            self.attacks_since_name = 0;
            let revealed_name = dict_str(&combat, "revealed_name", "敌人");
            self.log_internal(&format!("{} 开始失名，必须重新写“名”。", revealed_name));
        } else {
            let revealed_name = dict_str(&combat, "revealed_name", "敌人");
            self.log_internal(&format!("攻击命中：{}。", revealed_name));
        }
    }

    fn guard(&mut self) {
        self.elapsed_seconds += 30;
        self.log_internal("你稳住阵线，争取到半步距离。");
    }

    fn verify_current_scene(&mut self) -> bool {
        let walkthrough = dict_value_as_array(&self.scene, "walkthrough");
        let ending_flag = dict_str(&self.scene, "ending_flag", "");
        let required_flags_arr = dict_value_as_array(&self.scene, "required_flags");
        let min_minutes = dict_f64(&self.scene, "min_minutes", 0.0);

        for cmd_var in walkthrough.iter_shared() {
            let cmd = cmd_var.stringify().to_string();
            self.apply_text_command_internal(&cmd);
            if self.has_flag_internal(&ending_flag) {
                break;
            }
        }

        let required_flags: Vec<String> = required_flags_arr
            .iter_shared()
            .map(|v| v.stringify().to_string())
            .collect();
        let missing: Vec<&String> = required_flags
            .iter()
            .filter(|f| !self.has_flag_internal(f))
            .collect();

        let duration_ok = (self.elapsed_seconds as f64) / 60.0 >= min_minutes;
        let complete = self.has_flag_internal(&ending_flag) && missing.is_empty();
        let ok = duration_ok && complete;

        godot_print!(
            "{} duration={:.1}min required={}/{} status={}",
            self.scene_id,
            (self.elapsed_seconds as f64) / 60.0,
            required_flags.len() - missing.len(),
            required_flags.len(),
            if ok { "PASS" } else { "FAIL" }
        );
        if !ok {
            let missing_strs: Vec<&str> = missing.iter().map(|s| s.as_str()).collect();
            godot_print!("missing={:?}", missing_strs);
        }
        ok
    }
}

// ── Module-level helpers ─────────────────────────────────────────────────────

fn push_group(groups: &mut VarArray, title: &str, actions: VarArray) {
    if actions.is_empty() {
        return;
    }
    let t = GString::from(title);
    let mut group = VarDictionary::new();
    group.set("title", &t.to_variant());
    group.set("actions", &actions.to_variant());
    let gv = group.to_variant();
    groups.push(&gv);
}
