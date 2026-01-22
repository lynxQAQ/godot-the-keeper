extends Node
class_name TruthElementResource

## 真理要素资源系统
## 管理真理要素的序列（I-V）、数量追踪和状态分布统计

# ========== 真理要素数据结构 ==========
## 真理要素统计信息
class TruthElementInfo:
	var serial: int  # 序列（1-5，对应I-V）
	var count: int  # 数量
	var state_distribution: Dictionary = {}  # 状态分布 {state: count}
	
	func _init(p_serial: int = 1, p_count: int = 0) -> void:
		serial = p_serial
		count = p_count
		# 初始化状态分布
		state_distribution = {
			Constants.TRUTH_STATE_ACTIVE: 0,
			Constants.TRUTH_STATE_SLEEPING: 0,
			Constants.TRUTH_STATE_EXTINCT: 0,
			Constants.TRUTH_STATE_SUBLIMATED: 0
		}

# ========== 内部变量 ==========
var _truth_elements: Dictionary = {}  # {serial: TruthElementInfo}
var _total_count: int = 0  # 总数量

# ========== 初始化 ==========
func _ready() -> void:
	# 初始化所有序列的真理要素
	for i in range(1, Constants.TRUTH_SERIAL_COUNT + 1):
		_truth_elements[i] = TruthElementInfo.new(i, 0)
	
	DebugLogger.info("TruthElementResource: 初始化完成，序列数量: " + str(Constants.TRUTH_SERIAL_COUNT), "TruthElementResource")

# ========== 真理要素管理 ==========
## 增加真理要素
## serial: 序列（1-5）
## amount: 数量
## state: 状态（可选，默认为活跃）
func add_truth_element(serial: int, amount: int, state: int = Constants.TRUTH_STATE_ACTIVE) -> bool:
	if serial < 1 or serial > Constants.TRUTH_SERIAL_COUNT:
		DebugLogger.error("TruthElementResource: 无效的序列: " + str(serial), "TruthElementResource")
		return false
	
	if amount <= 0:
		return false
	
	if not _truth_elements.has(serial):
		_truth_elements[serial] = TruthElementInfo.new(serial, 0)
	
	var element = _truth_elements[serial]
	element.count += amount
	element.state_distribution[state] = element.state_distribution.get(state, 0) + amount
	_total_count += amount
	
	# 发射信号
	SignalBus.truth_element_changed.emit(serial, element.count)
	SignalBus.resource_changed.emit(Constants.RESOURCE_TRUTH_ELEMENT, _total_count, 0)
	
	DebugLogger.debug("TruthElementResource: 序列 " + str(serial) + " 增加 " + str(amount) + "，当前数量: " + str(element.count), "TruthElementResource")
	return true

## 减少真理要素
## serial: 序列（1-5）
## amount: 数量
## state: 状态（可选，优先从指定状态减少）
func subtract_truth_element(serial: int, amount: int, state: int = -1) -> bool:
	if serial < 1 or serial > Constants.TRUTH_SERIAL_COUNT:
		DebugLogger.error("TruthElementResource: 无效的序列: " + str(serial), "TruthElementResource")
		return false
	
	if not _truth_elements.has(serial):
		return false
	
	var element = _truth_elements[serial]
	if element.count < amount:
		DebugLogger.warning("TruthElementResource: 序列 " + str(serial) + " 数量不足，需要: " + str(amount) + "，当前: " + str(element.count), "TruthElementResource")
		return false
	
	element.count -= amount
	_total_count -= amount
	
	# 从指定状态减少，如果没有指定则从活跃状态减少
	if state >= 0 and element.state_distribution.has(state):
		var state_amount = min(amount, element.state_distribution[state])
		element.state_distribution[state] -= state_amount
		amount -= state_amount
	
	# 如果还有剩余，从活跃状态减少
	if amount > 0 and element.state_distribution.has(Constants.TRUTH_STATE_ACTIVE):
		var state_amount = min(amount, element.state_distribution[Constants.TRUTH_STATE_ACTIVE])
		element.state_distribution[Constants.TRUTH_STATE_ACTIVE] -= state_amount
	
	# 发射信号
	SignalBus.truth_element_changed.emit(serial, element.count)
	SignalBus.resource_changed.emit(Constants.RESOURCE_TRUTH_ELEMENT, _total_count, 0)
	
	DebugLogger.debug("TruthElementResource: 序列 " + str(serial) + " 减少 " + str(amount) + "，当前数量: " + str(element.count), "TruthElementResource")
	return true

