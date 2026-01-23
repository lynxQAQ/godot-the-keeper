extends Control
class_name InnerWorldGrid

## 里世界网格系统
## 管理里世界的网格逻辑和交互

# ========== 预加载 ==========
const GridSystemScene = preload("res://scenes/worlds/GridSystemInner.tscn")
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
var grid_system: GridSystemInner = null

## 真理要素数据字典（key: element_id, value: TruthElementData）
var truth_elements: Dictionary = {}

## 真理要素可视化节点字典（key: element_id, value: TruthElement）
var truth_element_nodes: Dictionary = {}

## 真理要素容器节点
var truth_element_container: Node2D = null

## 真理之茧系统引用
var truth_cocoon_system: TruthCocoon = null

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
	
	# 重要：设置鼠标过滤模式为 IGNORE，让事件穿透到子节点 GridSystemInner
	# GridSystemInner 是 Node2D，它使用 _input 处理事件，需要事件能穿透 Control 节点
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	#DebugLogger.debug("InnerWorldGrid: 设置 mouse_filter = MOUSE_FILTER_IGNORE", "InnerWorldGrid")
	
	# 实例化GridSystemInner场景
	grid_system = GridSystemScene.instantiate()
	if not grid_system:
		push_error("InnerWorldGrid: 无法实例化GridSystemInner场景")
		return
	
	# 添加到场景树
	# 注意：在 SubViewport 架构下，Node2D 会自动在视口内渲染，无需特殊布局
	add_child(grid_system)
	
	# 创建真理要素容器节点
	truth_element_container = Node2D.new()
	truth_element_container.name = "TruthElementContainer"
	grid_system.add_child(truth_element_container)
	
	# 连接信号
	if not grid_system.grid_clicked.is_connected(_on_grid_clicked):
		grid_system.grid_clicked.connect(_on_grid_clicked)
		print("[初始化] InnerWorldGrid: 已连接 grid_clicked 信号")
	else:
		print("[初始化] InnerWorldGrid: grid_clicked 信号已连接，跳过")
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
## 转发输入事件到 GridSystemInner（确保 GridSystemInner 能接收到输入）
## 注意：Control 节点使用 _gui_input 而不是 _input
## 由于设置了 mouse_filter = MOUSE_FILTER_IGNORE，事件会自动穿透到子节点 GridSystemInner
func _gui_input(event: InputEvent) -> void:
	pass

# ========== 初始化 ==========
## 初始化里世界
func _initialize_inner_world() -> void:
	if not grid_system:
		return
	
	# 设置网格尺寸并重新初始化网格地图
	# GridSystemInner 会自动根据当前所在的 SubViewport 大小计算居中
	var new_size = Vector2i(
		Constants.DEFAULT_GRID_SIZE_X,
		Constants.DEFAULT_GRID_SIZE_Y
	)
	# 延迟执行，确保 GridSystemInner 的 _ready() 已完成
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
			grid_data.has_truth_cocoon = grid_data.cocoon_level > 0
			
			# 更新网格数据
			grid_system.set_grid(pos, grid_data)

## 加载里世界规则
func _load_inner_rule() -> void:
	if not grid_system:
		return
	
	# 创建里世界规则（grid_manager会在GridSystemInner中自动设置）
	var rule = GridSystemRule_Inner.new()
	grid_system.set_grid_rule(rule)
	
	# 如果grid_manager已经初始化，立即设置
	if grid_system.grid_manager:
		rule.grid_manager = grid_system.grid_manager
	else:
		# 等待GridSystemInner初始化完成
		await grid_system.grid_map_initialized
		if rule:
			rule.grid_manager = grid_system.grid_manager

