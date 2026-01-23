extends RefCounted
class_name Hand

## 手牌管理系统
## 管理当前持有的卡牌、添加移除、数量限制、排序筛选等

# ========== 手牌数据 ==========
var _cards: Array[String] = []  # 手牌ID列表
var _max_size: int = Constants.DEFAULT_HAND_SIZE  # 手牌数量上限

# ========== 初始化 ==========
func _init(max_size: int = Constants.DEFAULT_HAND_SIZE) -> void:
	_max_size = max_size

# ========== 手牌管理 ==========
## 添加卡牌到手牌（从牌组抽牌）
func add_card(card_id: String) -> bool:
	if card_id.is_empty():
		return false
	
	if is_full():
		DebugLogger.warning("Hand: 手牌已满，无法添加卡牌: " + card_id, "Hand")
		return false
	
	_cards.append(card_id)
	SignalBus.card_added_to_hand.emit(card_id)
	DebugLogger.debug("Hand: 添加卡牌到手牌: " + card_id + "，当前手牌数: " + str(_cards.size()), "Hand")
	return true

## 从手牌移除卡牌（使用、丢弃）
func remove_card(card_id: String) -> bool:
	var index = _cards.find(card_id)
	if index < 0:
		DebugLogger.warning("Hand: 手牌中不存在卡牌: " + card_id, "Hand")
		return false
	
	_cards.remove_at(index)
	SignalBus.card_removed_from_hand.emit(card_id)
	DebugLogger.debug("Hand: 从手牌移除卡牌: " + card_id + "，当前手牌数: " + str(_cards.size()), "Hand")
	return true

## 添加多张卡牌
func add_cards(card_ids: Array[String]) -> int:
	var added_count = 0
	for card_id in card_ids:
		if add_card(card_id):
			added_count += 1
		else:
			break  # 手牌已满，停止添加
	return added_count

## 移除多张卡牌
func remove_cards(card_ids: Array[String]) -> int:
	var removed_count = 0
	for card_id in card_ids:
		if remove_card(card_id):
			removed_count += 1
	return removed_count

## 检查手牌中是否有指定卡牌
func has_card(card_id: String) -> bool:
	return card_id in _cards

## 获取卡牌在手牌中的索引
func get_card_index(card_id: String) -> int:
	return _cards.find(card_id)

# ========== 查询接口 ==========
## 获取手牌大小
func get_size() -> int:
	return _cards.size()

## 获取手牌上限
func get_max_size() -> int:
	return _max_size

## 设置手牌上限
func set_max_size(size: int) -> void:
	if size < 0:
		DebugLogger.warning("Hand: 手牌上限不能为负数: " + str(size), "Hand")
		return
	
	_max_size = size
	
	# 如果当前手牌数超过新上限，移除多余的卡牌
	while _cards.size() > _max_size:
		var removed_card = _cards.pop_back()
		SignalBus.card_removed_from_hand.emit(removed_card)
		DebugLogger.debug("Hand: 手牌上限减少，移除卡牌: " + removed_card, "Hand")
	
	DebugLogger.info("Hand: 手牌上限设置为: " + str(_max_size), "Hand")

## 获取所有手牌ID
func get_all_cards() -> Array[String]:
	return _cards.duplicate()

## 获取指定索引的卡牌
func get_card_at(index: int) -> String:
	if index < 0 or index >= _cards.size():
		return ""
	return _cards[index]

## 检查手牌是否为空
func is_empty() -> bool:
	return _cards.is_empty()

## 检查手牌是否已满
func is_full() -> bool:
	return _cards.size() >= _max_size

## 检查是否可以添加卡牌
func can_add_card() -> bool:
	return not is_full()

## 获取剩余手牌空间
func get_remaining_space() -> int:
	return max(0, _max_size - _cards.size())

# ========== 手牌验证 ==========
## 验证手牌数量是否超过上限
func validate() -> bool:
	if _cards.size() > _max_size:
		DebugLogger.warning("Hand: 手牌数量超过上限: " + str(_cards.size()) + " > " + str(_max_size), "Hand")
		return false
	return true

