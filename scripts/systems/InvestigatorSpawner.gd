extends Node
class_name InvestigatorSpawner

## 调查员生成系统
## 负责管理调查员的生成逻辑和计时器

# ========== 信号 ==========
## 调查员已生成
signal investigator_spawned(investigator_id: String, position: Vector2i)

# ========== 导出属性 ==========
## 网格系统引用（需要外部设置）
var grid_system: GridSystemSurface = null

## 秘密管理器引用（用于排除秘密位置）
var secret_manager: SecretManager = null

## 生成延迟时间（秒）
@export var spawn_delay: float = 20.0

# ========== 生命周期 ==========
func _ready():
	pass

# ========== 初始化 ==========
## 设置网格系统引用（必须在调用其他方法前调用）
func set_grid_system(system: GridSystemSurface) -> void:
	grid_system = system

## 设置秘密管理器引用（用于排除秘密位置）
func set_secret_manager(manager: SecretManager) -> void:
	secret_manager = manager

# ========== 调查员生成 ==========
## 启动调查员生成计时器（默认20秒后生成）
func start_spawn_timer(delay: float = -1.0) -> void:
	var wait_time = delay if delay > 0.0 else spawn_delay
	# 等待指定时间
	await get_tree().create_timer(wait_time).timeout
	# 时间到后生成调查员
	spawn_investigator_at_edge()

## 找到所有紧贴边缘的已开垦网格
func get_edge_explored_grids() -> Array[Vector2i]:
	var edge_explored: Array[Vector2i] = []
	
	if not grid_system:
		return edge_explored
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return edge_explored
	
	# 遍历所有边缘网格
	for x in range(grid_manager.grid_size.x):
		# 上边缘
		var pos_top = Vector2i(x, 0)
		var grid_data_top = grid_manager.get_grid(pos_top)
		if grid_data_top and grid_data_top.get_is_explored_type():
			edge_explored.append(pos_top)
		
		# 下边缘
		var pos_bottom = Vector2i(x, grid_manager.grid_size.y - 1)
		var grid_data_bottom = grid_manager.get_grid(pos_bottom)
		if grid_data_bottom and grid_data_bottom.get_is_explored_type():
			edge_explored.append(pos_bottom)
	
	for y in range(1, grid_manager.grid_size.y - 1):
		# 左边缘
		var pos_left = Vector2i(0, y)
		var grid_data_left = grid_manager.get_grid(pos_left)
		if grid_data_left and grid_data_left.get_is_explored_type():
			edge_explored.append(pos_left)
		
		# 右边缘
		var pos_right = Vector2i(grid_manager.grid_size.x - 1, y)
		var grid_data_right = grid_manager.get_grid(pos_right)
		if grid_data_right and grid_data_right.get_is_explored_type():
			edge_explored.append(pos_right)
	
	return edge_explored

## 在边缘已开垦网格上生成调查员
func spawn_investigator_at_edge() -> void:
	if not grid_system:
		DebugLogger.warning("InvestigatorSpawner: 无法生成调查员 - grid_system 为空", "InvestigatorSpawner")
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		DebugLogger.warning("InvestigatorSpawner: 无法生成调查员 - grid_manager 为空", "InvestigatorSpawner")
		return
	
	# 获取所有边缘已开垦网格
	var edge_explored = get_edge_explored_grids()
	
	if edge_explored.is_empty():
		DebugLogger.warning("InvestigatorSpawner: 没有边缘已开垦网格，无法生成调查员", "InvestigatorSpawner")
		return
	
	# 排除秘密位置，确保调查员不会生成在秘密所在位置
	var valid_spawn_positions: Array[Vector2i] = []
	var secret_pos = Vector2i(-1, -1)
	if secret_manager and secret_manager.has_secret_node():
		secret_pos = secret_manager.get_secret_position()
	
	# 过滤掉秘密位置
	for pos in edge_explored:
		if pos != secret_pos:
			valid_spawn_positions.append(pos)
	
	# 如果没有有效位置（所有边缘位置都是秘密位置），使用所有边缘位置
	if valid_spawn_positions.is_empty():
		# 复制边缘位置数组
		for pos in edge_explored:
			valid_spawn_positions.append(pos)
		DebugLogger.warning("InvestigatorSpawner: 所有边缘位置都是秘密位置，将在边缘随机生成", "InvestigatorSpawner")
	else:
		DebugLogger.debug("InvestigatorSpawner: 排除秘密位置 " + str(secret_pos) + "，有效生成位置数量: " + str(valid_spawn_positions.size()), "InvestigatorSpawner")
	
	# 随机选择一个边缘已开垦网格
	var spawn_pos = valid_spawn_positions[randi() % valid_spawn_positions.size()]
	
	# 创建调查员数据
	var investigator_id = "inv_%03d" % Time.get_ticks_msec()
	var investigator_data = InvestigatorData.new(
		investigator_id,
		"调查员",
		Constants.DEFAULT_INVESTIGATOR_HEALTH,
		Constants.DEFAULT_INVESTIGATOR_SANITY
	)
	
	# 设置随机属性值（50-70之间）
	investigator_data.strength = randi_range(50, 70)
	investigator_data.agility = randi_range(50, 70)
	investigator_data.intelligence = randi_range(50, 70)
	investigator_data.willpower = randi_range(50, 70)
	
	# 添加一些基础技能
	investigator_data.add_skill("调查", randi_range(1, 3))
	investigator_data.add_skill("战斗", randi_range(1, 3))
	
	# 设置初始位置
	investigator_data.set_position(spawn_pos)
	
	if GameManagers.InvestigatorManager == null:
		DebugLogger.error("InvestigatorSpawner: InvestigatorManager未初始化", "InvestigatorSpawner")
		return
	
	# 生成调查员（使用GameManagers的InvestigatorManager）
	var investigator = GameManagers.InvestigatorManager.spawn_investigator(
		investigator_data,
		grid_manager,
		grid_system  # 使用grid_system作为父节点
	)
	
	if not investigator:
		DebugLogger.error("InvestigatorSpawner: 生成调查员失败", "InvestigatorSpawner")
		return
	
	# 如果存在秘密，设置调查员的目标位置为秘密位置
	if secret_manager and secret_manager.has_secret_node():
		var target_secret_pos = secret_manager.get_secret_position()
		if target_secret_pos != Vector2i(-1, -1):
			investigator.set_target_position(target_secret_pos)
			DebugLogger.info("InvestigatorSpawner: 调查员已生成在 " + str(spawn_pos) + "，目标位置: " + str(target_secret_pos), "InvestigatorSpawner")
		else:
			DebugLogger.info("InvestigatorSpawner: 调查员已生成在 " + str(spawn_pos), "InvestigatorSpawner")
	else:
		DebugLogger.info("InvestigatorSpawner: 调查员已生成在 " + str(spawn_pos) + "（暂无目标）", "InvestigatorSpawner")
	
	investigator_spawned.emit(investigator_id, spawn_pos)
