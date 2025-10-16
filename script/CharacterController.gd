extends CharacterBody2D

@export var speed = 100.0
var target_position = Vector2.ZERO
var is_selected = false
var is_sitting = false
var facing_direction = "down"  # 新增：记录角色朝向
var navigation_path: Array = []
var path_index = 0
var near_chair = null  # 新增：当前靠近的椅子
var current_chair = null  # 新增：当前坐着的椅子
var target_chair = null  # 新增：目标椅子（用于自动坐下）
var auto_sit_enabled = false  # 新增：是否启用自动坐下

# AI代理系统
var ai_agent: AIAgent

# 避障相关变量
var stuck_timer = 0.0
var last_position = Vector2.ZERO
var stuck_threshold = 2.0  # 卡住检测时间（减少）
var avoidance_force = Vector2.ZERO
var avoidance_timer = 0.0
var recalculate_count = 0  # 重新计算路径的次数
var max_recalculate_attempts = 3  # 最大重试次数
var last_avoidance_direction = Vector2.ZERO  # 记录上次避障方向
var direction_stability_timer = 0.0  # 方向稳定计时器

func _ready():
	add_to_group("controllable_characters")
	# 创建ChatHistory节点
	if not has_node("ChatHistory"):
		var chat_history_scene = load("res://scene/ChatHistory.tscn")
		var chat_history = chat_history_scene.instantiate()
		add_child(chat_history)

	# 创建AI代理
	ai_agent = AIAgent.new()
	add_child(ai_agent)

	# 创建AI模型显示标签
	create_ai_model_label()

	# 设置初始动画
	$AnimatedSprite2D.play("idle_" + facing_direction)

func set_selected(selected: bool):
	is_selected = selected
	# 切换AI代理的控制状态（添加空值检查）
	if ai_agent:
		ai_agent.toggle_player_control(selected)
	# 可以在这里添加选中效果,比如添加一个光环或改变颜色

func move_to(target: Vector2):
	if is_sitting:
		return

	# 只有在不是自动坐下模式时才重置目标椅子状态
	if not auto_sit_enabled:
		target_chair = null

	# 使用导航系统计算路径
	var navigation_map = get_world_2d().navigation_map

	# 设置路径寻找参数
	var path_params = NavigationPathQueryParameters2D.new()
	path_params.map = navigation_map
	path_params.start_position = global_position
	path_params.target_position = target
	path_params.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_CORRIDORFUNNEL # 使用漏斗算法优化路径
	# 注意：PATH_SIMPLIFICATION_EDGECENTERED 在当前Godot版本中不可用

	# 获取路径
	var path_result = NavigationPathQueryResult2D.new()
	NavigationServer2D.query_path(path_params, path_result)
	navigation_path = path_result.path

	# 如果导航失败，尝试直接移动
	if navigation_path.is_empty():
		navigation_path = [global_position, target]

	# 打印调试信息
	print("路径点数量: ", navigation_path.size())
	print("起点: ", global_position)
	print("终点: ", target)

	path_index = 0
	target_position = target
	# 重置避障相关变量
	stuck_timer = 0.0
	last_position = global_position
	avoidance_force = Vector2.ZERO
	avoidance_timer = 0.0
	recalculate_count = 0  # 重置重试次数

