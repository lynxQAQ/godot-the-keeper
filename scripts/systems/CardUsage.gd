extends Node

## 卡牌使用系统
## 负责卡牌使用验证、逻辑执行、反馈等
## 注意：不使用class_name，因为它是autoload单例

# ========== 初始化 ==========
func _ready() -> void:
	_connect_signals()
	DebugLogger.info("CardUsage: 初始化完成", "CardUsage")

func _connect_signals() -> void:
	# 可以连接相关信号
	pass

# ========== 卡牌使用验证 ==========
## 验证是否可以使用卡牌
## card_id: 卡牌ID
## position: 使用位置（可选，用于实体类卡牌）
## 返回验证结果和错误信息
func validate_card_usage(card_id: String, position: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var result = {
		"valid": false,
		"error": ""
	}
	
	# 检查卡牌是否存在
	var card = CardLibrary.get_card(card_id)
	if card == null:
		result["error"] = "卡牌不存在: " + card_id
		return result
	
	# 检查卡牌是否已解锁
	if not card.is_unlocked:
		result["error"] = "卡牌未解锁: " + card_id
		return result
	
	# 检查资源是否足够
	if not card.can_afford():
		result["error"] = "资源不足，无法使用卡牌: " + card_id
		return result
	
	# 检查位置是否有效（实体类卡牌需要位置）
	if card.card_type == Constants.CONSTRUCT_TYPE_ENTITY:
		if position.x < 0 or position.y < 0:
			result["error"] = "实体类卡牌需要指定有效位置"
			return result
		
		# 可以在这里添加更多位置验证逻辑
		# 例如：检查位置是否在已开垦的网格上、是否已有构造体等
	
	result["valid"] = true
	return result

## 检查位置是否有效（用于实体类卡牌）
func is_position_valid(position: Vector2i, card_id: String) -> bool:
	if position.x < 0 or position.y < 0:
		return false
	
	# 可以在这里添加更多位置验证逻辑
	# 例如：检查网格类型、是否已有构造体等
	# 这里需要根据实际的网格系统来实现
	
	return true

# ========== 卡牌使用逻辑 ==========
## 使用卡牌
## card_id: 卡牌ID
## position: 使用位置（实体类卡牌必需，虚体类卡牌可选）
## 返回是否成功使用
func use_card(card_id: String, position: Vector2i = Vector2i(-1, -1)) -> bool:
	# 验证卡牌使用
	var validation = validate_card_usage(card_id, position)
	if not validation["valid"]:
		DebugLogger.warning("CardUsage: 卡牌使用验证失败: " + validation["error"], "CardUsage")
		return false
	
	var card = CardLibrary.get_card(card_id)
	if card == null:
		return false
	
	# 消耗资源
	if not _consume_resources(card):
		DebugLogger.warning("CardUsage: 资源消耗失败: " + card_id, "CardUsage")
		return false
	
	# 根据卡牌类型执行不同的逻辑
	var success = false
	if card.card_type == Constants.CONSTRUCT_TYPE_ENTITY:
		success = _use_entity_card(card, position)
	elif card.card_type == Constants.CONSTRUCT_TYPE_VIRTUAL:
		success = _use_virtual_card(card, position)
	
	if success:
		# 发射卡牌使用信号
		SignalBus.card_used.emit(card_id, position)
		DebugLogger.info("CardUsage: 成功使用卡牌: " + card_id + "，位置: " + str(position), "CardUsage")
	
	return success

## 使用实体类卡牌
func _use_entity_card(card: CardData, position: Vector2i) -> bool:
	# 创建实体构造体
	if ConstructManager == null:
		DebugLogger.error("CardUsage: ConstructManager未找到", "CardUsage")
		return false
	
	# 创建EntityData
	var entity_data = EntityData.new()
	entity_data.id = card.id + "_" + str(Time.get_ticks_msec())  # 生成唯一ID
	entity_data.name = card.name
	entity_data.serial = card.serial
	entity_data.position = position
	
	# 如果有构造体数据引用，可以加载并应用数据
	if not card.construct_data_ref.is_empty():
		var construct_ref = DataManager.load_resource_file(card.construct_data_ref)
		if construct_ref != null and construct_ref is ConstructData:
			var construct_data = construct_ref as ConstructData
			entity_data.effect_range = construct_data.effect_range
			entity_data.trigger_probability = construct_data.trigger_probability
			entity_data.effects = construct_data.effects.duplicate()
	
	# 加载Entity场景
	var entity_scene = load("res://scenes/entities/Entity.tscn")
	if entity_scene == null:
		DebugLogger.error("CardUsage: 无法加载Entity场景", "CardUsage")
		return false
	
	# 实例化Entity
	var entity = entity_scene.instantiate() as Entity
	if entity == null:
		DebugLogger.error("CardUsage: 无法实例化Entity", "CardUsage")
		return false
	
	# 初始化Entity
	entity.initialize(entity_data)
	
	# 添加到场景树（需要找到合适的父节点）
	var world_root = get_tree().current_scene
	if world_root:
		world_root.add_child(entity)
		# 注册到ConstructManager
		if ConstructManager.register_entity(entity):
			DebugLogger.info("CardUsage: 成功生成实体构造体: " + entity_data.id, "CardUsage")
			return true
		else:
			entity.queue_free()
			return false
	else:
		DebugLogger.error("CardUsage: 无法找到场景根节点", "CardUsage")
		entity.queue_free()
		return false

## 使用虚体类卡牌
func _use_virtual_card(card: CardData, position: Vector2i) -> bool:
	# 创建虚体构造体
	if ConstructManager == null:
		DebugLogger.error("CardUsage: ConstructManager未找到", "CardUsage")
		return false
	
	# 创建VirtualData
	var virtual_data = VirtualData.new()
	virtual_data.id = card.id + "_" + str(Time.get_ticks_msec())  # 生成唯一ID
	virtual_data.name = card.name
	virtual_data.serial = card.serial
	virtual_data.center_position = position
	
	# 如果有构造体数据引用，可以加载并应用数据
	if not card.construct_data_ref.is_empty():
		var construct_ref = DataManager.load_resource_file(card.construct_data_ref)
		if construct_ref != null and construct_ref is ConstructData:
			var construct_data = construct_ref as ConstructData
			virtual_data.effect_range = construct_data.effect_range
			virtual_data.trigger_probability = construct_data.trigger_probability
			virtual_data.effects = construct_data.effects.duplicate()
			# 如果引用的是VirtualData类型，尝试获取duration属性
			if construct_ref is VirtualData:
				var virtual_ref = construct_ref as VirtualData
				virtual_data.duration = virtual_ref.duration
			else:
				virtual_data.duration = -1.0  # 默认永久
	
	# 加载Virtual场景
	var virtual_scene = load("res://scenes/entities/Virtual.tscn")
	if virtual_scene == null:
		DebugLogger.error("CardUsage: 无法加载Virtual场景", "CardUsage")
		return false
	
	# 实例化Virtual
	var virtual = virtual_scene.instantiate() as Virtual
	if virtual == null:
		DebugLogger.error("CardUsage: 无法实例化Virtual", "CardUsage")
		return false
	
	# 初始化Virtual
	virtual.initialize(virtual_data)
	
	# 添加到场景树（需要找到合适的父节点）
	var world_root = get_tree().current_scene
	if world_root:
		world_root.add_child(virtual)
		# 注册到ConstructManager
		if ConstructManager.register_virtual(virtual):
			DebugLogger.info("CardUsage: 成功生成虚体构造体: " + virtual_data.id, "CardUsage")
			return true
		else:
			virtual.queue_free()
			return false
	else:
		DebugLogger.error("CardUsage: 无法找到场景根节点", "CardUsage")
		virtual.queue_free()
		return false

## 消耗资源
func _consume_resources(card: CardData) -> bool:
	# 消耗表构造力
	if card.cost_table_construct > 0:
		if not ResourceManager.consume_table_construct(card.cost_table_construct):
			return false
	
	# 消耗里构造力
	if card.cost_inner_construct > 0:
		if not ResourceManager.consume_inner_construct(card.cost_inner_construct):
			# 如果里构造力不足，回退表构造力
			if card.cost_table_construct > 0:
				ResourceManager.add_table_construct(card.cost_table_construct)
			return false
	
	return true

# ========== 卡牌使用反馈 ==========
## 播放卡牌使用动画（占位，需要UI系统实现）
func play_use_animation(card_id: String, position: Vector2i) -> void:
	# 这里可以触发动画信号或调用UI系统播放动画
	DebugLogger.debug("CardUsage: 播放卡牌使用动画: " + card_id, "CardUsage")

## 播放卡牌使用音效（占位，需要音频系统实现）
func play_use_sound(card_id: String) -> void:
	# 这里可以触发音效信号或调用音频系统播放音效
	DebugLogger.debug("CardUsage: 播放卡牌使用音效: " + card_id, "CardUsage")

## 显示卡牌使用提示（占位，需要UI系统实现）
func show_use_hint(card_id: String, message: String) -> void:
	# 这里可以触发UI信号或调用UI系统显示提示
	DebugLogger.info("CardUsage: 显示使用提示: " + message, "CardUsage")

# ========== 批量操作 ==========
## 批量使用卡牌
func use_cards(card_positions: Dictionary) -> Dictionary:
	# card_positions: {card_id: position}
	var results = {
		"success": [],
		"failed": []
	}
	
	for card_id in card_positions:
		var position = card_positions[card_id]
		if use_card(card_id, position):
			results["success"].append(card_id)
		else:
			results["failed"].append(card_id)
	
	return results
