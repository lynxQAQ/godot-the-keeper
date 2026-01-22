extends RefCounted
class_name Deck

## 牌组系统
## 管理牌组数据结构、卡牌添加移除、洗牌抽牌等逻辑

# ========== 牌组数据 ==========
var _cards: Array[String] = []  # 卡牌ID列表
var _draw_pile: Array[String] = []  # 抽牌堆
var _discard_pile: Array[String] = []  # 弃牌堆

# ========== 初始化 ==========
func _init(initial_cards: Array[String] = []) -> void:
	_cards = initial_cards.duplicate()
	_draw_pile = _cards.duplicate()
	shuffle()

# ========== 卡牌管理 ==========
## 添加卡牌到牌组
func add_card(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	
	_cards.append(card_id)
	_draw_pile.append(card_id)
	DebugLogger.debug("Deck: 添加卡牌到牌组: " + card_id, "Deck")
	return true

## 移除卡牌（从牌组中移除指定卡牌）
func remove_card(card_id: String) -> bool:
	var removed = false
	
	# 从主牌组移除
	var index = _cards.find(card_id)
	if index >= 0:
		_cards.remove_at(index)
		removed = true
	
	# 从抽牌堆移除
	index = _draw_pile.find(card_id)
	if index >= 0:
		_draw_pile.remove_at(index)
	
	# 从弃牌堆移除
	index = _discard_pile.find(card_id)
	if index >= 0:
		_discard_pile.remove_at(index)
	
	if removed:
		DebugLogger.debug("Deck: 从牌组移除卡牌: " + card_id, "Deck")
	return removed

## 添加多张卡牌
func add_cards(card_ids: Array[String]) -> int:
	var added_count = 0
	for card_id in card_ids:
		if add_card(card_id):
			added_count += 1
	return added_count

## 移除多张卡牌
func remove_cards(card_ids: Array[String]) -> int:
	var removed_count = 0
	for card_id in card_ids:
		if remove_card(card_id):
			removed_count += 1
	return removed_count

## 检查牌组中是否有指定卡牌
func has_card(card_id: String) -> bool:
	return card_id in _cards

## 获取卡牌在牌组中的数量
func get_card_count(card_id: String) -> int:
	var count = 0
	for id in _cards:
		if id == card_id:
			count += 1
	return count

# ========== 查询接口 ==========
## 获取牌组大小
func get_size() -> int:
	return _cards.size()

## 获取抽牌堆大小
func get_draw_pile_size() -> int:
	return _draw_pile.size()

## 获取弃牌堆大小
func get_discard_pile_size() -> int:
	return _discard_pile.size()

## 获取所有卡牌ID
func get_all_cards() -> Array[String]:
	return _cards.duplicate()

## 获取抽牌堆所有卡牌
func get_draw_pile() -> Array[String]:
	return _draw_pile.duplicate()

## 获取弃牌堆所有卡牌
func get_discard_pile() -> Array[String]:
	return _discard_pile.duplicate()

## 检查牌组是否为空
func is_empty() -> bool:
	return _cards.is_empty()

## 检查抽牌堆是否为空
func is_draw_pile_empty() -> bool:
	return _draw_pile.is_empty()

# ========== 洗牌和抽牌 ==========
## 洗牌（打乱抽牌堆）
func shuffle() -> void:
	_draw_pile.shuffle()
	DebugLogger.debug("Deck: 牌组已洗牌，抽牌堆大小: " + str(_draw_pile.size()), "Deck")

## 抽牌（从抽牌堆顶部抽取）
func draw_card() -> String:
	if _draw_pile.is_empty():
		# 如果抽牌堆为空，尝试将弃牌堆洗牌后重新加入抽牌堆
		if not _discard_pile.is_empty():
			reshuffle_discard_pile()
		
		if _draw_pile.is_empty():
			DebugLogger.warning("Deck: 抽牌堆和弃牌堆都为空，无法抽牌", "Deck")
			return ""
	
	var card_id = _draw_pile.pop_front()
	DebugLogger.debug("Deck: 抽牌: " + card_id + "，剩余: " + str(_draw_pile.size()), "Deck")
	return card_id

## 抽多张牌
func draw_cards(count: int) -> Array[String]:
	var result: Array[String] = []
	for i in range(count):
		var card_id = draw_card()
		if card_id.is_empty():
			break
		result.append(card_id)
	return result

## 将卡牌加入弃牌堆
func discard_card(card_id: String) -> void:
	if card_id.is_empty():
		return
	
	_discard_pile.append(card_id)
	DebugLogger.debug("Deck: 卡牌加入弃牌堆: " + card_id, "Deck")

## 将多张卡牌加入弃牌堆
func discard_cards(card_ids: Array[String]) -> void:
	for card_id in card_ids:
		discard_card(card_id)

## 将弃牌堆洗牌后重新加入抽牌堆
func reshuffle_discard_pile() -> void:
	if _discard_pile.is_empty():
		return
	
	_draw_pile.append_array(_discard_pile)
	_discard_pile.clear()
	shuffle()
	DebugLogger.info("Deck: 弃牌堆已洗牌并重新加入抽牌堆", "Deck")

## 查看抽牌堆顶部卡牌（不抽取）
func peek_top_card() -> String:
	if _draw_pile.is_empty():
		return ""
	return _draw_pile[0]

## 查看抽牌堆顶部多张卡牌（不抽取）
func peek_top_cards(count: int) -> Array[String]:
	var result: Array[String] = []
	for i in range(min(count, _draw_pile.size())):
		result.append(_draw_pile[i])
	return result

# ========== 序列化 ==========
## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"cards": _cards.duplicate(),
		"draw_pile": _draw_pile.duplicate(),
		"discard_pile": _discard_pile.duplicate()
	}

## 从字典反序列化
func from_dict(data: Dictionary) -> void:
	_cards = data.get("cards", []).duplicate()
	_draw_pile = data.get("draw_pile", []).duplicate()
	_discard_pile = data.get("discard_pile", []).duplicate()

## 序列化为JSON字符串
func to_json() -> String:
	return JSON.stringify(to_dict())

## 从JSON字符串反序列化
func from_json(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Deck: Failed to parse JSON: " + json_string)
		return false
	
	if json.data is Dictionary:
		from_dict(json.data)
		return true
	else:
		push_error("Deck: JSON data is not a Dictionary")
		return false

# ========== 重置和清理 ==========
## 重置牌组（清空所有卡牌）
func reset() -> void:
	_cards.clear()
	_draw_pile.clear()
	_discard_pile.clear()
	DebugLogger.info("Deck: 牌组已重置", "Deck")

## 清空弃牌堆
func clear_discard_pile() -> void:
	_discard_pile.clear()
	DebugLogger.debug("Deck: 弃牌堆已清空", "Deck")

## 将弃牌堆重新加入抽牌堆（不洗牌）
func return_discard_to_draw() -> void:
	_draw_pile.append_array(_discard_pile)
	_discard_pile.clear()
	DebugLogger.debug("Deck: 弃牌堆已重新加入抽牌堆", "Deck")
