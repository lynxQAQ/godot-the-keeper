extends Node

## 资源管理器
## 单例，负责管理表构造力、里构造力等资源的生成、消耗、追踪和管理

# ========== 资源数据 ==========
var _table_construct: ResourceData  # 表构造力
var _inner_construct: ResourceData  # 里构造力
var _truth_element_resource: TruthElementResource  # 真理要素资源系统

# ========== 资源生成计时器 ==========
var _table_construct_timer: float = 0.0  # 表构造力生成计时器（用于generation_rate）
var _inner_construct_timer: float = 0.0  # 里构造力生成计时器（用于generation_rate）
var _auto_generation_timer: float = 0.0  # 自动生成计时器（每5秒生成1点）

# ========== 初始化 ==========
func _ready() -> void:
	# 初始化资源数据
	_table_construct = ResourceData.new(
		Constants.RESOURCE_TABLE_CONSTRUCT,
		Constants.DEFAULT_TABLE_CONSTRUCT,
		Constants.DEFAULT_TABLE_CONSTRUCT_MAX,
		0.0
	)
	
	_inner_construct = ResourceData.new(
		Constants.RESOURCE_INNER_CONSTRUCT,
		Constants.DEFAULT_INNER_CONSTRUCT,
		Constants.DEFAULT_INNER_CONSTRUCT_MAX,
		0.0
	)
	
	# 初始化真理要素资源系统
	_truth_element_resource = TruthElementResource.new()
	add_child(_truth_element_resource)
	
	# 连接信号
	_connect_signals()
	
	DebugLogger.info("ResourceManager: 初始化完成", "ResourceManager")
	DebugLogger.info("ResourceManager: 表构造力 " + str(_table_construct.current_value) + "/" + str(_table_construct.max_value), "ResourceManager")
	DebugLogger.info("ResourceManager: 里构造力 " + str(_inner_construct.current_value) + "/" + str(_inner_construct.max_value), "ResourceManager")

func _connect_signals() -> void:
	# 连接游戏阶段信号，在回合开始时恢复资源
	SignalBus.preparation_phase_started.connect(_on_preparation_phase_started)
	SignalBus.round_started.connect(_on_round_started)

func _process(delta: float) -> void:
	# 处理资源自动生成（基于generation_rate）
	_process_table_construct_generation(delta)
	_process_inner_construct_generation(delta)
	
	# 处理每5秒自动生成（游戏开始后）
	_process_auto_generation(delta)

# ========== 表构造力系统 ==========
## 获取表构造力当前值
func get_table_construct() -> int:
	return _table_construct.current_value

## 获取表构造力上限
func get_table_construct_max() -> int:
	return _table_construct.max_value

