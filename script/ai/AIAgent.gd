extends Node

class_name AIAgent

# 角色的感知范围
const PERCEPTION_RADIUS = 200

# 角色的状态
enum State {
	IDLE,
	MOVING,
	TALKING
}

# 当前状态
var current_state = State.IDLE

# 是否由玩家控制
var is_player_controlled = false

# 角色节点引用
@onready var character = get_parent()
@onready var character_controller = character
@onready var dialog_manager = get_node("/root/DialogManager")
@onready var character_manager = get_node("/root/CharacterManager")

# 定时器，用于定期进行AI决策
var decision_timer: Timer

# 直接使用自动加载单例
@onready var api_manager = get_node("/root/APIManager")

# 添加新的感知相关变量
@onready var room_manager = get_node("/root/Office/RoomManager")

func _ready():
	# 等待SettingsManager初始化完成后再开始AI决策
	if SettingsManager.has_signal("initialization_completed"):
		SettingsManager.initialization_completed.connect(_initialize_ai_agent)
		print("[AIAgent] %s 等待SettingsManager初始化完成..." % character.name)
	else:
		# 向后兼容，立即初始化
		_initialize_ai_agent()

# 初始化AI代理（在SettingsManager初始化完成后调用）
func _initialize_ai_agent():
	print("[AIAgent] %s 开始初始化AI代理..." % character.name)

	# 创建并配置决策定时器
	decision_timer = Timer.new()
	decision_timer.wait_time = 60  # 每1分钟进行一次决策
	decision_timer.one_shot = false
	add_child(decision_timer)
	decision_timer.timeout.connect(_on_decision_timer_timeout)
	decision_timer.start()

	# 创建一个一次性定时器，等待10秒后再开始第一次决策
	var initial_delay = Timer.new()
	initial_delay.wait_time = 10.0
	initial_delay.one_shot = true
	add_child(initial_delay)
	initial_delay.timeout.connect(func(): make_decision())
	initial_delay.start()

	print("[AIAgent] %s AI代理初始化完成" % character.name)

# 切换玩家控制状态
func toggle_player_control(enabled: bool):
	is_player_controlled = enabled
	if enabled:
		# 停止AI决策
		if decision_timer:
			decision_timer.stop()
		current_state = State.IDLE
	else:
		# 恢复AI决策
		if decision_timer:
			decision_timer.start()

# 定时器超时时进行决策
func _on_decision_timer_timeout():
	if not is_player_controlled:
		make_decision()

# 修改生成场景描述函数
func generate_scene_description() -> String:
	var description = ""
	# 获取当前房间信息
	var current_room = room_manager.get_current_room(room_manager.rooms, character.global_position)
	if current_room:
		description += "你现在在" + current_room.name + "。"
		description += "\n" + current_room.description

	# 获取环境信息
	var environment_info = get_environment_info()
	description += "\n" + environment_info

	# 获取房间内的物品和角色
	var room_objects = get_room_objects(current_room)
	var room_characters = get_room_characters(current_room)

	# 添加物品描述
	if room_objects.size() > 0:
		description += "\n房间内有以下物品："
		for obj in room_objects:
			var item_info = get_object_info(obj)
			description += "\n- " + item_info

	# 添加角色描述
	if room_characters.size() > 0:
		description += "\n房间内有以下角色："
		for char in room_characters:
			# 获取角色职位信息
			var char_personality = CharacterPersonality.get_personality(char.name)
			var position = char_personality.get("position", "未知职位")

			description += "\n- " + char.name + "（" + position + "）"
			if char.has_method("get_current_state"):
				description += " - 状态：" + char.get_current_state()

	# 添加地图感知信息
	description += "\n\n地图信息："
	for room_name in room_manager.rooms:
		var room = room_manager.rooms[room_name]
		var distance = character.global_position.distance_to(room.position)
		# 计算房间边界
		var left = room.position.x - room.size.x / 2
		var right = room.position.x + room.size.x / 2
		var top = room.position.y - room.size.y / 2
		var bottom = room.position.y + room.size.y / 2

		description += "\n- " + room.name + "："
		description += "中心坐标(" + str(int(room.position.x)) + ", " + str(int(room.position.y)) + ")"
		description += "，边界范围[左:" + str(int(left)) + ", 右:" + str(int(right)) + ", 上:" + str(int(top)) + ", 下:" + str(int(bottom)) + "]"
		description += "，距离约" + str(int(distance)) + "米"
		description += "，方向:" + get_direction_description(character.global_position, room.position)

		# 添加房间内角色信息
		var room_chars = get_room_characters(room)
		if room_chars.size() > 0:
			description += "，房间内角色："
			for i in range(room_chars.size()):
				var char = room_chars[i]
				var char_personality = CharacterPersonality.get_personality(char.name)
				var position = char_personality.get("position", "未知职位")
				if i > 0:
					description += "、"
				description += char.name + "(" + position + ")"

	return description

# 获取房间内的物品
func get_room_objects(room: RoomData) -> Array:
	var room_objects = []
	var objects = get_tree().get_nodes_in_group("interactable")

	for obj in objects:
		if room and room_manager.is_position_in_room(obj.global_position, room):
			room_objects.append(obj)

	return room_objects

# 获取房间内的角色
func get_room_characters(room: RoomData) -> Array:
	var room_characters = []
	var characters = get_tree().get_nodes_in_group("character")

	for char in characters:
		if char != character and room and room_manager.is_position_in_room(char.global_position, room):
			room_characters.append(char)

	return room_characters

# 获取方向描述
func get_direction_description(from_pos: Vector2, to_pos: Vector2) -> String:
	var direction = to_pos - from_pos
	var angle = rad_to_deg(direction.angle())

	if angle >= -22.5 and angle < 22.5:
		return "东边"
	elif angle >= 22.5 and angle < 67.5:
		return "东北方向"
	elif angle >= 67.5 and angle < 112.5:
		return "北边"
	elif angle >= 112.5 and angle < 157.5:
		return "西北方向"
	elif angle >= 157.5 or angle < -157.5:
		return "西边"
	elif angle >= -157.5 and angle < -112.5:
		return "西南方向"
	elif angle >= -112.5 and angle < -67.5:
		return "南边"
	else:
		return "东南方向"

# 获取环境信息
func get_environment_info() -> String:
	# 获取当前场景名称
	var current_scene = get_tree().current_scene.name
	var environment_info = ""

	# 根据场景名称提供不同的环境描述
	match current_scene:
		"Office":
			environment_info = "这是一家现代化的公司，有多个工作区、会议室和休息区。办公室装修简洁明亮，有大窗户可以看到外面的景色。"
		"School":
			environment_info = "这是一个学校。"
		"Jail":
			environment_info = "这是监狱。"
		_:
			# 默认描述
			environment_info = "。"

	# 添加时间信息
	var time = Time.get_time_dict_from_system()
	var hour = time.hour
	var time_description = ""

	if hour >= 6 and hour < 9:
		time_description = "现在是早晨，办公室刚开始一天的工作。"
	elif hour >= 9 and hour < 12:
		time_description = "现在是上午，办公室正处于工作高峰期。"
	elif hour >= 12 and hour < 14:
		time_description = "现在是午餐时间，一些同事可能去吃午饭了。"
	elif hour >= 14 and hour < 18:
		time_description = "现在是下午，大家都在专注工作。"
	elif hour >= 18 and hour < 21:
		time_description = "现在是傍晚，一些同事开始准备下班。"
	else:
		time_description = "现在是夜晚，办公室只有少数人在加班。"

	environment_info += "\n" + time_description
	return environment_info

# 获取物品信息和功能
func get_object_info(obj: Node2D) -> String:
	var info = obj.name

	# 根据物品类型添加功能描述
	if obj is StaticBody2D:
		# 检查物品类型并添加相应描述
		if "Chair" in obj.name or obj.is_in_group("chairs"):
			info += "（一把椅子，可以坐下休息或工作）"
			# 检查椅子是否被占用
			if obj.has_method("is_occupied") and obj.is_occupied():
				info += "，目前有人正在使用"
			else:
				info += "，目前无人使用"
		elif "Desk" in obj.name:
			info += "（一张办公桌，可以在这里工作、放置电脑和文件）"
		elif "Computer" in obj.name:
			info += "（一台电脑，可以用来处理工作、查看邮件或浏览网页）"
		elif "Printer" in obj.name:
			info += "（一台打印机，可以打印文件）"
		elif "CoffeeMachine" in obj.name:
			info += "（一台咖啡机，可以提供咖啡提神）"
		elif "WaterDispenser" in obj.name:
			info += "（一台饮水机，可以喝水解渴）"
		elif "Sofa" in obj.name:
			info += "（一张沙发，可以坐下休息放松）"
		elif "Whiteboard" in obj.name:
			info += "（一块白板，可以用来开会讨论或记录想法）"
		elif "Bookshelf" in obj.name:
			info += "（一个书架，存放各种书籍和资料）"
		elif "FileCabinet" in obj.name:
			info += "（一个文件柜，存放重要文件和档案）"
		elif "Plant" in obj.name:
			info += "（一盆植物，为办公环境增添生机）"
		else:
			# 默认描述
			info += "（一个办公用品）"

	# 添加距离信息
	var distance = int(obj.global_position.distance_to(character.global_position))
	info += "，距离约" + str(distance) + "米"

	return info

# 标记是否正在等待API响应
var waiting_responses = {}

