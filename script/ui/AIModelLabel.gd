extends Label

# 角色名称（用于获取角色独立的AI设置）
var character_name: String = ""

# 当前设置
var current_settings = {
	"api_type": "Ollama",
	"model": "qwen2.5:1.5b",
	"api_key": ""
}

func _ready():
	# 获取角色名称
	var parent_character = get_parent()
	if parent_character:
		character_name = parent_character.name

	# 设置标签样式
	setup_label_style()

	# 连接到SettingsManager的设置更新信号
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		if settings_manager.has_signal("settings_changed"):
			settings_manager.settings_changed.connect(_on_settings_updated)

		# 如果SettingsManager有初始化完成信号，等待初始化完成
		if settings_manager.has_signal("initialization_completed"):
			settings_manager.initialization_completed.connect(_on_settings_manager_initialized)
			print("[AIModelLabel] 角色 %s 等待SettingsManager初始化完成..." % character_name)
		else:
			# 立即加载设置（向后兼容）
			load_and_update_display()
	else:
		# 如果找不到SettingsManager，使用默认设置
		load_and_update_display()

# SettingsManager初始化完成回调
func _on_settings_manager_initialized():
	print("[AIModelLabel] 角色 %s SettingsManager初始化完成，加载设置..." % character_name)
	load_and_update_display()

func setup_label_style():
	# 设置字体颜色为白色
	modulate = Color.WHITE  # 白色

	# 设置字体大小
	add_theme_font_size_override("font_size", 16)

	# 设置白色边框效果
	add_theme_color_override("font_outline_color", Color.NAVY_BLUE)
	add_theme_constant_override("outline_size", 1)

func load_and_update_display():
	# 加载设置
	load_settings()

	# 检查是否应该显示AI模型标签（从全局设置获取）
	var settings_manager = get_node_or_null("/root/SettingsManager")
	var should_show = true
	if settings_manager:
		var global_settings = settings_manager.get_settings()
		should_show = global_settings.get("show_ai_model_label", true)
	visible = should_show

	# 更新显示文本
	update_display_text()

func load_settings():
	# 使用SettingsManager获取角色对应的AI设置
	var settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager:
		if character_name != "":
			current_settings = settings_manager.get_character_ai_settings(character_name)
			print("[AIModelLabel] 角色 ", character_name, " 使用AI设置 - API类型：", current_settings.api_type, "，模型：", current_settings.model)
		else:
			current_settings = settings_manager.get_settings()
			print("[AIModelLabel] 使用默认AI设置 - API类型：", current_settings.api_type, "，模型：", current_settings.model)
	else:
		print("[AIModelLabel] 无法找到SettingsManager，使用默认设置")

func update_display_text():
	# 格式化显示文本
	# var display_text = current_settings.api_type + ": " + current_settings.model
	var display_text = current_settings.model
	text = display_text

	# 动态调整偏移量以确保文本居中
	adjust_offset_for_text()

func _on_settings_updated(new_settings):
	# 当设置更新时重新加载并更新显示
	load_settings()
	update_display_text()

	# 检查是否应该显示AI模型标签（始终从全局设置获取）
	var should_show = new_settings.get("show_ai_model_label", true)
	visible = should_show

	print("[AIModelLabel] 角色 %s 设置已更新，当前模型：%s" % [character_name, current_settings.model])

# 动态调整偏移量以确保文本居中对齐
func adjust_offset_for_text():
	# 等待一帧确保文本已更新
	await get_tree().process_frame

	# 获取文本的实际渲染尺寸
	var text_size = get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size"))

	# 计算需要的宽度（文本宽度 + 一些边距）
	var required_width = text_size.x + 10  # 左右各5像素边距
	var half_width = required_width / 2.0

	# 动态调整偏移量，确保标签居中
	offset_left = -half_width
	offset_right = half_width

# 公共方法：手动刷新显示（用于外部调用）
func refresh_display():
	load_and_update_display()