## 增加表构造力
## amount: 增加的数量
## 返回实际增加的数量
func add_table_construct(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var added = _table_construct.add(amount)
	if added > 0:
		_emit_table_construct_changed()
		DebugLogger.debug("ResourceManager: 表构造力增加 " + str(added) + "，当前: " + str(_table_construct.current_value) + "/" + str(_table_construct.max_value), "ResourceManager")
	return added

## 消耗表构造力
## amount: 消耗的数量
## 返回是否成功消耗
func consume_table_construct(amount: int) -> bool:
	if amount <= 0:
		return false
	
	if not _table_construct.has_enough(amount):
		DebugLogger.warning("ResourceManager: 表构造力不足，需要: " + str(amount) + "，当前: " + str(_table_construct.current_value), "ResourceManager")
		return false
	
	var consumed = _table_construct.subtract(amount)
	if consumed > 0:
		_emit_table_construct_changed()
		DebugLogger.debug("ResourceManager: 表构造力消耗 " + str(consumed) + "，当前: " + str(_table_construct.current_value) + "/" + str(_table_construct.max_value), "ResourceManager")
	return consumed == amount

## 检查是否有足够的表构造力
func has_enough_table_construct(amount: int) -> bool:
	return _table_construct.has_enough(amount)

## 设置表构造力上限
func set_table_construct_max(value: int) -> void:
	_table_construct.set_max(value)
	_emit_table_construct_changed()
	DebugLogger.info("ResourceManager: 表构造力上限设置为 " + str(value), "ResourceManager")

## 设置表构造力生成速率
func set_table_construct_generation_rate(rate: float) -> void:
	_table_construct.generation_rate = rate
	DebugLogger.info("ResourceManager: 表构造力生成速率设置为 " + str(rate), "ResourceManager")

## 处理表构造力自动生成
func _process_table_construct_generation(delta: float) -> void:
	if _table_construct.generation_rate <= 0.0:
		return
	
	_table_construct_timer += delta
	var generation_interval = 1.0 / _table_construct.generation_rate if _table_construct.generation_rate > 0 else 1.0
	
	if _table_construct_timer >= generation_interval:
		var amount = int(_table_construct_timer / generation_interval)
		_table_construct_timer = fmod(_table_construct_timer, generation_interval)
		if amount > 0:
			add_table_construct(amount)

## 发射表构造力变化信号
func _emit_table_construct_changed() -> void:
	SignalBus.table_construct_changed.emit(_table_construct.current_value, _table_construct.max_value)
	SignalBus.resource_changed.emit(Constants.RESOURCE_TABLE_CONSTRUCT, _table_construct.current_value, _table_construct.max_value)

# ========== 里构造力系统 ==========
## 获取里构造力当前值
func get_inner_construct() -> int:
	return _inner_construct.current_value

## 获取里构造力上限
func get_inner_construct_max() -> int:
	return _inner_construct.max_value

## 增加里构造力
## amount: 增加的数量
## 返回实际增加的数量
func add_inner_construct(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var added = _inner_construct.add(amount)
	if added > 0:
		_emit_inner_construct_changed()
		DebugLogger.debug("ResourceManager: 里构造力增加 " + str(added) + "，当前: " + str(_inner_construct.current_value) + "/" + str(_inner_construct.max_value), "ResourceManager")
	return added

## 消耗里构造力
## amount: 消耗的数量
## 返回是否成功消耗
func consume_inner_construct(amount: int) -> bool:
	if amount <= 0:
		return false
	
	if not _inner_construct.has_enough(amount):
		DebugLogger.warning("ResourceManager: 里构造力不足，需要: " + str(amount) + "，当前: " + str(_inner_construct.current_value), "ResourceManager")
		return false
	
	var consumed = _inner_construct.subtract(amount)
	if consumed > 0:
		_emit_inner_construct_changed()
		DebugLogger.debug("ResourceManager: 里构造力消耗 " + str(consumed) + "，当前: " + str(_inner_construct.current_value) + "/" + str(_inner_construct.max_value), "ResourceManager")
	return consumed == amount

## 检查是否有足够的里构造力
func has_enough_inner_construct(amount: int) -> bool:
	return _inner_construct.has_enough(amount)

## 设置里构造力上限
func set_inner_construct_max(value: int) -> void:
	_inner_construct.set_max(value)
	_emit_inner_construct_changed()
	DebugLogger.info("ResourceManager: 里构造力上限设置为 " + str(value), "ResourceManager")

## 设置里构造力生成速率
func set_inner_construct_generation_rate(rate: float) -> void:
	_inner_construct.generation_rate = rate
	DebugLogger.info("ResourceManager: 里构造力生成速率设置为 " + str(rate), "ResourceManager")

## 处理里构造力自动生成
func _process_inner_construct_generation(delta: float) -> void:
	if _inner_construct.generation_rate <= 0.0:
		return
	
	_inner_construct_timer += delta
	var generation_interval = 1.0 / _inner_construct.generation_rate if _inner_construct.generation_rate > 0 else 1.0
	
	if _inner_construct_timer >= generation_interval:
		var amount = int(_inner_construct_timer / generation_interval)
		_inner_construct_timer = fmod(_inner_construct_timer, generation_interval)
		if amount > 0:
			add_inner_construct(amount)

## 发射里构造力变化信号
func _emit_inner_construct_changed() -> void:
	SignalBus.inner_construct_changed.emit(_inner_construct.current_value, _inner_construct.max_value)
	SignalBus.resource_changed.emit(Constants.RESOURCE_INNER_CONSTRUCT, _inner_construct.current_value, _inner_construct.max_value)

# ========== 自动生成系统（每5秒生成1点） ==========
## 处理每5秒自动生成资源
func _process_auto_generation(delta: float) -> void:
	_auto_generation_timer += delta
	
	if _auto_generation_timer >= Constants.AUTO_GENERATION_INTERVAL:
		# 生成表构造力
		if Constants.AUTO_GENERATION_TABLE_CONSTRUCT > 0:
			add_table_construct(Constants.AUTO_GENERATION_TABLE_CONSTRUCT)
		
		# 生成里构造力
		if Constants.AUTO_GENERATION_INNER_CONSTRUCT > 0:
			add_inner_construct(Constants.AUTO_GENERATION_INNER_CONSTRUCT)
		
		# 重置计时器
		_auto_generation_timer = fmod(_auto_generation_timer, Constants.AUTO_GENERATION_INTERVAL)
		
		DebugLogger.debug("ResourceManager: 自动生成资源 - 表构造力+" + str(Constants.AUTO_GENERATION_TABLE_CONSTRUCT) + "，里构造力+" + str(Constants.AUTO_GENERATION_INNER_CONSTRUCT), "ResourceManager")

# ========== 真理要素资源系统接口 ==========
## 获取真理要素资源系统
func get_truth_element_resource() -> TruthElementResource:
	return _truth_element_resource

## 增加真理要素（委托给TruthElementResource）
func add_truth_element(serial: int, amount: int, state: int = Constants.TRUTH_STATE_ACTIVE) -> bool:
	return _truth_element_resource.add_truth_element(serial, amount, state)

## 减少真理要素（委托给TruthElementResource）
func subtract_truth_element(serial: int, amount: int, state: int = -1) -> bool:
	return _truth_element_resource.subtract_truth_element(serial, amount, state)

## 获取真理要素数量（委托给TruthElementResource）
func get_truth_element_count(serial: int) -> int:
	return _truth_element_resource.get_truth_element_count(serial)

# ========== 资源恢复机制 ==========
## 回合开始时恢复资源
func _on_round_started(round_number: int) -> void:
	DebugLogger.info("ResourceManager: 回合 " + str(round_number) + " 开始，恢复资源", "ResourceManager")
	# 可以在这里实现回合开始时的资源恢复逻辑
	# 例如：恢复部分表构造力
	# add_table_construct(5)

## 准备阶段开始时恢复资源
func _on_preparation_phase_started() -> void:
	DebugLogger.info("ResourceManager: 准备阶段开始，恢复资源", "ResourceManager")
	# 可以在这里实现准备阶段开始时的资源恢复逻辑
	# 例如：恢复全部表构造力
	# _table_construct.set_value(_table_construct.max_value)
	# _emit_table_construct_changed()

# ========== 资源上限和增长规则 ==========
## 增加表构造力上限
func increase_table_construct_max(amount: int) -> void:
	set_table_construct_max(_table_construct.max_value + amount)

## 增加里构造力上限
func increase_inner_construct_max(amount: int) -> void:
	set_inner_construct_max(_inner_construct.max_value + amount)

# ========== 重置和初始化 ==========
## 重置所有资源
func reset() -> void:
	_table_construct.set_value(Constants.DEFAULT_TABLE_CONSTRUCT)
	_table_construct.set_max(Constants.DEFAULT_TABLE_CONSTRUCT_MAX)
	_inner_construct.set_value(Constants.DEFAULT_INNER_CONSTRUCT)
	_inner_construct.set_max(Constants.DEFAULT_INNER_CONSTRUCT_MAX)
	_truth_element_resource.reset()
	
	_table_construct_timer = 0.0
	_inner_construct_timer = 0.0
	
	_emit_table_construct_changed()
	_emit_inner_construct_changed()
	
	DebugLogger.info("ResourceManager: 所有资源已重置", "ResourceManager")

## 初始化资源（使用自定义值）
func initialize(
	table_construct: int = Constants.DEFAULT_TABLE_CONSTRUCT,
	table_construct_max: int = Constants.DEFAULT_TABLE_CONSTRUCT_MAX,
	inner_construct: int = Constants.DEFAULT_INNER_CONSTRUCT,
	inner_construct_max: int = Constants.DEFAULT_INNER_CONSTRUCT_MAX
) -> void:
	_table_construct.set_value(table_construct)
	_table_construct.set_max(table_construct_max)
	_inner_construct.set_value(inner_construct)
	_inner_construct.set_max(inner_construct_max)
	
	_emit_table_construct_changed()
	_emit_inner_construct_changed()
	
	DebugLogger.info("ResourceManager: 资源已初始化", "ResourceManager")