# 获取角色详细状态信息
func get_character_status_info(char_node = null) -> String:
	# 使用传入的角色节点，如果没有则使用当前角色
	var target_character = char_node if char_node else character
	var status_info = ""

	# 基本状态信息
	var money = target_character.get_meta("money", 0)
	var mood = target_character.get_meta("mood", "普通")
	var health = target_character.get_meta("health", "良好")

	status_info += "\n\n个人状态信息："
	status_info += "\n- 存款：" + str(money) + "元"
	status_info += "\n- 心情状态：" + mood
	status_info += "\n- 健康状况：" + health

	# 使用MemoryManager获取格式化的记忆信息
	status_info += MemoryManager.get_formatted_memories_for_prompt(target_character)

	# 情感关系信息
	var relations = target_character.get_meta("relations", {})
	if relations.size() > 0:
		status_info += "\n\n对其他同事的情感关系："
		for target_name in relations:
			var relation = relations[target_name]
			var emotion_type = relation["type"] if relation.has("type") else "未知"
			var strength = relation["strength"] if relation.has("strength") else 0
			var strength_desc = ""
			if strength < -5:
				strength_desc = "强烈"
			elif strength < 0:
				strength_desc = "轻微"
			elif strength == 0:
				strength_desc = "中立"
			elif strength <= 5:
				strength_desc = "轻微"
			else:
				strength_desc = "强烈"

			status_info += "\n- 对" + target_name + "：" + strength_desc + emotion_type + "（强度：" + str(strength) + "）"

	return status_info

# 获取公司员工信息字符串
func get_company_employees_info() -> String:
	var employees_info = "\n\n公司员工名单及职位信息："

	# 遍历CharacterPersonality中的所有角色配置
	for character_name in CharacterPersonality.PERSONALITY_CONFIG:
		var personality = CharacterPersonality.PERSONALITY_CONFIG[character_name]
		employees_info += "\n- " + character_name + "：" + personality["position"]

	employees_info += "\n注意：在生成任何内容时，只能提及以上列出的员工，不要创造新的角色名字。"
	return employees_info

# 获取公司基本信息字符串
func get_company_basic_info() -> String:
	var company_info = "\n\n公司基本信息："
	company_info += "\n你们公司的主要产品是《CountSheep》小游戏。"
	company_info += "\n游戏宣传语：Can't Sleep? Count Sheep"
	company_info += "\n游戏玩法：通过让用户数手机屏幕上跳过的小羊，然后有九宫格数字按钮来计数得分。"
	company_info += "\n该游戏目前十分流行，吸引了许多跟时髦的小青年充值购买小羊皮肤和按键皮肤。"
	return company_info

# 获取角色任务信息
func get_character_task_info(char_node = null) -> String:
	# 使用传入的角色节点，如果没有则使用当前角色
	var target_character = char_node if char_node else character
	var task_info = ""

	# 获取任务列表
	var tasks = target_character.get_meta("tasks", [])

	if tasks.is_empty():
		task_info += "\n\n当前任务状态：暂无任务"
		return task_info

	# 按渴望程度排序任务（从高到低）
	tasks.sort_custom(func(a, b): return a["priority"] > b["priority"])

	task_info += "\n\n当前任务列表（按渴望程度排序）："

	# 显示前3个最重要的任务
	var display_count = min(3, tasks.size())
	for i in range(display_count):
		var task = tasks[i]
		task_info += "\n%d. %s（渴望程度：%d/10）" % [i + 1, task["description"], task["priority"]]

	# 如果还有更多任务，显示总数
	if tasks.size() > display_count:
		task_info += "\n...还有 %d 个任务待完成" % (tasks.size() - display_count)

	task_info += "\n\n任务完成建议：你应该优先完成渴望程度最高的任务。"

	# 检查是否需要刷新每日任务
	_check_and_refresh_daily_tasks(target_character)

	return task_info

# 检查并刷新每日任务
func _check_and_refresh_daily_tasks(character_node):
	if not character_node:
		return

	# 获取上次刷新时间
	var last_refresh = character_node.get_meta("last_task_refresh", 0)
	var current_time = Time.get_unix_time_from_system()

	# 计算时间差（秒）
	var time_diff = current_time - last_refresh

	# 如果超过24小时（86400秒），刷新任务
	if time_diff >= 86400:
		_refresh_daily_tasks(character_node)

# 刷新每日任务
func _refresh_daily_tasks(character_node):
	if not character_node:
		return

	# 获取当前任务列表
	var tasks = character_node.get_meta("tasks", [])

	# 保留未完成的任务
	var incomplete_tasks = []
	for task in tasks:
		if not task.get("completed", false):
			incomplete_tasks.append(task)

	# 重新排序任务（根据优先级从高到低）
	incomplete_tasks.sort_custom(func(a, b): return a["priority"] > b["priority"])

	# 如果任务数量少于3个，自动生成新任务
	while incomplete_tasks.size() < 3:
		# 生成随机任务
		var new_task = _generate_random_task(character_node)
		if new_task:
			incomplete_tasks.append(new_task)
		else:
			break

	# 更新任务列表
	character_node.set_meta("tasks", incomplete_tasks)

	# 更新刷新时间
	character_node.set_meta("last_task_refresh", Time.get_unix_time_from_system())

	# 添加任务刷新记忆
	var memory_text = "你更新了今天的任务计划，共有%d个任务需要完成。" % incomplete_tasks.size()
	MemoryManager.add_memory(character_node, memory_text, MemoryManager.MemoryType.TASK, MemoryManager.MemoryImportance.NORMAL)

	print("[AIAgent] %s 的任务已刷新，当前有 %d 个任务" % [character_node.name, incomplete_tasks.size()])

# 生成随机任务
func _generate_random_task(character_node):
	if not character_node:
		return null

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(character_node.name)

	# 根据角色职位和性格生成适合的任务
	var tasks_pool = []

	# 通用任务
	tasks_pool.append("检查邮件")
	tasks_pool.append("整理工作区")
	tasks_pool.append("与同事交流")
	tasks_pool.append("参加会议")
	tasks_pool.append("休息放松一下")
	tasks_pool.append("准备明天的工作")
	tasks_pool.append("回复重要邮件")
	tasks_pool.append("整理文件")
	tasks_pool.append("学习新技能")
	tasks_pool.append("思考工作改进方案")
	tasks_pool.append("与上级沟通工作进展")
	tasks_pool.append("帮助同事解决问题")
	tasks_pool.append("制定工作计划")
	tasks_pool.append("总结今日工作")
	tasks_pool.append("准备工作报告")

	# 根据职位添加特定任务
	if personality["position"].to_lower().contains("经理") or personality["position"].to_lower().contains("主管"):
		tasks_pool.append("审核团队报告")
		tasks_pool.append("分配工作任务")
		tasks_pool.append("评估团队表现")
		tasks_pool.append("制定部门策略")
		tasks_pool.append("与其他部门协调")
	elif personality["position"].to_lower().contains("销售"):
		tasks_pool.append("联系潜在客户")
		tasks_pool.append("准备销售演示")
		tasks_pool.append("跟进销售线索")
		tasks_pool.append("更新客户资料")
		tasks_pool.append("制定销售策略")
	elif personality["position"].to_lower().contains("技术") or personality["position"].to_lower().contains("工程"):
		tasks_pool.append("修复技术问题")
		tasks_pool.append("开发新功能")
		tasks_pool.append("代码审查")
		tasks_pool.append("技术文档编写")
		tasks_pool.append("系统测试")
	elif personality["position"].to_lower().contains("人力") or personality["position"].to_lower().contains("HR"):
		tasks_pool.append("审核简历")
		tasks_pool.append("安排面试")
		tasks_pool.append("处理员工问题")
		tasks_pool.append("组织团队活动")
		tasks_pool.append("更新员工档案")

	# 随机选择一个任务
	var random_task = tasks_pool[randi() % tasks_pool.size()]

	# 随机生成优先级（1-10）
	var random_priority = randi() % 10 + 1

	# 创建任务对象
	return {
		"description": random_task,
		"priority": random_priority,
		"created_at": Time.get_unix_time_from_system(),
		"completed": false
	}

# 生成决策并执行行为
func make_decision():
	# 如果正在等待API响应，跳过本次决策
	if character.name in waiting_responses and waiting_responses[character.name]:
		print("[AIAgent] %s 正在等待上一次API响应，跳过本次决策" % character.name)
		return
	# 如果正在对话中，进行聊天中的决策
	if dialog_manager.is_character_in_conversation(character):
		print("[AIAgent] %s 正在对话中，进行聊天决策" % character.name)
		await make_conversation_decision()
		return

	# 检查并初始化任务系统
	await _check_and_initialize_tasks()

	# 生成场景描述
	var scene_description = generate_scene_description()
	print("[AIAgent] %s 的场景描述：\n%s" % [character.name, scene_description])

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(character.name)

	# 获取角色详细状态信息
	var status_info = get_character_status_info(character)

	# 获取任务信息
	var task_info = get_character_task_info(character)

	# 构建prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。你的性格是：%s。你的说话风格是：%s。你的工作职责是：%s。你的工作习惯是：%s。" % [
		character.name,
		personality["position"],
		personality["personality"],
		personality["speaking_style"],
		personality["work_duties"],
		personality["work_habits"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += status_info  # 添加详细状态信息
	prompt += task_info   # 添加任务信息
	prompt += "\n" + scene_description
	prompt += "\n请根据你的职位、性格、当前个人状态（包括心情、健康、财务状况）、记忆、情感关系、当前任务列表以及当前环境信息，综合考虑在这个情境下最合理的行动。"
	prompt += "\n特别注意：你的决策应该受到以下因素影响："
	prompt += "\n- 你的心情状态可能影响你的行为倾向"
	prompt += "\n- 你的健康状况可能限制你的活动能力"
	prompt += "\n- 你的财务状况可能影响你对金钱相关话题的敏感度"
	prompt += "\n- 你的记忆会影响你对当前情况的判断"
	prompt += "\n- 你对其他同事的情感关系会影响你是否愿意与他们互动"
	prompt += "\n- 你应该优先考虑完成渴望程度高的任务"
	prompt += "\n- 你的行动应该与当前最重要的任务相关"
	prompt += "\n\n根据以上所有信息，你想要采取什么行动？请从以下选项中选择一个："
	prompt += "\n1. 调整任务（重新安排或修改当前的任务优先级）"
	prompt += "\n2. 继续当前任务（执行当前最重要的任务）"
	prompt += "\n请只回复数字1或2，不要有任何其他文字。"

	# 使用APIManager生成AI决策
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 为每个角色创建唯一的回调连接
	# 断开之前可能存在的连接，避免重复连接
	if http_request.request_completed.is_connected(_on_decision_request_completed):
		http_request.request_completed.disconnect(_on_decision_request_completed)

	# 使用带有角色标识的回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_decision_request_completed(result, response_code, headers, body, character)
	)
	waiting_responses[character.name] = true

