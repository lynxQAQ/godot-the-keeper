extends Node2D
class_name Virtual

## 虚体单位
## 管理虚体的视觉表现、持续时间、范围效果

# ========== 节点引用 ==========
@onready var particles: GPUParticles2D = get_node("GPUParticles2D") if has_node("GPUParticles2D") else null
@onready var range_indicator: Node2D = get_node("RangeIndicator") if has_node("RangeIndicator") else null

# ========== 数据 ==========
var virtual_data: VirtualData = null
var construct_state: ConstructState = null
var effects: Array[ConstructEffect] = []

# ========== 初始化 ==========
func _ready() -> void:
	construct_state = ConstructState.new(Constants.CONSTRUCT_STATE_INACTIVE)
	_update_visual()

# ========== 初始化接口 ==========
## 初始化虚体
func initialize(data: VirtualData) -> void:
	virtual_data = data
	if virtual_data:
		position = _grid_to_world(virtual_data.center_position)
		construct_state.change_state(Constants.CONSTRUCT_STATE_ACTIVE)
		_update_visual()
		_update_range_indicator()
		
		# 发射信号
		SignalBus.construct_spawned.emit(virtual_data.id, Constants.CONSTRUCT_TYPE_VIRTUAL, virtual_data.center_position)
		
		DebugLogger.info("Virtual: 初始化虚体 " + virtual_data.name + " 在位置 " + str(virtual_data.center_position), "Virtual")

## 设置中心位置
func set_center_position(pos: Vector2i) -> void:
	if virtual_data:
		virtual_data.set_center_position(pos)
		position = _grid_to_world(pos)
		_update_range_indicator()

## 获取中心位置
func get_center_position() -> Vector2i:
	if virtual_data:
		return virtual_data.get_center_position()
	return Vector2i.ZERO

# ========== 更新 ==========
func _process(delta: float) -> void:
	if construct_state:
		construct_state.update(delta)
	
	# 更新时间
	if virtual_data:
		if not virtual_data.update_time(delta):
			# 时间耗尽，销毁虚体
			destroy()

# ========== 视觉效果 ==========
func _update_visual() -> void:
	if particles:
		# 根据状态更新粒子效果
		if construct_state and construct_state.is_active():
			particles.emitting = true
		else:
			particles.emitting = false
	
	# 根据剩余时间更新透明度
	if virtual_data and virtual_data.duration > 0:
		var alpha = virtual_data.get_time_percentage()
		modulate.a = alpha

func _update_range_indicator() -> void:
	if not range_indicator or not virtual_data:
		return
	
	# 更新影响范围指示器
	# 这里可以显示一个圆圈表示影响范围

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
	if not virtual_data or not construct_state.is_active():
		return
	
	# 检查是否过期
	if virtual_data.is_expired():
		return
	
	# 检查生效概率
	if randf() > virtual_data.trigger_probability:
		return
	
	# 应用所有效果
	for effect in effects:
		# 这里需要传入检定结果，暂时使用默认值
		var check_result = Constants.CHECK_RESULT_SUCCESS
		effect.apply_effect(investigator, check_result)
		
		SignalBus.effect_triggered.emit(virtual_data.id, "", effect.effect_type)

# ========== 工具函数 ==========
## 网格坐标转世界坐标
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	# 这里需要根据实际的网格系统计算
	# 假设每个网格是32x32像素
	return Vector2(grid_pos.x * 32, grid_pos.y * 32)

## 销毁虚体
func destroy() -> void:
	if construct_state:
		construct_state.change_state(Constants.CONSTRUCT_STATE_DESTROYED)
	
	SignalBus.construct_destroyed.emit(virtual_data.id if virtual_data else "")
	queue_free()
