extends Node

## PromptManager - 提示词管理器
## 管理用户输入的提示词，控制有效期和类型

## 提示词类型
enum PromptType {
	ONE_TIME,      # 一次性提示词（触发一次后失效）
	CONTINUOUS     # 持续影响提示词（在有效期内持续生效）
}

## 提示词数据结构
class Prompt:
	var id: String
	var content: String
	var prompt_type: PromptType
	var created_at: float  # Unix timestamp
	var expires_at: float  # Unix timestamp
	var is_active: bool
	var triggered_count: int  # 一次性提示词的触发次数

	func _init(content: String, prompt_type: PromptType):
		self.id = str(Time.get_unix_time_from_system()) + "_" + str(randi())
		self.content = content
		self.prompt_type = prompt_type
		self.created_at = Time.get_unix_time_from_system()
		self.expires_at = self.created_at + (5 * 3600)  # 5小时后过期
		self.is_active = true
		self.triggered_count = 0

	func is_expired() -> bool:
		return Time.get_unix_time_from_system() > expires_at

	func get_remaining_time() -> float:
		var remaining = expires_at - Time.get_unix_time_from_system()
		return max(0.0, remaining)

	func get_remaining_time_string() -> String:
		var remaining = get_remaining_time()
		var hours = int(remaining / 3600)
		var minutes = int((remaining - hours * 3600) / 60)
		var seconds = int(remaining - hours * 3600 - minutes * 60)

		if hours > 0:
			return "%dh %dm %ds" % [hours, minutes, seconds]
		elif minutes > 0:
			return "%dm %ds" % [minutes, seconds]
		else:
			return "%ds" % seconds

## 所有提示词列表
var prompts: Array[Prompt] = []

## 字数限制
const MAX_CONTENT_LENGTH = 100

## 是否启用调试模式
var debug_mode: bool = true

## 信号
signal prompt_added(prompt: Prompt)
signal prompt_expired(prompt: Prompt)
signal prompt_triggered(prompt: Prompt)

func _ready():
	if debug_mode:
		print("[PromptManager] 初始化完成")

	# 启动定时器检查过期的提示词
	var timer = Timer.new()
	timer.wait_time = 10.0  # 每10秒检查一次
	timer.one_shot = false
	timer.timeout.connect(_check_expired_prompts)
	add_child(timer)
	timer.start()

## ========================================
## 提示词操作
## ========================================

## 添加新提示词
func add_prompt(content: String, prompt_type: PromptType = PromptType.CONTINUOUS) -> Prompt:
	# 验证字数
	if content.length() > MAX_CONTENT_LENGTH:
		push_error("[PromptManager] 提示词超过字数限制（%d字）" % MAX_CONTENT_LENGTH)
		return null

	if content.strip_edges().is_empty():
		push_error("[PromptManager] 提示词不能为空")
		return null

	# 创建新提示词
	var prompt = Prompt.new(content, prompt_type)
	prompts.append(prompt)

	if debug_mode:
		print("[PromptManager] 新增提示词: \"%s\" (类型: %s, 有效期: 5小时)" % [
			content,
			"一次性" if prompt_type == PromptType.ONE_TIME else "持续影响"
		])

	prompt_added.emit(prompt)
	return prompt

## 获取所有活跃的提示词
func get_active_prompts() -> Array[Prompt]:
	var active: Array[Prompt] = []
	for prompt in prompts:
		if prompt.is_active and not prompt.is_expired():
			active.append(prompt)
	return active

## 获取所有提示词（包括过期的）
func get_all_prompts() -> Array[Prompt]:
	return prompts.duplicate()

## 移除提示词
func remove_prompt(prompt: Prompt) -> void:
	prompts.erase(prompt)
	if debug_mode:
		print("[PromptManager] 移除提示词: \"%s\"" % prompt.content)

## 移除所有提示词
func clear_all_prompts() -> void:
	prompts.clear()
	if debug_mode:
		print("[PromptManager] 清空所有提示词")

## 触发一次性提示词（调用后标记为已触发）
func trigger_prompt(prompt: Prompt) -> void:
	if prompt.prompt_type == PromptType.ONE_TIME:
		prompt.triggered_count += 1
		prompt.is_active = false  # 一次性提示词触发后失效

		if debug_mode:
			print("[PromptManager] 一次性提示词已触发: \"%s\"" % prompt.content)

		prompt_triggered.emit(prompt)

## ========================================
## 生成提示词文本（用于LLM Prompt注入）
## ========================================

## 获取所有活跃提示词的文本（用于注入到Agent的Prompt）
func get_prompts_text_for_agent() -> String:
	var active = get_active_prompts()

	if active.is_empty():
		return ""

	var text = "\n【用户的特殊指令】\n"
	text += "以下是用户给你的特殊指令，你应该尽量遵循这些指令：\n"

	for prompt in active:
		var type_label = "（持续影响）" if prompt.prompt_type == PromptType.CONTINUOUS else "（一次性）"
		text += "- %s %s\n" % [prompt.content, type_label]

	text += "\n请在你的决策和对话中体现这些指令的影响。\n"

	return text

## 获取简短版本（用于对话）
func get_brief_prompts_text() -> String:
	var active = get_active_prompts()

	if active.is_empty():
		return ""

	var text = "当前用户指令: "
	var contents: Array[String] = []
	for prompt in active:
		contents.append(prompt.content)

	text += ", ".join(contents)
	return text

## ========================================
## 内部方法
## ========================================

## 定时检查过期的提示词
func _check_expired_prompts() -> void:
	var expired_prompts: Array[Prompt] = []

	for prompt in prompts:
		if prompt.is_expired() and prompt.is_active:
			prompt.is_active = false
			expired_prompts.append(prompt)

	# 触发过期事件
	for prompt in expired_prompts:
		if debug_mode:
			print("[PromptManager] 提示词已过期: \"%s\"" % prompt.content)
		prompt_expired.emit(prompt)

## ========================================
## 工具函数
## ========================================

## 获取活跃提示词数量
func get_active_prompt_count() -> int:
	return get_active_prompts().size()

## 验证提示词内容
func validate_content(content: String) -> Dictionary:
	var result = {
		"valid": true,
		"error": ""
	}

	if content.strip_edges().is_empty():
		result.valid = false
		result.error = "提示词不能为空"
		return result

	if content.length() > MAX_CONTENT_LENGTH:
		result.valid = false
		result.error = "提示词超过字数限制（最多%d字）" % MAX_CONTENT_LENGTH
		return result

	return result

## 获取提示词统计信息
func get_statistics() -> Dictionary:
	var stats = {
		"total": prompts.size(),
		"active": 0,
		"expired": 0,
		"one_time": 0,
		"continuous": 0
	}

	for prompt in prompts:
		if prompt.is_active and not prompt.is_expired():
			stats.active += 1
		if prompt.is_expired():
			stats.expired += 1
		if prompt.prompt_type == PromptType.ONE_TIME:
			stats.one_time += 1
		else:
			stats.continuous += 1

	return stats
