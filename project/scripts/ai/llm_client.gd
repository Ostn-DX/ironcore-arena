extends Node
class_name LLMClient
## LLMClient - Local AI integration for dynamic content generation
## Part of Studio Architecture: RTX 4080 Optimization
## Requires: Ollama running locally (http://localhost:11434)

signal response_received(request_id: String, response: String, model: String)
signal stream_chunk(request_id: String, chunk: String)
signal request_failed(request_id: String, error: String)
signal model_loaded(model_name: String)
signal model_unloaded(model_name: String)

const OLLAMA_URL: String = "http://localhost:11434/api"
const DEFAULT_MODEL: String = "llama3.1:8b"
const DEFAULT_CODE_MODEL: String = "codellama:13b"

# Configuration
@export var default_model: String = DEFAULT_MODEL
@export var default_temperature: float = 0.7
@export var default_max_tokens: int = 512
@export var request_timeout_seconds: float = 60.0

# State
var _http: HTTPRequest
var _active_requests: Dictionary = {}  # request_id -> {prompt, start_time, model}
var _loaded_models: Array[String] = []
var _current_model: String = ""
var _is_initialized: bool = false

func _ready() -> void:
	_setup_http()
	_check_ollama_connection()
	print("LLMClient: Initialized")

func _setup_http() -> void:
	_http = HTTPRequest.new()
	_http.timeout = request_timeout_seconds
	add_child(_http)
	# Bible B1.3: Safe signal connection
	if _http and is_instance_valid(_http):
		if not _http.request_completed.is_connected(_on_request_completed):
			_http.request_completed.connect(_on_request_completed)

func _check_ollama_connection() -> void:
	## Verify Ollama is running
	var check_http = HTTPRequest.new()
	add_child(check_http)
	# Bible B1.3: Safe signal connection
	if check_http and is_instance_valid(check_http):
		if not check_http.request_completed.is_connected(_on_connection_check):
			check_http.request_completed.connect(_on_connection_check)
	check_http.request(OLLAMA_URL + "/tags")

