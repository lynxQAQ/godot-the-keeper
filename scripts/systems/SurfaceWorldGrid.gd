extends Control
class_name SurfaceWorldGrid

## 表世界网格系统
## 管理表世界的网格逻辑和交互

# ========== 预加载 ==========
const GridSystemScene = preload("res://scenes/worlds/GridSystem.tscn")
const GridSystemRule_Surface = preload("res://scripts/systems/GridSystemRule_Surface.gd")
const SecretScene = preload("res://scenes/entities/Secret.tscn")

# ========== 信号 ==========
## 网格被开垦
signal grid_explored(grid_pos: Vector2i)
## 迷宫被创建
signal maze_created(grid_pos: Vector2i)
## 秘密位置被发现
signal secret_found(grid_pos: Vector2i)

# ========== 导出属性 ==========
## 网格系统实例
var grid_system: GridSystem = null

# ========== 内部状态 ==========
## 是否已创建初始路径（防止重复创建）
var _initial_path_created: bool = false

## 当前秘密节点（如果为null表示玩家持有秘密）
var _secret_node: Secret = null

## 秘密容器节点
var _secret_container: Node2D = null

## 是否持有秘密（玩家已拾起但未放置）
var _has_secret_in_hand: bool = false

# ========== 生命周期 ==========
func _ready():
	# 设置Control布局（重要：确保 Control 节点正确填充父容器）
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# 实例化GridSystem场景
	grid_system = GridSystemScene.instantiate()
	if not grid_system:
		push_error("SurfaceWorldGrid: 无法实例化GridSystem场景")
		return
	
	# 添加到场景树
	# 注意：在 SubViewport 架构下，Node2D 会自动在视口内渲染，无需特殊布局
	add_child(grid_system)
	
	# 创建秘密容器节点
	_secret_container = Node2D.new()
	_secret_container.name = "SecretContainer"
	grid_system.add_child(_secret_container)
	
	# 连接信号
	grid_system.grid_clicked.connect(_on_grid_clicked)
	grid_system.grid_hovered.connect(_on_grid_hovered)
	grid_system.grid_state_changed.connect(_on_grid_state_changed)
	grid_system.grid_map_initialized.connect(_on_grid_map_initialized)
	
	# 加载表世界规则
	call_deferred("_load_surface_rule")
	
	# 初始化表世界网格
	_initialize_surface_world()

# ========== 输入转发 ==========
## 转发输入事件到 GridSystem（确保 GridSystem 能接收到输入）
## 注意：Secret 的点击由 Secret 的 Area2D 自己处理，不需要在这里拦截
func _input(event: InputEvent) -> void:
	if grid_system:
		# 将事件传递给 GridSystem
		# GridSystem 会自己处理，这里只是确保事件能到达
		pass

# ========== 初始化 ==========
## 初始化表世界
func _initialize_surface_world() -> void:
	if not grid_system:
		return
	
	# 设置网格尺寸并重新初始化网格地图
	# GridSystem 会自动根据当前所在的 SubViewport 大小计算居中
	var new_size = Vector2i(
		Constants.DEFAULT_GRID_SIZE_X,
		Constants.DEFAULT_GRID_SIZE_Y
	)
	# 延迟执行，确保 GridSystem 的 _ready() 已完成
	call_deferred("_reinitialize_grid_system", new_size)

## 加载表世界规则
func _load_surface_rule() -> void:
	if not grid_system:
		return
	
	# 创建表世界规则（grid_manager会在GridSystem中自动设置）
	var rule = GridSystemRule_Surface.new()
	grid_system.set_grid_rule(rule)
	
	# 如果grid_manager已经初始化，立即设置
	if grid_system.grid_manager:
		rule.grid_manager = grid_system.grid_manager
	else:
		# 等待GridSystem初始化完成
		await grid_system.grid_map_initialized
		if rule:
			rule.grid_manager = grid_system.grid_manager

