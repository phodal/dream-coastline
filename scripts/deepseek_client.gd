class_name DeepSeekClient
extends Node

signal completed(text: String)
signal failed(message: String)

const DEFAULT_ENDPOINT := "https://api.deepseek.com/chat/completions"
const DEFAULT_MODEL := "deepseek-v4-flash"
const LOCAL_CONFIG_PATH := "res://deepseek.local.cfg"
const USER_CONFIG_PATH := "user://deepseek.cfg"

var api_key := ""
var endpoint := DEFAULT_ENDPOINT
var model := DEFAULT_MODEL
var max_tokens := 420
var temperature := 0.4
var thinking_enabled := false
var _http: HTTPRequest
var _pending := false


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.name = "DeepSeekHTTPRequest"
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)
	reload_config()


func reload_config() -> void:
	api_key = OS.get_environment("DEEPSEEK_API_KEY").strip_edges()
	endpoint = DEFAULT_ENDPOINT
	model = DEFAULT_MODEL
	max_tokens = 420
	temperature = 0.4
	thinking_enabled = false

	_load_config_file(LOCAL_CONFIG_PATH)
	_load_config_file(USER_CONFIG_PATH)


func is_configured() -> bool:
	return not api_key.is_empty()


func is_pending() -> bool:
	return _pending


func request_scene_notes(scene: Dictionary, location: Dictionary, log_lines: Array[String], metrics: Dictionary) -> void:
	if _pending:
		failed.emit("DeepSeek request already running.")
		return
	if not is_configured():
		failed.emit("DeepSeek is not configured. Set DEEPSEEK_API_KEY or create deepseek.local.cfg.")
		return

	var messages := [
		{
			"role": "system",
			"content": "你是一个 Godot 剧情 RPG 设计助手。请用中文给出简短、可执行的场景设计建议，不要输出代码。"
		},
		{
			"role": "user",
			"content": _build_scene_prompt(scene, location, log_lines, metrics)
		}
	]
	var body := {
		"model": model,
		"messages": messages,
		"max_tokens": max_tokens,
		"temperature": temperature,
		"stream": false,
		"thinking": {"type": "enabled" if thinking_enabled else "disabled"}
	}
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer %s" % api_key,
	])

	_pending = true
	var error := _http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		_pending = false
		failed.emit("DeepSeek request failed to start: %s" % error_string(error))


func _load_config_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return

	var config := ConfigFile.new()
	var error := config.load(path)
	if error != OK:
		push_warning("Could not load DeepSeek config %s: %s" % [path, error_string(error)])
		return

	var configured_key := str(config.get_value("deepseek", "api_key", "")).strip_edges()
	if not configured_key.is_empty():
		api_key = configured_key
	endpoint = str(config.get_value("deepseek", "endpoint", endpoint)).strip_edges()
	model = str(config.get_value("deepseek", "model", model)).strip_edges()
	max_tokens = int(config.get_value("deepseek", "max_tokens", max_tokens))
	temperature = float(config.get_value("deepseek", "temperature", temperature))
	thinking_enabled = bool(config.get_value("deepseek", "thinking_enabled", thinking_enabled))


func _build_scene_prompt(scene: Dictionary, location: Dictionary, log_lines: Array[String], current_metrics: Dictionary) -> String:
	var parts := PackedStringArray()
	parts.append("请阅读当前游戏场景状态，输出三部分：")
	parts.append("1. 这一幕当前最应该强化的玩家体验。")
	parts.append("2. 1-3 个下一步可做的关卡/交互建议。")
	parts.append("3. 一个需要避免的叙事或系统风险。")
	parts.append("")
	parts.append("场景标题：%s" % scene.get("title", ""))
	parts.append("设计源文件：%s" % scene.get("source", ""))
	parts.append("当前位置：%s" % location.get("name", ""))
	parts.append("当前位置描述：%s" % location.get("description", ""))
	parts.append("指标：%s" % JSON.stringify(current_metrics))
	if not log_lines.is_empty():
		parts.append("最近事件：")
		for line in log_lines:
			parts.append("- %s" % line)
	return "\n".join(parts)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_pending = false
	if result != HTTPRequest.RESULT_SUCCESS:
		failed.emit("DeepSeek network error: %s" % result)
		return
	if response_code < 200 or response_code >= 300:
		failed.emit("DeepSeek HTTP %s: %s" % [response_code, body.get_string_from_utf8()])
		return

	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		failed.emit("DeepSeek returned invalid JSON.")
		return

	var choices: Array = parsed.get("choices", [])
	if choices.is_empty():
		failed.emit("DeepSeek returned no choices.")
		return

	var message: Dictionary = choices[0].get("message", {})
	var content := str(message.get("content", "")).strip_edges()
	if content.is_empty():
		failed.emit("DeepSeek returned an empty response.")
		return

	completed.emit(content)