# 处理API响应
func _on_decision_request_completed(result, _response_code, headers, body, char_node = null):
	# 使用传入的角色节点，如果没有则使用当前角色
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 的HTTP请求失败，错误码：%s，使用默认决策" % [target_character.name, result])
		_execute_default_decision(target_character)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 的JSON解析失败，使用默认决策" % target_character.name)
		_execute_default_decision(target_character)
		return

	# 使用APIConfig统一解析响应
	var decision = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if decision == "":
		print("[AIAgent] %s 的API响应解析失败，使用默认决策" % target_character.name)
		_execute_default_decision(target_character)
		return

	decision = decision.strip_edges()

	# 根据决策执行行为
	print("[AIAgent] %s 的决策结果：%s" % [target_character.name, decision])
	match decision:
		"1":  # 调整任务
			print("[AIAgent] %s 决定调整任务" % target_character.name)
			await _adjust_tasks(target_character)
		"2":  # 继续当前任务
			print("[AIAgent] %s 决定继续当前任务" % target_character.name)
			await _continue_current_task(target_character)
		_:
			print("[AIAgent] 无效的决策：", decision)

# 聊天中的决策
func make_conversation_decision():
	# 如果正在等待API响应，跳过本次决策
	if character.name in waiting_responses and waiting_responses[character.name]:
		print("[AIAgent] %s 正在等待上一次API响应，跳过聊天决策" % character.name)
		return

	# 获取当前对话的对象
	var conversation_partner = _get_conversation_partner(character)
	if not conversation_partner:
		print("[AIAgent] %s 无法获取对话对象" % character.name)
		return

	# 获取聊天记录
	var chat_history = ""
	if character.has_node("ChatHistory"):
		var history_node = character.get_node("ChatHistory")
		chat_history = history_node.get_recent_conversation_with(conversation_partner.name, 10)

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(character.name)

	# 获取角色详细状态信息
	var status_info = get_character_status_info(character)

	# 获取任务信息
	var task_info = get_character_task_info(character)

	# 构建聊天决策prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。你的性格是：%s。你的说话风格是：%s。" % [
		character.name,
		personality["position"],
		personality["personality"],
		personality["speaking_style"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += status_info
	prompt += task_info

	# 添加当前对话信息
	prompt += "\n\n你正在与%s对话。" % conversation_partner.name

	# 添加聊天记录
	if chat_history != "":
		prompt += "\n\n你们最近的对话记录：\n" + chat_history
	else:
		prompt += "\n\n这是你们刚开始的对话。"

	# 添加决策选项
	prompt += "\n\n请根据你的性格、当前状态、任务列表和对话内容，判断你是否应该继续这次对话："
	prompt += "\n- 如果当前对话有助于完成你的任务，或者你觉得有必要继续交流，选择继续对话"
	prompt += "\n- 如果你觉得对话已经足够，或者你有更重要的事情要做，选择结束对话"
	prompt += "\n\n请从以下选项中选择一个："
	prompt += "\n1. 继续对话（保持当前对话状态）"
	prompt += "\n2. 结束对话（礼貌地结束当前对话）"
	prompt += "\n请只回复数字1或2，不要有任何其他文字。"

	# 使用APIManager生成AI决策
	var character_name = character.name if character else "Unknown"
	print(prompt)
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 连接回调函数
	if http_request.request_completed.is_connected(_on_conversation_decision_completed):
		http_request.request_completed.disconnect(_on_conversation_decision_completed)

	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_conversation_decision_completed(result, response_code, headers, body, character, conversation_partner)
	)
	waiting_responses[character.name] = true

# 处理聊天决策API响应
func _on_conversation_decision_completed(result, _response_code, headers, body, char_node, partner_node):
	# 重置等待状态
	waiting_responses[char_node.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 的聊天决策HTTP请求失败，错误码：%s" % [char_node.name, result])
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 的聊天决策JSON解析失败" % char_node.name)
		return

	# 使用APIConfig统一解析响应
	var decision = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if decision == "":
		print("[AIAgent] %s 的聊天决策API响应解析失败" % char_node.name)
		return

	decision = decision.strip_edges()

	# 根据决策执行行为
	print("[AIAgent] %s 的聊天决策结果：%s" % [char_node.name, decision])
	match decision:
		"1":  # 继续对话
			print("[AIAgent] %s 决定继续对话" % char_node.name)
			# 不做任何操作，保持对话状态
		"2":  # 结束对话
			print("[AIAgent] %s 决定结束对话" % char_node.name)
			await _generate_farewell_message(char_node, partner_node)
		_:
			print("[AIAgent] 无效的聊天决策：", decision)

# 生成告别消息并结束对话
func _generate_farewell_message(char_node, partner_node):
	# 获取角色人设
	var personality = CharacterPersonality.get_personality(char_node.name)

	# 获取聊天记录
	var chat_history = ""
	if char_node.has_node("ChatHistory"):
		var history_node = char_node.get_node("ChatHistory")
		chat_history = history_node.get_recent_conversation_with(partner_node.name, 5)

	# 构建告别消息prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。你的性格是：%s。你的说话风格是：%s。" % [
		char_node.name,
		personality["position"],
		personality["personality"],
		personality["speaking_style"]
	]

	prompt += "\n\n你正在与%s对话，现在你决定要结束这次对话。" % partner_node.name

	if chat_history != "":
		prompt += "\n\n你们刚才的对话内容：\n" + chat_history

	prompt += "\n\n请生成一句礼貌的告别话语来结束这次对话。要求："
	prompt += "\n- 符合你的性格和说话风格"
	prompt += "\n- 语气自然友好"
	prompt += "\n- 长度适中（1-2句话）"
	prompt += "\n- 不要解释为什么要离开，只需要礼貌告别"
	prompt += "\n\n请直接回复告别的话语，不要包含其他内容。"

	# 使用APIManager生成告别消息
	var character_name = char_node.name if char_node else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 连接回调函数
	if http_request.request_completed.is_connected(_on_farewell_message_completed):
		http_request.request_completed.disconnect(_on_farewell_message_completed)

	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_farewell_message_completed(result, response_code, headers, body, char_node, partner_node)
	)
	waiting_responses[char_node.name] = true

