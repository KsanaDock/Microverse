# SettingsManager.gd - 设置管理器单例
# 统一管理游戏设置，使用信号机制实现解耦

extends Node

# 设置变化信号
signal settings_changed(new_settings)
# 初始化完成信号
signal initialization_completed()

# 设置文件路径
const CONFIG_FILE = "user://settings.cfg"
const CHARACTER_AI_CONFIG_FILE = "user://character_ai_settings.cfg"

# 当前设置（默认AI设置）
var current_settings = {
	"api_type": "Ollama",
	"model": "qwen2.5:1.5b",
	"api_key": "",
	"show_ai_model_label": true,
	# 显示设置
	"window_mode": "windowed", # windowed | fullscreen | exclusive_fullscreen
	"screen_width": 1280,
	"screen_height": 720
}

# 角色独立AI设置
var character_ai_settings = {}

# 可用的API类型和模型（通过APIConfig统一管理）
var api_types: Array[String] = []
var _api_config_loaded: bool = false

func _ready():
	_load_api_config()
	load_settings()
	# 异步初始化Ollama模型列表
	_initialize_ollama_models()
	print("[SettingsManager] 设置管理器已初始化")

# 异步初始化Ollama模型列表
func _initialize_ollama_models():
	if current_settings.api_type == "Ollama":
		print("[SettingsManager] 检测到使用Ollama，正在获取本地模型列表...")
		APIConfig.get_models_for_api_async("Ollama", func(models: Array[String]):
			if models.size() > 0:
				var updated = false

				# 检查全局设置的模型是否存在
				if not models.has(current_settings.model):
					print("[SettingsManager] 当前模型 %s 不存在，切换到 %s" % [current_settings.model, models[0]])
					current_settings.model = models[0]
					updated = true

				# 检查所有角色独立设置的模型是否存在
				for character_name in character_ai_settings.keys():
					var char_settings = character_ai_settings[character_name]
					if char_settings.has("api_type") and char_settings.api_type == "Ollama":
						if char_settings.has("model") and not models.has(char_settings.model):
							print("[SettingsManager] 角色 %s 的模型 %s 不存在，切换到 %s" % [character_name, char_settings.model, models[0]])
							char_settings.model = models[0]
							updated = true

				if updated:
					save_settings()
					settings_changed.emit(current_settings.duplicate())

				print("[SettingsManager] Ollama模型列表已更新：", models)
			else:
				print("[SettingsManager] 获取Ollama模型失败，使用硬编码列表")

			# 发出初始化完成信号
			initialization_completed.emit()
		)
	else:
		# 非Ollama API，直接发出初始化完成信号
		initialization_completed.emit()

# 加载API配置
func _load_api_config():
	if not _api_config_loaded:
		api_types = APIConfig.get_api_types()
		_api_config_loaded = true

# 获取当前设置
func get_settings() -> Dictionary:
	return current_settings.duplicate()

# 更新设置并通知所有监听者
func update_settings(new_settings: Dictionary):
	current_settings = new_settings.duplicate()
	save_settings()
	settings_changed.emit(current_settings.duplicate())
	print("[SettingsManager] 设置已更新并通知所有监听者")
	# 应用显示设置
	apply_display_settings()

# 获取指定API类型的模型列表
func get_models_for_api(api_type: String) -> Array:
	_load_api_config()
	return APIConfig.get_models_for_api(api_type)

# 异步获取指定API类型的模型列表（支持Ollama动态获取）
func get_models_for_api_async(api_type: String, callback: Callable):
	_load_api_config()
	APIConfig.get_models_for_api_async(api_type, callback)

# 获取可用模型列表（为了兼容性）
func get_available_models(api_type: String) -> Array:
	return get_models_for_api(api_type)

# 保存设置到文件
func save_settings():
	var file = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_settings))
		file.close()
		print("[SettingsManager] 设置已保存到文件")
	else:
		print("[SettingsManager错误] 无法打开配置文件进行写入：", CONFIG_FILE)

	# 保存角色AI设置
	save_character_ai_settings()