## 重新初始化网格系统（当 grid_size 改变时）
func _reinitialize_grid_system(new_size: Vector2i) -> void:
	if not grid_system:
		return
	
	# 如果 GridSystemInner 已经初始化，使用公共方法重新初始化
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
func create_truth_element(pos: Vector2i, serial: int = 1, density: float = 0.5, causality: int = 0, material: int = 0, transcendence: int = 0) -> TruthElementData:
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
	var element_data = TruthElementData.new(pos, serial, density, causality, material, transcendence)
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

	# 更新资源管理器中的真理要素数量
	var resource_manager = _get_resource_manager()
	if resource_manager:
		resource_manager.add_truth_element(serial, 1, element_data.state)
	
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
	DebugLogger.debug("InnerWorldGrid: explore_grid 开始 - pos: " + str(pos), "InnerWorldGrid")
	if not grid_system:
		DebugLogger.warning("InnerWorldGrid: explore_grid - grid_system 为空", "InnerWorldGrid")
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		DebugLogger.warning("InnerWorldGrid: explore_grid - grid_manager 为空", "InnerWorldGrid")
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		DebugLogger.warning("InnerWorldGrid: explore_grid - grid_data 为空", "InnerWorldGrid")
		return false
	
	DebugLogger.debug("InnerWorldGrid: explore_grid - grid_data.grid_type: " + str(grid_data.grid_type) + ", is_unexplored: " + str(grid_data.is_unexplored()), "InnerWorldGrid")
	
	# 使用规则系统检查是否可以开垦
	var grid_rule = grid_system.get_grid_rule()
	if grid_rule:
		var validate_result = grid_rule.validate_explore(pos)
		if not validate_result.valid:
			DebugLogger.warning("InnerWorldGrid: 规则验证失败 - " + str(validate_result.reason), "InnerWorldGrid")
			return false
	
	# 检查是否可以开垦（基础检查）
	if not grid_data.is_unexplored():
		DebugLogger.debug("InnerWorldGrid: explore_grid - 网格已开垦，跳过", "InnerWorldGrid")
		return false
	
	# 检查是否有足够的里构造力
	var resource_manager = _get_resource_manager()
	if resource_manager:
		if not resource_manager.has_enough_inner_construct(Constants.COST_EXPLORE_INNER_GRID):
			DebugLogger.warning("InnerWorldGrid: 里构造力不足，无法开垦网格", "InnerWorldGrid")
			return false
		
		# 消耗里构造力
		if not resource_manager.consume_inner_construct(Constants.COST_EXPLORE_INNER_GRID):
			DebugLogger.warning("InnerWorldGrid: 消耗里构造力失败", "InnerWorldGrid")
			return false
	else:
		DebugLogger.warning("InnerWorldGrid: explore_grid - resource_manager 为空", "InnerWorldGrid")
	
	# 记录开垦前的等级
	var cocoon_level = grid_data.cocoon_level
	
	# 开垦网格
	grid_data.set_explored()
	# 如果存在真理之茧，保持茧标记
	if cocoon_level > 0:
		grid_data.has_truth_cocoon = true
	grid_system.set_grid(pos, grid_data)
	
	# 如果等级不为0，在该网格生成真理要素
	if cocoon_level > 0:
		# 随机生成因果、物质、超然三个属性（每个属性范围0-100）
		var causality_value = randi() % 101
		var material_value = randi() % 101
		var transcendence_value = randi() % 101
		
		# 确保至少有一个属性不为0（避免全0的情况）
		if causality_value == 0 and material_value == 0 and transcendence_value == 0:
			# 随机选择一个属性设置为非零值
			var random_attr = randi() % 3
			match random_attr:
				0:
					causality_value = randi_range(1, 100)
				1:
					material_value = randi_range(1, 100)
				2:
					transcendence_value = randi_range(1, 100)
		
		# 根据等级决定序列（等级0对应序列1，等级1对应序列2，以此类推，最高到序列5）
		var serial = min(cocoon_level + 1, 5)
		
		# 创建真理要素
		var element_data = create_truth_element(pos, serial, 0.5, causality_value, material_value, transcendence_value)
		if element_data:
			DebugLogger.debug("InnerWorldGrid: 在开垦的网格 " + str(pos) + " 生成真理要素，等级 " + str(cocoon_level) + "，序列 " + str(serial), "InnerWorldGrid")
	
	# 如果存在真理之茧，交由真理之茧系统处理
	if cocoon_level > 0 and truth_cocoon_system:
		truth_cocoon_system.create_cocoon(pos, cocoon_level)
	
	# 执行规则系统的后处理
	if grid_rule:
		grid_rule.on_explore(pos)
	
	DebugLogger.debug("InnerWorldGrid: 成功开垦网格 " + str(pos) + "，消耗 " + str(Constants.COST_EXPLORE_INNER_GRID) + " 点里构造力", "InnerWorldGrid")
	return true

