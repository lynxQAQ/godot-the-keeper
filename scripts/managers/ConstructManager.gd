extends Node

## 构造体管理器
## 单例，负责管理所有构造体实例的注册、查询、更新和清理

# ========== 构造体存储 ==========
var _entities: Dictionary = {}  # {id: Entity}
var _virtuals: Dictionary = {}  # {id: Virtual}
var _entity_by_position: Dictionary = {}  # {Vector2i: Entity}
var _virtual_by_position: Dictionary = {}  # {Vector2i: Array[Virtual]}

# ========== 初始化 ==========
func _ready() -> void:
	DebugLogger.info("ConstructManager: 初始化完成", "ConstructManager")

func _process(delta: float) -> void:
	# 更新所有构造体
	_update_all_constructs(delta)

# ========== 注册和注销 ==========
## 注册实体
func register_entity(entity: Entity) -> bool:
	if not entity or not entity.entity_data:
		DebugLogger.error("ConstructManager: 尝试注册无效的实体", "ConstructManager")
		return false
	
	var entity_id = entity.entity_data.id
	if _entities.has(entity_id):
		DebugLogger.warning("ConstructManager: 实体 " + entity_id + " 已存在，将被覆盖", "ConstructManager")
	
	_entities[entity_id] = entity
	_entity_by_position[entity.entity_data.position] = entity
	
	DebugLogger.debug("ConstructManager: 注册实体 " + entity_id, "ConstructManager")
	return true

## 注册虚体
func register_virtual(virtual: Virtual) -> bool:
	if not virtual or not virtual.virtual_data:
		DebugLogger.error("ConstructManager: 尝试注册无效的虚体", "ConstructManager")
		return false
	
	var virtual_id = virtual.virtual_data.id
	if _virtuals.has(virtual_id):
		DebugLogger.warning("ConstructManager: 虚体 " + virtual_id + " 已存在，将被覆盖", "ConstructManager")
	
	_virtuals[virtual_id] = virtual
	
	# 虚体可以多个在同一位置
	if not _virtual_by_position.has(virtual.virtual_data.center_position):
		_virtual_by_position[virtual.virtual_data.center_position] = []
	_virtual_by_position[virtual.virtual_data.center_position].append(virtual)
	
	DebugLogger.debug("ConstructManager: 注册虚体 " + virtual_id, "ConstructManager")
	return true

## 注销实体
func unregister_entity(entity_id: String) -> bool:
	if not _entities.has(entity_id):
		return false
	
	var entity = _entities[entity_id]
	if entity and entity.entity_data:
		_entity_by_position.erase(entity.entity_data.position)
	
	_entities.erase(entity_id)
	DebugLogger.debug("ConstructManager: 注销实体 " + entity_id, "ConstructManager")
	return true

## 注销虚体
func unregister_virtual(virtual_id: String) -> bool:
	if not _virtuals.has(virtual_id):
		return false
	
	var virtual = _virtuals[virtual_id]
	if virtual and virtual.virtual_data:
		var pos = virtual.virtual_data.center_position
		if _virtual_by_position.has(pos):
			var virtuals_at_pos = _virtual_by_position[pos]
			virtuals_at_pos.erase(virtual)
			if virtuals_at_pos.is_empty():
				_virtual_by_position.erase(pos)
	
	_virtuals.erase(virtual_id)
	DebugLogger.debug("ConstructManager: 注销虚体 " + virtual_id, "ConstructManager")
	return true

# ========== 查询接口 ==========
## 根据ID获取实体
func get_entity(entity_id: String) -> Entity:
	return _entities.get(entity_id, null)

## 根据ID获取虚体
func get_virtual(virtual_id: String) -> Virtual:
	return _virtuals.get(virtual_id, null)

## 根据位置获取实体
func get_entity_at_position(pos: Vector2i) -> Entity:
	return _entity_by_position.get(pos, null)

## 根据位置获取虚体列表
func get_virtuals_at_position(pos: Vector2i) -> Array[Virtual]:
	return _virtual_by_position.get(pos, []).duplicate()

## 根据位置获取所有构造体（实体+虚体）
func get_constructs_at_position(pos: Vector2i) -> Array:
	var result = []
	var entity = get_entity_at_position(pos)
	if entity:
		result.append(entity)
	result.append_array(get_virtuals_at_position(pos))
	return result

