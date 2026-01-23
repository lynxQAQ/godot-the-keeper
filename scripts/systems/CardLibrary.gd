class_name CardLibrary
extends Node

## 卡牌库系统
## 负责管理所有卡牌数据、加载、查询、解锁状态等

# ========== 卡牌数据存储 ==========
var _card_database: Dictionary = {}  # 所有卡牌数据 {card_id: CardData}
var _unlocked_cards: Array[String] = []  # 已解锁的卡牌ID列表
var _collected_cards: Array[String] = []  # 已收集的卡牌ID列表
var _card_pool: Array[String] = []  # 可用卡牌池（已解锁且已收集）

# ========== 初始化 ==========
func _ready() -> void:
	# 连接信号
	_connect_signals()
	# 自动加载卡牌数据（如果文件存在）
	if ResourceLoader.exists("res://data/cards.json"):
		load_cards_from_json("res://data/cards.json")
	else:
		DebugLogger.warning("CardLibrary: 卡牌数据文件不存在: res://data/cards.json，跳过加载", "CardLibrary")
	DebugLogger.info("CardLibrary: 初始化完成", "CardLibrary")

func _connect_signals() -> void:
	# 可以连接游戏开始信号来初始化卡牌库
	SignalBus.game_started.connect(_on_game_started)

# ========== 卡牌数据加载 ==========
## 从JSON文件加载卡牌数据
## file_path: JSON文件路径
## 返回加载的卡牌数量
func load_cards_from_json(file_path: String) -> int:
	var json_data = DataManager.load_json_file(file_path)
	if json_data.is_empty():
		DebugLogger.error("CardLibrary: 无法加载JSON文件: " + file_path, "CardLibrary")
		return 0
	
	var cards_array: Array = []
	if json_data.has("cards") and json_data["cards"] is Array:
		cards_array = json_data["cards"]
	elif json_data.has("data") and json_data["data"] is Array:
		cards_array = json_data["data"]
	else:
		DebugLogger.error("CardLibrary: JSON文件格式错误，缺少cards或data字段: " + file_path, "CardLibrary")
		return 0
	
	var loaded_count = 0
	for card_dict in cards_array:
		if not card_dict is Dictionary:
			continue
		
		var card = CardData.new()
		card.from_dict(card_dict)
		
		if card.validate():
			_card_database[card.id] = card
			loaded_count += 1
			DebugLogger.debug("CardLibrary: 加载卡牌 " + card.id + " - " + card.name, "CardLibrary")
		else:
			DebugLogger.warning("CardLibrary: 卡牌数据验证失败: " + str(card_dict), "CardLibrary")
	
	_update_card_pool()
	DebugLogger.info("CardLibrary: 从JSON加载了 " + str(loaded_count) + " 张卡牌", "CardLibrary")
	return loaded_count

## 从Resource文件加载卡牌数据
## file_path: Resource文件路径
## 返回是否成功加载
func load_card_from_resource(file_path: String) -> bool:
	var resource = DataManager.load_resource_file(file_path)
	if resource == null:
		DebugLogger.error("CardLibrary: 无法加载Resource文件: " + file_path, "CardLibrary")
		return false
	
	if not resource is CardData:
		DebugLogger.error("CardLibrary: Resource不是CardData类型: " + file_path, "CardLibrary")
		return false
	
	var card = resource as CardData
	if card.validate():
		_card_database[card.id] = card
		_update_card_pool()
		DebugLogger.info("CardLibrary: 从Resource加载卡牌 " + card.id + " - " + card.name, "CardLibrary")
		return true
	else:
		DebugLogger.warning("CardLibrary: 卡牌数据验证失败: " + file_path, "CardLibrary")
		return false

## 添加卡牌数据（手动）
func add_card(card: CardData) -> bool:
	if not card.validate():
		DebugLogger.warning("CardLibrary: 卡牌数据验证失败: " + card.id, "CardLibrary")
		return false
	
	_card_database[card.id] = card
	_update_card_pool()
	DebugLogger.debug("CardLibrary: 添加卡牌 " + card.id + " - " + card.name, "CardLibrary")
	return true

# ========== 卡牌查询接口 ==========
## 根据ID获取卡牌
func get_card(card_id: String) -> CardData:
	if _card_database.has(card_id):
		return _card_database[card_id]
	DebugLogger.warning("CardLibrary: 卡牌不存在: " + card_id, "CardLibrary")
	return null

## 根据类型获取所有卡牌
func get_cards_by_type(card_type: int) -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id in _card_database:
		var card = _card_database[card_id]
		if card.card_type == card_type:
			result.append(card)
	return result

## 根据序列获取所有卡牌
func get_cards_by_serial(serial: int) -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id in _card_database:
		var card = _card_database[card_id]
		if card.serial == serial:
			result.append(card)
	return result

## 根据类型和序列获取所有卡牌
func get_cards_by_type_and_serial(card_type: int, serial: int) -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id in _card_database:
		var card = _card_database[card_id]
		if card.card_type == card_type and card.serial == serial:
			result.append(card)
	return result

