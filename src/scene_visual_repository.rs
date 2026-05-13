use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;

use crate::scene_database::read_json_dict;

const VISUAL_DIR: &str = "res://data/visual_scenes";

#[derive(GodotClass)]
pub struct RustSceneVisualRepository {
    scenes: VarDictionary,
}

#[godot_api]
impl IRefCounted for RustSceneVisualRepository {
    fn init(_base: Base<RefCounted>) -> Self {
        Self {
            scenes: VarDictionary::new(),
        }
    }
}

#[godot_api]
impl RustSceneVisualRepository {
    #[func]
    fn load_for_scene_ids(&mut self, scene_ids: PackedStringArray) {
        self.scenes.clear();

        for scene_id in scene_ids.as_slice() {
            let path = format!("{VISUAL_DIR}/{scene_id}.json");
            if let Some(parsed) = read_json_dict(&path) {
                self.scenes.set(scene_id, &parsed);
            }
        }
    }

    #[func]
    fn location_visual(&self, scene_id: GString, location_id: GString) -> Variant {
        location_visual_dict(&self.scenes, scene_id, location_id).to_variant()
    }

    #[func]
    fn spawn_for(&self, scene_id: GString, location_id: GString) -> Vector2i {
        let visual = location_visual_dict(&self.scenes, scene_id, location_id);
        let spawn = dict_value_as_dict(&visual, "spawn");
        Vector2i::new(dict_i32(&spawn, "x", 7), dict_i32(&spawn, "y", 6))
    }

    #[func]
    fn interaction_at(
        &self,
        scene_id: GString,
        location_id: GString,
        position: Vector2i,
    ) -> Variant {
        let visual = location_visual_dict(&self.scenes, scene_id, location_id);
        let props = dict_value_as_array(&visual, "props");

        for prop_variant in props.iter_shared() {
            let Ok(prop) = prop_variant.try_to::<VarDictionary>() else {
                continue;
            };

            if !rect_has_point(&prop, position) {
                continue;
            }

            if prop.contains_key("exit") || prop.contains_key("item") || prop.contains_key("action")
            {
                return prop.to_variant();
            }
        }

        VarDictionary::new().to_variant()
    }

    #[func]
    fn is_blocked(&self, scene_id: GString, location_id: GString, position: Vector2i) -> bool {
        if position.x <= 0 || position.y <= 0 || position.x >= 14 || position.y >= 8 {
            return true;
        }

        let visual = location_visual_dict(&self.scenes, scene_id, location_id);
        let props = dict_value_as_array(&visual, "props");

        for prop_variant in props.iter_shared() {
            let Ok(prop) = prop_variant.try_to::<VarDictionary>() else {
                continue;
            };

            if !dict_bool(&prop, "solid", false) {
                continue;
            }

            if rect_has_point(&prop, position) {
                return true;
            }
        }

        false
    }
}

fn location_visual_dict(
    scenes: &VarDictionary,
    scene_id: GString,
    location_id: GString,
) -> VarDictionary {
    let scene_key = Variant::from(scene_id);
    let visual_scene = scenes
        .get(&scene_key)
        .and_then(|value| value.try_to::<VarDictionary>().ok())
        .unwrap_or_default();
    let locations = dict_value_as_dict(&visual_scene, "locations");
    let location_key = Variant::from(location_id);
    locations
        .get(&location_key)
        .and_then(|value| value.try_to::<VarDictionary>().ok())
        .unwrap_or_default()
}

fn dict_value_as_dict(dict: &VarDictionary, key: &str) -> VarDictionary {
    dict.get(key)
        .and_then(|value| value.try_to::<VarDictionary>().ok())
        .unwrap_or_default()
}

fn dict_value_as_array(dict: &VarDictionary, key: &str) -> VarArray {
    dict.get(key)
        .and_then(|value| value.try_to::<VarArray>().ok())
        .unwrap_or_default()
}

fn dict_i32(dict: &VarDictionary, key: &str, default: i32) -> i32 {
    dict.get(key)
        .and_then(|value| value.try_to_relaxed::<i32>().ok())
        .unwrap_or(default)
}

fn dict_bool(dict: &VarDictionary, key: &str, default: bool) -> bool {
    dict.get(key)
        .and_then(|value| value.try_to_relaxed::<bool>().ok())
        .unwrap_or(default)
}

fn rect_has_point(prop: &VarDictionary, position: Vector2i) -> bool {
    let x = dict_i32(prop, "x", 0);
    let y = dict_i32(prop, "y", 0);
    let w = dict_i32(prop, "w", 1).max(1);
    let h = dict_i32(prop, "h", 1).max(1);

    position.x >= x && position.x < x + w && position.y >= y && position.y < y + h
}