# 处理告别消息API响应
func _on_farewell_message_completed(result, _response_code, headers, body, char_node, partner_node):
	# 重置等待状态
	waiting_responses[char_node.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 的告别消息HTTP请求失败，错误码：%s" % [char_node.name, result])
		# 使用默认告别消息
		_send_farewell_and_end_conversation(char_node, partner_node, "好的，你先去忙其他事情了，回头聊。")
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 的告别消息JSON解析失败" % char_node.name)
		_send_farewell_and_end_conversation(char_node, partner_node, "好的，你先去忙其他事情了，回头聊。")
		return

	# 使用APIConfig统一解析响应
	var farewell_message = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if farewell_message == "":
		print("[AIAgent] %s 的告别消息API响应解析失败" % char_node.name)
		farewell_message = "好的，你先去忙其他事情了，回头聊。"

	farewell_message = farewell_message.strip_edges()
	print("[AIAgent] %s 生成的告别消息：%s" % [char_node.name, farewell_message])

	# 发送告别消息并结束对话
	_send_farewell_and_end_conversation(char_node, partner_node, farewell_message)

# 发送告别消息并结束对话
func _send_farewell_and_end_conversation(char_node, partner_node, farewell_message):
	# 通过DialogManager发送告别消息
	var dialog_manager = get_node("/root/DialogManager")
	if dialog_manager:
		# 创建对话气泡显示告别消息
		var dialog_bubble_scene = preload("res://scene/UI/DialogBubble.tscn")
		var dialog_bubble = dialog_bubble_scene.instantiate()
		get_tree().root.add_child(dialog_bubble)
		dialog_bubble.target_node = char_node
		dialog_bubble.show_dialog(farewell_message)

		# 保存告别消息到聊天记录
		var formatted_message = char_node.name + ": " + farewell_message
		if char_node.has_node("ChatHistory"):
			var char_history = char_node.get_node("ChatHistory")
			char_history.add_message(partner_node.name, formatted_message)
		if partner_node.has_node("ChatHistory"):
			var partner_history = partner_node.get_node("ChatHistory")
			partner_history.add_message(char_node.name, formatted_message)

		# 等待一小段时间让消息显示
		await get_tree().create_timer(1.0).timeout

		# 结束对话
		dialog_manager.end_character_conversations(char_node)
	else:
		print("[AIAgent] 无法获取DialogManager，直接结束对话")
		# 如果无法获取DialogManager，尝试直接获取并结束对话
		var fallback_dialog_manager = get_node("/root/DialogManager")
		if fallback_dialog_manager:
			fallback_dialog_manager.end_character_conversations(char_node)

# 生成思考内容
func generate_thinking_content(char_node = null):
	# 使用传入的角色节点，如果没有则使用当前角色
	var target_character = char_node if char_node else character

	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		print("[AIAgent] %s 正在等待上一次API响应，跳过生成思考内容" % target_character.name)
		return

	# 生成场景描述
	var scene_description = generate_scene_description()

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(target_character.name)

	# 获取角色详细状态信息
	var status_info = get_character_status_info(target_character)

	# 获取当前任务信息
	var tasks_info = ""
	var metadata = target_character.get_meta("character_data", {})
	var tasks = metadata.get("tasks", [])
	if tasks.size() > 0:
		# 获取未完成的任务
		var active_tasks = []
		for task in tasks:
			if not task.get("completed", false):
				active_tasks.append(task)

		if active_tasks.size() > 0:
			# 按优先级排序
			active_tasks.sort_custom(func(a, b): return a.priority > b.priority)
			tasks_info += "\n\n你当前的任务列表："
			for i in range(min(active_tasks.size(), 3)):
				var task = active_tasks[i]
				tasks_info += "\n%d. %s（渴望程度：%d）" % [i+1, task.description, task.priority]

	# 构建简化的思考prompt
	var prompt = "你是%s，职位：%s。性格：%s。说话风格：%s。" % [
		target_character.name,
		personality["position"],
		personality["personality"],
		personality["speaking_style"]
	]

	# 只添加关键的个人状态信息
	var money = target_character.get_meta("money", 0)
	var mood = target_character.get_meta("mood", "普通")
	var health = target_character.get_meta("health", "良好")
	prompt += "\n当前状态：心情%s，健康%s，存款%d元。" % [mood, health, money]

	# 添加最重要的任务信息
	if tasks_info != "":
		prompt += tasks_info

	# 添加最近的重要记忆（只取最后1条）
	var recent_memories = MemoryManager.get_recent_memories(target_character, 24)
	if recent_memories.size() > 0:
		var recent_memory = MemoryManager._format_memory_for_display(recent_memories[recent_memories.size() - 1])
		prompt += "\n最近记忆：" + recent_memory

	prompt += "\n\n现在请用第一人称表达你此刻的内心想法。要求："
	prompt += "\n1. 体现你的性格和说话风格"
	prompt += "\n2. 考虑你的当前状态和任务"
	prompt += "\n3. 50-100字的简短内心独白"
	prompt += "\n4. 只返回纯粹的心理活动，不要任何环境描述、动作描述或旁白"
	prompt += "\n5. 像真实的内心声音一样自然流露"

	print(prompt)
	# 使用APIManager生成思考内容
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接，避免重复连接
	if http_request.request_completed.is_connected(_on_thinking_request_completed):
		http_request.request_completed.disconnect(_on_thinking_request_completed)

	# 使用带有角色标识的回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_thinking_request_completed(result, response_code, headers, body, target_character)
	)
	waiting_responses[target_character.name] = true

# 检查并初始化任务系统
func _check_and_initialize_tasks():
	# 检查角色是否已有任务数据
	var metadata = character.get_meta("character_data", {})
	if not metadata.has("tasks") or metadata["tasks"].size() == 0:
		print("[AIAgent] %s 没有任务数据，开始生成初始任务" % character.name)
		await _generate_initial_tasks()
	else:
		print("[AIAgent] %s 已有 %d 个任务" % [character.name, metadata["tasks"].size()])

# 生成初始任务
func _generate_initial_tasks():
	# 如果正在等待API响应，跳过
	if character.name in waiting_responses and waiting_responses[character.name]:
		return

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(character.name)

	# 获取角色详细状态信息
	var status_info = get_character_status_info(character)

	# 构建生成任务的prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。你的性格是：%s。你的说话风格是：%s。你的工作职责是：%s。你的工作习惯是：%s。" % [
		character.name,
		personality["position"],
		personality["personality"],
		personality["speaking_style"],
		personality["work_duties"],
		personality["work_habits"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += status_info
	prompt += "\n\n请根据你的职位、性格和当前状态，生成3个你当前最想做的任务。这些任务应该："
	prompt += "\n- 符合你的职位和工作职责"
	prompt += "\n- 体现你的性格特点"
	prompt += "\n- 考虑你当前的心情、健康和财务状况"
	prompt += "\n- 包括工作任务和个人事务"
	prompt += "\n- 每个任务用一句话描述（20-50字）"
	prompt += "\n\n请按以下格式输出，每行一个任务，格式为：任务描述|渴望程度（1-10的数字）"
	prompt += "\n例如："
	prompt += "\n完成本月的销售报告|8"
	prompt += "\n与同事讨论新项目方案|6"
	prompt += "\n整理办公桌上的文件|4"
	prompt += "\n\n请生成3个任务："

	# 使用APIManager生成任务
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_generate_tasks_completed):
		http_request.request_completed.disconnect(_on_generate_tasks_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_generate_tasks_completed(result, response_code, headers, body, character)
	)
	waiting_responses[character.name] = true

# 处理生成任务的API响应
func _on_generate_tasks_completed(result, _response_code, headers, body, char_node = null):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 生成任务的HTTP请求失败，错误码：%s" % [target_character.name, result])
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 生成任务的JSON解析失败" % target_character.name)
		return

	# 解析AI生成的任务内容
	var task_content = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if task_content == "":
		print("[AIAgent] %s 的任务生成API响应解析失败，使用默认任务" % target_character.name)
		_generate_default_tasks(target_character)
		return

	print("[AIAgent] %s 生成的任务内容：\n%s" % [target_character.name, task_content])

	# 解析任务列表
	var tasks = []
	var lines = task_content.split("\n")
	for line in lines:
		line = line.strip_edges()
		if line.length() > 0 and "|" in line:
			var parts = line.split("|")
			if parts.size() >= 2:
				var description = parts[0].strip_edges()
				var priority_str = parts[1].strip_edges()
				var priority = int(priority_str) if priority_str.is_valid_int() else 5

				# 确保优先级在1-10范围内
				priority = max(1, min(10, priority))

				tasks.append({
					"description": description,
					"priority": priority,
					"created_at": Time.get_unix_time_from_system(),
					"completed": false
				})

	# 如果解析的任务少于3个，用随机任务补充
	while tasks.size() < 3:
		tasks.append(_generate_random_task(target_character))

	# 按优先级排序
	tasks.sort_custom(func(a, b): return a.priority > b.priority)

	# 保存任务到角色元数据
	var metadata = target_character.get_meta("character_data", {})
	metadata["tasks"] = tasks
	target_character.set_meta("character_data", metadata)

	# 添加任务生成记忆
	var memory_text = "你为自己制定了新的任务计划，包含了%d个重要任务，准备开始执行。" % tasks.size()
	MemoryManager.add_memory(target_character, memory_text, MemoryManager.MemoryType.TASK, MemoryManager.MemoryImportance.NORMAL)

	print("[AIAgent] %s 成功生成并保存了 %d 个任务" % [target_character.name, tasks.size()])

# 调整任务
func _adjust_tasks(char_node = null):
	var target_character = char_node if char_node else character

	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		return

	# 获取当前任务
	var metadata = target_character.get_meta("character_data", {})
	var tasks = metadata.get("tasks", [])

	if tasks.size() == 0:
		print("[AIAgent] %s 没有任务可调整" % target_character.name)
		return

	# 获取角色人设和状态
	var personality = CharacterPersonality.get_personality(target_character.name)
	var status_info = get_character_status_info(target_character)
	var scene_description = generate_scene_description()

	# 构建调整任务的prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。你的性格是：%s。" % [
		target_character.name,
		personality["position"],
		personality["personality"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += status_info
	prompt += "\n" + scene_description
	prompt += "\n\n你当前的任务列表："
	for i in range(min(tasks.size(), 5)):
		var task = tasks[i]
		prompt += "\n%d. %s（渴望程度：%d）" % [i+1, task.description, task.priority]

	prompt += "\n\n根据你当前的状态、环境和心情，你是否需要调整这些任务的优先级？"
	prompt += "\n请从以下选项中选择："
	prompt += "\n1. 保持当前任务优先级不变"
	prompt += "\n2. 重新安排任务优先级"
	prompt += "\n3. 添加一个新的紧急任务"
	prompt += "\n请只回复数字1、2或3，不要有任何其他文字。"

	# 使用APIManager生成决策
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_adjust_tasks_completed):
		http_request.request_completed.disconnect(_on_adjust_tasks_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_adjust_tasks_completed(result, response_code, headers, body, target_character)
	)
	waiting_responses[target_character.name] = true

# 处理调整任务的API响应
func _on_adjust_tasks_completed(result, _response_code, headers, body, char_node = null):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 调整任务的HTTP请求失败" % target_character.name)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 调整任务的JSON解析失败" % target_character.name)
		return

	# 解析决策
	var decision = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if decision == "":
		print("[AIAgent] %s 的任务调整API响应解析失败" % target_character.name)
		return

	decision = decision.strip_edges()
	print("[AIAgent] %s 的任务调整决策：%s" % [target_character.name, decision])

	match decision:
		"1":  # 保持不变
			print("[AIAgent] %s 决定保持当前任务优先级" % target_character.name)
			# 添加记忆
			_add_memory(target_character, "你检查了当前的任务列表，决定保持现有的优先级安排。")
		"2":  # 重新安排
			print("[AIAgent] %s 决定重新安排任务优先级" % target_character.name)
			await _rearrange_task_priorities(target_character)
		"3":  # 添加新任务
			print("[AIAgent] %s 决定添加新的紧急任务" % target_character.name)
			await _add_urgent_task(target_character)
		_:
			print("[AIAgent] %s 的任务调整决策无效：%s" % [target_character.name, decision])