## 重新初始化网格系统（当 grid_size 改变时）
func _reinitialize_grid_system(new_size: Vector2i) -> void:
	if not grid_system:
		return
	
	# 如果 GridSystem 已经初始化，使用公共方法重新初始化
	if grid_system.grid_manager:
		grid_system.resize_grid_map(new_size)
		# 重新加载规则（因为grid_manager可能已更新）
		if grid_system.get_grid_rule():
			grid_system.get_grid_rule().grid_manager = grid_system.grid_manager
	else:
		# 如果还没初始化，直接设置 grid_size，_ready() 会自动处理
		grid_system.grid_size = new_size

# ========== 网格操作 ==========
## 开垦网格（从未开垦转为已开垦）
func explore_grid(pos: Vector2i) -> bool:
	if not grid_system:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	# 使用规则系统检查是否可以开垦
	var grid_rule = grid_system.get_grid_rule()
	if grid_rule:
		var validate_result = grid_rule.validate_explore(pos)
		if not validate_result.valid:
			# 可以在这里显示提示信息
			print("无法开垦: ", validate_result.reason)
			return false
	
	# 检查是否可以开垦（基础检查）
	if not grid_data.is_unexplored():
		return false
	
	# 检查是否有足够的表构造力
	var resource_manager = _get_resource_manager()
	if resource_manager:
		if not resource_manager.has_enough_table_construct(Constants.COST_EXPLORE_SURFACE_GRID):
			DebugLogger.warning("SurfaceWorldGrid: 表构造力不足，无法开垦网格", "SurfaceWorldGrid")
			print("表构造力不足，需要 " + str(Constants.COST_EXPLORE_SURFACE_GRID) + " 点表构造力")
			return false
		
		# 消耗表构造力
		if not resource_manager.consume_table_construct(Constants.COST_EXPLORE_SURFACE_GRID):
			DebugLogger.warning("SurfaceWorldGrid: 消耗表构造力失败", "SurfaceWorldGrid")
			return false
	
	# 开垦网格
	grid_data.set_explored()
	grid_system.set_grid(pos, grid_data)
	
	# 执行规则系统的后处理
	if grid_rule:
		grid_rule.on_explore(pos)
	
	grid_explored.emit(pos)
	DebugLogger.debug("SurfaceWorldGrid: 成功开垦网格 " + str(pos) + "，消耗 " + str(Constants.COST_EXPLORE_SURFACE_GRID) + " 点表构造力", "SurfaceWorldGrid")
	return true

## 直接开垦网格（绕过规则检查，用于初始化等特殊情况）
func _explore_grid_direct(pos: Vector2i) -> bool:
	if not grid_system:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	# 检查是否可以开垦（基础检查）
	if not grid_data.is_unexplored():
		return false
	
	# 直接开垦网格（不经过规则检查）
	grid_data.set_explored()
	grid_system.set_grid(pos, grid_data)
	
	# 执行规则系统的后处理
	var grid_rule = grid_system.get_grid_rule()
	if grid_rule:
		grid_rule.on_explore(pos)
	
	grid_explored.emit(pos)
	return true

## 创建迷宫
func create_maze(pos: Vector2i) -> bool:
	if not grid_system:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	# 检查是否可以创建迷宫（必须是已开垦的网格）
	if grid_data.grid_type != Constants.GRID_TYPE_EXPLORED:
		return false
	
	# 创建迷宫
	grid_data.set_maze()
	grid_data.has_maze = true
	grid_system.set_grid(pos, grid_data)
	
	maze_created.emit(pos)
	return true