## 根据类型获取所有构造体
func get_constructs_by_type(construct_type: int) -> Array:
	if construct_type == Constants.CONSTRUCT_TYPE_ENTITY:
		return _entities.values().duplicate()
	elif construct_type == Constants.CONSTRUCT_TYPE_VIRTUAL:
		return _virtuals.values().duplicate()
	return []

## 根据范围获取构造体
func get_constructs_in_range(center: Vector2i, range_distance: int) -> Array:
	var result = []
	
	# 检查实体
	for entity in _entities.values():
		if entity and entity.entity_data:
			var distance = _manhattan_distance(center, entity.entity_data.position)
			if distance <= range_distance:
				result.append(entity)
	
	# 检查虚体
	for virtual in _virtuals.values():
		if virtual and virtual.virtual_data:
			var distance = _manhattan_distance(center, virtual.virtual_data.center_position)
			if distance <= range_distance:
				result.append(virtual)
	
	return result

# ========== 影响范围检测 ==========
## 检查位置是否在构造体的影响范围内
func is_position_in_range(construct_id: String, pos: Vector2i) -> bool:
	var entity = get_entity(construct_id)
	if entity and entity.entity_data:
		var distance = _manhattan_distance(entity.entity_data.position, pos)
		return distance <= entity.entity_data.effect_range
	
	var virtual = get_virtual(construct_id)
	if virtual and virtual.virtual_data:
		var distance = _manhattan_distance(virtual.virtual_data.center_position, pos)
		return distance <= virtual.virtual_data.effect_range
	
	return false

## 获取影响指定位置的所有构造体
func get_constructs_affecting_position(pos: Vector2i) -> Array:
	var result = []
	
	# 检查实体
	for entity in _entities.values():
		if entity and entity.entity_data:
			if is_position_in_range(entity.entity_data.id, pos):
				result.append(entity)
	
	# 检查虚体
	for virtual in _virtuals.values():
		if virtual and virtual.virtual_data:
			if is_position_in_range(virtual.virtual_data.id, pos):
				result.append(virtual)
	
	return result

# ========== 更新和清理 ==========
## 更新所有构造体
func _update_all_constructs(delta: float) -> void:
	# 实体和虚体会在各自的_process中更新
	# 这里可以做一些全局的更新逻辑
	pass

## 清理已销毁的构造体
func cleanup_destroyed() -> void:
	var to_remove_entities = []
	var to_remove_virtuals = []
	
	# 检查实体
	for entity_id in _entities:
		var entity = _entities[entity_id]
		if not entity or (entity.construct_state and entity.construct_state.is_destroyed()):
			to_remove_entities.append(entity_id)
	
	# 检查虚体
	for virtual_id in _virtuals:
		var virtual = _virtuals[virtual_id]
		if not virtual or (virtual.construct_state and virtual.construct_state.is_destroyed()):
			to_remove_virtuals.append(virtual_id)
	
	# 移除已销毁的构造体
	for entity_id in to_remove_entities:
		unregister_entity(entity_id)
	
	for virtual_id in to_remove_virtuals:
		unregister_virtual(virtual_id)

## 清理所有构造体
func clear_all() -> void:
	_entities.clear()
	_virtuals.clear()
	_entity_by_position.clear()
	_virtual_by_position.clear()
	DebugLogger.info("ConstructManager: 已清理所有构造体", "ConstructManager")

# ========== 统计接口 ==========
## 获取实体数量
func get_entity_count() -> int:
	return _entities.size()

## 获取虚体数量
func get_virtual_count() -> int:
	return _virtuals.size()

## 获取构造体总数
func get_total_count() -> int:
	return _entities.size() + _virtuals.size()

## 获取按序列统计的实体数量
func get_entity_count_by_serial() -> Dictionary:
	var result = {}
	for i in range(1, 6):
		result[i] = 0
	
	for entity in _entities.values():
		if entity and entity.entity_data:
			var serial = entity.entity_data.serial
			result[serial] = result.get(serial, 0) + 1
	
	return result

## 获取按序列统计的虚体数量
func get_virtual_count_by_serial() -> Dictionary:
	var result = {}
	for i in range(1, 6):
		result[i] = 0
	
	for virtual in _virtuals.values():
		if virtual and virtual.virtual_data:
			var serial = virtual.virtual_data.serial
			result[serial] = result.get(serial, 0) + 1
	
	return result

# ========== 工具函数 ==========
## 计算曼哈顿距离
func _manhattan_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)
