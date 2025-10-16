extends VBoxContainer

# 引用UI控件
@onready var use_default_checkbox = $UseDefaultCheckBox
@onready var api_type_option = $APITypeContainer/APITypeOption
@onready var model_option = $ModelContainer/ModelOption
@onready var api_key_input = $APIKeyContainer/APIKeyInput
@onready var save_button = $ButtonContainer/SaveButton
@onready var reset_button = $ButtonContainer/ResetButton

# 当前选中的角色名称
var current_character_name: String = ""

# API类型映射（从SettingsManager获取）
var api_types: Array[String] = []

func _ready():
	# 从SettingsManager获取API类型列表
	api_types = SettingsManager.api_types

	# 初始化API类型选项
	for api_type in api_types:
		api_type_option.add_item(api_type)

	# 连接信号
	use_default_checkbox.toggled.connect(_on_use_default_toggled)
	api_type_option.item_selected.connect(_on_api_type_selected)
	save_button.pressed.connect(_on_save_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	# 连接设置变化信号
	SettingsManager.settings_changed.connect(_on_settings_changed)

	# 初始化界面
	_update_ui_state()

func set_character(character_name: String):
	"""设置当前角色"""
	# 如果之前有角色，先保存当前状态
	if not current_character_name.is_empty() and current_character_name != character_name:
		_auto_save_current_settings()

	current_character_name = character_name
	_load_character_settings()

func _auto_save_current_settings():
	"""自动保存当前设置状态"""
	if current_character_name.is_empty():
		return

	if use_default_checkbox.button_pressed:
		# 如果勾选了使用默认设置，删除角色独立设置
		SettingsManager.remove_character_ai_settings(current_character_name)
		print("[CharacterAISettings] 自动保存：角色 ", current_character_name, " 使用默认AI设置")
	else:
		# 如果没有勾选，保存当前UI中的设置为角色独立设置
		var settings = {
			"api_type": api_types[api_type_option.selected] if api_type_option.selected >= 0 else "Ollama",
			"model": model_option.get_item_text(model_option.selected) if model_option.selected >= 0 else "",
			"api_key": api_key_input.text
		}

		SettingsManager.set_character_ai_settings(current_character_name, settings)
		print("[CharacterAISettings] 自动保存：角色 ", current_character_name, " 的独立AI设置 - API类型：", settings.api_type, "，模型：", settings.model)

func _load_character_settings():
	"""加载角色设置"""
	if current_character_name.is_empty():
		return

	# 检查是否有独立设置
	var has_independent_settings = SettingsManager.has_character_ai_settings(current_character_name)
	use_default_checkbox.button_pressed = not has_independent_settings

	if has_independent_settings:
		# 加载角色独立设置
		var character_settings = SettingsManager.get_character_ai_settings(current_character_name)
		_apply_settings_to_ui(character_settings)
	else:
		# 加载默认设置
		var default_settings = SettingsManager.current_settings
		_apply_settings_to_ui(default_settings)

	_update_ui_state()

func _apply_settings_to_ui(settings: Dictionary):
	"""将设置应用到UI"""
	# 设置API类型
	var api_type = settings.get("api_type", "Ollama")
	var api_type_index = api_types.find(api_type)
	if api_type_index >= 0:
		api_type_option.selected = api_type_index

	# 设置API密钥
	var api_key = settings.get("api_key", "")
	api_key_input.text = api_key

	# 异步更新模型列表并设置选中的模型
	var model = settings.get("model", "")
	_update_model_list_and_select(api_type, model)

func _update_model_list_and_select(api_type: String, target_model: String):
	"""更新模型列表并选择指定模型"""
	model_option.clear()
	model_option.add_item("加载中...")
	model_option.disabled = true

	SettingsManager.get_models_for_api_async(api_type, func(models: Array[String]):
		model_option.clear()
		model_option.disabled = false

		for model in models:
			model_option.add_item(model)

		# 设置选中的模型
		if not target_model.is_empty():
			for i in range(model_option.get_item_count()):
				if model_option.get_item_text(i) == target_model:
					model_option.selected = i
					break

		print("[CharacterAISettings] 模型列表已更新：", models, "，选中模型：", target_model)
	)



func _update_ui_state():
	"""更新UI状态"""
	var use_default = use_default_checkbox.button_pressed

	# 禁用/启用设置控件
	api_type_option.disabled = use_default
	model_option.disabled = use_default
	api_key_input.editable = not use_default
	save_button.disabled = use_default
	reset_button.disabled = use_default or not SettingsManager.has_character_ai_settings(current_character_name)

func _on_use_default_toggled(button_pressed: bool):
	"""使用默认设置复选框切换"""
	if button_pressed:
		# 切换到使用默认设置
		var default_settings = SettingsManager.current_settings
		_apply_settings_to_ui(default_settings)
	else:
		# 切换到独立设置
		if SettingsManager.has_character_ai_settings(current_character_name):
			# 如果有独立设置，加载独立设置
			var character_settings = SettingsManager.character_ai_settings.get(current_character_name, {})
			_apply_settings_to_ui(character_settings)
		else:
			# 如果没有独立设置，使用当前默认设置作为起始点
			var default_settings = SettingsManager.current_settings
			_apply_settings_to_ui(default_settings)

	_update_ui_state()

func _on_api_type_selected(index: int):
	"""API类型选择变化"""
	var api_type = api_types[index]
	_update_model_list_and_select(api_type, "")  # 不预选任何模型

	# 清空API密钥（不同API类型可能需要不同密钥）
	if api_type == "Ollama":
		api_key_input.text = ""
		api_key_input.placeholder_text = "Ollama无需API密钥"
	else:
		api_key_input.placeholder_text = "输入" + api_type + "的API密钥"

func _on_save_pressed():
	"""保存设置"""
	if current_character_name.is_empty():
		print("错误：没有选中角色")
		return

	if use_default_checkbox.button_pressed:
		# 删除角色独立设置
		SettingsManager.remove_character_ai_settings(current_character_name)
		print("已删除角色 ", current_character_name, " 的独立AI设置")
	else:
		# 保存角色独立设置
		var settings = {
			"api_type": api_types[api_type_option.selected],
			"model": model_option.get_item_text(model_option.selected) if model_option.selected >= 0 else "",
			"api_key": api_key_input.text
		}

		SettingsManager.set_character_ai_settings(current_character_name, settings)
		print("已保存角色 ", current_character_name, " 的AI设置 - API类型：", settings.api_type, "，模型：", settings.model)

	_update_ui_state()

func _on_reset_pressed():
	"""重置为默认设置"""
	if current_character_name.is_empty():
		return

	# 删除角色独立设置
	SettingsManager.remove_character_ai_settings(current_character_name)

	# 切换到使用默认设置
	use_default_checkbox.button_pressed = true
	_on_use_default_toggled(true)

	print("已重置角色 ", current_character_name, " 的AI设置为默认")

func _on_settings_changed(new_settings = null):
	"""全局设置变化时更新界面"""
	if use_default_checkbox.button_pressed:
		# 如果当前使用默认设置，更新界面
		var default_settings = new_settings if new_settings else SettingsManager.current_settings
		_apply_settings_to_ui(default_settings)