# 从文件加载设置
func load_settings():
	if FileAccess.file_exists(CONFIG_FILE):
		var file = FileAccess.open(CONFIG_FILE, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()

			if content.strip_edges() != "":
				var data = JSON.parse_string(content)
				if data:
					current_settings = data
					print("[SettingsManager] 设置已从文件加载")
				else:
					print("[SettingsManager错误] JSON解析失败，使用默认设置")
			else:
				print("[SettingsManager警告] 配置文件为空，使用默认设置")
		else:
			print("[SettingsManager错误] 无法打开配置文件进行读取：", CONFIG_FILE)
	else:
		print("[SettingsManager] 配置文件不存在，使用默认设置")

	# 加载角色AI设置
	load_character_ai_settings()
	# 应用显示设置
	apply_display_settings()

# 获取角色AI设置（优先使用角色独立设置，没有则返回默认设置）
func get_character_ai_settings(character_name: String) -> Dictionary:
	if character_ai_settings.has(character_name):
		return character_ai_settings[character_name].duplicate()
	else:
		return current_settings.duplicate()

# 设置角色AI配置
func set_character_ai_settings(character_name: String, settings: Dictionary):
	character_ai_settings[character_name] = settings.duplicate()
	save_character_ai_settings()
	settings_changed.emit(current_settings.duplicate())
	print("[SettingsManager] 角色 ", character_name, " 的AI设置已更新")

# 删除角色AI设置（恢复使用默认设置）
func remove_character_ai_settings(character_name: String):
	if character_ai_settings.has(character_name):
		character_ai_settings.erase(character_name)
		save_character_ai_settings()
		settings_changed.emit(current_settings.duplicate())
		print("[SettingsManager] 角色 ", character_name, " 已恢复使用默认AI设置")

# 检查角色是否有独立AI设置
func has_character_ai_settings(character_name: String) -> bool:
	return character_ai_settings.has(character_name)

# 获取所有有独立AI设置的角色列表
func get_characters_with_ai_settings() -> Array:
	return character_ai_settings.keys()

# 保存角色AI设置到文件
func save_character_ai_settings():
	var file = FileAccess.open(CHARACTER_AI_CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(character_ai_settings))
		file.close()
		print("[SettingsManager] 角色AI设置已保存到文件")
	else:
		print("[SettingsManager错误] 无法打开角色AI配置文件进行写入：", CHARACTER_AI_CONFIG_FILE)

# 从文件加载角色AI设置
func load_character_ai_settings():
	if FileAccess.file_exists(CHARACTER_AI_CONFIG_FILE):
		var file = FileAccess.open(CHARACTER_AI_CONFIG_FILE, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()

			if content.strip_edges() != "":
				var data = JSON.parse_string(content)
				if data:
					character_ai_settings = data
					print("[SettingsManager] 角色AI设置已从文件加载")
				else:
					print("[SettingsManager错误] 角色AI设置JSON解析失败")
			else:
				print("[SettingsManager警告] 角色AI配置文件为空")
		else:
			print("[SettingsManager错误] 无法打开角色AI配置文件进行读取：", CHARACTER_AI_CONFIG_FILE)
	else:
		print("[SettingsManager] 角色AI配置文件不存在，使用空配置")

# 应用显示与窗口模式设置
func apply_display_settings(settings: Dictionary = {}):
	var s = settings if not settings.is_empty() else current_settings
	var win := get_tree().root
	if not win:
		return

	var mode: String = s.get("window_mode", "windowed")
	match mode:
		"exclusive_fullscreen":
			win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			var w = int(s.get("screen_width", 1920))
			var h = int(s.get("screen_height", 1080))
			win.size = Vector2i(w, h)
		"fullscreen":
			win.mode = Window.MODE_FULLSCREEN
		"windowed":
			win.mode = Window.MODE_WINDOWED
			win.borderless = false
			var w2 = int(s.get("screen_width", 1280))
			var h2 = int(s.get("screen_height", 720))
			win.size = Vector2i(w2, h2)
			var screen = win.current_screen
			var scr = DisplayServer.screen_get_size(screen)
			win.position = (scr - win.size) / 2

	# 兜底设置缩放
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
