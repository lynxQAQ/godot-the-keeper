extends RefCounted
class_name CardReserve

## 卡牌预备区系统
## 管理仪式生成的卡牌暂存区，支持添加、移除、容量管理

# ========== 预备区数据 ==========
var _cards: Array[String] = []  # 预备区卡牌ID列表
var _max_capacity: int = 10  # 预备区最大容量

# ========== 初始化 ==========
func _init(max_capacity: int = 10) -> void:
	_max_capacity = max_capacity

# ========== 卡牌管理 ==========
## 添加卡牌到预备区
func add_card(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	
	if is_full():
		DebugLogger.warning("CardReserve: 预备区已满，无法添加卡牌: " + card_id, "CardReserve")
		return false
	
	_cards.append(card_id)
	DebugLogger.debug("CardReserve: 添加卡牌到预备区: " + card_id + "，当前数量: " + str(_cards.size()), "CardReserve")
	return true

## 从预备区移除卡牌（到手牌或使用）
func remove_card(card_id: String) -> bool:
	var index = _cards.find(card_id)
	if index < 0:
		DebugLogger.warning("CardReserve: 预备区中不存在卡牌: " + card_id, "CardReserve")
		return false
	
	_cards.remove_at(index)
	DebugLogger.debug("CardReserve: 从预备区移除卡牌: " + card_id + "，当前数量: " + str(_cards.size()), "CardReserve")
	return true

## 添加多张卡牌
func add_cards(card_ids: Array[String]) -> int:
	var added_count = 0
	for card_id in card_ids:
		if add_card(card_id):
			added_count += 1
		else:
			break  # 预备区已满，停止添加
	return added_count

## 移除多张卡牌
func remove_cards(card_ids: Array[String]) -> int:
	var removed_count = 0
	for card_id in card_ids:
		if remove_card(card_id):
			removed_count += 1
	return removed_count

## 检查预备区中是否有指定卡牌
func has_card(card_id: String) -> bool:
	return card_id in _cards

## 获取卡牌在预备区中的索引
func get_card_index(card_id: String) -> int:
	return _cards.find(card_id)

# ========== 查询接口 ==========
## 获取预备区大小
func get_size() -> int:
	return _cards.size()

## 获取预备区最大容量
func get_max_capacity() -> int:
	return _max_capacity

## 设置预备区最大容量
func set_max_capacity(capacity: int) -> void:
	if capacity < 0:
		DebugLogger.warning("CardReserve: 预备区容量不能为负数: " + str(capacity), "CardReserve")
		return
	
	_max_capacity = capacity
	
	# 如果当前卡牌数超过新容量，移除多余的卡牌
	while _cards.size() > _max_capacity:
		var removed_card = _cards.pop_back()
		DebugLogger.warning("CardReserve: 预备区容量减少，移除卡牌: " + removed_card, "CardReserve")
	
	DebugLogger.info("CardReserve: 预备区容量设置为: " + str(_max_capacity), "CardReserve")

## 获取所有预备区卡牌ID
func get_all_cards() -> Array[String]:
	return _cards.duplicate()

## 获取指定索引的卡牌
func get_card_at(index: int) -> String:
	if index < 0 or index >= _cards.size():
		return ""
	return _cards[index]

## 检查预备区是否为空
func is_empty() -> bool:
	return _cards.is_empty()

## 检查预备区是否已满
func is_full() -> bool:
	return _cards.size() >= _max_capacity

## 检查是否可以添加卡牌
func can_add_card() -> bool:
	return not is_full()

## 获取剩余空间
func get_remaining_space() -> int:
	return max(0, _max_capacity - _cards.size())

# ========== 容量管理 ==========
## 验证预备区数量是否超过容量
func validate() -> bool:
	if _cards.size() > _max_capacity:
		DebugLogger.warning("CardReserve: 预备区数量超过容量: " + str(_cards.size()) + " > " + str(_max_capacity), "CardReserve")
		return false
	return true

## 修正预备区（移除超过容量的卡牌）
func fix() -> void:
	while _cards.size() > _max_capacity:
		var removed_card = _cards.pop_back()
		DebugLogger.warning("CardReserve: 修正预备区，移除超过容量的卡牌: " + removed_card, "CardReserve")

## 增加容量
func increase_capacity(amount: int) -> void:
	if amount > 0:
		_max_capacity += amount
		DebugLogger.info("CardReserve: 预备区容量增加 " + str(amount) + "，当前容量: " + str(_max_capacity), "CardReserve")

## 减少容量
func decrease_capacity(amount: int) -> void:
	if amount > 0:
		set_max_capacity(_max_capacity - amount)

# ========== 卡牌移动 ==========
## 将卡牌从预备区移动到手牌
func move_to_hand(card_id: String, hand: Hand) -> bool:
	if not has_card(card_id):
		return false
	
	if not hand.can_add_card():
		DebugLogger.warning("CardReserve: 手牌已满，无法移动卡牌: " + card_id, "CardReserve")
		return false
	
	if remove_card(card_id):
		if hand.add_card(card_id):
			DebugLogger.info("CardReserve: 卡牌从预备区移动到手牌: " + card_id, "CardReserve")
			return true
		else:
			# 如果添加到手牌失败，将卡牌放回预备区
			add_card(card_id)
			return false
	return false

## 将多张卡牌从预备区移动到手牌
func move_multiple_to_hand(card_ids: Array[String], hand: Hand) -> int:
	var moved_count = 0
	for card_id in card_ids:
		if move_to_hand(card_id, hand):
			moved_count += 1
		else:
			break  # 手牌已满，停止移动
	return moved_count

## 将所有卡牌移动到手牌
func move_all_to_hand(hand: Hand) -> int:
	var moved_count = 0
	var cards_to_move = _cards.duplicate()
	for card_id in cards_to_move:
		if move_to_hand(card_id, hand):
			moved_count += 1
		else:
			break  # 手牌已满，停止移动
	return moved_count

# ========== 重置和清理 ==========
## 清空预备区
func clear() -> void:
	_cards.clear()
	DebugLogger.info("CardReserve: 预备区已清空", "CardReserve")

## 重置预备区（清空并重置容量）
func reset(max_capacity: int = 10) -> void:
	clear()
	_max_capacity = max_capacity
	DebugLogger.info("CardReserve: 预备区已重置，容量: " + str(_max_capacity), "CardReserve")

# ========== 序列化 ==========
## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"cards": _cards.duplicate(),
		"max_capacity": _max_capacity
	}

## 从字典反序列化
func from_dict(data: Dictionary) -> void:
	_cards = data.get("cards", []).duplicate()
	_max_capacity = data.get("max_capacity", 10)
	fix()  # 确保不超过容量

## 序列化为JSON字符串
func to_json() -> String:
	return JSON.stringify(to_dict())

## 从JSON字符串反序列化
func from_json(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("CardReserve: Failed to parse JSON: " + json_string)
		return false
	
	if json.data is Dictionary:
		from_dict(json.data)
		return true
	else:
		push_error("CardReserve: JSON data is not a Dictionary")
		return false