## 获取所有卡牌
func get_all_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id in _card_database:
		result.append(_card_database[card_id])
	return result

## 获取所有卡牌ID
func get_all_card_ids() -> Array[String]:
	return _card_database.keys()

# ========== 卡牌解锁状态管理 ==========
## 解锁卡牌
func unlock_card(card_id: String) -> bool:
	if not _card_database.has(card_id):
		DebugLogger.warning("CardLibrary: 无法解锁不存在的卡牌: " + card_id, "CardLibrary")
		return false
	
	var card = _card_database[card_id]
	if not card.is_unlocked:
		card.unlock()
		if not card_id in _unlocked_cards:
			_unlocked_cards.append(card_id)
		_update_card_pool()
		DebugLogger.info("CardLibrary: 解锁卡牌 " + card_id, "CardLibrary")
		return true
	return false

## 锁定卡牌
func lock_card(card_id: String) -> bool:
	if not _card_database.has(card_id):
		return false
	
	var card = _card_database[card_id]
	if card.is_unlocked:
		card.lock()
		_unlocked_cards.erase(card_id)
		_update_card_pool()
		DebugLogger.info("CardLibrary: 锁定卡牌 " + card_id, "CardLibrary")
		return true
	return false

## 检查卡牌是否已解锁
func is_card_unlocked(card_id: String) -> bool:
	if not _card_database.has(card_id):
		return false
	return _card_database[card_id].is_unlocked

## 获取所有已解锁的卡牌
func get_unlocked_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id in _unlocked_cards:
		if _card_database.has(card_id):
			result.append(_card_database[card_id])
	return result

# ========== 卡牌收集状态管理 ==========
## 收集卡牌
func collect_card(card_id: String) -> bool:
	if not _card_database.has(card_id):
		DebugLogger.warning("CardLibrary: 无法收集不存在的卡牌: " + card_id, "CardLibrary")
		return false
	
	var card = _card_database[card_id]
	if not card.is_collected:
		card.collect()
		if not card_id in _collected_cards:
			_collected_cards.append(card_id)
		_update_card_pool()
		DebugLogger.info("CardLibrary: 收集卡牌 " + card_id, "CardLibrary")
		return true
	return false

## 取消收集卡牌
func uncollect_card(card_id: String) -> bool:
	if not _card_database.has(card_id):
		return false
	
	var card = _card_database[card_id]
	if card.is_collected:
		card.uncollect()
		_collected_cards.erase(card_id)
		_update_card_pool()
		DebugLogger.info("CardLibrary: 取消收集卡牌 " + card_id, "CardLibrary")
		return true
	return false

## 检查卡牌是否已收集
func is_card_collected(card_id: String) -> bool:
	if not _card_database.has(card_id):
		return false
	return _card_database[card_id].is_collected

## 获取所有已收集的卡牌
func get_collected_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id in _collected_cards:
		if _card_database.has(card_id):
			result.append(_card_database[card_id])
	return result

# ========== 卡牌池管理 ==========
## 更新卡牌池（已解锁且已收集的卡牌）
func _update_card_pool() -> void:
	_card_pool.clear()
	for card_id in _card_database:
		var card = _card_database[card_id]
		if card.is_unlocked and card.is_collected:
			_card_pool.append(card_id)

## 获取可用卡牌池
func get_card_pool() -> Array[String]:
	return _card_pool.duplicate()

## 从卡牌池随机获取卡牌
func get_random_card_from_pool() -> CardData:
	if _card_pool.is_empty():
		return null
	
	var random_id = _card_pool[randi() % _card_pool.size()]
	return get_card(random_id)

## 从卡牌池随机获取多张卡牌
func get_random_cards_from_pool(count: int) -> Array[CardData]:
	var result: Array[CardData] = []
	var available_pool = _card_pool.duplicate()
	
	for i in range(min(count, available_pool.size())):
		var random_index = randi() % available_pool.size()
		var card_id = available_pool[random_index]
		result.append(get_card(card_id))
		available_pool.remove_at(random_index)
	
	return result

# ========== 游戏事件处理 ==========
func _on_game_started() -> void:
	# 游戏开始时可以初始化默认解锁的卡牌
	DebugLogger.info("CardLibrary: 游戏开始，初始化卡牌库", "CardLibrary")

# ========== 重置和清理 ==========
## 重置卡牌库
func reset() -> void:
	_card_database.clear()
	_unlocked_cards.clear()
	_collected_cards.clear()
	_card_pool.clear()
	DebugLogger.info("CardLibrary: 卡牌库已重置", "CardLibrary")

## 清空解锁和收集状态（保留数据）
func clear_status() -> void:
	for card_id in _card_database:
		var card = _card_database[card_id]
		card.lock()
		card.uncollect()
	_unlocked_cards.clear()
	_collected_cards.clear()
	_card_pool.clear()
	DebugLogger.info("CardLibrary: 卡牌状态已清空", "CardLibrary")