## 放置秘密（创建Secret场景节点）
func place_secret(pos: Vector2i) -> bool:
	if not grid_system or not _secret_container:
		return false
	
	# 检查是否持有秘密
	if not _has_secret_in_hand:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	# 检查是否已经是已开垦的网格
	if not grid_data.get_is_explored_type():
		DebugLogger.warning("SurfaceWorldGrid: 无法在未开垦的网格上放置秘密", "SurfaceWorldGrid")
		return false
	
	# 如果之前有秘密节点，先移除（理论上不应该有，因为已经拾起了）
	if _secret_node:
		_remove_secret()
	
	# 从场景文件实例化Secret节点
	var secret = SecretScene.instantiate()
	if not secret:
		DebugLogger.error("SurfaceWorldGrid: 无法实例化Secret场景", "SurfaceWorldGrid")
		return false
	
	# 计算世界坐标
	var world_pos = grid_system.grid_to_world(pos)
	
	# 先添加到容器（确保节点在场景树中）
	_secret_container.add_child(secret)
	
	# 然后设置位置
	secret.grid_pos = pos
	secret.world_pos = world_pos
	secret.position = world_pos
	
	# 连接点击信号
	if not secret.secret_clicked.is_connected(_on_secret_clicked):
		secret.secret_clicked.connect(_on_secret_clicked)
	
	# 更新状态
	_secret_node = secret
	_has_secret_in_hand = false
	
	secret_found.emit(pos)
	DebugLogger.debug("SurfaceWorldGrid: 秘密已放置在 " + str(pos), "SurfaceWorldGrid")
	return true

## 移除秘密节点
func _remove_secret() -> void:
	if _secret_node:
		_secret_node.queue_free()
		_secret_node = null

## 拾起秘密
func _pickup_secret() -> bool:
	if not _secret_node:
		return false
	
	# 移除秘密节点
	_remove_secret()
	
	# 更新状态：玩家持有秘密
	_has_secret_in_hand = true
	
	DebugLogger.debug("SurfaceWorldGrid: 秘密已拾起", "SurfaceWorldGrid")
	return true

## 处理秘密交互（拾起或放置）
func _handle_secret_interaction(grid_pos: Vector2i, grid_data: GridData) -> bool:
	# 如果玩家持有秘密，尝试放置
	if _has_secret_in_hand:
		# 必须放置在已开垦的网格上
		if grid_data.get_is_explored_type():
			if place_secret(grid_pos):
				print("秘密已放置在: ", grid_pos)
				return true
			else:
				print("无法在此位置放置秘密")
				return false
		else:
			print("秘密只能放置在已开垦的网格上")
			return false
	
	return false

## 秘密被点击时的处理
func _on_secret_clicked(secret: Secret) -> void:
	if secret == _secret_node:
		if _pickup_secret():
			print("秘密已拾起")

## 生成初始秘密（在已开垦的网格中随机选择一个）
func _spawn_initial_secret() -> void:
	if not grid_system or not _secret_container:
		DebugLogger.warning("SurfaceWorldGrid: 无法生成初始秘密 - grid_system 或 _secret_container 为空", "SurfaceWorldGrid")
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		DebugLogger.warning("SurfaceWorldGrid: 无法生成初始秘密 - grid_manager 为空", "SurfaceWorldGrid")
		return
	
	# 收集所有已开垦的网格位置
	var explored_positions: Array[Vector2i] = []
	for x in range(grid_manager.grid_size.x):
		for y in range(grid_manager.grid_size.y):
			var pos = Vector2i(x, y)
			var grid_data = grid_manager.get_grid(pos)
			if grid_data and grid_data.get_is_explored_type():
				explored_positions.append(pos)
	
	# 如果没有已开垦的网格，无法生成秘密
	if explored_positions.is_empty():
		DebugLogger.warning("SurfaceWorldGrid: 没有已开垦的网格，无法生成秘密", "SurfaceWorldGrid")
		return
	
	# 随机选择一个已开垦的网格放置秘密
	var random_pos = explored_positions[randi() % explored_positions.size()]
	
	# 直接创建 Secret 节点，不需要检查 _has_secret_in_hand（因为这是初始生成）
	var grid_data = grid_manager.get_grid(random_pos)
	if not grid_data or not grid_data.get_is_explored_type():
		DebugLogger.warning("SurfaceWorldGrid: 选中的网格不是已开垦的网格", "SurfaceWorldGrid")
		return
	
	# 如果之前有秘密节点，先移除（理论上不应该有）
	if _secret_node:
		_remove_secret()
	
	# 从场景文件实例化Secret节点
	var secret = SecretScene.instantiate()
	if not secret:
		DebugLogger.error("SurfaceWorldGrid: 无法实例化Secret场景", "SurfaceWorldGrid")
		return
	
	# 计算世界坐标
	var world_pos = grid_system.grid_to_world(random_pos)
	
	# 先添加到容器（确保节点在场景树中）
	_secret_container.add_child(secret)
	
	# 然后设置位置
	secret.grid_pos = random_pos
	secret.world_pos = world_pos
	secret.position = world_pos
	
	# 连接点击信号
	if not secret.secret_clicked.is_connected(_on_secret_clicked):
		secret.secret_clicked.connect(_on_secret_clicked)
	
	# 更新状态（初始生成时，玩家不持有秘密，秘密直接放在网格上）
	_secret_node = secret
	_has_secret_in_hand = false
	
	secret_found.emit(random_pos)
	DebugLogger.debug("SurfaceWorldGrid: 初始秘密已生成在 " + str(random_pos), "SurfaceWorldGrid")

