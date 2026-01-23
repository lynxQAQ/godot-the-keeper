class_name InvestigatorManager
extends Node

## 调查员管理器
## 负责管理所有调查员实例的注册、查询、更新和清理

# ========== 预加载 ==========
const InvestigatorScene = preload("res://scenes/entities/Investigator.tscn")

# ========== 调查员存储 ==========
var _investigators: Dictionary = {}  # {id: Investigator}
var _investigators_by_position: Dictionary = {}  # {Vector2i: Array[Investigator]}

# ========== 初始化 ==========
func _ready() -> void:
	DebugLogger.info("InvestigatorManager: 初始化完成", "InvestigatorManager")

func _process(delta: float) -> void:
	# 更新所有调查员
	_update_all_investigators(delta)

# ========== 注册和注销 ==========
## 注册调查员
func register_investigator(investigator: Investigator) -> bool:
	if not investigator or not investigator.investigator_data:
		DebugLogger.error("InvestigatorManager: 尝试注册无效的调查员", "InvestigatorManager")
		return false
	
	var investigator_id = investigator.investigator_data.id
	if _investigators.has(investigator_id):
		DebugLogger.warning("InvestigatorManager: 调查员 " + investigator_id + " 已存在，将被覆盖", "InvestigatorManager")
	
	_investigators[investigator_id] = investigator
	
	# 更新位置索引
	_update_position_index(investigator)
	
	DebugLogger.debug("InvestigatorManager: 注册调查员 " + investigator_id, "InvestigatorManager")
	return true

## 注销调查员
func unregister_investigator(investigator_id: String) -> bool:
	if not _investigators.has(investigator_id):
		return false
	
	var investigator = _investigators[investigator_id]
	if investigator and investigator.investigator_data:
		_remove_from_position_index(investigator.investigator_data.position, investigator)
	
	_investigators.erase(investigator_id)
	DebugLogger.debug("InvestigatorManager: 注销调查员 " + investigator_id, "InvestigatorManager")
	return true

# ========== 查询接口 ==========
## 根据ID获取调查员
func get_investigator(investigator_id: String) -> Investigator:
	return _investigators.get(investigator_id, null)

## 根据位置获取调查员列表
func get_investigators_at_position(pos: Vector2i) -> Array[Investigator]:
	return _investigators_by_position.get(pos, []).duplicate()

## 根据状态获取调查员列表
func get_investigators_by_state(is_alive: bool = true) -> Array[Investigator]:
	var result: Array[Investigator] = []
	for investigator in _investigators.values():
		if investigator and investigator.investigator_state:
			if is_alive and investigator.investigator_state.is_alive():
				result.append(investigator)
			elif not is_alive and investigator.investigator_state.is_dead():
				result.append(investigator)
	return result

## 获取所有调查员
func get_all_investigators() -> Array[Investigator]:
	return _investigators.values().duplicate()

## 获取存活调查员数量
func get_alive_count() -> int:
	return get_investigators_by_state(true).size()

## 获取死亡调查员数量
func get_dead_count() -> int:
	return get_investigators_by_state(false).size()

# ========== 生成和初始化 ==========
## 生成调查员
func spawn_investigator(
	data: InvestigatorData,
	grid_manager: GridMapManager,
	parent_node: Node2D
) -> Investigator:
	if not data or not grid_manager or not parent_node:
		DebugLogger.error("InvestigatorManager: 生成调查员参数无效", "InvestigatorManager")
		return null
	
	# 实例化调查员场景
	var investigator = InvestigatorScene.instantiate()
	if not investigator:
		DebugLogger.error("InvestigatorManager: 无法实例化调查员场景", "InvestigatorManager")
		return null
	
	# 添加到父节点
	parent_node.add_child(investigator)
	
	# 初始化调查员
	investigator.initialize(data, grid_manager)
	
	# 注册调查员
	register_investigator(investigator)
	
	DebugLogger.info("InvestigatorManager: 生成调查员 " + data.name + " 在位置 " + str(data.position), "InvestigatorManager")
	return investigator

## 批量生成调查员
func spawn_investigators(
	investigator_data_list: Array[InvestigatorData],
	grid_manager: GridMapManager,
	parent_node: Node2D
) -> Array[Investigator]:
	var result: Array[Investigator] = []
	for data in investigator_data_list:
		var investigator = spawn_investigator(data, grid_manager, parent_node)
		if investigator:
			result.append(investigator)
	return result

# ========== 更新和清理 ==========
## 更新所有调查员
func _update_all_investigators(delta: float) -> void:
	# 调查员会在各自的_process中更新
	# 这里可以做一些全局的更新逻辑
	pass

## 清理已死亡的调查员
func cleanup_dead() -> void:
	var to_remove: Array[String] = []
	
	for investigator_id in _investigators:
		var investigator = _investigators[investigator_id]
		if not investigator or (investigator.investigator_state and investigator.investigator_state.is_dead()):
			to_remove.append(investigator_id)
	
	for investigator_id in to_remove:
		unregister_investigator(investigator_id)
		var investigator = _investigators.get(investigator_id)
		if investigator:
			investigator.destroy()

## 清理所有调查员
func clear_all() -> void:
	for investigator_id in _investigators.keys():
		var investigator = _investigators[investigator_id]
		if investigator:
			investigator.destroy()
	
	_investigators.clear()
	_investigators_by_position.clear()
	DebugLogger.info("InvestigatorManager: 已清理所有调查员", "InvestigatorManager")

# ========== 位置索引管理 ==========
## 更新位置索引
func _update_position_index(investigator: Investigator) -> void:
	if not investigator or not investigator.investigator_data:
		return
	
	var pos = investigator.investigator_data.position
	if not _investigators_by_position.has(pos):
		_investigators_by_position[pos] = []
	
	var investigators_at_pos = _investigators_by_position[pos]
	if not investigators_at_pos.has(investigator):
		investigators_at_pos.append(investigator)

## 从位置索引移除
func _remove_from_position_index(pos: Vector2i, investigator: Investigator) -> void:
	if not _investigators_by_position.has(pos):
		return
	
	var investigators_at_pos = _investigators_by_position[pos]
	investigators_at_pos.erase(investigator)
	
	if investigators_at_pos.is_empty():
		_investigators_by_position.erase(pos)

# ========== 胜利/失败判定 ==========
## 检查是否有调查员到达目标（秘密位置）
func check_victory_condition(secret_position: Vector2i) -> bool:
	var investigators_at_secret = get_investigators_at_position(secret_position)
	for investigator in investigators_at_secret:
		if investigator and investigator.investigator_state and investigator.investigator_state.is_alive():
			return true
	return false

## 检查是否所有调查员都已死亡
func check_all_dead() -> bool:
	return get_alive_count() == 0

## 检查是否胜利（所有调查员死亡）
func check_win_condition() -> bool:
	return check_all_dead()

## 检查是否失败（有调查员到达秘密且存活）
func check_lose_condition(secret_position: Vector2i) -> bool:
	return check_victory_condition(secret_position)

# ========== 批量操作 ==========
## 设置所有调查员的目标位置
func set_all_targets(target_position: Vector2i) -> void:
	for investigator in _investigators.values():
		if investigator:
			investigator.set_target_position(target_position)

## 更新所有调查员的位置索引
func update_all_position_indices() -> void:
	_investigators_by_position.clear()
	for investigator in _investigators.values():
		if investigator:
			_update_position_index(investigator)