# 改进的避障方向计算 - 减少震荡
func _calculate_avoidance_direction(desired_direction: Vector2) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var final_direction = desired_direction

	# 前方障碍物检测
	var detection_distance = 35.0
	var front_query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + desired_direction * detection_distance
	)
	front_query.exclude = [self]
	front_query.collision_mask = 1

	var front_result = space_state.intersect_ray(front_query)

	# 如果前方有障碍物
	if front_result:
		var obstacle_distance = global_position.distance_to(front_result.position)

		# 只有在很近的时候才避障
		if obstacle_distance < 30.0:
			# 计算避障方向 - 使用更稳定的方法
			var obstacle_normal = front_result.normal
			var avoidance_direction = Vector2.ZERO

			# 优先使用上次的避障方向来保持稳定性
			if direction_stability_timer > 0 and last_avoidance_direction != Vector2.ZERO:
				avoidance_direction = last_avoidance_direction
				direction_stability_timer -= get_physics_process_delta_time()
			else:
				# 计算新的避障方向
				var left_direction = desired_direction.rotated(deg_to_rad(-90))
				var right_direction = desired_direction.rotated(deg_to_rad(90))

				# 检测左右通畅性
				var left_clear = _is_direction_clear(left_direction, 25.0)
				var right_clear = _is_direction_clear(right_direction, 25.0)

				if left_clear and not right_clear:
					avoidance_direction = left_direction
				elif right_clear and not left_clear:
					avoidance_direction = right_direction
				elif left_clear and right_clear:
					# 两边都通畅，选择更接近目标的方向
					var target_dir = (target_position - global_position).normalized()
					if left_direction.dot(target_dir) > right_direction.dot(target_dir):
						avoidance_direction = left_direction
					else:
						avoidance_direction = right_direction
				else:
					# 两边都不通畅，使用法向量
					avoidance_direction = obstacle_normal

				# 记录避障方向并设置稳定时间
				last_avoidance_direction = avoidance_direction
				direction_stability_timer = 0.8  # 保持方向稳定0.8秒

			# 平滑混合方向，减少震荡
			var blend_factor = min(1.0, (30.0 - obstacle_distance) / 15.0)  # 距离越近避障越强
			final_direction = desired_direction.lerp(avoidance_direction, blend_factor * 0.6)
			final_direction = final_direction.normalized()

			# 设置避障状态
			avoidance_force = avoidance_direction.normalized()
			avoidance_timer = 0.5  # 减少避障持续时间
	else:
		# 没有障碍物时重置稳定计时器
		direction_stability_timer = 0.0
		last_avoidance_direction = Vector2.ZERO

	# 如果还在避障状态中，轻微应用避障力
	if avoidance_timer > 0:
		final_direction = final_direction.lerp(avoidance_force, 0.3)
		final_direction = final_direction.normalized()
		avoidance_timer -= get_physics_process_delta_time()

	return final_direction

# 检测指定方向是否通畅
func _is_direction_clear(direction: Vector2, distance: float) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction * distance
	)
	query.exclude = [self]
	query.collision_mask = 1

	var result = space_state.intersect_ray(query)
	return result.is_empty()

# 检测是否卡住 - 优化检测逻辑
func _check_if_stuck(delta: float):
	var movement_threshold = 5.0  # 降低最小移动距离阈值

	if global_position.distance_to(last_position) < movement_threshold:
		stuck_timer += delta
	else:
		stuck_timer = 0.0
		last_position = global_position
		recalculate_count = 0  # 重置重试次数

	# 如果卡住时间过长且重试次数未超限，重新计算路径
	if stuck_timer > stuck_threshold and navigation_path.size() > 0 and recalculate_count < max_recalculate_attempts:
		print("[CharacterController] %s 检测到卡住，第%d次重新计算路径" % [name, recalculate_count + 1])
		_recalculate_path()
		stuck_timer = 0.0
	elif recalculate_count >= max_recalculate_attempts:
		# 超过最大重试次数，尝试简单的直线路径
		print("[CharacterController] %s 重试次数过多，使用直线路径" % name)
		navigation_path = [global_position, target_position]
		path_index = 0
		stuck_timer = 0.0
		recalculate_count = 0

# 重新计算路径
func _recalculate_path():
	if target_position != Vector2.ZERO:
		recalculate_count += 1

		# 尝试计算新路径，根据重试次数增加偏移范围
		var offset_range = 30.0 + (recalculate_count * 20.0)
		var offset_target = target_position + Vector2(randf_range(-offset_range, offset_range), randf_range(-offset_range, offset_range))

		# 直接重新计算路径，不调用move_to避免重置计数器
		var navigation_map = get_world_2d().navigation_map
		var path_params = NavigationPathQueryParameters2D.new()
		path_params.map = navigation_map
		path_params.start_position = global_position
		path_params.target_position = offset_target
		path_params.path_postprocessing = NavigationPathQueryParameters2D.PATH_POSTPROCESSING_CORRIDORFUNNEL

		var path_result = NavigationPathQueryResult2D.new()
		NavigationServer2D.query_path(path_params, path_result)
		navigation_path = path_result.path

		if navigation_path.is_empty():
			navigation_path = [global_position, offset_target]

		path_index = 0
		print("[CharacterController] %s 重新计算路径完成，路径点数量: %d" % [name, navigation_path.size()])