## 检查网格是否可通行（用于寻路）
func is_passable(pos: Vector2i) -> bool:
	if not grid_system:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	return grid_data.is_passable

## 获取可通行的相邻网格
func get_passable_neighbors(pos: Vector2i) -> Array[Vector2i]:
	if not grid_system:
		return []
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return []
	
	var neighbors = grid_manager.get_neighbor_positions(pos)
	var passable_neighbors: Array[Vector2i] = []
	
	for neighbor_pos in neighbors:
		if is_passable(neighbor_pos):
			passable_neighbors.append(neighbor_pos)
	
	return passable_neighbors

# ========== 信号处理 ==========
func _on_grid_clicked(grid_pos: Vector2i, grid_data: GridData) -> void:
	if not grid_data:
		return
	
	# 优先处理秘密的拾起和放置
	# 如果玩家持有秘密，尝试放置
	if _has_secret_in_hand:
		if _handle_secret_interaction(grid_pos, grid_data):
			return
	
	# 处理网格点击的业务逻辑：点击未开垦的网格时，尝试开垦
	if grid_data.is_unexplored():
		explore_grid(grid_pos)

func _on_grid_hovered(grid_pos: Vector2i, grid_data: GridData) -> void:
	# 处理网格悬停的业务逻辑
	pass

func _on_grid_state_changed(grid_pos: Vector2i, grid_data: GridData) -> void:
	# 处理网格状态变化的业务逻辑
	pass

func _on_grid_map_initialized() -> void:
	# 网格地图初始化完成后的处理
	# 创建初始的5格开垦通路（只创建一次）
	if not _initial_path_created:
		_initial_path_created = true
		call_deferred("_create_initial_path")
		# 启动20秒计时器，然后实例化调查员
		call_deferred("_start_investigator_spawn_timer")