# 继续当前任务
func _continue_current_task(char_node = null):
	var target_character = char_node if char_node else character

	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		return

	# 获取当前最重要的任务
	var metadata = target_character.get_meta("character_data", {})
	var tasks = metadata.get("tasks", [])

	# 过滤未完成的任务并按优先级排序
	var active_tasks = []
	for task in tasks:
		if not task.get("completed", false):
			active_tasks.append(task)

	if active_tasks.size() == 0:
		print("[AIAgent] %s 没有未完成的任务" % target_character.name)
		# 生成新任务
		await _generate_initial_tasks()
		return

	# 按优先级排序
	active_tasks.sort_custom(func(a, b): return a.priority > b.priority)
	var current_task = active_tasks[0]

	# 获取角色人设和状态
	var personality = CharacterPersonality.get_personality(target_character.name)
	var status_info = get_character_status_info(target_character)
	var scene_description = generate_scene_description()

	# 构建执行任务的prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。你的性格是：%s。" % [
		target_character.name,
		personality["position"],
		personality["personality"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += status_info
	prompt += "\n" + scene_description
	prompt += "\n\n你当前最重要的任务是：%s（渴望程度：%d）" % [current_task.description, current_task.priority]
	prompt += "\n\n为了完成这个任务，你需要采取什么具体行动？请从以下选项中选择："
	prompt += "\n1. 移动到某个位置（去找相关的人或物品）"
	prompt += "\n2. 与某个角色交谈（讨论任务相关内容）"
	prompt += "\n3. 思考规划（在当前位置思考如何完成任务）"
	prompt += "\n4. 完成任务（任务已经可以标记为完成）"
	prompt += "\n请只回复数字1、2、3或4，不要有任何其他文字。"

	# 使用APIManager生成决策
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_continue_task_completed):
		http_request.request_completed.disconnect(_on_continue_task_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_continue_task_completed(result, response_code, headers, body, target_character, current_task)
	)
	waiting_responses[target_character.name] = true

# 处理继续任务的API响应
func _on_continue_task_completed(result, _response_code, headers, body, char_node = null, current_task = null):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 继续任务的HTTP请求失败" % target_character.name)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 继续任务的JSON解析失败" % target_character.name)
		return

	# 解析决策
	var decision = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if decision == "":
		print("[AIAgent] %s 的任务调整API响应解析失败" % target_character.name)
		return

	decision = decision.strip_edges()
	print("[AIAgent] %s 的任务执行决策：%s" % [target_character.name, decision])

	match decision:
		"1":  # 移动
			print("[AIAgent] %s 决定移动来完成任务：%s" % [target_character.name, current_task.description])
			await _execute_task_movement(target_character, current_task)
		"2":  # 对话
			print("[AIAgent] %s 决定通过对话来完成任务：%s" % [target_character.name, current_task.description])
			await _execute_task_conversation(target_character, current_task)
		"3":  # 思考
			print("[AIAgent] %s 决定思考如何完成任务：%s" % [target_character.name, current_task.description])
			await _execute_task_thinking(target_character, current_task)
		"4":  # 完成任务
			print("[AIAgent] %s 决定标记任务为完成：%s" % [target_character.name, current_task.description])
			_complete_task(target_character, current_task)
		_:
			print("[AIAgent] %s 的任务执行决策无效：%s" % [target_character.name, decision])

# 添加记忆的辅助函数
func _add_memory(target_character, content: String):
	# 使用MemoryManager添加记忆
	MemoryManager.add_memory(target_character, content, MemoryManager.MemoryType.PERSONAL, MemoryManager.MemoryImportance.NORMAL)

# 执行任务相关的移动
func _execute_task_movement(target_character, current_task):
	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		return

	# 获取角色人设和状态
	var personality = CharacterPersonality.get_personality(target_character.name)
	var scene_description = generate_scene_description()

	# 构建移动决策的prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。" % [
		target_character.name,
		personality["position"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += "\n" + scene_description
	prompt += "\n\n你当前的任务是：%s" % current_task.description
	prompt += "\n\n为了完成这个任务，你需要移动到哪里？请根据当前环境中的物品以及公司员工信息，选择一个最合适的目标。"
	prompt += "\n请只回复目标的名字，不要有任何其他文字。如果没有合适的目标，请回复'无合适目标'。"
	print(prompt)
	# 使用APIManager生成决策
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_task_movement_completed):
		http_request.request_completed.disconnect(_on_task_movement_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_task_movement_completed(result, response_code, headers, body, target_character, current_task)
	)
	waiting_responses[target_character.name] = true

# 处理任务移动的API响应
func _on_task_movement_completed(result, _response_code, headers, body, char_node = null, current_task = null):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 任务移动的HTTP请求失败" % target_character.name)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 任务移动的JSON解析失败" % target_character.name)
		return

	# 解析目标
	var target_name = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if target_name == "":
		print("[AIAgent] %s 的任务移动API响应解析失败" % target_character.name)
		return

	target_name = target_name.strip_edges()
	print("[AIAgent] %s 选择移动到：%s" % [target_character.name, target_name])

	if target_name == "无合适目标":
		print("[AIAgent] %s 没有找到合适的移动目标" % target_character.name)
		_add_memory(target_character, "你想要完成任务'%s'，但是当前环境中没有合适的移动目标。" % current_task.description)
		return

	# 尝试找到目标并移动
	var target_info = _find_target_by_name(target_name)
	if not target_info.is_empty():
		var target_display_name = ""
		match target_info.type:
			"object":
				target_display_name = target_info.target.name + "（物品）"
			"character":
				target_display_name = target_info.target.name + "（角色）"
			"room":
				target_display_name = target_info.target.name + "（房间）"
		print("[AIAgent] %s 开始移动到 %s 来完成任务" % [target_character.name, target_display_name])
		move_to_target(target_info, target_character)
		_add_memory(target_character, "为了完成任务'%s'，你移动到了%s。" % [current_task.description, target_display_name])
	else:
		print("[AIAgent] %s 没有找到名为'%s'的目标" % [target_character.name, target_name])
		# 当前房间找不到目标，询问是否要去其他房间寻找
		await _handle_target_not_found(target_character, target_name, current_task)

# 根据名字查找目标
func _find_target_by_name(target_name: String):
	# 获取当前房间
	var current_room = room_manager.get_current_room(room_manager.rooms, character.global_position)
	if not current_room:
		return {}

	# 查找角色
	var room_characters = get_room_characters(current_room)
	for char in room_characters:
		if char.name.to_lower().contains(target_name.to_lower()) or target_name.to_lower().contains(char.name.to_lower()):
			return {"type": "character", "target": char}

	# 查找物品
	var room_objects = get_room_objects(current_room)
	for obj in room_objects:
		if obj.name.to_lower().contains(target_name.to_lower()) or target_name.to_lower().contains(obj.name.to_lower()):
			return {"type": "object", "target": obj}

	# 查找房间
	for room_name in room_manager.rooms:
		var room = room_manager.rooms[room_name]
		if room.name.to_lower().contains(target_name.to_lower()) or target_name.to_lower().contains(room.name.to_lower()):
			return {"type": "room", "target": room}

	return {}

# 执行任务相关的对话
func _execute_task_conversation(target_character, current_task):
	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		return

	# 获取所有角色（除了自己）
	var all_characters = get_tree().get_nodes_in_group("characters")
	var available_chars = []
	for char in all_characters:
		if char != target_character:
			available_chars.append(char)

	if available_chars.size() == 0:
		print("[AIAgent] %s 没有其他角色可以交谈" % target_character.name)
		_add_memory(target_character, "你想要通过对话来完成任务'%s'，但是公司里没有其他人。" % current_task.description)
		return

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(target_character.name)

	# 构建对话选择的prompt，包含角色的精确坐标信息
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。" % [
		target_character.name,
		personality["position"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += "\n\n你当前的任务是：%s" % current_task.description
	prompt += "\n\n公司里有以下同事可以交谈："
	for char in available_chars:
		var char_personality = CharacterPersonality.get_personality(char.name)
		var char_room = room_manager.get_current_room(room_manager.rooms, char.global_position)
		var room_name = char_room.name if char_room else "未知位置"
		var distance = target_character.global_position.distance_to(char.global_position)
		prompt += "\n- %s（%s，位置：%s，距离：%.0f米）" % [char.name, char_personality["position"], room_name, distance]

	prompt += "\n\n为了完成这个任务，你最想与谁交谈？请说明选择的原因，然后在最后一行只写出角色的名字。"

	# 使用APIManager生成决策
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_task_conversation_completed):
		http_request.request_completed.disconnect(_on_task_conversation_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_task_conversation_completed(result, response_code, headers, body, target_character, current_task, available_chars)
	)
	waiting_responses[target_character.name] = true