func _physics_process(delta):
	# AI控制的角色或被选中的角色都可以移动
	if not is_selected and ai_agent.is_player_controlled:
		return

	# 处理键盘输入 - 只有被选中的角色才能响应键盘输入
	var input_direction = Vector2.ZERO
	if is_selected:
		input_direction.x = Input.get_axis("move_left", "move_right")
		input_direction.y = Input.get_axis("move_up", "move_down")
		input_direction = input_direction.normalized()

	if input_direction != Vector2.ZERO:
		# 键盘控制优先，取消寻路
		navigation_path.clear()
		target_position = Vector2.ZERO
		velocity = input_direction * speed

		if abs(input_direction.x) > abs(input_direction.y):
			facing_direction = "right" if input_direction.x > 0 else "left"
	elif navigation_path.size() > 0:
		# 沿着计算出的路径移动
		if path_index < navigation_path.size():
			var next_point = navigation_path[path_index]
			var direction = (next_point - global_position).normalized()

			# 改进的避障逻辑
			var final_direction = _calculate_avoidance_direction(direction)

			# 根据距离调整速度，接近终点时减速
			var distance_to_target = global_position.distance_to(next_point)
			var adjusted_speed = speed

			# 如果接近终点，减速
			if path_index == navigation_path.size() - 1 and distance_to_target < 50:
				adjusted_speed = lerp(speed * 0.4, speed, distance_to_target / 50)

			# 确保direction不为空
			if final_direction != Vector2.ZERO:
				velocity = final_direction * adjusted_speed
			else:
				velocity = Vector2.ZERO

			# 更新朝向
			if abs(final_direction.x) > abs(final_direction.y):
				facing_direction = "right" if final_direction.x > 0 else "left"

			# 到达路径点后移动到下一个点 - 动态调整阈值
			var base_threshold = 12.0
			var speed_factor = velocity.length() / speed
			var arrival_threshold = base_threshold * max(0.5, speed_factor)  # 速度越快阈值越大

			if global_position.distance_to(next_point) < arrival_threshold:
				path_index += 1

				# 如果还有下一个路径点，预先调整方向
				if path_index < navigation_path.size():
					var next_next_point = navigation_path[path_index]
					var next_direction = (next_next_point - global_position).normalized()
					# 更平滑的转向
					final_direction = final_direction.lerp(next_direction, 0.2)

			# 检测是否卡住
			_check_if_stuck(delta)
		else:
			# 到达终点
			navigation_path.clear()
			velocity = Vector2.ZERO

			# 检查是否需要自动坐下
			_check_auto_sit()
	else:
		velocity = Vector2.ZERO

	# 更新动画
	update_animation()

	if not is_sitting:
		move_and_slide()

func _unhandled_input(event):
	if not is_selected:
		return

	if event.is_action_pressed("sit"):
		if near_chair and not is_sitting:
			# 如果靠近椅子且未坐下，尝试坐到椅子上
			sit_on_chair(near_chair)
		elif current_chair and is_sitting:
			# 如果已经坐在椅子上，站起来
			stand_up_from_chair()
		else:
			# 普通的坐下/站起
			toggle_sit()

func sit_on_chair(chair):
	if chair.sit_character(self):
		is_sitting = true
		current_chair = chair
		target_position = Vector2.ZERO
		velocity = Vector2.ZERO
		facing_direction = chair.sit_direction

		# 播放对应方向的坐下动画
		var anim_name = "sit_" + facing_direction
		if facing_direction == "up":
			anim_name = "sit_up"
		elif facing_direction == "down":
			anim_name = "sit_down"

		$AnimatedSprite2D.play(anim_name)
		return true
	return false

func stand_up_from_chair():
	if current_chair and current_chair.stand_up():
		is_sitting = false
		current_chair = null

		# 重置Z轴顺序
		z_index = 0

		# 根据之前的坐姿选择站起动画
		var anim_name = "stand_" + facing_direction
		if facing_direction == "up":
			anim_name = "stand_up"
		elif facing_direction == "down":
			anim_name = "stand_down"

		$AnimatedSprite2D.play(anim_name)

		# 等待站起动画播放完成
		await $AnimatedSprite2D.animation_finished

		# 切换到闲置动画
		$AnimatedSprite2D.play("idle_" + facing_direction)

		# 重置导航相关变量
		navigation_path.clear()
		path_index = 0
		target_position = global_position
		velocity = Vector2.ZERO

func toggle_sit():
	# 只在不靠近椅子时允许自由坐下
	if near_chair:
		return

	is_sitting = !is_sitting
	var animated_sprite = $AnimatedSprite2D

	if is_sitting:
		target_position = Vector2.ZERO
		velocity = Vector2.ZERO
		animated_sprite.play("sit_" + facing_direction)
	else:
		animated_sprite.play("idle_" + facing_direction)

