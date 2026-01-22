extends Node2D
class_name Investigator

## 调查员实体
## 管理调查员的视觉表现、位置、移动和状态

# ========== 预加载 ==========
const Extensions = preload("res://scripts/utils/Extensions.gd")

# ========== 节点引用 ==========
@onready var sprite: ColorRect = get_node("ColorRect") if has_node("ColorRect") else null
@onready var health_bar: ProgressBar = get_node("HealthBar") if has_node("HealthBar") else null
@onready var sanity_bar: ProgressBar = get_node("SanityBar") if has_node("SanityBar") else null

# ========== 数据 ==========
var investigator_data: InvestigatorData = null
var investigator_state: InvestigatorState = null
var investigator_movement: InvestigatorMovement = null
var investigator_pathfinding: InvestigatorPathfinding = null

# ========== 移动相关 ==========
var target_world_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var move_speed: float = 100.0  # 像素/秒

# ========== 初始化 ==========
func _ready() -> void:
	investigator_state = InvestigatorState.new()
	investigator_movement = InvestigatorMovement.new()
	investigator_pathfinding = InvestigatorPathfinding.new()
	
	# 连接状态信号
	if investigator_state:
		investigator_state.health_changed.connect(_on_health_changed)
		investigator_state.sanity_changed.connect(_on_sanity_changed)
		investigator_state.investigator_died.connect(_on_investigator_died)
	
	_update_visual()

# ========== 初始化接口 ==========
## 初始化调查员
func initialize(data: InvestigatorData, grid_manager: GridMapManager = null) -> void:
	investigator_data = data
	if investigator_data:
		# 初始化状态
		if investigator_state:
			investigator_state.initialize_from_data(investigator_data)
		
		# 设置位置
		if grid_manager:
			var world_pos = _grid_to_world(investigator_data.position, grid_manager)
			position = world_pos
			target_world_position = world_pos
		
		# 设置寻路系统
		if investigator_pathfinding:
			investigator_pathfinding.set_grid_manager(grid_manager)
		
		_update_visual()
		_update_bars()
		
		# 发射信号
		SignalBus.investigator_spawned.emit(investigator_data.id, investigator_data.position)
		
		DebugLogger.info("Investigator: 初始化调查员 " + investigator_data.name + " 在位置 " + str(investigator_data.position), "Investigator")

## 设置网格位置
func set_grid_position(pos: Vector2i, grid_manager: GridMapManager = null) -> void:
	if investigator_data:
		investigator_data.set_position(pos)
		if grid_manager:
			var world_pos = _grid_to_world(pos, grid_manager)
			position = world_pos
			target_world_position = world_pos
			
			# 发射移动信号
			SignalBus.investigator_moved.emit(investigator_data.id, investigator_data.position, pos)

## 获取网格位置
func get_grid_position() -> Vector2i:
	if investigator_data:
		return investigator_data.get_position()
	return Vector2i.ZERO

## 设置目标位置（秘密位置）
func set_target_position(target: Vector2i) -> void:
	if investigator_pathfinding:
		var current_pos = get_grid_position()
		investigator_pathfinding.set_target(target, current_pos)

# ========== 更新 ==========
func _process(delta: float) -> void:
	# 更新状态效果
	if investigator_state:
		investigator_state.update_status_effects(delta)
	
	# 处理移动
	_process_movement(delta)
	
	# 更新UI
	_update_bars()