# 处理任务对话的API响应
func _on_task_conversation_completed(result, _response_code, headers, body, char_node = null, current_task = null, available_chars = []):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 任务对话的HTTP请求失败" % target_character.name)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 任务对话的JSON解析失败" % target_character.name)
		return

	# 解析选择的角色
	var chosen_name = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if chosen_name == "":
		print("[AIAgent] %s 的任务对话API响应解析失败" % target_character.name)
		return

	# 从响应中提取角色名字（取最后一行）
	var lines = chosen_name.strip_edges().split("\n")
	if lines.size() > 0:
		chosen_name = lines[-1].strip_edges()

	print("[AIAgent] %s 选择与 %s 交谈" % [target_character.name, chosen_name])

	# 找到对应的角色
	var chosen_character = null
	for char in available_chars:
		if char.name.to_lower().contains(chosen_name.to_lower()) or chosen_name.to_lower().contains(char.name.to_lower()):
			chosen_character = char
			break

	if chosen_character:
		# 检查目标角色是否在同一房间
		var current_room = room_manager.get_current_room(room_manager.rooms, target_character.global_position)
		var target_room = room_manager.get_current_room(room_manager.rooms, chosen_character.global_position)

		if current_room == target_room:
			# 在同一房间，直接开始交谈
			print("[AIAgent] %s 与 %s 在同一房间，开始交谈" % [target_character.name, chosen_character.name])
			initiate_conversation(chosen_character, target_character)
			_add_memory(target_character, "为了完成任务'%s'，你与%s进行了交谈。" % [current_task.description, chosen_character.name])
		else:
			# 不在同一房间，直接移动到目标角色的精确位置
			var target_room_name = target_room.name if target_room else "未知位置"
			print("[AIAgent] %s 需要移动到 %s 找 %s 交谈" % [target_character.name, target_room_name, chosen_character.name])

			# 直接移动到目标角色的位置
			if target_character.has_method("move_to"):
				# 获取目标角色的精确坐标
				var target_pos = chosen_character.global_position
				print("[AIAgent] %s 移动到坐标 (%s, %s) 寻找 %s" % [target_character.name, target_pos.x, target_pos.y, chosen_character.name])
				target_character.move_to(target_pos)

				# 添加记忆
				_add_memory(target_character, "为了完成任务'%s'，你需要去找%s交谈，正在前往%s的位置(%.0f, %.0f)。" % [current_task.description, chosen_character.name, target_room_name, target_pos.x, target_pos.y])

				# 使用更智能的到达检测机制
				_start_movement_tracking(target_character, chosen_character, current_task)
			else:
				print("[AIAgent] %s 无法移动，交谈失败" % target_character.name)
				_add_memory(target_character, "你想要去找%s交谈来完成任务'%s'，但是无法移动。" % [chosen_character.name, current_task.description])
	else:
		print("[AIAgent] %s 没有找到名为'%s'的角色" % [target_character.name, chosen_name])
		# 默认与第一个角色交谈
		if available_chars.size() > 0:
			var default_char = available_chars[0]
			print("[AIAgent] %s 默认与 %s 交谈" % [target_character.name, default_char.name])

			# 对默认角色也进行同样的房间检查和移动逻辑
			var current_room = room_manager.get_current_room(room_manager.rooms, target_character.global_position)
			var target_room = room_manager.get_current_room(room_manager.rooms, default_char.global_position)

			if current_room == target_room:
				# 在同一房间，直接开始交谈
				initiate_conversation(default_char, target_character)
				_add_memory(target_character, "为了完成任务'%s'，你与%s进行了交谈。" % [current_task.description, default_char.name])
			else:
				# 不在同一房间，移动到默认角色位置
				if target_character.has_method("move_to"):
					var target_pos = default_char.global_position
					var target_room_name = target_room.name if target_room else "未知位置"
					print("[AIAgent] %s 移动到坐标 (%s, %s) 寻找默认角色 %s" % [target_character.name, target_pos.x, target_pos.y, default_char.name])
					target_character.move_to(target_pos)
					_add_memory(target_character, "为了完成任务'%s'，你需要去找%s交谈，正在前往%s的位置(%.0f, %.0f)。" % [current_task.description, default_char.name, target_room_name, target_pos.x, target_pos.y])
					_start_movement_tracking(target_character, default_char, current_task)
				else:
					_add_memory(target_character, "你想要交谈来完成任务'%s'，但是无法移动到合适的交谈对象那里。" % current_task.description)

# 执行任务相关的思考
func _execute_task_thinking(target_character, current_task):
	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		return

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(target_character.name)
	var status_info = get_character_status_info(target_character)
	var scene_description = generate_scene_description()

	# 构建思考prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。你的性格是：%s。你的说话风格是：%s。" % [
		target_character.name,
		personality["position"],
		personality["personality"],
		personality["speaking_style"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += status_info
	prompt += "\n" + scene_description
	prompt += "\n\n你当前的任务是：%s（渴望程度：%d）" % [current_task.description, current_task.priority]
	prompt += "\n\n请思考如何完成这个任务。考虑以下方面："
	prompt += "\n- 完成这个任务需要哪些步骤？"
	prompt += "\n- 你需要什么资源或帮助？"
	prompt += "\n- 可能遇到什么困难？"
	prompt += "\n- 你的当前状态如何影响任务执行？"
	prompt += "\n\n请用第一人称描述你的思考过程，体现出你的性格特点和说话风格（150-250字）。"

	# 使用APIManager生成思考内容
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_task_thinking_completed):
		http_request.request_completed.disconnect(_on_task_thinking_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_task_thinking_completed(result, response_code, headers, body, target_character, current_task)
	)
	waiting_responses[target_character.name] = true

# 处理任务思考的API响应
func _on_task_thinking_completed(result, _response_code, headers, body, char_node = null, current_task = null):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 任务思考的HTTP请求失败" % target_character.name)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 任务思考的JSON解析失败" % target_character.name)
		return

	# 解析思考内容
	var thinking_content = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if thinking_content == "":
		print("[AIAgent] %s 的任务思考API响应解析失败" % target_character.name)
		return

	thinking_content = thinking_content.strip_edges()
	print("[AIAgent] %s 关于任务'%s'的思考：\n%s" % [target_character.name, current_task.description, thinking_content])

	# 添加思考记忆
	_add_memory(target_character, "你思考了如何完成任务'%s'：%s" % [current_task.description, thinking_content])

# 完成任务
func _complete_task(target_character, current_task):
	# 获取角色元数据
	var metadata = target_character.get_meta("character_data", {})
	var tasks = metadata.get("tasks", [])

	# 找到并标记任务为完成
	for i in range(tasks.size()):
		var task = tasks[i]
		if task.description == current_task.description and task.created_at == current_task.created_at:
			task["completed"] = true
			task["completed_at"] = Time.get_unix_time_from_system()
			break

	# 保存更新的任务列表
	metadata["tasks"] = tasks
	target_character.set_meta("character_data", metadata)

	# 添加完成任务的记忆
	_add_memory(target_character, "你成功完成了任务：%s。感觉很有成就感！" % current_task.description)

	print("[AIAgent] %s 完成了任务：%s" % [target_character.name, current_task.description])

# 重新安排任务优先级（占位函数）
func _rearrange_task_priorities(target_character):
	print("[AIAgent] %s 重新安排任务优先级（功能待实现）" % target_character.name)
	_add_memory(target_character, "你重新考虑了任务的优先级安排。")

# 添加紧急任务（占位函数）
func _add_urgent_task(target_character):
	print("[AIAgent] %s 添加紧急任务（功能待实现）" % target_character.name)
	_add_memory(target_character, "你意识到有一个紧急任务需要处理。")

# 处理思考内容的API响应
func _on_thinking_request_completed(result, _response_code, headers, body, char_node = null):
	# 使用传入的角色节点，如果没有则使用当前角色
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 的思考内容HTTP请求失败，错误码：%s" % [target_character.name, result])
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 的思考内容JSON解析失败" % target_character.name)
		return

	# 使用APIConfig统一解析响应
	var thinking_content = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if thinking_content == "":
		print("[AIAgent] %s 的思考内容API响应解析失败" % target_character.name)
		return

	thinking_content = thinking_content.strip_edges()

	# 显示思考内容
	print("[AIAgent] %s 的思考内容：\n%s" % [target_character.name, thinking_content])

	# 这里可以添加更多处理思考内容的逻辑，例如显示在UI上、影响角色状态等

# 选择随机目标（包括房间内物品、其他角色和其他房间）
func _choose_random_target() -> Dictionary:
	var all_targets = []
	var current_room = room_manager.get_current_room(room_manager.rooms, character.global_position)

	# 添加当前房间内的物品
	var room_objects = get_room_objects(current_room)
	for obj in room_objects:
		all_targets.append({"type": "object", "target": obj, "position": obj.global_position})

	# 添加当前房间内的其他角色
	var room_characters = get_room_characters(current_room)
	for char in room_characters:
		all_targets.append({"type": "character", "target": char, "position": char.global_position})

	# 添加其他房间作为目标
	for room_name in room_manager.rooms:
		var room = room_manager.rooms[room_name]
		# 排除当前所在的房间
		if current_room == null or room.name != current_room.name:
			all_targets.append({"type": "room", "target": room, "position": room.position})

	if all_targets.size() > 0:
		all_targets.shuffle()
		return all_targets[0]

	return {}

# 移动到目标位置（支持物品、角色和房间）
func move_to_target(target_info: Dictionary, char_node = null):
	# 使用传入的角色节点，如果没有则使用当前角色
	var target_character = char_node if char_node else character
	var target_controller = target_character

	if target_info.is_empty():
		print("[AIAgent] %s 没有有效的移动目标" % target_character.name)
		return

	if current_state != State.MOVING:
		current_state = State.MOVING
		var target_name = ""
		var target_position = Vector2.ZERO

		match target_info.type:
			"object":
				target_name = target_info.target.name + "（物品）"
				# 移动到物品附近，稍微偏移避免重叠
				target_position = target_info.target.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			"character":
				target_name = target_info.target.name + "（角色）"
				# 移动到角色附近，保持适当距离
				target_position = target_info.target.global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			"room":
				target_name = target_info.target.name + "（房间）"
				# 移动到房间中心坐标
				target_position = target_info.target.position

		print("[AIAgent] %s 开始移动到 %s" % [target_character.name, target_name])
		target_controller.move_to(target_position)

