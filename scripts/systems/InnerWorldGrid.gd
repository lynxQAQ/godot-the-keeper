extends Control
class_name InnerWorldGrid

## 里世界网格系统
## 管理里世界的网格逻辑和交互

# ========== 预加载 ==========
const GridSystemScene = preload("res://scenes/worlds/GridSystem.tscn")
const GridSystemRule_Inner = preload("res://scripts/systems/GridSystemRule_Inner.gd")
const TruthElementScene = preload("res://scripts/entities/TruthElement.gd")

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

## 真理要素数据字典（key: element_id, value: TruthElementData）
var truth_elements: Dictionary = {}

## 真理要素可视化节点字典（key: element_id, value: TruthElement）
var truth_element_nodes: Dictionary = {}

## 真理要素容器节点
var truth_element_container: Node2D = null

## 移动更新间隔（秒）
@export var move_update_interval: float = 2.0

## 上次移动更新时间
var last_move_update_time: float = 0.0

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
	
	# 创建真理要素容器节点
	truth_element_container = Node2D.new()
	truth_element_container.name = "TruthElementContainer"
	grid_system.add_child(truth_element_container)
	
	# 连接信号
	grid_system.grid_clicked.connect(_on_grid_clicked)
	grid_system.grid_hovered.connect(_on_grid_hovered)
	grid_system.grid_state_changed.connect(_on_grid_state_changed)
	grid_system.grid_map_initialized.connect(_on_grid_map_initialized)
	
	# 加载里世界规则
	call_deferred("_load_inner_rule")
	
	# 初始化里世界网格
	_initialize_inner_world()

# ========== 更新循环 ==========
func _process(delta: float) -> void:
	# 更新真理要素移动
	_update_truth_elements_movement(delta)

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

## 初始化未开垦网格的等级
## 随机分配等级0或1，比例约为7:3
func _initialize_cocoon_levels() -> void:
	if not grid_system:
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return
	
	var all_positions = grid_manager.get_all_positions()
	for pos in all_positions:
		var grid_data = grid_manager.get_grid(pos)
		if grid_data and grid_data.is_unexplored():
			# 随机分配等级：70%概率为0，30%概率为1
			var random_value = randf()
			if random_value < 0.7:
				grid_data.cocoon_level = 0
			else:
				grid_data.cocoon_level = 1
			
			# 更新网格数据
			grid_system.set_grid(pos, grid_data)

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

## 放置真理要素（更新网格密度）
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

## 创建真理要素（创建可视化节点）
func create_truth_element(pos: Vector2i, serial: int = 1, density: float = 0.5) -> TruthElementData:
	if not grid_system or not truth_element_container:
		return null
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return null
	
	# 检查位置是否已开垦
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data or not grid_data.get_is_explored_type():
		DebugLogger.warning("InnerWorldGrid: 无法在未开垦的网格创建真理要素", "InnerWorldGrid")
		return null
	
	# 创建真理要素数据
	var element_data = TruthElementData.new(pos, serial, density)
	truth_elements[element_data.id] = element_data
	
	# 创建可视化节点
	var element_node = TruthElement.new()
	element_node.set_element_data(element_data)
	
	# 计算世界坐标
	var world_pos = grid_system.grid_to_world(pos)
	element_node.set_grid_position(pos, world_pos)
	
	truth_element_container.add_child(element_node)
	truth_element_nodes[element_data.id] = element_node
	
	# 更新网格密度
	place_truth_element(pos, density)
	
	DebugLogger.debug("InnerWorldGrid: 创建真理要素 " + element_data.id + " 在位置 " + str(pos), "InnerWorldGrid")
	return element_data

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
	
	# 检查是否有足够的里构造力
	var resource_manager = _get_resource_manager()
	if resource_manager:
		if not resource_manager.has_enough_inner_construct(Constants.COST_EXPLORE_INNER_GRID):
			DebugLogger.warning("InnerWorldGrid: 里构造力不足，无法开垦网格", "InnerWorldGrid")
			print("里构造力不足，需要 " + str(Constants.COST_EXPLORE_INNER_GRID) + " 点里构造力")
			return false
		
		# 消耗里构造力
		if not resource_manager.consume_inner_construct(Constants.COST_EXPLORE_INNER_GRID):
			DebugLogger.warning("InnerWorldGrid: 消耗里构造力失败", "InnerWorldGrid")
			return false
	
	# 记录开垦前的等级
	var cocoon_level = grid_data.cocoon_level
	
	# 开垦网格
	grid_data.set_explored()
	grid_system.set_grid(pos, grid_data)
	
	# 如果开垦前等级不为0，则生成真理要素
	if cocoon_level > 0:
		# 根据等级设置真理要素密度（等级越高，密度越高）
		var density = min(0.3 + (cocoon_level * 0.1), 1.0)  # 基础0.3，每级+0.1，最高1.0
		# 随机选择序列（1-5）
		var serial = randi() % 5 + 1
		# 创建真理要素可视化节点
		create_truth_element(pos, serial, density)
		DebugLogger.debug("InnerWorldGrid: 开垦等级 " + str(cocoon_level) + " 的网格 " + str(pos) + "，生成真理要素，序列: " + str(serial) + "，密度: " + str(density), "InnerWorldGrid")
	
	# 执行规则系统的后处理
	if grid_rule:
		grid_rule.on_explore(pos)
	
	DebugLogger.debug("InnerWorldGrid: 成功开垦网格 " + str(pos) + "，消耗 " + str(Constants.COST_EXPLORE_INNER_GRID) + " 点里构造力", "InnerWorldGrid")
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
	# 初始化未开垦网格的等级（随机分配0或1，比例7:3）
	_initialize_cocoon_levels()
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

