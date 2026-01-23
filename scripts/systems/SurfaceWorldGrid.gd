extends Control
class_name SurfaceWorldGrid

## 表世界网格系统
## 管理表世界的网格逻辑和交互

# ========== 预加载 ==========
const GridSystemScene = preload("res://scenes/worlds/GridSystemSurface.tscn")
const GridSystemRule_Surface = preload("res://scripts/systems/GridSystemRule_Surface.gd")

# ========== 信号 ==========
## 网格被开垦
signal grid_explored(grid_pos: Vector2i)
## 迷宫被创建
signal maze_created(grid_pos: Vector2i)
## 秘密位置被发现
signal secret_found(grid_pos: Vector2i)

# ========== 导出属性 ==========
## 网格系统实例
var grid_system: GridSystemSurface = null

# ========== 组件引用 ==========
## 秘密管理器
var secret_manager: SecretManager = null
## 网格开垦管理器
var grid_reclamation: GridReclamation = null
## 调查员生成器
var investigator_spawner: InvestigatorSpawner = null

# ========== 生命周期 ==========
func _ready():
	# 设置Control布局（重要：确保 Control 节点正确填充父容器）
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# 实例化GridSystemSurface场景
	grid_system = GridSystemScene.instantiate()
	if not grid_system:
		push_error("SurfaceWorldGrid: 无法实例化GridSystemSurface场景")
		return
	
	# 添加到场景树
	# 注意：在 SubViewport 架构下，Node2D 会自动在视口内渲染，无需特殊布局
	add_child(grid_system)
	
	# 初始化组件
	_initialize_components()
	
	# 连接信号
	grid_system.grid_clicked.connect(_on_grid_clicked)
	grid_system.grid_hovered.connect(_on_grid_hovered)
	grid_system.grid_state_changed.connect(_on_grid_state_changed)
	grid_system.grid_map_initialized.connect(_on_grid_map_initialized)
	
	# 加载表世界规则
	call_deferred("_load_surface_rule")
	
	# 初始化表世界网格
	_initialize_surface_world()

# ========== 组件初始化 ==========
## 初始化所有组件
func _initialize_components() -> void:
	# 获取或创建组件节点
	secret_manager = get_node_or_null("SecretManager") as SecretManager
	if not secret_manager:
		secret_manager = SecretManager.new()
		secret_manager.name = "SecretManager"
		add_child(secret_manager)
	
	grid_reclamation = get_node_or_null("GridReclamation") as GridReclamation
	if not grid_reclamation:
		grid_reclamation = GridReclamation.new()
		grid_reclamation.name = "GridReclamation"
		add_child(grid_reclamation)
	
	investigator_spawner = get_node_or_null("InvestigatorSpawner") as InvestigatorSpawner
	if not investigator_spawner:
		investigator_spawner = InvestigatorSpawner.new()
		investigator_spawner.name = "InvestigatorSpawner"
		add_child(investigator_spawner)
	
	# 设置组件引用（延迟到grid_system初始化后）
	call_deferred("_setup_component_references")
	
	# 连接组件信号
	_connect_component_signals()

## 设置组件引用
func _setup_component_references() -> void:
	if grid_system:
		if secret_manager:
			secret_manager.set_grid_system(grid_system)
		if grid_reclamation:
			grid_reclamation.set_grid_system(grid_system)
		if investigator_spawner:
			investigator_spawner.set_grid_system(grid_system)
			# 设置秘密管理器引用（用于排除秘密位置）
			if secret_manager:
				investigator_spawner.set_secret_manager(secret_manager)

## 连接组件信号
func _connect_component_signals() -> void:
	if secret_manager:
		if not secret_manager.secret_found.is_connected(_on_secret_found):
			secret_manager.secret_found.connect(_on_secret_found)
	
	if grid_reclamation:
		if not grid_reclamation.grid_explored.is_connected(_on_grid_explored):
			grid_reclamation.grid_explored.connect(_on_grid_explored)
	
	if investigator_spawner:
		if not investigator_spawner.investigator_spawned.is_connected(_on_investigator_spawned):
			investigator_spawner.investigator_spawned.connect(_on_investigator_spawned)

## 组件信号转发
func _on_secret_found(grid_pos: Vector2i) -> void:
	secret_found.emit(grid_pos)

func _on_grid_explored(grid_pos: Vector2i) -> void:
	grid_explored.emit(grid_pos)

func _on_investigator_spawned(investigator_id: String, position: Vector2i) -> void:
	# 可以在这里添加额外的处理逻辑
	pass

# ========== 初始化 ==========
## 初始化表世界
func _initialize_surface_world() -> void:
	if not grid_system:
		return
	
	# 设置网格尺寸并重新初始化网格地图
	# GridSystemSurface 会自动根据当前所在的 SubViewport 大小计算居中
	var new_size = Vector2i(
		Constants.DEFAULT_GRID_SIZE_X,
		Constants.DEFAULT_GRID_SIZE_Y
	)
	# 延迟执行，确保 GridSystemSurface 的 _ready() 已完成
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
	
	# 如果 GridSystemSurface 已经初始化，使用公共方法重新初始化
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
	if grid_reclamation:
		return grid_reclamation.explore_grid(pos)
	return false

## 直接开垦网格（绕过规则检查，用于初始化等特殊情况）
func _explore_grid_direct(pos: Vector2i) -> bool:
	if grid_reclamation:
		return grid_reclamation.explore_grid_direct(pos)
	return false

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
	if secret_manager:
		return secret_manager.place_secret(pos)
	return false

## 处理秘密交互（拾起或放置）
func _handle_secret_interaction(grid_pos: Vector2i, grid_data: GridData) -> bool:
	if secret_manager:
		return secret_manager.handle_secret_interaction(grid_pos, grid_data)
	return false

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
	
	# 优先检查该网格位置是否有 Secret（如果玩家没有持有秘密）
	# 如果有 Secret，直接触发 Secret 的点击，屏蔽网格点击
	if secret_manager and not secret_manager.has_secret_in_hand():
		var secret_pos = secret_manager.get_secret_position()
		if secret_pos == grid_pos:
			# 该网格位置有 Secret，触发 Secret 点击
			var secret_node = secret_manager.get_secret_node()
			if secret_node:
				secret_node.secret_clicked.emit(secret_node)
				return
	
	# 优先处理秘密的拾起和放置
	# 如果玩家持有秘密，尝试放置
	if secret_manager and secret_manager.has_secret_in_hand():
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
	if grid_reclamation and not grid_reclamation.is_initial_path_created():
		call_deferred("_create_initial_path")
		# 启动20秒计时器，然后实例化调查员
		if investigator_spawner:
			call_deferred("_start_investigator_spawn_timer")

## 创建初始的5格开垦通路
func _create_initial_path() -> void:
	if grid_reclamation:
		grid_reclamation.create_initial_path()
		# 在已开垦的网格中随机生成一个秘密
		if secret_manager:
			call_deferred("_spawn_initial_secret")

## 生成初始秘密
func _spawn_initial_secret() -> void:
	if secret_manager:
		secret_manager.spawn_initial_secret()

# ========== 公共接口 ==========
## 获取网格系统引用
func get_grid_system() -> GridSystemSurface:
	return grid_system

## 获取网格管理器引用
func get_grid_manager() -> GridMapManager:
	if grid_system:
		return grid_system.get_grid_manager()
	return null

## 启动调查员生成计时器（20秒后生成）
func _start_investigator_spawn_timer() -> void:
	if investigator_spawner:
		investigator_spawner.start_spawn_timer(20.0)