# 发起对话
func initiate_conversation(other_character: Node2D, char_node = null):
	# 使用传入的角色节点，如果没有则使用当前角色
	var target_character = char_node if char_node else character

	if current_state != State.TALKING:
		current_state = State.TALKING
		print("[AIAgent] %s 尝试开始与 %s 对话" % [target_character.name, other_character.name])
		character_manager.current_character = target_character
		dialog_manager._try_start_conversation()

# 执行默认决策（当API失败时使用）
func _execute_default_decision(target_character):
	print("[AIAgent] %s 使用默认决策逻辑" % target_character.name)

	# 获取当前任务
	var tasks = target_character.get_meta("tasks", [])
	if tasks.is_empty():
		# 如果没有任务，生成默认任务
		_generate_default_tasks(target_character)
		return

	# 随机选择一个决策（1或2）
	var random_decision = randi() % 2 + 1
	var decision = str(random_decision)

	print("[AIAgent] %s 的默认决策结果：%s" % [target_character.name, decision])
	match decision:
		"1":  # 调整任务
			print("[AIAgent] %s 决定调整任务（默认）" % target_character.name)
			_adjust_tasks_default(target_character)
		"2":  # 继续当前任务
			print("[AIAgent] %s 决定继续当前任务（默认）" % target_character.name)
			_continue_current_task_default(target_character)

# 生成默认任务（当API失败时使用）
func _generate_default_tasks(target_character):
	print("[AIAgent] %s 生成默认任务列表" % target_character.name)

	# 创建10个默认任务
	var default_tasks = []
	for i in range(10):
		var task = _generate_random_task(target_character)
		if task:
			default_tasks.append(task)

	# 按优先级排序
	default_tasks.sort_custom(func(a, b): return a.priority > b.priority)

	# 保存任务到角色元数据
	target_character.set_meta("tasks", default_tasks)

	# 添加任务生成记忆
	var memories = target_character.get_meta("memories", [])
	memories.append("你为自己制定了新的任务计划，包含了%d个重要任务，准备开始执行。" % default_tasks.size())
	target_character.set_meta("memories", memories)

	print("[AIAgent] %s 已生成 %d 个默认任务" % [target_character.name, default_tasks.size()])

# 默认调整任务逻辑
func _adjust_tasks_default(target_character):
	print("[AIAgent] %s 执行默认任务调整" % target_character.name)

	# 随机选择调整方式
	var adjustment_type = randi() % 3 + 1
	match adjustment_type:
		1:  # 保持不变
			print("[AIAgent] %s 决定保持当前任务优先级（默认）" % target_character.name)
			_add_memory(target_character, "你检查了当前的任务列表，决定保持现有的优先级安排。")
		2:  # 重新安排
			print("[AIAgent] %s 决定重新安排任务优先级（默认）" % target_character.name)
			_rearrange_task_priorities_default(target_character)
		3:  # 添加新任务
			print("[AIAgent] %s 决定添加新的紧急任务（默认）" % target_character.name)
			_add_urgent_task_default(target_character)

# 默认继续当前任务逻辑
func _continue_current_task_default(target_character):
	print("[AIAgent] %s 执行默认任务继续逻辑" % target_character.name)

	var tasks = target_character.get_meta("tasks", [])
	if tasks.is_empty():
		print("[AIAgent] %s 没有任务可执行，生成新任务" % target_character.name)
		_generate_default_tasks(target_character)
		return

	# 获取最高优先级的任务
	var current_task = tasks[0]
	print("[AIAgent] %s 继续执行任务：%s（默认）" % [target_character.name, current_task.description])

	# 添加记忆
	_add_memory(target_character, "你继续专注于当前最重要的任务：%s" % current_task.description)

	# 随机选择执行方式
	var execution_type = randi() % 2 + 1
	match execution_type:
		1:  # 移动到相关位置
			_execute_task_movement_default(target_character, current_task)
		2:  # 与相关角色对话
			_execute_task_conversation_default(target_character, current_task)

# 默认重新安排任务优先级
func _rearrange_task_priorities_default(target_character):
	var tasks = target_character.get_meta("tasks", [])
	if tasks.size() < 2:
		return

	# 随机打乱前几个任务的优先级
	for i in range(min(3, tasks.size())):
		tasks[i].priority = randi() % 10 + 1

	# 重新排序
	tasks.sort_custom(func(a, b): return a.priority > b.priority)
	target_character.set_meta("tasks", tasks)

	_add_memory(target_character, "你重新调整了任务的优先级，现在专注于最重要的事情。")
	print("[AIAgent] %s 已重新安排任务优先级（默认）" % target_character.name)

# 默认添加紧急任务
func _add_urgent_task_default(target_character):
	var urgent_tasks = [
		"处理紧急邮件",
		"参加临时会议",
		"解决突发问题",
		"协助同事完成工作",
		"准备重要报告"
	]

	var urgent_task = {
		"description": urgent_tasks[randi() % urgent_tasks.size()],
		"priority": randi() % 3 + 8,  # 高优先级 8-10
		"created_at": Time.get_unix_time_from_system(),
		"completed": false
	}

	var tasks = target_character.get_meta("tasks", [])
	tasks.append(urgent_task)
	tasks.sort_custom(func(a, b): return a.priority > b.priority)
	target_character.set_meta("tasks", tasks)

	_add_memory(target_character, "你添加了一个新的紧急任务：%s" % urgent_task.description)
	print("[AIAgent] %s 添加了紧急任务：%s（默认）" % [target_character.name, urgent_task.description])

# 默认执行任务移动
func _execute_task_movement_default(target_character, current_task):
	# 随机选择一个房间移动
	var room_names = room_manager.rooms.keys()
	if room_names.size() > 0:
		var random_room_name = room_names[randi() % room_names.size()]
		var room = room_manager.rooms[random_room_name]
		# CharacterController脚本直接附加在角色根节点上
		if target_character and target_character.has_method("move_to"):
			print("[AIAgent] %s 移动到 %s 执行任务（默认）" % [target_character.name, random_room_name])
			target_character.move_to(room.position)
			_add_memory(target_character, "你移动到%s来完成任务：%s" % [random_room_name, current_task.description])

# 默认执行任务对话
func _execute_task_conversation_default(target_character, current_task):
	# 随机选择一个角色对话
	var characters = get_tree().get_nodes_in_group("character")
	var available_chars = []
	for char in characters:
		if char != target_character:
			available_chars.append(char)

	if available_chars.size() > 0:
		var random_char = available_chars[randi() % available_chars.size()]
		print("[AIAgent] %s 与 %s 对话执行任务（默认）" % [target_character.name, random_char.name])
		initiate_conversation(random_char, target_character)

# 处理找不到目标的情况
func _handle_target_not_found(target_character, target_name: String, current_task):
	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		return

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(target_character.name)

	# 获取所有房间列表
	var room_names = []
	for room_name in room_manager.rooms:
		room_names.append(room_name)

	# 构建决策prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。" % [
		target_character.name,
		personality["position"]
	]

	prompt += "\n\n你当前的任务是：%s" % current_task.description
	prompt += "\n你想要找到'%s'来完成这个任务，但是在当前房间没有找到这个目标。" % target_name
	prompt += "\n\n公司有以下房间：%s" % ", ".join(room_names)
	prompt += "\n\n请选择你的行动："
	prompt += "\n1. 去其他房间寻找'%s'" % target_name
	prompt += "\n2. 留在原地，重新安排任务"
	prompt += "\n\n请只回复数字1或2，不要有任何其他文字。"

	print(prompt)

	# 使用APIManager生成决策
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_target_not_found_decision_completed):
		http_request.request_completed.disconnect(_on_target_not_found_decision_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_target_not_found_decision_completed(result, response_code, headers, body, target_character, target_name, current_task)
	)
	waiting_responses[target_character.name] = true

# 处理找不到目标的决策API响应
func _on_target_not_found_decision_completed(result, _response_code, headers, body, char_node = null, target_name: String = "", current_task = null):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 找不到目标决策的HTTP请求失败" % target_character.name)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 找不到目标决策的JSON解析失败" % target_character.name)
		return

	# 解析决策
	var decision = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if decision == "":
		print("[AIAgent] %s 的找不到目标决策API响应解析失败" % target_character.name)
		return

	decision = decision.strip_edges()
	print("[AIAgent] %s 的找不到目标决策：%s" % [target_character.name, decision])

	match decision:
		"1":  # 去其他房间寻找
			print("[AIAgent] %s 决定去其他房间寻找'%s'" % [target_character.name, target_name])
			await _choose_room_to_search(target_character, target_name, current_task)
		"2":  # 重新安排任务
			print("[AIAgent] %s 决定重新安排任务" % target_character.name)
			_add_memory(target_character, "你本来要找'%s'来完成任务'%s'，但是找不到，所以需要重新安排任务。" % [target_name, current_task.description])
			await _reschedule_task(target_character, current_task, target_name)
		_:
			print("[AIAgent] %s 的找不到目标决策无效：%s" % [target_character.name, decision])
			_add_memory(target_character, "你想要找到'%s'来完成任务，但是没有找到这个目标。" % target_name)