## 获取ResourceManager实例
func _get_resource_manager():
	if has_node("/root/ResourceManager"):
		return get_node("/root/ResourceManager")
	return null

# ========== 真理要素移动管理 ==========
## 更新所有真理要素的移动
func _update_truth_elements_movement(delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0  # 转换为秒
	
	# 每隔一定时间更新一次移动
	if current_time - last_move_update_time < move_update_interval:
		return
	
	last_move_update_time = current_time
	
	# 遍历所有真理要素，尝试移动
	for element_id in truth_elements.keys():
		var element_data: TruthElementData = truth_elements[element_id]
		if not element_data:
			continue
		
		# 检查是否可以移动
		if not element_data.can_move(current_time):
			continue
		
		# 尝试移动到相邻的已开垦网格
		var next_pos = _find_next_move_position(element_data.grid_pos)
		if next_pos != Vector2i(-1, -1):
			_move_truth_element(element_id, next_pos)
			element_data.update_move_time(current_time)

## 查找下一个移动位置（随机选择相邻的已开垦网格）
func _find_next_move_position(current_pos: Vector2i) -> Vector2i:
	if not grid_system:
		return Vector2i(-1, -1)
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return Vector2i(-1, -1)
	
	# 获取相邻网格（四方向）
	var neighbors = grid_manager.get_neighbor_positions(current_pos)
	var valid_neighbors: Array[Vector2i] = []
	
	# 筛选出已开垦的网格
	for neighbor_pos in neighbors:
		var grid_data = grid_manager.get_grid(neighbor_pos)
		if grid_data and grid_data.get_is_explored_type():
			valid_neighbors.append(neighbor_pos)
	
	# 如果没有有效邻居，返回无效位置
	if valid_neighbors.is_empty():
		return Vector2i(-1, -1)
	
	# 随机选择一个有效邻居
	return valid_neighbors[randi() % valid_neighbors.size()]

## 移动真理要素到新位置
func _move_truth_element(element_id: String, new_grid_pos: Vector2i) -> void:
	if not truth_elements.has(element_id) or not truth_element_nodes.has(element_id):
		return
	
	var element_data: TruthElementData = truth_elements[element_id]
	var element_node: TruthElement = truth_element_nodes[element_id]
	
	if not element_data or not element_node:
		return
	
	# 更新数据中的网格位置
	element_data.grid_pos = new_grid_pos
	
	# 计算新的世界坐标
	var new_world_pos = grid_system.grid_to_world(new_grid_pos)
	
	# 开始移动动画
	element_node.start_move_to(new_world_pos)
	
	DebugLogger.debug("InnerWorldGrid: 真理要素 " + element_id + " 移动到 " + str(new_grid_pos), "InnerWorldGrid")