func _on_connection_check(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("LLMClient: Connected to Ollama")
		_is_initialized = true
		_refresh_loaded_models()
	else:
		push_warning("LLMClient: Cannot connect to Ollama. Is it running? (http://localhost:11434)")

# ============================================================================
# GENERATION METHODS
# ============================================================================

func generate(prompt: String, options: Dictionary = {}) -> String:
	## Generate text with local LLM
	if not _is_initialized:
		push_warning("LLMClient: Not initialized, cannot generate")
		return ""
	
	var request_id = _generate_request_id()
	var model: String = options.get("model", default_model)
	
	var body = {
		"model": model,
		"prompt": prompt,
		"stream": false,
		"options": {
			"temperature": options.get("temperature", default_temperature),
			"num_predict": options.get("max_tokens", default_max_tokens),
			"top_p": options.get("top_p", 0.9),
			"top_k": options.get("top_k", 40),
			"repeat_penalty": options.get("repeat_penalty", 1.1),
			"seed": options.get("seed", -1)
		}
	}
	
	var json_body = JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	
	var req_error: Error = _http.request(OLLAMA_URL + "/generate", headers, HTTPClient.METHOD_POST, json_body)
	if req_error != OK:
		push_error("LLMClient: HTTP request failed: %d" % req_error)
		request_failed.emit(request_id, "HTTP request failed")
		return ""
	
	_active_requests[request_id] = {
		"prompt": prompt,
		"model": model,
		"start_time": Time.get_ticks_msec(),
		"is_code": options.get("is_code", false)
	}
	
	return request_id

func generate_code(prompt: String, language: String = "gdscript", options: Dictionary = {}) -> String:
	## Generate code with codellama
	var code_prompt = """Write %s code for the following:

%s

Requirements:
- Follow Godot 4.x best practices
- Include type hints where appropriate
- Add brief comments for complex logic
- Return only the code, no explanations

Code:""" % [language, prompt]
	
	var code_options = options.duplicate()
	code_options["model"] = options.get("model", DEFAULT_CODE_MODEL)
	code_options["temperature"] = options.get("temperature", 0.3)  # Lower temp for code
	code_options["is_code"] = true
	
	return await generate(code_prompt, code_options)

func generate_dialogue(character_name: String, context: String, tone: String = "neutral", options: Dictionary = {}) -> String:
	## Generate character dialogue
	var prompt: String = """You are %s, a character in Ironcore Arena (a mech combat game).

Context: %s
Tone: %s

Respond with a single line of dialogue (max 100 characters). Be concise and impactful:

%s:""" % [character_name, context, tone, character_name]
	
	options["temperature"] = options.get("temperature", 0.8)
	options["max_tokens"] = options.get("max_tokens", 50)
	
	return await generate(prompt, options)

func generate_quest_description(quest_type: String, difficulty: String, options: Dictionary = {}) -> String:
	## Generate quest content
	var prompt: String = """Generate a quest for Ironcore Arena (mech combat game).

Quest Type: %s
Difficulty: %s

Provide:
1. Title (max 5 words)
2. Description (1-2 sentences)
3. Objective (clear, actionable)
4. Reward (credits and/or component)

Format as JSON with keys: title, description, objective, reward""" % [quest_type, difficulty]
	
	options["temperature"] = options.get("temperature", 0.9)
	
	return await generate(prompt, options)

func generate_item_description(item_type: String, rarity: String, options: Dictionary = {}) -> String:
	## Generate item/flavor text
	var prompt: String = """Generate an item for Ironcore Arena (mech combat game).

Item Type: %s
Rarity: %s

Provide:
1. Name (cool, technical sounding)
2. Description (1 sentence, flavor text)
3. Stats (brief, gameplay-relevant)

Format as JSON with keys: name, description, stats""" % [item_type, rarity]
	
	return await generate(prompt, options)

# ============================================================================
# MODEL MANAGEMENT
# ============================================================================

func load_model(model_name: String) -> bool:
	## Load a model into memory
	if model_name in _loaded_models:
		_current_model = model_name
		return true
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var body = JSON.stringify({"model": model_name})
	var headers = ["Content-Type: application/json"]
	
	var req_error: Error = http.request(OLLAMA_URL + "/pull", headers, HTTPClient.METHOD_POST, body)
	if req_error != OK:
		return false
	
	# Wait for completion
	var result = await http.request_completed
	http.queue_free()
	
	if result[0] == HTTPRequest.RESULT_SUCCESS and result[1] == 200:
		_loaded_models.append(model_name)
		_current_model = model_name
		model_loaded.emit(model_name)
		return true
	
	return false

func unload_model(model_name: String) -> void:
	## Unload a model from memory
	if model_name == _current_model:
		_current_model = ""
	
	_loaded_models.erase(model_name)
	model_unloaded.emit(model_name)

func switch_model(model_name: String) -> bool:
	## Switch to a different model
	return await load_model(model_name)

func get_loaded_models() -> Array[String]:
	return _loaded_models.duplicate()

func get_current_model() -> String:
	return _current_model

func _refresh_loaded_models() -> void:
	## Get list of models from Ollama
	var http = HTTPRequest.new()
	add_child(http)
	# Bible B1.3: Safe signal connection
	if http and is_instance_valid(http):
		if not http.request_completed.is_connected(_on_models_refreshed):
			http.request_completed.connect(_on_models_refreshed)
	http.request(OLLAMA_URL + "/tags")

func _on_models_refreshed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.new()
		if json.parse(body.get_string_from_utf8()) == OK:
			var data = json.data
			if data.has("models"):
				_loaded_models.clear()
				for model in data.models:
					_loaded_models.append(model.name)
				print("LLMClient: Available models: %s" % ", ".join(_loaded_models))

# ============================================================================
# RESPONSE HANDLING
# ============================================================================

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_push_error_to_active("HTTP error: %d" % result)
		return
	
	if response_code != 200:
		_push_error_to_active("HTTP %d" % response_code)
		return
	
	var json = JSON.new()
	var parse_result: int = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		_push_error_to_active("JSON parse error: %s" % json.get_error_message())
		return
	
	var response = json.data
	var request_id: String = _active_requests.keys()[0] if not _active_requests.is_empty() else ""
	
	if request_id.is_empty():
		return
	
	var request_info = _active_requests[request_id]
	var duration_ms = Time.get_ticks_msec() - request_info.start_time
	
	if response.has("response"):
		var text = response.response
		print("LLMClient: Generated %d tokens in %dms" % [text.length(), duration_ms])
		response_received.emit(request_id, text, request_info.model)
	else:
		_push_error_to_active("No response in LLM output")
	
	_active_requests.erase(request_id)

func _push_error_to_active(error_msg: String) -> void:
	if not _active_requests.is_empty():
		var request_id: int = _active_requests.keys()[0]
		request_failed.emit(request_id, error_msg)
		_active_requests.erase(request_id)

func _generate_request_id() -> String:
	return "llm_%d_%d" % [Time.get_ticks_msec(), randi()]

# ============================================================================
# UTILITY
# ============================================================================

func is_available() -> bool:
	return _is_initialized

func get_active_request_count() -> int:
	return _active_requests.size()