func update_animation():
	var animated_sprite = $AnimatedSprite2D
	if is_sitting:
		return

	if velocity == Vector2.ZERO:
		# 根据最后移动的方向播放对应的idle动画
		var idle_anim = "idle_" + facing_direction
		animated_sprite.play(idle_anim)
	else:
		if abs(velocity.x) > abs(velocity.y):
			if velocity.x > 0:
				animated_sprite.play("run_right")
				facing_direction = "right"
			else:
				animated_sprite.play("run_left")
				facing_direction = "left"
		else:
			if velocity.y > 0:
				animated_sprite.play("run_down")
				facing_direction = "down"
			else:
				animated_sprite.play("run_up")
				facing_direction = "up"

# 移动到椅子并自动坐下
func move_to_chair(chair):
	if is_sitting or not chair or chair.occupied:
		return false

	# 设置目标椅子和自动坐下标志
	target_chair = chair
	auto_sit_enabled = true

	# 计算椅子的接近位置（椅子前方一定距离）
	var approach_position = _calculate_chair_approach_position(chair)

	# 移动到接近位置
	move_to(approach_position)

	print("[CharacterController] %s 开始移动到椅子: %s" % [name, chair.name])
	return true

# 计算椅子的接近位置
func _calculate_chair_approach_position(chair) -> Vector2:
	var chair_pos = chair.global_position
	var current_pos = global_position

	# 计算从当前位置到椅子的方向
	var direction_to_chair = (chair_pos - current_pos).normalized()

	# 如果距离椅子很近（小于25像素），直接返回椅子位置
	var distance_to_chair = current_pos.distance_to(chair_pos)
	if distance_to_chair <= 25.0:
		return chair_pos

	# 否则，在椅子周围25像素的范围内找一个接近位置
	# 从当前方向接近，保持25像素的距离
	var approach_offset = -direction_to_chair * 25.0

	return chair_pos + approach_offset

# 检查是否需要自动坐下
func _check_auto_sit():
	if not auto_sit_enabled or not target_chair:
		return

	# 检查目标椅子是否仍然可用
	if target_chair.occupied:
		print("[CharacterController] %s 目标椅子已被占用，取消自动坐下" % name)
		target_chair = null
		auto_sit_enabled = false
		return

	# 检查是否在椅子的交互范围内 - 使用更大的范围
	var distance_to_chair = global_position.distance_to(target_chair.global_position)
	print("[CharacterController] %s 距离椅子: %.1f 像素" % [name, distance_to_chair])

	# 使用合理的交互范围（约角色大小的一半），或者检查是否在椅子的交互区域内
	if distance_to_chair <= 20.0 or near_chair == target_chair:
		# 尝试坐到椅子上
		print("[CharacterController] %s 尝试坐到椅子上..." % name)
		if sit_on_chair(target_chair):
			print("[CharacterController] %s 成功自动坐到椅子上" % name)
		else:
			print("[CharacterController] %s 无法坐到椅子上" % name)

		# 重置自动坐下状态
		target_chair = null
		auto_sit_enabled = false
	else:
		# 距离太远，但不要重新移动，避免无限循环
		# 直接尝试坐下，因为可能是精度问题
		print("[CharacterController] %s 距离椅子较远 (%.1f)，直接尝试坐下" % [name, distance_to_chair])
		if sit_on_chair(target_chair):
			print("[CharacterController] %s 成功坐到椅子上" % name)
		else:
			print("[CharacterController] %s 无法坐到椅子上，取消自动坐下" % name)

		# 重置自动坐下状态
		target_chair = null
		auto_sit_enabled = false

# 创建AI模型显示标签
func create_ai_model_label():
	# 检查是否已经存在AI模型标签
	if has_node("AIModelLabel"):
		return

	# 加载AI模型标签场景
	var ai_label_scene = load("res://scene/ui/AIModelLabel.tscn")
	if ai_label_scene:
		var ai_label = ai_label_scene.instantiate()
		ai_label.name = "AIModelLabel"

		# 设置标签位置（角色下方）
		ai_label.position = Vector2(0, 40)  # 角色下方40像素

		# 添加到角色节点
		add_child(ai_label)

		# 连接到SettingsManager的设置更新信号
		var settings_manager = get_node_or_null("/root/SettingsManager")
		if settings_manager and settings_manager.has_signal("settings_changed"):
			settings_manager.settings_changed.connect(_on_ai_settings_changed)

		print("[CharacterController] AI模型标签已创建：", name)
	else:
		print("[CharacterController错误] 无法加载AI模型标签场景")

# 设置更新回调
func _on_ai_settings_changed(new_settings):
	var ai_label = get_node_or_null("AIModelLabel")
	if ai_label and ai_label.has_method("refresh_display"):
		ai_label.refresh_display()
		print("[CharacterController] AI模型标签已更新：", name)
