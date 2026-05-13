use godot::prelude::*;

pub(crate) fn dict_value_as_dict(dict: &VarDictionary, key: &str) -> VarDictionary {
    dict.get(key)
        .and_then(|v| v.try_to::<VarDictionary>().ok())
        .unwrap_or_default()
}

pub(crate) fn dict_value_as_array(dict: &VarDictionary, key: &str) -> VarArray {
    dict.get(key)
        .and_then(|v| v.try_to::<VarArray>().ok())
        .unwrap_or_default()
}

pub(crate) fn dict_i32(dict: &VarDictionary, key: &str, default: i32) -> i32 {
    dict.get(key)
        .and_then(|v| v.try_to_relaxed::<i32>().ok())
        .unwrap_or(default)
}

pub(crate) fn dict_f64(dict: &VarDictionary, key: &str, default: f64) -> f64 {
    dict.get(key)
        .and_then(|v| v.try_to_relaxed::<f64>().ok())
        .unwrap_or(default)
}

pub(crate) fn dict_bool(dict: &VarDictionary, key: &str, default: bool) -> bool {
    dict.get(key)
        .and_then(|v| v.try_to_relaxed::<bool>().ok())
        .unwrap_or(default)
}

pub(crate) fn dict_str(dict: &VarDictionary, key: &str, default: &str) -> String {
    dict.get(key)
        .and_then(|v| v.try_to::<GString>().ok())
        .map(|s| s.to_string())
        .unwrap_or_else(|| default.to_string())
}
