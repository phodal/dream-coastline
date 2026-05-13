use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;

use crate::dict_helpers::*;
use crate::game_session::RustGameSession;
use crate::scene_visual_repository::RustSceneVisualRepository;

#[derive(GodotClass)]
pub struct RustRpgPlayerController {
    #[var]
    tile: Vector2i,
    #[var]
    facing: Vector2i,
    #[var]
    is_moving: bool,
    #[var]
    blocked_tile: Vector2i,

    session: Option<Gd<RustGameSession>>,
    visual_repository: Option<Gd<RustSceneVisualRepository>>,

    previous_tile: Vector2i,
    move_elapsed: f64,
    move_duration: f64,
    blocked_feedback_elapsed: f64,
    blocked_feedback_duration: f64,
    queued_direction: Vector2i,
    has_queued_direction: bool,
}

#[godot_api]
impl IRefCounted for RustRpgPlayerController {
    fn init(_base: Base<RefCounted>) -> Self {
        Self {
            tile: Vector2i::new(7, 6),
            facing: Vector2i::new(0, 1),
            is_moving: false,
            blocked_tile: Vector2i::ZERO,
            session: None,
            visual_repository: None,
            previous_tile: Vector2i::new(7, 6),
            move_elapsed: 0.0,
            move_duration: 0.2,
            blocked_feedback_elapsed: 0.0,
            blocked_feedback_duration: 0.3,
            queued_direction: Vector2i::ZERO,
            has_queued_direction: false,
        }
    }
}

#[godot_api]
impl RustRpgPlayerController {
    #[func]
    fn set_session(&mut self, session: Gd<RustGameSession>) {
        self.session = Some(session);
    }

    #[func]
    fn set_visual_repository(&mut self, repository: Gd<RustSceneVisualRepository>) {
        self.visual_repository = Some(repository);
    }

    #[func]
    fn reset_for_location(&mut self) {
        let Some(session) = self.session.as_ref() else {
            return;
        };
        let Some(visual_repo) = self.visual_repository.as_ref() else {
            return;
        };

        let scene_id = session.bind().scene_id.clone();
        let location_id = session.bind().location_id.clone();

        let spawn = visual_repo
            .to_variant()
            .call(
                "spawn_for",
                &[scene_id.to_variant(), location_id.to_variant()],
            )
            .try_to::<Vector2i>()
            .unwrap_or(Vector2i::new(7, 6));

        self.tile = spawn;
        self.previous_tile = self.tile;
        self.is_moving = false;
        self.move_elapsed = 0.0;
        self.queued_direction = Vector2i::ZERO;
        self.has_queued_direction = false;
        self.blocked_tile = Vector2i::ZERO;
        self.blocked_feedback_elapsed = 0.0;
    }

    #[func]
    fn try_move(&mut self, direction: Vector2i) -> bool {
        if self.is_moving {
            if direction != Vector2i::ZERO {
                self.queued_direction = direction;
                self.has_queued_direction = true;
            }
            return false;
        }

        self.facing = direction;
        let target = self.tile + direction;

        let blocked = self.is_tile_blocked(target);

        if blocked {
            self.blocked_tile = target;
            self.blocked_feedback_elapsed = self.blocked_feedback_duration;
            return false;
        }

        self.previous_tile = self.tile;
        self.tile = target;
        self.is_moving = true;
        self.move_elapsed = 0.0;
        true
    }

    #[func]
    fn update(&mut self, delta: f64) -> bool {
        let mut changed = false;
        if self.blocked_feedback_elapsed > 0.0 {
            self.blocked_feedback_elapsed =
                (self.blocked_feedback_elapsed - delta).max(0.0);
            changed = true;
        }
        if !self.is_moving {
            return changed;
        }
        self.move_elapsed += delta;
        if self.move_elapsed >= self.move_duration {
            self.finish_move();
            if self.has_queued_direction {
                let next_direction = self.queued_direction;
                self.has_queued_direction = false;
                self.queued_direction = Vector2i::ZERO;
                self.try_move(next_direction);
            }
        }
        true
    }

    #[func]
    fn complete_movement(&mut self) {
        self.finish_move();
    }