# ========== 信号处理 ==========
func _on_grid_clicked(grid_pos: Vector2i, grid_data: GridData) -> void:
	print("[点击] InnerWorldGrid._on_grid_clicked: 被调用 - grid_pos: ", grid_pos)
	# 处理网格点击的业务逻辑
	if not grid_data:
		print("[点击] InnerWorldGrid._on_grid_clicked: grid_data 为空，返回")
		return

	print("[点击] InnerWorldGrid._on_grid_clicked: grid_type: ", grid_data.grid_type, ", is_unexplored: ", grid_data.is_unexplored(), ", cocoon_level: ", grid_data.cocoon_level)

	# 优先处理真理之茧破茧
	if grid_data.has_truth_cocoon and grid_data.cocoon_level > 0 and truth_cocoon_system:
		print("[点击] InnerWorldGrid._on_grid_clicked: 处理真理之茧破茧")
		truth_cocoon_system.break_cocoon_at(grid_pos)
		return

	# 未开垦网格的开垦逻辑由 InnerWorldGridExploration 处理
	# 查找 InnerWorldGridExploration 节点并调用其方法
	if grid_data.is_unexplored():
		print("[点击] InnerWorldGrid._on_grid_clicked: 检测到未开垦网格，查找 InnerWorldGridExploration")
		# 查找 InnerWorldGridExploration 节点（从父节点开始查找）
		var exploration_system: InnerWorldGridExploration = null
		var parent = get_parent()
		print("[点击] InnerWorldGrid._on_grid_clicked: parent = ", parent.name if parent else "null")
		
		if parent:
			# 方法1：从父节点查找
			exploration_system = parent.find_child("InnerWorldGridExploration", true, false) as InnerWorldGridExploration
			print("[点击] InnerWorldGrid._on_grid_clicked: 方法1查找结果: ", exploration_system)
			
			# 方法2：如果方法1失败，尝试从场景根节点查找
			if not exploration_system:
				var scene_root = get_tree().root
				var inner_world_grid_manager = scene_root.find_child("SubwordInner", true, false)
				print("[点击] InnerWorldGrid._on_grid_clicked: inner_world_grid_manager = ", inner_world_grid_manager)
				if inner_world_grid_manager:
					exploration_system = inner_world_grid_manager.find_child("InnerWorldGridExploration", true, false) as InnerWorldGridExploration
					print("[点击] InnerWorldGrid._on_grid_clicked: 方法2查找结果: ", exploration_system)
		
		if exploration_system:
			print("[点击] InnerWorldGrid._on_grid_clicked: 找到 InnerWorldGridExploration，调用 _on_grid_clicked")
			exploration_system._on_grid_clicked(grid_pos, grid_data)
		else:
			print("[点击] InnerWorldGrid._on_grid_clicked: 警告 - 未找到 InnerWorldGridExploration，使用默认逻辑")
			# 如果没有找到 InnerWorldGridExploration，使用默认逻辑（向后兼容）
			var result = explore_grid(grid_pos)
			print("[点击] InnerWorldGrid._on_grid_clicked: 默认开垦结果: ", result)
	else:
		print("[点击] InnerWorldGrid._on_grid_clicked: 网格已开垦，跳过")

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
	# 注意：未开垦网格的等级初始化现在由 InnerWorldGridExploration 处理
	# _initialize_cocoon_levels()  # 已移至 InnerWorldGridExploration
	# 初始化所有网格的活跃度
	update_all_activities()
	# 同步真理之茧可视化
	if truth_cocoon_system:
		truth_cocoon_system.sync_from_grid()