# 选择要搜索的房间
func _choose_room_to_search(target_character, target_name: String, current_task):
	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		return

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(target_character.name)

	# 获取当前房间
	var current_room = room_manager.get_current_room(room_manager.rooms, target_character.global_position)
	var current_room_name = current_room.name if current_room else "未知房间"

	# 获取所有房间列表（排除当前房间）
	var room_names = []
	for room_name in room_manager.rooms:
		if room_name != current_room_name:
			room_names.append(room_name)

	if room_names.size() == 0:
		print("[AIAgent] %s 没有其他房间可以搜索" % target_character.name)
		_add_memory(target_character, "你想要去其他房间寻找'%s'，但是没有其他房间可以去。" % target_name)
		return

	# 构建房间选择prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。" % [
		target_character.name,
		personality["position"]
	]

	prompt += "\n\n你当前的任务是：%s" % current_task.description
	prompt += "\n你想要找到'%s'来完成这个任务，但是在当前房间'%s'没有找到。" % [target_name, current_room_name]
	prompt += "\n\n你可以去以下房间寻找："
	for i in range(room_names.size()):
		prompt += "\n%d. %s" % [i + 1, room_names[i]]

	prompt += "\n\n请选择你想要去的房间，只回复对应的数字（1-%d），不要有任何其他文字。" % room_names.size()

	print(prompt)

	# 使用APIManager生成决策
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_room_choice_completed):
		http_request.request_completed.disconnect(_on_room_choice_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_room_choice_completed(result, response_code, headers, body, target_character, target_name, current_task, room_names)
	)
	waiting_responses[target_character.name] = true

# 处理房间选择的API响应
func _on_room_choice_completed(result, _response_code, headers, body, char_node = null, target_name: String = "", current_task = null, room_names: Array = []):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 房间选择的HTTP请求失败" % target_character.name)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 房间选择的JSON解析失败" % target_character.name)
		return

	# 解析选择
	var choice = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if choice == "":
		print("[AIAgent] %s 的房间选择API响应解析失败" % target_character.name)
		return

	choice = choice.strip_edges()
	print("[AIAgent] %s 选择的房间：%s" % [target_character.name, choice])

	# 验证选择是否有效
	var choice_index = choice.to_int() - 1
	if choice_index >= 0 and choice_index < room_names.size():
		var selected_room_name = room_names[choice_index]
		var selected_room = room_manager.rooms[selected_room_name]

		print("[AIAgent] %s 开始移动到 %s 寻找'%s'" % [target_character.name, selected_room_name, target_name])

		# 移动到选择的房间
		if target_character and target_character.has_method("move_to"):
			target_character.move_to(selected_room.position)
			_add_memory(target_character, "为了寻找'%s'来完成任务'%s'，你移动到了%s。" % [target_name, current_task.description, selected_room_name])
	else:
		print("[AIAgent] %s 的房间选择无效：%s" % [target_character.name, choice])
		_add_memory(target_character, "你想要选择房间去寻找'%s'，但是选择无效。" % target_name)

# 重新安排任务
func _reschedule_task(target_character, current_task, failed_target_name: String):
	# 如果正在等待API响应，跳过
	if target_character.name in waiting_responses and waiting_responses[target_character.name]:
		return

	# 获取角色人设
	var personality = CharacterPersonality.get_personality(target_character.name)

	# 获取场景描述
	var scene_description = generate_scene_description()

	# 构建重新安排任务的prompt
	var prompt = "你是一个办公室员工，名字是%s。你的职位是：%s。" % [
		target_character.name,
		personality["position"]
	]

	# 添加公司基本信息和员工名单信息
	prompt += get_company_basic_info()
	prompt += get_company_employees_info()
	prompt += "\n" + scene_description

	prompt += "\n\n你原本的任务是：%s" % current_task.description
	prompt += "\n但是你找不到'%s'来完成这个任务。" % failed_target_name
	prompt += "\n\n请重新安排一个新的任务，这个任务应该："
	prompt += "\n1. 适合你的职位和当前环境"
	prompt += "\n2. 可以在当前环境中完成"
	prompt += "\n3. 符合办公室工作的常理"
	prompt += "\n\n请只回复新任务的描述，不要有任何其他文字。"

	print(prompt)

	# 使用APIManager生成新任务
	var character_name = character.name if character else "Unknown"
	var http_request = await api_manager.generate_dialog(prompt, character_name)

	# 断开之前可能存在的连接
	if http_request.request_completed.is_connected(_on_reschedule_task_completed):
		http_request.request_completed.disconnect(_on_reschedule_task_completed)

	# 连接回调函数
	http_request.request_completed.connect(func(result, response_code, headers, body):
		_on_reschedule_task_completed(result, response_code, headers, body, target_character, current_task)
	)
	waiting_responses[target_character.name] = true

# 处理重新安排任务的API响应
func _on_reschedule_task_completed(result, _response_code, headers, body, char_node = null, old_task = null):
	var target_character = char_node if char_node else character

	# 重置等待状态
	waiting_responses[target_character.name] = false

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[AIAgent] %s 重新安排任务的HTTP请求失败" % target_character.name)
		return

	var response = JSON.parse_string(body.get_string_from_utf8())
	if not response:
		print("[AIAgent] %s 重新安排任务的JSON解析失败" % target_character.name)
		return

	# 解析新任务
	var new_task_description = APIConfig.parse_response(api_manager.current_settings.api_type, response)
	if new_task_description == "":
		print("[AIAgent] %s 的重新安排任务API响应解析失败" % target_character.name)
		return

	new_task_description = new_task_description.strip_edges()
	print("[AIAgent] %s 重新安排的新任务：%s" % [target_character.name, new_task_description])

	# 更新任务
	var metadata = target_character.get_meta("character_data", {})
	if not metadata.has("current_task"):
		metadata["current_task"] = {}

	metadata["current_task"]["description"] = new_task_description
	metadata["current_task"]["start_time"] = Time.get_unix_time_from_system()
	target_character.set_meta("character_data", metadata)

	_add_memory(target_character, "由于找不到目标，你重新安排了新任务：%s" % new_task_description)
	print("[AIAgent] %s 的任务已更新为：%s" % [target_character.name, new_task_description])

# 获取角色的对话伙伴
func _get_conversation_partner(character: CharacterBody2D) -> CharacterBody2D:
	if not dialog_manager or not dialog_manager.dialog_service:
		return null

	# 获取角色参与的对话ID列表
	var conversation_ids = dialog_manager.dialog_service.get_character_conversations(character)
	if conversation_ids.is_empty():
		return null

	# 获取第一个对话的对话伙伴
	var conversation_id = conversation_ids[0]
	var active_conversations = dialog_manager.dialog_service.active_conversations
	if not active_conversations.has(conversation_id):
		return null

	var conversation = active_conversations[conversation_id]
	if conversation.speaker == character:
		return conversation.listener
	else:
		return conversation.speaker

# 开始移动跟踪，智能检测角色是否到达目标位置
func _start_movement_tracking(moving_character: CharacterBody2D, target_character: CharacterBody2D, current_task):
	var tracking_data = {
		"moving_character": moving_character,
		"target_character": target_character,
		"current_task": current_task,
		"start_time": Time.get_unix_time_from_system(),
		"last_position": moving_character.global_position,
		"stuck_time": 0.0,
		"check_count": 0
	}

	# 创建定时器进行周期性检查
	var tracking_timer = Timer.new()
	tracking_timer.wait_time = 0.5  # 每0.5秒检查一次
	tracking_timer.timeout.connect(func(): _check_movement_progress(tracking_data, tracking_timer))
	moving_character.add_child(tracking_timer)
	tracking_timer.start()

	print("[AIAgent] 开始跟踪 %s 移动到 %s 的进度" % [moving_character.name, target_character.name])

# 检查移动进度
func _check_movement_progress(tracking_data: Dictionary, tracking_timer: Timer):
	var moving_char = tracking_data["moving_character"]
	var target_char = tracking_data["target_character"]
	var current_task = tracking_data["current_task"]
	var start_time = tracking_data["start_time"]
	var last_pos = tracking_data["last_position"]

	tracking_data["check_count"] += 1
	var current_time = Time.get_unix_time_from_system()
	var elapsed_time = current_time - start_time
	var current_pos = moving_char.global_position
	var distance_to_target = current_pos.distance_to(target_char.global_position)

	# 检查是否到达目标位置（交谈距离内）
	if distance_to_target <= 150:
		print("[AIAgent] %s 成功到达 %s 附近，开始交谈" % [moving_char.name, target_char.name])
		initiate_conversation(target_char, moving_char)
		_add_memory(moving_char, "为了完成任务'%s'，你成功找到了%s并进行了交谈。" % [current_task.description, target_char.name])
		_cleanup_tracking_timer(tracking_timer)
		return

	# 检查是否卡住（位置没有明显变化）
	var movement_distance = current_pos.distance_to(last_pos)
	if movement_distance < 10:  # 移动距离小于10像素认为可能卡住
		tracking_data["stuck_time"] += tracking_timer.wait_time
	else:
		tracking_data["stuck_time"] = 0.0
		tracking_data["last_position"] = current_pos

	# 超时或卡住太久，放弃移动
	if elapsed_time > 15.0 or tracking_data["stuck_time"] > 5.0:
		var reason = "超时" if elapsed_time > 15.0 else "卡住"
		print("[AIAgent] %s 移动到 %s 失败：%s (距离: %.0f)" % [moving_char.name, target_char.name, reason, distance_to_target])
		_add_memory(moving_char, "你试图去找%s交谈来完成任务'%s'，但是移动过程中遇到了问题（%s）。" % [target_char.name, current_task.description, reason])
		_cleanup_tracking_timer(tracking_timer)
		return

	# 每10次检查输出一次进度信息
	if tracking_data["check_count"] % 10 == 0:
		print("[AIAgent] %s 移动进度：距离 %s 还有 %.0f 像素" % [moving_char.name, target_char.name, distance_to_target])

# 清理跟踪定时器
func _cleanup_tracking_timer(tracking_timer: Timer):
	if tracking_timer and is_instance_valid(tracking_timer):
		tracking_timer.stop()
		tracking_timer.queue_free()
