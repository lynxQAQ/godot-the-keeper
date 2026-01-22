extends Control
class_name InnerWorldGrid

## 里世界网格系统
## 管理里世界的网格逻辑和交互

# ========== 预加载 ==========
const GridSystemScene = preload("res://scenes/worlds/GridSystem.tscn")
const GridSystemRule_Inner = preload("res://scripts/systems/GridSystemRule_Inner.gd")

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
	# 注意：在 SubViewport 架构下，Node2D 会自动在视口内渲染，无需特殊布局
	add_child(grid_system)
	
	# 连接信号
	grid_system.grid_clicked.connect(_on_grid_clicked)
	grid_system.grid_hovered.connect(_on_grid_hovered)
	grid_system.grid_state_changed.connect(_on_grid_state_changed)
	grid_system.grid_map_initialized.connect(_on_grid_map_initialized)
	
	# 加载里世界规则
	call_deferred("_load_inner_rule")
	
	# 初始化里世界网格
	_initialize_inner_world()

# ========== 输入转发 ==========
## 转发输入事件到 GridSystem（确保 GridSystem 能接收到输入）
func _input(event: InputEvent) -> void:
	if grid_system:
		# 将事件传递给 GridSystem
		# GridSystem 会自己处理，这里只是确保事件能到达
		pass

# ========== 初始化 ==========
## 初始化里世界
func _initialize_inner_world() -> void:
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

## 加载里世界规则
func _load_inner_rule() -> void:
	if not grid_system:
		return
	
	# 创建里世界规则（grid_manager会在GridSystem中自动设置）
	var rule = GridSystemRule_Inner.new()
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
	
	# 开垦网格
	grid_data.set_explored()
	grid_system.set_grid(pos, grid_data)
	
	# 执行规则系统的后处理
	if grid_rule:
		grid_rule.on_explore(pos)
	
	return true

# ========== 信号处理 ==========
func _on_grid_clicked(grid_pos: Vector2i, grid_data: GridData) -> void:
	# 处理网格点击的业务逻辑：点击未开垦的网格时，尝试开垦
	if grid_data and grid_data.is_unexplored():
		explore_grid(grid_pos)

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