# ========== 公共接口 ==========
## 获取网格系统引用
func get_grid_system() -> GridSystemInner:
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

# ========== 真理要素管理 ==========
## 设置真理之茧系统
func set_truth_cocoon_system(system: TruthCocoon) -> void:
	truth_cocoon_system = system
	if truth_cocoon_system:
		truth_cocoon_system.sync_from_grid()

## 获取指定序列的真理要素ID列表
func get_truth_element_ids_by_serial(serial: int, state: int = -1) -> Array[String]:
	var result: Array[String] = []
	for element_id in truth_elements.keys():
		var element_data: TruthElementData = truth_elements[element_id]
		if element_data and element_data.serial == serial:
			if state < 0 or element_data.state == state:
				result.append(element_id)
	return result

## 获取指定序列的真理要素数量
func get_truth_element_count_by_serial(serial: int, state: int = -1) -> int:
	return get_truth_element_ids_by_serial(serial, state).size()

## 移除真理要素
func remove_truth_element(element_id: String) -> bool:
	if not truth_elements.has(element_id):
		return false
	var element_data: TruthElementData = truth_elements[element_id]
	var element_node: TruthElement = truth_element_nodes.get(element_id, null)
	if element_node and is_instance_valid(element_node):
		element_node.queue_free()
	truth_element_nodes.erase(element_id)
	truth_elements.erase(element_id)

	# 更新资源统计
	var resource_manager = _get_resource_manager()
	if resource_manager and element_data:
		resource_manager.subtract_truth_element(element_data.serial, 1, element_data.state)

	# 更新网格密度
	_update_density_after_removal(element_data.grid_pos)
	return true

## 消耗真理要素（用于仪式）
func consume_truth_elements(requirements: Dictionary) -> Dictionary:
	var missing: Dictionary = {}
	for serial in requirements.keys():
		var serial_int = int(serial)
		var need = int(requirements[serial])
		var available = get_truth_element_count_by_serial(serial_int)
		if available < need:
			missing[serial_int] = need - available
	
	if not missing.is_empty():
		return {"success": false, "missing": missing}

	for serial in requirements.keys():
		var serial_int = int(serial)
		var need = int(requirements[serial])
		var pool: Array[String] = []
		pool.append_array(get_truth_element_ids_by_serial(serial_int, Constants.TRUTH_STATE_ACTIVE))
		pool.append_array(get_truth_element_ids_by_serial(serial_int, Constants.TRUTH_STATE_SLEEPING))
		pool.append_array(get_truth_element_ids_by_serial(serial_int, Constants.TRUTH_STATE_EXTINCT))
		pool.append_array(get_truth_element_ids_by_serial(serial_int, Constants.TRUTH_STATE_SUBLIMATED))
		for i in range(min(need, pool.size())):
			remove_truth_element(pool[i])

	return {"success": true, "missing": {}}

## 更新真理要素视觉
func refresh_truth_element_visual(element_id: String) -> void:
	if truth_element_nodes.has(element_id):
		var element_node: TruthElement = truth_element_nodes[element_id]
		if element_node:
			element_node.refresh_state()

func _update_density_after_removal(pos: Vector2i) -> void:
	if not grid_system:
		return
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return
	# 如果该位置仍有真理要素，维持密度；否则归零
	var still_exists = false
	for element_id in truth_elements.keys():
		var element_data: TruthElementData = truth_elements[element_id]
		if element_data and element_data.grid_pos == pos:
			still_exists = true
			break
	grid_data.truth_density = 0.5 if still_exists else 0.0
	grid_system.set_grid(pos, grid_data)

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
	
	#DebugLogger.debug("InnerWorldGrid: 真理要素 " + element_id + " 移动到 " + str(new_grid_pos), "InnerWorldGrid")