## 创建初始的5格开垦通路
func _create_initial_path() -> void:
	if not grid_system:
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return
	
	# 生成一条5格的通路，确保至少有一个网格在边缘
	var path_positions: Array[Vector2i] = []
	
	# 随机选择一个边缘位置作为起点
	var edge_positions: Array[Vector2i] = []
	for x in range(grid_manager.grid_size.x):
		edge_positions.append(Vector2i(x, 0))  # 上边缘
		edge_positions.append(Vector2i(x, grid_manager.grid_size.y - 1))  # 下边缘
	for y in range(1, grid_manager.grid_size.y - 1):
		edge_positions.append(Vector2i(0, y))  # 左边缘
		edge_positions.append(Vector2i(grid_manager.grid_size.x - 1, y))  # 右边缘
	
	if edge_positions.is_empty():
		return
	
	# 随机选择一个边缘位置作为起点
	var start_pos = edge_positions[randi() % edge_positions.size()]
	path_positions.append(start_pos)
	
	# 从起点开始，生成4个相邻的网格，形成一条连续的通路
	var current_pos = start_pos
	var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]  # 上下左右
	
	for i in range(4):  # 还需要4个网格，总共5个
		var valid_directions: Array[Vector2i] = []
		
		# 找出所有有效的方向（不超出边界，且未被使用）
		for dir in directions:
			var next_pos = current_pos + dir
			if grid_manager.is_valid_position(next_pos):
				# 检查是否已经在路径中
				var already_in_path = false
				for path_pos in path_positions:
					if path_pos == next_pos:
						already_in_path = true
						break
				if not already_in_path:
					valid_directions.append(dir)
		
		if valid_directions.is_empty():
			# 如果没有有效方向，尝试从路径的最后一个点（除了current_pos）继续扩展
			# 这样可以确保路径是连续的
			var found_alternative = false
			for j in range(path_positions.size() - 1, -1, -1):
				var candidate_pos = path_positions[j]
				if candidate_pos == current_pos:
					continue
				
				# 检查这个候选位置是否有有效方向
				var candidate_directions: Array[Vector2i] = []
				for dir in directions:
					var next_pos = candidate_pos + dir
					if grid_manager.is_valid_position(next_pos):
						var already_in_path = false
						for path_pos in path_positions:
							if path_pos == next_pos:
								already_in_path = true
								break
						if not already_in_path:
							candidate_directions.append(dir)
				
				if not candidate_directions.is_empty():
					current_pos = candidate_pos
					var chosen_dir = candidate_directions[randi() % candidate_directions.size()]
					current_pos = current_pos + chosen_dir
					path_positions.append(current_pos)
					found_alternative = true
					break
			
			if not found_alternative:
				# 如果找不到替代方案，提前结束
				break
		else:
			# 随机选择一个有效方向
			var chosen_dir = valid_directions[randi() % valid_directions.size()]
			current_pos = current_pos + chosen_dir
			path_positions.append(current_pos)
	
	# 确保至少生成了5个网格（如果少于5个，尝试补充）
	if path_positions.size() < 5:
		# 尝试从最后一个位置继续扩展
		var last_pos = path_positions[path_positions.size() - 1]
		var attempts = 0
		while path_positions.size() < 5 and attempts < 10:
			attempts += 1
			var valid_directions: Array[Vector2i] = []
			for dir in directions:
				var next_pos = last_pos + dir
				if grid_manager.is_valid_position(next_pos):
					var already_in_path = false
					for path_pos in path_positions:
						if path_pos == next_pos:
							already_in_path = true
							break
					if not already_in_path:
						valid_directions.append(dir)
			
			if not valid_directions.is_empty():
				var chosen_dir = valid_directions[randi() % valid_directions.size()]
				last_pos = last_pos + chosen_dir
				path_positions.append(last_pos)
			else:
				# 如果无法继续扩展，尝试从路径中的其他点继续
				var found_expansion = false
				for path_pos in path_positions:
					if path_pos == last_pos:
						continue
					var candidate_directions: Array[Vector2i] = []
					for dir in directions:
						var next_pos = path_pos + dir
						if grid_manager.is_valid_position(next_pos):
							var already_in_path = false
							for existing_pos in path_positions:
								if existing_pos == next_pos:
									already_in_path = true
									break
							if not already_in_path:
								candidate_directions.append(dir)
					
					if not candidate_directions.is_empty():
						var chosen_dir = candidate_directions[randi() % candidate_directions.size()]
						last_pos = path_pos + chosen_dir
						path_positions.append(last_pos)
						found_expansion = true
						break
				
				if not found_expansion:
					break
	
	# 开垦所有路径上的网格（至少开垦已生成的网格）
	for pos in path_positions:
		_explore_grid_direct(pos)
	
	# 在已开垦的网格中随机生成一个秘密
	call_deferred("_spawn_initial_secret")

