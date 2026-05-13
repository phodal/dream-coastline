use godot::prelude::*;

mod save_game_repository;
mod scene_database;
mod scene_visual_repository;
mod settings_repository;

struct DreamCoastlineExtension;

#[gdextension]
unsafe impl ExtensionLibrary for DreamCoastlineExtension {}
