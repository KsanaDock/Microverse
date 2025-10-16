extends CanvasLayer

# GlobalSettingsUI - 游戏设置界面管理
# 现在使用SettingsManager统一管理所有设置

# 当前设置（从SettingsManager获取）
var current_settings = {}

@onready var settings_ui = $SettingsUI
@onready var api_type_option = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/API设置/APITypeContainer/APITypeOption
@onready var model_option = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/API设置/ModelContainer/ModelOption
@onready var api_key_input = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/API设置/APIKeyContainer/APIKeyInput
@onready var ai_label_checkbox = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/API设置/AILabelContainer/AILabelCheckBox
@onready var save_button = $SettingsUI/NinePatchRect/VBoxContainer/ButtonContainer/SaveButton
@onready var cancel_button = $SettingsUI/NinePatchRect/VBoxContainer/ButtonContainer/CancelButton
@onready var map_button = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/游戏/MapButton
@onready var main_menu_button = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/游戏/MainMenuButton
@onready var quit_button = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/游戏/QuitButton
@onready var window_mode_option = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/游戏/WindowModeContainer/WindowModeOption
@onready var resolution_option = $SettingsUI/NinePatchRect/VBoxContainer/TabContainer/游戏/ResolutionContainer/ResolutionOption

func _ready():
	hide_settings()

	# 初始化API类型选项
	for type in SettingsManager.api_types:
		api_type_option.add_item(type)

	# 连接设置管理器
	SettingsManager.settings_changed.connect(_on_settings_changed)
	current_settings = SettingsManager.get_settings()
	update_ui()
	print("[GlobalSettingsUI] 已连接设置管理器")

	# 连接信号
	api_type_option.item_selected.connect(_on_api_type_selected)
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	map_button.pressed.connect(_on_map_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	window_mode_option.item_selected.connect(_on_window_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)

	# 设置为单例，确保在场景转换时不被销毁
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if settings_ui.visible:
			hide_settings()
		else:
			show_settings()

# 设置变化回调
func _on_settings_changed(new_settings: Dictionary):
	current_settings = new_settings.duplicate()
	update_ui()
	print("[GlobalSettingsUI] 设置已更新，UI已刷新")

# 更新UI显示
func update_ui():
	# 设置API类型
	var api_index = SettingsManager.api_types.find(current_settings.api_type)
	if api_index >= 0:
		api_type_option.selected = api_index

	# 异步更新模型选项
	_update_model_options()

	# 设置API Key
	api_key_input.text = current_settings.api_key

	# 设置AI标签显示复选框
	ai_label_checkbox.button_pressed = current_settings.get("show_ai_model_label", true)

	# 根据API类型显示/隐藏API Key输入框
	api_key_input.get_parent().visible = current_settings.api_type != "Ollama"

	# 初始化分辨率/窗口模式UI
	_init_display_options()
	_sync_display_options()

# 异步更新模型选项
func _update_model_options():
	model_option.clear()
	model_option.add_item("加载中...")
	model_option.disabled = true

	SettingsManager.get_models_for_api_async(current_settings.api_type, func(models: Array[String]):
		# 获取最新的设置，确保使用最新的模型信息
		current_settings = SettingsManager.get_settings()

		model_option.clear()
		model_option.disabled = false

		for model in models:
			model_option.add_item(model)

		# 选择当前模型
		var model_index = models.find(current_settings.model)
		if model_index >= 0:
			model_option.select(model_index)
		elif models.size() > 0:
			# 如果当前模型不存在，选择第一个可用模型
			model_option.select(0)
			current_settings.model = models[0]

		print("[GlobalSettingsUI] 模型选项已更新，当前模型：", current_settings.model)
	)

# API类型选择回调
func _on_api_type_selected(index):
	current_settings.api_type = SettingsManager.api_types[index]

	# 异步获取新API类型的模型并重置选择
	SettingsManager.get_models_for_api_async(current_settings.api_type, func(models: Array[String]):
		if models.size() > 0:
			current_settings.model = models[0]
		update_ui()
	)

# 初始化窗口模式与分辨率选项
func _init_display_options():
	if window_mode_option.get_item_count() == 0:
		window_mode_option.add_item("窗口化")
		window_mode_option.add_item("全屏")
		window_mode_option.add_item("独占全屏")
	if resolution_option.get_item_count() == 0:
		for r in ["1280 x 720", "1600 x 900", "1920 x 1080", "2560 x 1440", "2880 x 1800", "3840 x 2160"]:
			resolution_option.add_item(r)

func _sync_display_options():
	var mode = str(current_settings.get("window_mode", "windowed"))
	var idx = 0
	match mode:
		"windowed": idx = 0
		"fullscreen": idx = 1
		"exclusive_fullscreen": idx = 2
	window_mode_option.select(idx)

	var w = int(current_settings.get("screen_width", 1280))
	var h = int(current_settings.get("screen_height", 720))
	var target = "%d x %d" % [w, h]
	var found = false
	for i in range(resolution_option.get_item_count()):
		if resolution_option.get_item_text(i) == target:
			resolution_option.select(i)
			found = true
			break
	if not found:
		resolution_option.add_item(target)
		resolution_option.select(resolution_option.get_item_count() - 1)
	resolution_option.disabled = (current_settings.get("window_mode", "windowed") == "fullscreen")

func _on_window_mode_selected(_i):
	var t = window_mode_option.get_item_text(window_mode_option.selected)
	match t:
		"窗口化":
			current_settings.window_mode = "windowed"
		"全屏":
			current_settings.window_mode = "fullscreen"
		"独占全屏":
			current_settings.window_mode = "exclusive_fullscreen"
	resolution_option.disabled = current_settings.window_mode == "fullscreen"

func _on_resolution_selected(_i):
	var txt = resolution_option.get_item_text(resolution_option.selected)
	var parts = txt.split("x")
	if parts.size() == 2:
		current_settings.screen_width = int(parts[0].strip_edges())
		current_settings.screen_height = int(parts[1].strip_edges())

# 保存按钮回调
func _on_save_pressed():
	current_settings.model = model_option.get_item_text(model_option.selected)
	if current_settings.api_type != "Ollama":
		current_settings.api_key = api_key_input.text

	# 保存AI标签显示设置
	current_settings.show_ai_model_label = ai_label_checkbox.button_pressed

	# 通过SettingsManager更新设置
	SettingsManager.update_settings(current_settings)
	hide_settings()
	print("[GlobalSettingsUI] 设置已保存并通知所有组件")

# 取消按钮回调
func _on_cancel_pressed():
	current_settings = SettingsManager.get_settings()
	update_ui()
	hide_settings()

# 地图按钮回调
func _on_map_pressed():
	hide_settings()
	get_tree().change_scene_to_file("res://scene/MapSelection.tscn")

# 主菜单按钮回调
func _on_main_menu_pressed():
	hide_settings()
	get_tree().change_scene_to_file("res://scene/MainMenu.tscn")

# 退出按钮回调
func _on_quit_pressed():
	get_tree().quit()

# 显示设置界面
func show_settings():
	settings_ui.visible = true

# 隐藏设置界面
func hide_settings():
	settings_ui.visible = false

# 检查设置UI是否可见
func is_settings_visible() -> bool:
	return settings_ui.visible