# ========== 公共接口 ==========
## 获取网格系统引用
func get_grid_system() -> GridSystem:
	return grid_system

## 获取网格管理器引用
func get_grid_manager() -> GridMapManager:
	if grid_system:
		return grid_system.get_grid_manager()
	return null

## 获取ResourceManager实例
func _get_resource_manager():
	if has_node("/root/ResourceManager"):
		return get_node("/root/ResourceManager")
	return null

# ========== 调查员生成 ==========
## 启动调查员生成计时器（20秒后生成）
func _start_investigator_spawn_timer() -> void:
	# 等待20秒
	await get_tree().create_timer(20.0).timeout
	# 20秒后生成调查员
	_spawn_investigator_at_edge()

## 找到所有紧贴边缘的已开垦网格
func _get_edge_explored_grids() -> Array[Vector2i]:
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
func _spawn_investigator_at_edge() -> void:
	if not grid_system:
		DebugLogger.warning("SurfaceWorldGrid: 无法生成调查员 - grid_system 为空", "SurfaceWorldGrid")
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		DebugLogger.warning("SurfaceWorldGrid: 无法生成调查员 - grid_manager 为空", "SurfaceWorldGrid")
		return
	
	# 获取所有边缘已开垦网格
	var edge_explored = _get_edge_explored_grids()
	
	if edge_explored.is_empty():
		DebugLogger.warning("SurfaceWorldGrid: 没有边缘已开垦网格，无法生成调查员", "SurfaceWorldGrid")
		return
	
	# 排除秘密位置，确保调查员不会生成在秘密所在位置
	var valid_spawn_positions: Array[Vector2i] = []
	var secret_pos = Vector2i(-1, -1)
	if _secret_node:
		secret_pos = _secret_node.get_grid_position()
	
	# 过滤掉秘密位置
	for pos in edge_explored:
		if pos != secret_pos:
			valid_spawn_positions.append(pos)
	
	# 如果没有有效位置（所有边缘位置都是秘密位置），使用所有边缘位置
	if valid_spawn_positions.is_empty():
		# 复制边缘位置数组
		for pos in edge_explored:
			valid_spawn_positions.append(pos)
		DebugLogger.warning("SurfaceWorldGrid: 所有边缘位置都是秘密位置，将在边缘随机生成", "SurfaceWorldGrid")
	else:
		DebugLogger.debug("SurfaceWorldGrid: 排除秘密位置 " + str(secret_pos) + "，有效生成位置数量: " + str(valid_spawn_positions.size()), "SurfaceWorldGrid")
	
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
		DebugLogger.error("SurfaceWorldGrid: InvestigatorManager未初始化", "SurfaceWorldGrid")
		return
	
	# 生成调查员（使用GameManagers的InvestigatorManager）
	var investigator = GameManagers.InvestigatorManager.spawn_investigator(
		investigator_data,
		grid_manager,
		grid_system  # 使用grid_system作为父节点
	)
	
	if not investigator:
		DebugLogger.error("SurfaceWorldGrid: 生成调查员失败", "SurfaceWorldGrid")
		return
	
	# 如果存在秘密，设置调查员的目标位置为秘密位置
	if _secret_node:
		var target_secret_pos = _secret_node.get_grid_position()
		if target_secret_pos != Vector2i(-1, -1):
			investigator.set_target_position(target_secret_pos)
			DebugLogger.info("SurfaceWorldGrid: 调查员已生成在 " + str(spawn_pos) + "，目标位置: " + str(target_secret_pos), "SurfaceWorldGrid")
		else:
			DebugLogger.info("SurfaceWorldGrid: 调查员已生成在 " + str(spawn_pos), "SurfaceWorldGrid")
	else:
		DebugLogger.info("SurfaceWorldGrid: 调查员已生成在 " + str(spawn_pos) + "（暂无目标）", "SurfaceWorldGrid")
