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
	
	# 连接信号
	grid_system.grid_clicked.connect(_on_grid_clicked)
	grid_system.grid_hovered.connect(_on_grid_hovered)
	grid_system.grid_state_changed.connect(_on_grid_state_changed)
	grid_system.grid_map_initialized.connect(_on_grid_map_initialized)
	
	# 初始化表世界网格
	_initialize_surface_world()

# ========== 输入转发 ==========
## 转发输入事件到 GridSystem（确保 GridSystem 能接收到输入）
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

## 重新初始化网格系统（当 grid_size 改变时）
func _reinitialize_grid_system(new_size: Vector2i) -> void:
	if not grid_system:
		return
	
	# 如果 GridSystem 已经初始化，使用公共方法重新初始化
	if grid_system.grid_manager:
		grid_system.resize_grid_map(new_size)
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
	pass

func _on_grid_hovered(grid_pos: Vector2i, grid_data: GridData) -> void:
	# 处理网格悬停的业务逻辑
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
	
	
