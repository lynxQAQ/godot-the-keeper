extends Control
class_name SurfaceWorldGrid

## 表世界网格系统
## 管理表世界的网格逻辑和交互

# ========== 预加载 ==========
const GridSystemScene = preload("res://scenes/worlds/GridSystem.tscn")

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

# ========== 生命周期 ==========
func _ready():
	# 实例化GridSystem场景
	grid_system = GridSystemScene.instantiate()
	if not grid_system:
		push_error("SurfaceWorldGrid: 无法实例化GridSystem场景")
		return
	
	# 添加到场景树
	add_child(grid_system)
	
	# 设置GridSystem的布局，使其填充父容器
	_setup_grid_system_layout()
	
	# 连接信号
	grid_system.grid_clicked.connect(_on_grid_clicked)
	grid_system.grid_hovered.connect(_on_grid_hovered)
	grid_system.grid_state_changed.connect(_on_grid_state_changed)
	grid_system.grid_map_initialized.connect(_on_grid_map_initialized)
	
	# 监听自身大小变化，同步更新GridContainer
	if not resized.is_connected(_on_self_resized):
		resized.connect(_on_self_resized)
	
	# 初始化表世界网格
	_initialize_surface_world()

# ========== 初始化 ==========
## 设置GridSystem的布局
func _setup_grid_system_layout() -> void:
	if not grid_system:
		return
	
	# GridSystem是Node2D，需要确保其子节点GridContainer填充父容器
	# 获取GridContainer并设置其大小
	var grid_container = grid_system.get_node_or_null("GridContainer") as Control
	if grid_container:
		# 延迟设置，确保父容器大小已确定
		call_deferred("_update_grid_container_size")

## 更新GridContainer的大小，使其匹配父容器
func _update_grid_container_size() -> void:
	if not grid_system:
		return
	
	# 获取父容器（即SurfaceWorldGrid）的大小
	var parent_size = size
	if parent_size.x <= 0 or parent_size.y <= 0:
		# 如果大小还未确定，使用rect
		var rect = get_rect()
		parent_size = rect.size
	print('SurfaceWorldGrid 容器大小', parent_size)
	# 通过GridSystem的公共接口设置GridContainer大小
	grid_system.set_container_size(parent_size)

## 自身大小变化回调
func _on_self_resized() -> void:
	_update_grid_container_size()

## 初始化表世界
func _initialize_surface_world() -> void:
	if not grid_system:
		return
	
	# 确保GridContainer大小已设置
	_update_grid_container_size()
	
	# 使用默认尺寸初始化网格系统
	var grid_size = Vector2i(
		Constants.DEFAULT_GRID_SIZE_X,
		Constants.DEFAULT_GRID_SIZE_Y
	)
	grid_system.initialize(grid_size)

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
	
	# 检查是否可以开垦
	if not grid_data.is_unexplored():
		return false
	
	# 开垦网格
	grid_data.set_explored()
	grid_system.set_grid(pos, grid_data)
	
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

## 标记秘密位置
func mark_secret(pos: Vector2i) -> bool:
	if not grid_system:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	grid_data.has_secret = true
	grid_system.set_grid(pos, grid_data)
	
	secret_found.emit(pos)
	return true

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
	# 处理网格点击的业务逻辑
	# 例如：显示网格信息、执行操作等
	pass

func _on_grid_hovered(grid_pos: Vector2i, grid_data: GridData) -> void:
	# 处理网格悬停的业务逻辑
	# 例如：显示提示信息等
	pass

func _on_grid_state_changed(grid_pos: Vector2i, grid_data: GridData) -> void:
	# 处理网格状态变化的业务逻辑
	pass

func _on_grid_map_initialized() -> void:
	# 网格地图初始化完成后的处理
	pass

# ========== 公共接口 ==========
## 获取网格系统引用
func get_grid_system() -> GridSystem:
	return grid_system

## 获取网格管理器引用
func get_grid_manager() -> GridMapManager:
	if grid_system:
		return grid_system.get_grid_manager()
	return null