    #[func]
    fn visual_tile(&self) -> Vector2 {
        if self.is_moving && self.move_duration > 0.0 {
            let t = (self.move_elapsed / self.move_duration).min(1.0) as f32;
            let from = Vector2::new(
                self.previous_tile.x as f32,
                self.previous_tile.y as f32,
            );
            let to = Vector2::new(self.tile.x as f32, self.tile.y as f32);
            from.lerp(to, t)
        } else {
            Vector2::new(self.tile.x as f32, self.tile.y as f32)
        }
    }

    #[func]
    fn has_blocked_feedback(&self) -> bool {
        self.blocked_feedback_elapsed > 0.0
    }

    #[func]
    fn to_save_data(&self) -> Variant {
        let mut payload = VarDictionary::new();
        payload.set("tile_x", &self.tile.x.to_variant());
        payload.set("tile_y", &self.tile.y.to_variant());
        payload.set("facing_x", &self.facing.x.to_variant());
        payload.set("facing_y", &self.facing.y.to_variant());
        payload.to_variant()
    }

    #[func]
    fn load_save_data(&mut self, data: Variant) {
        let Ok(data_dict) = data.try_to::<VarDictionary>() else {
            return;
        };
        let tile_x = dict_i32(&data_dict, "tile_x", 7);
        let tile_y = dict_i32(&data_dict, "tile_y", 6);
        let facing_x = dict_i32(&data_dict, "facing_x", 0);
        let facing_y = dict_i32(&data_dict, "facing_y", 1);
        self.tile = Vector2i::new(tile_x, tile_y);
        self.previous_tile = self.tile;
        self.facing = Vector2i::new(facing_x, facing_y);
        self.is_moving = false;
        self.move_elapsed = 0.0;
    }

    #[func]
    fn interact(&mut self) {
        if self.is_moving {
            return;
        }
        let interaction = self.current_interaction_dict();
        if interaction.is_empty() {
            if let Some(session) = self.session.as_ref() {
                let msg = GString::from("\u{8fd9}\u{91cc}\u{6ca1}\u{6709}\u{53ef}\u{4ee5}\u{4e92}\u{52a8}\u{7684}\u{4e1c}\u{897f}\u{3002}");
                session.to_variant().call("append_event_log", &[msg.to_variant()]);
            }
            return;
        }

        if interaction.contains_key("exit") {
            let exit_id = interaction
                .get("exit")
                .map(|v| v.stringify())
                .unwrap_or_default();
            let verb = GString::from("go");
            let mut a = VarDictionary::new();
            a.set("verb", &verb.to_variant());
            a.set("arg", &exit_id.to_variant());
            if let Some(session) = self.session.as_ref() {
                session.to_variant().call("apply_action", &[a.to_variant()]);
            }
            self.reset_for_location();
        } else if interaction.contains_key("item") {
            let item_id = interaction
                .get("item")
                .map(|v| v.stringify())
                .unwrap_or_default();
            let verb = GString::from("inspect");
            let mut a = VarDictionary::new();
            a.set("verb", &verb.to_variant());
            a.set("arg", &item_id.to_variant());
            if let Some(session) = self.session.as_ref() {
                session.to_variant().call("apply_action", &[a.to_variant()]);
            }
        } else if interaction.contains_key("action") {
            let action = interaction
                .get("action")
                .and_then(|v| v.try_to::<VarDictionary>().ok())
                .unwrap_or_default();
            if let Some(session) = self.session.as_ref() {
                session.to_variant().call("apply_action", &[action.to_variant()]);
            }
        }
    }

