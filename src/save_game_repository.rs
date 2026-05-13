use std::io::Read;

use godot::classes::{IRefCounted, Json, RefCounted, file_access::ModeFlags};
use godot::prelude::*;
use godot::tools::GFile;

const SAVE_PATH: &str = "user://dream_coastline_save.json";

#[derive(GodotClass)]
pub struct RustSaveGameRepository;

#[godot_api]
impl IRefCounted for RustSaveGameRepository {
    fn init(_base: Base<RefCounted>) -> Self {
        Self
    }
}

#[godot_api]
impl RustSaveGameRepository {
    #[func]
    fn save(&self, session: Variant, player_controller: Variant) -> bool {
        let session_data = session.call("to_save_data", &[]);
        let player_data = player_controller.call("to_save_data", &[]);

        let payload: VarDictionary = dict! {
            "version" => 1,
            "session" => &session_data,
            "player" => &player_data,
        };

        let Ok(mut file) = GFile::open(SAVE_PATH, ModeFlags::WRITE) else {
            godot_warn!("Could not open save file: {SAVE_PATH}");
            return false;
        };

        let text = Json::stringify(&payload.to_variant());
        file.write_gstring(&text).is_ok()
    }

    #[func]
    fn load_into(&self, session: Variant, player_controller: Variant) -> bool {
        let Ok(mut file) = GFile::open(SAVE_PATH, ModeFlags::READ) else {
            return false;
        };

        let mut text = String::new();
        if file.read_to_string(&mut text).is_err() {
            return false;
        }

        let Some(parsed) = Json::parse_string(&text).try_to::<VarDictionary>().ok() else {
            return false;
        };

        let session_data = parsed.get("session").unwrap_or_else(Variant::nil);
        let player_data = parsed.get("player").unwrap_or_else(Variant::nil);
        session.call("load_save_data", &[session_data]);
        player_controller.call("load_save_data", &[player_data]);
        true
    }

    #[func]
    fn has_save(&self) -> bool {
        GFile::open(SAVE_PATH, ModeFlags::READ).is_ok()
    }
}
