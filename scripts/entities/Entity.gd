extends Node2D
class_name Entity

## 实体单位
## 管理实体的视觉表现、位置、移动和效果

# ========== 节点引用 ==========
@onready var sprite: Sprite2D = get_node("Sprite2D") if has_node("Sprite2D") else null
@onready var range_indicator: Node2D = get_node("RangeIndicator") if has_node("RangeIndicator") else null

# ========== 数据 ==========
var entity_data: EntityData = null
var construct_state: ConstructState = null
var effects: Array[ConstructEffect] = []

# ========== 初始化 ==========
func _ready() -> void:
	construct_state = ConstructState.new(Constants.CONSTRUCT_STATE_INACTIVE)
	_update_visual()

# ========== 初始化接口 ==========
## 初始化实体
func initialize(data: EntityData) -> void:
	entity_data = data
	if entity_data:
		position = _grid_to_world(entity_data.position)
		construct_state.change_state(Constants.CONSTRUCT_STATE_ACTIVE)
		_update_visual()
		_update_range_indicator()
		
		# 发射信号
		SignalBus.construct_spawned.emit(entity_data.id, Constants.CONSTRUCT_TYPE_ENTITY, entity_data.position)
		
		DebugLogger.info("Entity: 初始化实体 " + entity_data.name + " 在位置 " + str(entity_data.position), "Entity")

## 设置位置
func set_grid_position(pos: Vector2i) -> void:
	if entity_data:
		entity_data.set_position(pos)
		position = _grid_to_world(pos)
		_update_range_indicator()

## 获取网格位置
func get_grid_position() -> Vector2i:
	if entity_data:
		return entity_data.get_position()
	return Vector2i.ZERO

# ========== 更新 ==========
func _process(delta: float) -> void:
	if construct_state:
		construct_state.update(delta)
	
	# 处理移动
	if entity_data and entity_data.movement_speed > 0:
		_process_movement(delta)

## 处理移动
func _process_movement(delta: float) -> void:
	# 这里可以实现移动逻辑
	# 根据movement_rule决定移动方式
	match entity_data.movement_rule:
		"static":
			pass  # 不移动
		"follow":
			# 跟随目标（需要目标信息）
			pass
		"patrol":
			# 巡逻（需要路径信息）
			pass

# ========== 视觉效果 ==========
func _update_visual() -> void:
	if not sprite:
		return
	
	# 根据状态更新视觉
	if construct_state:
		match construct_state.get_state():
			Constants.CONSTRUCT_STATE_ACTIVE:
				sprite.modulate = Color.WHITE
			Constants.CONSTRUCT_STATE_DISABLED:
				sprite.modulate = Color.GRAY
			Constants.CONSTRUCT_STATE_DESTROYED:
				sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)

func _update_range_indicator() -> void:
	if not range_indicator or not entity_data:
		return
	
	# 更新影响范围指示器
	# 这里可以显示一个圆圈表示影响范围
	# 具体实现取决于RangeIndicator节点的类型

# ========== 效果系统 ==========
## 添加效果
func add_effect(effect: ConstructEffect) -> void:
	effects.append(effect)

## 移除效果
func remove_effect(effect: ConstructEffect) -> void:
	var index = effects.find(effect)
	if index >= 0:
		effects.remove_at(index)

## 触发效果（当调查员进入范围时）
func trigger_effects(investigator) -> void:
	if not entity_data or not construct_state.is_active():
		return
	
	# 检查生效概率
	if randf() > entity_data.trigger_probability:
		return
	
	# 应用所有效果
	for effect in effects:
		# 这里需要传入检定结果，暂时使用默认值
		# 实际应该从检定系统获取
		var check_result = Constants.CHECK_RESULT_SUCCESS
		effect.apply_effect(investigator, check_result)
		
		SignalBus.effect_triggered.emit(entity_data.id, "", effect.effect_type)

# ========== 工具函数 ==========
## 网格坐标转世界坐标
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	# 这里需要根据实际的网格系统计算
	# 假设每个网格是32x32像素
	return Vector2(grid_pos.x * 32, grid_pos.y * 32)

## 销毁实体
func destroy() -> void:
	if construct_state:
		construct_state.change_state(Constants.CONSTRUCT_STATE_DESTROYED)
	
	SignalBus.construct_destroyed.emit(entity_data.id if entity_data else "")
	queue_free()