## 处理移动
func _process_movement(delta: float) -> void:
	if not investigator_data or not investigator_pathfinding:
		return
	
	# 检查是否可以移动
	var current_time = Time.get_ticks_msec() / 1000.0
	if not investigator_movement.can_move(current_time):
		return
	
	# 检查是否被移动阻碍
	if investigator_state and investigator_state.is_movement_blocked():
		return
	
	# 获取下一个路径点
	var next_path_point = investigator_pathfinding.get_next_path_point()
	if next_path_point == Vector2i(-1, -1):
		return
	
	var current_pos = get_grid_position()
	
	# 如果已到达当前路径点，移动到下一个
	if current_pos == next_path_point:
		if investigator_pathfinding.move_to_next():
			next_path_point = investigator_pathfinding.get_next_path_point()
		else:
			# 已到达终点
			_on_reached_target()
			return
	
	# 检查路径是否仍然有效
	if not investigator_pathfinding.is_path_valid(current_pos):
		# 重新计算路径
		var target = investigator_pathfinding.target_position
		if target != Vector2i(-1, -1):
			investigator_pathfinding.recalculate_path(current_pos)
			next_path_point = investigator_pathfinding.get_next_path_point()
	
	# 获取可通行的邻居（需要从GridSystem获取）
	# 这里暂时使用寻路系统提供的路径点
	if next_path_point != Vector2i(-1, -1) and next_path_point != current_pos:
		# 移动到下一个路径点
		set_grid_position(next_path_point)
		investigator_movement.update_move_time(current_time)
		
		# 平滑移动动画
		if investigator_pathfinding and investigator_pathfinding.grid_manager:
			var target_world = _grid_to_world(next_path_point, investigator_pathfinding.grid_manager)
			target_world_position = target_world
			is_moving = true

# ========== 平滑移动 ==========
func _physics_process(delta: float) -> void:
	if is_moving:
		var distance = position.distance_to(target_world_position)
		if distance > 1.0:
			position = position.move_toward(target_world_position, move_speed * delta)
		else:
			position = target_world_position
			is_moving = false

# ========== 视觉效果 ==========
func _update_visual() -> void:
	if not sprite:
		return
	
	# 根据状态更新视觉
	if investigator_state:
		if investigator_state.is_dead():
			sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
			sprite.color = Color(0.5, 0.5, 0.5, 0.5)
		else:
			sprite.modulate = Color.WHITE
			sprite.color = Color(0.2, 0.6, 1, 1)

func _update_bars() -> void:
	if investigator_state:
		if health_bar:
			health_bar.max_value = investigator_state.health_max
			health_bar.value = investigator_state.health
		
		if sanity_bar:
			sanity_bar.max_value = investigator_state.sanity_max
			sanity_bar.value = investigator_state.sanity

# ========== 状态变化处理 ==========
func _on_health_changed(current: int, max_value: int) -> void:
	_update_bars()
	SignalBus.investigator_state_changed.emit(investigator_data.id if investigator_data else "", current, investigator_state.sanity if investigator_state else 0)

func _on_sanity_changed(current: int, max_value: int) -> void:
	_update_bars()
	SignalBus.investigator_state_changed.emit(investigator_data.id if investigator_data else "", investigator_state.health if investigator_state else 0, current)

func _on_investigator_died() -> void:
	_update_visual()
	SignalBus.investigator_died.emit(investigator_data.id if investigator_data else "")
	DebugLogger.info("Investigator: 调查员 " + (investigator_data.name if investigator_data else "") + " 已死亡", "Investigator")

# ========== 目标到达处理 ==========
func _on_reached_target() -> void:
	SignalBus.investigator_victory.emit(investigator_data.id if investigator_data else "")
	DebugLogger.info("Investigator: 调查员 " + (investigator_data.name if investigator_data else "") + " 到达目标", "Investigator")

# ========== 效果系统 ==========
## 应用伤害
func apply_damage(amount: int) -> void:
	if investigator_state:
		investigator_state.reduce_health(amount, true)

## 应用理智损失
func apply_sanity_loss(amount: int) -> void:
	if investigator_state:
		investigator_state.reduce_sanity(amount, true)

## 添加状态效果
func add_status_effect(effect_id: String, effect_type: String, duration: float, value: int = 0) -> void:
	if investigator_state:
		investigator_state.add_status_effect(effect_id, effect_type, duration, value)
	
	# 记录经历
	if investigator_data:
		var description = "受到效果: " + effect_type
		investigator_data.add_experience(effect_id, description)

# ========== 工具函数 ==========
## 网格坐标转世界坐标
func _grid_to_world(grid_pos: Vector2i, grid_manager: GridMapManager) -> Vector2:
	if not grid_manager:
		return Vector2(grid_pos.x * 32, grid_pos.y * 32)
	
	# 使用等距网格转换
	return Extensions.grid_to_world(grid_pos, grid_manager.cell_size)

## 销毁调查员
func destroy() -> void:
	if investigator_data:
		SignalBus.investigator_died.emit(investigator_data.id)
	queue_free()