## 修正手牌（移除超过上限的卡牌）
func fix() -> void:
	while _cards.size() > _max_size:
		var removed_card = _cards.pop_back()
		SignalBus.card_removed_from_hand.emit(removed_card)
		DebugLogger.warning("Hand: 修正手牌，移除超过上限的卡牌: " + removed_card, "Hand")

# ========== 手牌排序和筛选 ==========
## 按卡牌ID排序
func sort_by_id() -> void:
	_cards.sort()
	DebugLogger.debug("Hand: 手牌已按ID排序", "Hand")

## 按卡牌类型排序
func sort_by_type() -> void:
	_cards.sort_custom(_compare_by_type)
	DebugLogger.debug("Hand: 手牌已按类型排序", "Hand")

## 按序列排序
func sort_by_serial() -> void:
	_cards.sort_custom(_compare_by_serial)
	DebugLogger.debug("Hand: 手牌已按序列排序", "Hand")

## 按消耗排序
func sort_by_cost() -> void:
	_cards.sort_custom(_compare_by_cost)
	DebugLogger.debug("Hand: 手牌已按消耗排序", "Hand")

## 筛选指定类型的卡牌
func filter_by_type(card_type: int) -> Array[String]:
	if GameManagers.CardLibrary == null:
		return []
	var result: Array[String] = []
	for card_id in _cards:
		var card = GameManagers.CardLibrary.get_card(card_id)
		if card != null and card.card_type == card_type:
			result.append(card_id)
	return result

## 筛选指定序列的卡牌
func filter_by_serial(serial: int) -> Array[String]:
	if GameManagers.CardLibrary == null:
		return []
	var result: Array[String] = []
	for card_id in _cards:
		var card = GameManagers.CardLibrary.get_card(card_id)
		if card != null and card.serial == serial:
			result.append(card_id)
	return result

## 筛选可以使用的卡牌（资源足够）
func filter_playable() -> Array[String]:
	if GameManagers.CardLibrary == null:
		return []
	var result: Array[String] = []
	for card_id in _cards:
		var card = GameManagers.CardLibrary.get_card(card_id)
		if card != null and card.can_afford():
			result.append(card_id)
	return result

# ========== 排序比较函数 ==========
func _compare_by_type(a: String, b: String) -> bool:
	if GameManagers.CardLibrary == null:
		return false
	var card_a = GameManagers.CardLibrary.get_card(a)
	var card_b = GameManagers.CardLibrary.get_card(b)
	if card_a == null or card_b == null:
		return false
	return card_a.card_type < card_b.card_type

func _compare_by_serial(a: String, b: String) -> bool:
	if GameManagers.CardLibrary == null:
		return false
	var card_a = GameManagers.CardLibrary.get_card(a)
	var card_b = GameManagers.CardLibrary.get_card(b)
	if card_a == null or card_b == null:
		return false
	return card_a.serial < card_b.serial

func _compare_by_cost(a: String, b: String) -> bool:
	if GameManagers.CardLibrary == null:
		return false
	var card_a = GameManagers.CardLibrary.get_card(a)
	var card_b = GameManagers.CardLibrary.get_card(b)
	if card_a == null or card_b == null:
		return false
	return card_a.get_total_cost() < card_b.get_total_cost()

# ========== 重置和清理 ==========
## 清空手牌
func clear() -> void:
	var removed_cards = _cards.duplicate()
	_cards.clear()
	for card_id in removed_cards:
		SignalBus.card_removed_from_hand.emit(card_id)
	DebugLogger.info("Hand: 手牌已清空", "Hand")

## 重置手牌（清空并重置上限）
func reset(max_size: int = Constants.DEFAULT_HAND_SIZE) -> void:
	clear()
	_max_size = max_size
	DebugLogger.info("Hand: 手牌已重置，上限: " + str(_max_size), "Hand")