## 设置真理要素状态
## serial: 序列（1-5）
## amount: 数量
## from_state: 原状态
## to_state: 目标状态
func change_truth_element_state(serial: int, amount: int, from_state: int, to_state: int) -> bool:
	if serial < 1 or serial > Constants.TRUTH_SERIAL_COUNT:
		return false
	
	if not _truth_elements.has(serial):
		return false
	
	var element = _truth_elements[serial]
	if element.state_distribution.get(from_state, 0) < amount:
		return false
	
	element.state_distribution[from_state] -= amount
	element.state_distribution[to_state] = element.state_distribution.get(to_state, 0) + amount
	
	DebugLogger.debug("TruthElementResource: 序列 " + str(serial) + " 状态变化，从 " + Constants.get_truth_state_name(from_state) + " 到 " + Constants.get_truth_state_name(to_state) + "，数量: " + str(amount), "TruthElementResource")
	return true

# ========== 查询接口 ==========
## 获取指定序列的真理要素数量
func get_truth_element_count(serial: int) -> int:
	if not _truth_elements.has(serial):
		return 0
	return _truth_elements[serial].count

## 获取真理要素总数量
func get_total_count() -> int:
	return _total_count

## 获取指定序列的状态分布
func get_state_distribution(serial: int) -> Dictionary:
	if not _truth_elements.has(serial):
		return {}
	return _truth_elements[serial].state_distribution.duplicate()

## 获取所有序列的状态分布统计
func get_all_state_distribution() -> Dictionary:
	var result = {}
	for state in [Constants.TRUTH_STATE_ACTIVE, Constants.TRUTH_STATE_SLEEPING, Constants.TRUTH_STATE_EXTINCT, Constants.TRUTH_STATE_SUBLIMATED]:
		result[state] = 0
	
	for serial in _truth_elements:
		var element = _truth_elements[serial]
		for state in element.state_distribution:
			result[state] = result.get(state, 0) + element.state_distribution[state]
	
	return result

## 获取指定序列的指定状态数量
func get_state_count(serial: int, state: int) -> int:
	if not _truth_elements.has(serial):
		return 0
	return _truth_elements[serial].state_distribution.get(state, 0)

## 检查是否有足够的真理要素
func has_enough_truth_element(serial: int, amount: int) -> bool:
	return get_truth_element_count(serial) >= amount

# ========== 统计接口 ==========
## 获取所有序列的数量统计
func get_serial_statistics() -> Dictionary:
	var result = {}
	for serial in range(1, Constants.TRUTH_SERIAL_COUNT + 1):
		result[serial] = get_truth_element_count(serial)
	return result

## 重置所有真理要素
func reset() -> void:
	for serial in _truth_elements:
		var element = _truth_elements[serial]
		element.count = 0
		for state in element.state_distribution:
			element.state_distribution[state] = 0
	_total_count = 0
	
	# 发射信号
	for serial in range(1, Constants.TRUTH_SERIAL_COUNT + 1):
		SignalBus.truth_element_changed.emit(serial, 0)
	SignalBus.resource_changed.emit(Constants.RESOURCE_TRUTH_ELEMENT, 0, 0)
	
	DebugLogger.info("TruthElementResource: 已重置所有真理要素", "TruthElementResource")
