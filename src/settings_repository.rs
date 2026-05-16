use std::io::Read;

use godot::classes::{
    AudioServer, DisplayServer, IRefCounted, Json, RefCounted, display_server::WindowMode,
    file_access::ModeFlags,
};
use godot::global::linear_to_db;
use godot::prelude::*;
use godot::tools::GFile;

const SETTINGS_PATH: &str = "user://dream_coastline_settings.json";
const DEFAULT_VISUAL_STYLE: &str = "sunlit_mmo";

#[derive(GodotClass)]
pub struct RustSettingsRepository {
    fullscreen: bool,
    master_volume: f64,
    visual_style: String,
}

#[godot_api]
impl IRefCounted for RustSettingsRepository {
    fn init(_base: Base<RefCounted>) -> Self {
        Self {
            fullscreen: false,
            master_volume: 0.8,
            visual_style: DEFAULT_VISUAL_STYLE.to_string(),
        }
    }
}

#[godot_api]
impl RustSettingsRepository {
    #[func]
    fn load(&mut self) {
        let Some(mut file) = GFile::open(SETTINGS_PATH, ModeFlags::READ).ok() else {
            return;
        };

        let mut text = String::new();
        if file.read_to_string(&mut text).is_err() {
            return;
        }

        let Some(parsed) = Json::parse_string(&text).try_to::<VarDictionary>().ok() else {
            return;
        };

        self.fullscreen = parsed
            .get("fullscreen")
            .and_then(|value| value.try_to_relaxed::<bool>().ok())
            .unwrap_or(false);
        self.master_volume = parsed
            .get("master_volume")
            .and_then(|value| value.try_to_relaxed::<f64>().ok())
            .unwrap_or(0.8)
            .clamp(0.0, 1.0);
        self.visual_style = parsed
            .get("visual_style")
            .and_then(|value| value.try_to::<GString>().ok())
            .map(|value| normalize_visual_style(&value.to_string()))
            .unwrap_or_else(|| DEFAULT_VISUAL_STYLE.to_string());
    }

    #[func]
    fn save(&self) {
        let Ok(mut file) = GFile::open(SETTINGS_PATH, ModeFlags::WRITE) else {
            godot_warn!("Could not open settings file: {SETTINGS_PATH}");
            return;
        };

        let visual_style = GString::from(self.visual_style.as_str());
        let payload: VarDictionary = dict! {
            "fullscreen" => self.fullscreen,
            "master_volume" => self.master_volume,
            "visual_style" => &visual_style,
        };

        let text = Json::stringify(&payload.to_variant());
        if file.write_gstring(&text).is_err() {
            godot_warn!("Could not write settings file: {SETTINGS_PATH}");
        }
    }

    #[func]
    fn apply(&self) {
        let window_mode = if self.fullscreen {
            WindowMode::FULLSCREEN
        } else {
            WindowMode::WINDOWED
        };
        DisplayServer::singleton().window_set_mode(window_mode);

        let master_bus = AudioServer::singleton().get_bus_index("Master");
        if master_bus >= 0 {
            let mut audio_server = AudioServer::singleton();
            audio_server.set_bus_mute(master_bus, self.master_volume <= 0.001);
            audio_server.set_bus_volume_db(
                master_bus,
                linear_to_db(self.master_volume.max(0.001)) as f32,
            );
        }
    }

    #[func]
    fn fullscreen_enabled(&self) -> bool {
        self.fullscreen
    }

    #[func]
    fn set_fullscreen_enabled(&mut self, enabled: bool) {
        self.fullscreen = enabled;
    }

    #[func]
    fn master_volume_value(&self) -> f64 {
        self.master_volume
    }

    #[func]
    fn set_master_volume_value(&mut self, value: f64) {
        self.master_volume = value.clamp(0.0, 1.0);
    }

    #[func]
    fn visual_style(&self) -> GString {
        GString::from(self.visual_style.as_str())
    }

    #[func]
    fn set_visual_style(&mut self, value: GString) {
        self.visual_style = normalize_visual_style(&value.to_string());
    }
}

fn normalize_visual_style(value: &str) -> String {
    match value {
        "classic_dark" => "classic_dark".to_string(),
        "sunlit_mmo" => "sunlit_mmo".to_string(),
        _ => DEFAULT_VISUAL_STYLE.to_string(),
    }
}
