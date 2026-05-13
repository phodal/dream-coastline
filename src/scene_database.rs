use std::io::Read;

use godot::classes::{IRefCounted, Json, RefCounted, file_access::ModeFlags};
use godot::prelude::*;
use godot::tools::GFile;

const SCENE_DIR: &str = "res://data/story_scenes";
const SCENE_IDS: &[&str] = &[
    "00-prologue-lights-out",
    "01-illiterate",
    "02-moqi-academy",
    "03-dead-kingdom",
    "04-continuation-institute",
    "05-century-continuation",
    "06-return-star-plan",
    "07-lights-on-again",
];

#[derive(GodotClass)]
pub struct RustSceneDatabase {
    scenes: VarDictionary,
}

#[godot_api]
impl IRefCounted for RustSceneDatabase {
    fn init(_base: Base<RefCounted>) -> Self {
        Self {
            scenes: VarDictionary::new(),
        }
    }
}

#[godot_api]
impl RustSceneDatabase {
    #[func]
    fn load_all(&mut self) -> bool {
        self.scenes.clear();

        let mut ok = true;
        for scene_id in SCENE_IDS {
            let path = format!("{SCENE_DIR}/{scene_id}.json");
            match read_json_dict(&path) {
                Some(parsed) => self.scenes.set(*scene_id, &parsed),
                None => {
                    godot_error!("Could not parse scene data: {path}");
                    ok = false;
                }
            }
        }

        ok
    }

    #[func]
    fn count(&self) -> i32 {
        SCENE_IDS.len() as i32
    }

    #[func]
    fn scene_ids(&self) -> PackedStringArray {
        let mut ids = PackedStringArray::new();
        for scene_id in SCENE_IDS {
            ids.push(*scene_id);
        }
        ids
    }

    #[func]
    fn scene_id_at(&self, index: i32) -> GString {
        SCENE_IDS[clamp_scene_index(index)].into()
    }

    #[func]
    fn scene_at(&self, index: i32) -> Variant {
        let key = Variant::from(self.scene_id_at(index));
        self.scenes.get(&key).unwrap_or_else(Variant::nil)
    }
}

fn clamp_scene_index(index: i32) -> usize {
    if SCENE_IDS.is_empty() {
        return 0;
    }

    index.clamp(0, (SCENE_IDS.len() - 1) as i32) as usize
}

fn read_text(path: &str) -> Option<GString> {
    let mut file = GFile::open(path, ModeFlags::READ).ok()?;
    let mut text = String::new();
    file.read_to_string(&mut text).ok()?;
    Some(text.as_str().into())
}

pub(crate) fn read_json_dict(path: &str) -> Option<VarDictionary> {
    let text = read_text(path)?;
    Json::parse_string(&text).try_to::<VarDictionary>().ok()
}
