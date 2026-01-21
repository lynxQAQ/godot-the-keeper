extends Control
class_name InnerWorldGrid

## 里世界网格系统
## 管理里世界的网格逻辑和交互

# ========== 预加载 ==========
const GridSystemScene = preload("res://scenes/worlds/GridSystem.tscn")

# ========== 信号 ==========
## 真理之茧被创建
signal truth_cocoon_created(grid_pos: Vector2i)
## 真理要素被放置
signal truth_element_placed(grid_pos: Vector2i)
## 网格密度改变
signal density_changed(grid_pos: Vector2i, density: float)
## 网格活跃度改变
signal activity_changed(grid_pos: Vector2i, activity: float)

# ========== 导出属性 ==========
## 网格系统实例
var grid_system: GridSystem = null

# ========== 生命周期 ==========
func _ready():
	# 设置Control布局
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# 实例化GridSystem场景
	grid_system = GridSystemScene.instantiate()
	if not grid_system:
		push_error("InnerWorldGrid: 无法实例化GridSystem场景")
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
	
	# 初始化里世界网格
	_initialize_inner_world()

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
	
	# 获取父容器（即InnerWorldGrid）的大小
	var parent_size = size
	if parent_size.x <= 0 or parent_size.y <= 0:
		# 如果大小还未确定，使用rect
		var rect = get_rect()
		parent_size = rect.size
	
	# 通过GridSystem的公共接口设置GridContainer大小
	grid_system.set_container_size(parent_size)

## 自身大小变化回调
func _on_self_resized() -> void:
	_update_grid_container_size()

## 初始化里世界
func _initialize_inner_world() -> void:
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
## 创建真理之茧
func create_truth_cocoon(pos: Vector2i) -> bool:
	if not grid_system:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	# 检查是否可以创建真理之茧
	if grid_data.has_truth_cocoon:
		return false
	
	# 创建真理之茧
	grid_data.has_truth_cocoon = true
	grid_data.truth_density = 1.0  # 真理之茧位置密度最高
	grid_system.set_grid(pos, grid_data)
	
	truth_cocoon_created.emit(pos)
	return true

## 放置真理要素
func place_truth_element(pos: Vector2i, density: float = 0.5) -> bool:
	if not grid_system:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	# 更新真理要素密度
	grid_data.truth_density = clamp(density, 0.0, 1.0)
	grid_system.set_grid(pos, grid_data)
	
	truth_element_placed.emit(pos)
	density_changed.emit(pos, grid_data.truth_density)
	return true

## 更新网格密度
func update_density(pos: Vector2i, density: float) -> void:
	if not grid_system:
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return
	
	grid_data.truth_density = clamp(density, 0.0, 1.0)
	grid_system.set_grid(pos, grid_data)
	density_changed.emit(pos, grid_data.truth_density)

## 更新网格活跃度
func update_activity(pos: Vector2i, activity: float) -> void:
	if not grid_system:
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return
	
	grid_data.activity_level = clamp(activity, 0.0, 1.0)
	grid_system.set_grid(pos, grid_data)
	activity_changed.emit(pos, grid_data.activity_level)

## 计算网格密度（基于周围网格）
func calculate_density(pos: Vector2i) -> float:
	if not grid_system:
		return 0.0
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return 0.0
	
	var neighbors = grid_manager.get_neighbor_positions_8(pos)
	var total_density: float = 0.0
	var count: int = 0
	
	for neighbor_pos in neighbors:
		var neighbor_data = grid_manager.get_grid(neighbor_pos)
		if neighbor_data:
			total_density += neighbor_data.truth_density
			count += 1
	
	if count == 0:
		return 0.0
	
	return total_density / count

## 计算网格活跃度（基于密度和周围活跃度）
func calculate_activity(pos: Vector2i) -> float:
	if not grid_system:
		return 0.0
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return 0.0
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return 0.0
	
	# 基础活跃度 = 密度
	var base_activity = grid_data.truth_density
	
	# 如果有真理之茧，活跃度最高
	if grid_data.has_truth_cocoon:
		return 1.0
	
	# 计算周围网格的平均活跃度
	var neighbors = grid_manager.get_neighbor_positions_8(pos)
	var neighbor_activity: float = 0.0
	var count: int = 0
	
	for neighbor_pos in neighbors:
		var neighbor_data = grid_manager.get_grid(neighbor_pos)
		if neighbor_data:
			neighbor_activity += neighbor_data.activity_level
			count += 1
	
	if count > 0:
		neighbor_activity /= count
	
	# 活跃度 = 基础活跃度 * 0.7 + 周围活跃度 * 0.3
	return clamp(base_activity * 0.7 + neighbor_activity * 0.3, 0.0, 1.0)

## 更新所有网格的活跃度
func update_all_activities() -> void:
	if not grid_system:
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return
	
	var all_positions = grid_manager.get_all_positions()
	for pos in all_positions:
		var activity = calculate_activity(pos)
		update_activity(pos, activity)

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
	# 如果密度改变，重新计算活跃度
	# var activity = calculate_activity(grid_pos)
	# update_activity(grid_pos, activity)
	pass

func _on_grid_map_initialized() -> void:
	# 网格地图初始化完成后的处理
	# 初始化所有网格的活跃度
	update_all_activities()

# ========== 公共接口 ==========
## 获取网格系统引用
func get_grid_system() -> GridSystem:
	return grid_system

## 获取网格管理器引用
func get_grid_manager() -> GridMapManager:
	if grid_system:
		return grid_system.get_grid_manager()
	return null