    #[func]
    fn prompt_text(&self) -> GString {
        let interaction = self.current_interaction_dict();
        if interaction.contains_key("exit") {
            let exit_id = interaction
                .get("exit")
                .map(|v| v.stringify().to_string())
                .unwrap_or_default();

            let loc = self
                .session
                .as_ref()
                .map(|s| s.to_variant().call("current_location", &[]))
                .unwrap_or_else(Variant::nil);
            let exit_name = loc
                .try_to::<VarDictionary>()
                .ok()
                .as_ref()
                .map(|d| dict_value_as_dict(d, "exits"))
                .and_then(|exits| exits.get(exit_id.as_str()))
                .and_then(|v| v.try_to::<GString>().ok())
                .map(|s| s.to_string())
                .unwrap_or_else(|| exit_id.clone());
            return GString::from(
                format!("Space/Enter \u{8fdb}\u{5165}\u{ff1a}{}", exit_name).as_str(),
            );
        }

        if interaction.contains_key("item") {
            let item_id = interaction
                .get("item")
                .map(|v| v.stringify().to_string())
                .unwrap_or_default();

            let loc = self
                .session
                .as_ref()
                .map(|s| s.to_variant().call("current_location", &[]))
                .unwrap_or_else(Variant::nil);
            let item_name = loc
                .try_to::<VarDictionary>()
                .ok()
                .as_ref()
                .map(|d| dict_value_as_dict(d, "items"))
                .map(|items| dict_value_as_dict(&items, &item_id))
                .and_then(|item| item.get("name"))
                .and_then(|v| v.try_to::<GString>().ok())
                .map(|s| s.to_string())
                .unwrap_or_else(|| item_id.clone());
            return GString::from(
                format!("Space/Enter \u{8c03}\u{67e5}\u{ff1a}{}", item_name).as_str(),
            );
        }

        if interaction.contains_key("action") {
            let label = interaction
                .get("label")
                .and_then(|v| v.try_to::<GString>().ok())
                .map(|s| s.to_string())
                .or_else(|| {
                    interaction
                        .get("action")
                        .and_then(|v| v.try_to::<VarDictionary>().ok())
                        .as_ref()
                        .and_then(|d| d.get("verb"))
                        .and_then(|v| v.try_to::<GString>().ok())
                        .map(|s| s.to_string())
                })
                .unwrap_or_else(|| "\u{884c}\u{52a8}".to_string());
            return GString::from(format!("Space/Enter {}", label).as_str());
        }

        GString::from(
            "WASD/\u{65b9}\u{5411}\u{952e}\u{79fb}\u{52a8}\u{ff0c}Space/Enter \u{4e92}\u{52a8}",
        )
    }
}

// ── Private helpers ──────────────────────────────────────────────────────────

impl RustRpgPlayerController {
    fn finish_move(&mut self) {
        self.is_moving = false;
        self.move_elapsed = 0.0;
        self.previous_tile = self.tile;
    }

    fn is_tile_blocked(&self, target: Vector2i) -> bool {
        let Some(session) = self.session.as_ref() else {
            return true;
        };
        let Some(visual_repo) = self.visual_repository.as_ref() else {
            return true;
        };
        let scene_id = session.bind().scene_id.clone();
        let location_id = session.bind().location_id.clone();
        visual_repo
            .to_variant()
            .call(
                "is_blocked",
                &[
                    scene_id.to_variant(),
                    location_id.to_variant(),
                    target.to_variant(),
                ],
            )
            .try_to::<bool>()
            .unwrap_or(true)
    }

    fn current_interaction_dict(&self) -> VarDictionary {
        let Some(session) = self.session.as_ref() else {
            return VarDictionary::new();
        };
        let Some(visual_repo) = self.visual_repository.as_ref() else {
            return VarDictionary::new();
        };
        let scene_id = session.bind().scene_id.clone();
        let location_id = session.bind().location_id.clone();

        // Try facing-direction target first
        let target = self.tile + self.facing;
        let facing_result = visual_repo.to_variant().call(
            "interaction_at",
            &[
                scene_id.to_variant(),
                location_id.to_variant(),
                target.to_variant(),
            ],
        );
        if let Ok(d) = facing_result.try_to::<VarDictionary>() {
            if !d.is_empty() {
                return d;
            }
        }

        // Fallback: current tile
        let scene_id2 = session.bind().scene_id.clone();
        let location_id2 = session.bind().location_id.clone();
        visual_repo
            .to_variant()
            .call(
                "interaction_at",
                &[
                    scene_id2.to_variant(),
                    location_id2.to_variant(),
                    self.tile.to_variant(),
                ],
            )
            .try_to::<VarDictionary>()
            .unwrap_or_default()
    }
}
