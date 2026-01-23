extends Node
class_name InnerWorldGridExploration

## 里世界网格开垦系统
## 专门处理里世界网格的开垦逻辑和真理要素生成

# ========== 信号 ==========
## 网格被开垦
signal grid_explored(grid_pos: Vector2i, cocoon_level: int)
## 真理要素生成
signal truth_element_generated(grid_pos: Vector2i, element_data: TruthElementData)

# ========== 组件引用 ==========
## 里世界网格系统引用
var inner_world_grid: InnerWorldGrid = null

# ========== 导出属性 ==========
## 等级0的概率（0.0-1.0），剩余为等级1
@export var level_0_probability: float = 0.7

## 真理要素属性值范围
@export var min_attribute_value: int = 0
@export var max_attribute_value: int = 100

# ========== 生命周期 ==========
func _ready():
	print("[初始化] InnerWorldGridExploration: _ready 被调用")
	# 等待父节点初始化完成
	call_deferred("_initialize")

func _initialize() -> void:
	print("[初始化] InnerWorldGridExploration: _initialize 开始")
	# 获取 InnerWorldGrid 引用
	var parent = get_parent()
	print("[初始化] InnerWorldGridExploration: parent = ", parent.name if parent else "null")
	if parent is InnerWorldGrid:
		inner_world_grid = parent
		print("[初始化] InnerWorldGridExploration: parent 是 InnerWorldGrid")
	elif parent.has_node("InnerWorldGrid"):
		inner_world_grid = parent.get_node("InnerWorldGrid") as InnerWorldGrid
		print("[初始化] InnerWorldGridExploration: 从 parent 找到 InnerWorldGrid")
	else:
		# 尝试从场景根节点查找
		var scene_root = get_tree().root
		var inner_world_grid_manager = scene_root.find_child("SubwordInner", true, false)
		if inner_world_grid_manager:
			inner_world_grid = inner_world_grid_manager.find_child("InnerWorldGrid", true, false) as InnerWorldGrid
			print("[初始化] InnerWorldGridExploration: 从场景根节点找到 InnerWorldGrid")
	
	if not inner_world_grid:
		push_error("InnerWorldGridExploration: 未找到 InnerWorldGrid 引用")
		print("[初始化] InnerWorldGridExploration: 错误 - 未找到 InnerWorldGrid 引用")
		return
	
	print("[初始化] InnerWorldGridExploration: 找到 InnerWorldGrid 引用")
	
	# 等待网格系统初始化完成
	var max_attempts = 20
	var attempt = 0
	while not inner_world_grid.grid_system and attempt < max_attempts:
		await get_tree().process_frame
		attempt += 1
	
	if not inner_world_grid.grid_system:
		push_error("InnerWorldGridExploration: 无法获取 grid_system 引用")
		print("[初始化] InnerWorldGridExploration: 错误 - 无法获取 grid_system 引用")
		return
	
	print("[初始化] InnerWorldGridExploration: 找到 grid_system 引用")
	
	# 注意：不再直接连接 grid_clicked 信号
	# 而是通过 InnerWorldGrid 的 _on_grid_clicked 方法来调用
	# InnerWorldGrid 会在 _on_grid_clicked 中查找并调用本节点的 _on_grid_clicked 方法
	
	# 等待网格地图初始化完成后再初始化等级
	if inner_world_grid.grid_system.grid_manager:
		# 网格管理器已初始化，可以直接初始化等级
		call_deferred("_initialize_unexplored_grid_levels")
	else:
		# 等待网格地图初始化完成
		if inner_world_grid.grid_system.has_signal("grid_map_initialized"):
			await inner_world_grid.grid_system.grid_map_initialized
			call_deferred("_initialize_unexplored_grid_levels")
		else:
			# 延迟执行
			await get_tree().create_timer(0.5).timeout
			call_deferred("_initialize_unexplored_grid_levels")

# ========== 网格等级初始化 ==========
## 初始化未开垦网格的等级
## 随机分配等级0或1，比例由 level_0_probability 控制
func _initialize_unexplored_grid_levels() -> void:
	if not inner_world_grid or not inner_world_grid.grid_system:
		return
	
	var grid_manager = inner_world_grid.get_grid_manager()
	if not grid_manager:
		return
	
	var all_positions = grid_manager.get_all_positions()
	for pos in all_positions:
		var grid_data = grid_manager.get_grid(pos)
		if grid_data and grid_data.is_unexplored():
			# 随机分配等级：level_0_probability 概率为0，否则为1
			var random_value = randf()
			if random_value < level_0_probability:
				grid_data.cocoon_level = 0
			else:
				grid_data.cocoon_level = 1
			
			# 更新网格数据
			inner_world_grid.grid_system.set_grid(pos, grid_data)
			
			#DebugLogger.debug("InnerWorldGridExploration: 初始化网格 " + str(pos) + " 等级为 " + str(grid_data.cocoon_level), "InnerWorldGridExploration")

# ========== 网格点击处理 ==========
## 处理网格点击事件（公开方法，供 InnerWorldGrid 调用）
func _on_grid_clicked(grid_pos: Vector2i, grid_data: GridData) -> void:
	print("[点击] InnerWorldGridExploration._on_grid_clicked: 被调用 - grid_pos: ", grid_pos)
	if not grid_data:
		print("[点击] InnerWorldGridExploration._on_grid_clicked: grid_data 为空，返回")
		return
	
	print("[点击] InnerWorldGridExploration._on_grid_clicked: grid_type: ", grid_data.grid_type, ", is_unexplored: ", grid_data.is_unexplored())
	
	# 只处理未开垦的网格
	if not grid_data.is_unexplored():
		print("[点击] InnerWorldGridExploration._on_grid_clicked: 网格已开垦，跳过")
		return
	
	print("[点击] InnerWorldGridExploration._on_grid_clicked: 开始开垦网格")
	# 尝试开垦网格
	var result = explore_grid(grid_pos)
	print("[点击] InnerWorldGridExploration._on_grid_clicked: 开垦结果: ", result)

# ========== 网格开垦 ==========
## 开垦指定位置的网格
## 返回是否成功
func explore_grid(pos: Vector2i) -> bool:
	print("[开垦] InnerWorldGridExploration.explore_grid: 开始 - pos: ", pos)
	
	if not inner_world_grid:
		print("[开垦] InnerWorldGridExploration.explore_grid: 错误 - inner_world_grid 为空")
		DebugLogger.warning("InnerWorldGridExploration: inner_world_grid 为空", "InnerWorldGridExploration")
		return false
	
	var grid_manager = inner_world_grid.get_grid_manager()
	if not grid_manager:
		print("[开垦] InnerWorldGridExploration.explore_grid: 错误 - grid_manager 为空")
		DebugLogger.warning("InnerWorldGridExploration: grid_manager 为空", "InnerWorldGridExploration")
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		print("[开垦] InnerWorldGridExploration.explore_grid: 错误 - grid_data 为空")
		DebugLogger.warning("InnerWorldGridExploration: grid_data 为空", "InnerWorldGridExploration")
		return false
	
	print("[开垦] InnerWorldGridExploration.explore_grid: grid_data.grid_type: ", grid_data.grid_type, ", is_unexplored: ", grid_data.is_unexplored())
	
	# 检查是否可以开垦
	if not grid_data.is_unexplored():
		print("[开垦] InnerWorldGridExploration.explore_grid: 网格已开垦，跳过")
		return false
	
	# 检查是否有足够的里构造力
	var resource_manager = _get_resource_manager()
	if resource_manager:
		var current_inner = resource_manager.get_inner_construct()
		print("[开垦] InnerWorldGridExploration.explore_grid: 当前里构造力: ", current_inner, ", 需要: ", Constants.COST_EXPLORE_INNER_GRID)
		
		if not resource_manager.has_enough_inner_construct(Constants.COST_EXPLORE_INNER_GRID):
			print("[开垦] InnerWorldGridExploration.explore_grid: 里构造力不足")
			DebugLogger.warning("InnerWorldGridExploration: 里构造力不足，无法开垦网格", "InnerWorldGridExploration")
			return false
		
		# 消耗里构造力
		if not resource_manager.consume_inner_construct(Constants.COST_EXPLORE_INNER_GRID):
			print("[开垦] InnerWorldGridExploration.explore_grid: 消耗里构造力失败")
			DebugLogger.warning("InnerWorldGridExploration: 消耗里构造力失败", "InnerWorldGridExploration")
			return false
		print("[开垦] InnerWorldGridExploration.explore_grid: 成功消耗里构造力")
	else:
		print("[开垦] InnerWorldGridExploration.explore_grid: 警告 - resource_manager 为空，跳过资源检查")
	
	# 记录开垦前的等级
	var cocoon_level = grid_data.cocoon_level
	print("[开垦] InnerWorldGridExploration.explore_grid: 网格等级: ", cocoon_level)
	
	# 开垦网格
	grid_data.set_explored()
	grid_data.has_truth_cocoon = cocoon_level > 0
	inner_world_grid.grid_system.set_grid(pos, grid_data)
	print("[开垦] InnerWorldGridExploration.explore_grid: 网格状态已更新为已开垦")
	
	# 如果等级不为0，在该网格生成真理要素
	if cocoon_level > 0:
		print("[开垦] InnerWorldGridExploration.explore_grid: 等级不为0，生成真理要素")
		_generate_truth_element(pos, cocoon_level)
	else:
		print("[开垦] InnerWorldGridExploration.explore_grid: 等级为0，不生成真理要素")
	
	# 发射信号
	grid_explored.emit(pos, cocoon_level)
	
	print("[开垦] InnerWorldGridExploration.explore_grid: ✓ 成功开垦网格 ", pos, "，消耗 ", Constants.COST_EXPLORE_INNER_GRID, " 点里构造力，等级: ", cocoon_level)
	DebugLogger.debug("InnerWorldGridExploration: 成功开垦网格 " + str(pos) + "，消耗 " + str(Constants.COST_EXPLORE_INNER_GRID) + " 点里构造力，等级: " + str(cocoon_level), "InnerWorldGridExploration")
	return true

# ========== 真理要素生成 ==========
## 在指定位置生成真理要素
func _generate_truth_element(pos: Vector2i, cocoon_level: int) -> void:
	if not inner_world_grid:
		return
	
	# 随机生成因果、物质、超然三个属性（每个属性范围 min_attribute_value-max_attribute_value）
	var causality_value = randi_range(min_attribute_value, max_attribute_value)
	var material_value = randi_range(min_attribute_value, max_attribute_value)
	var transcendence_value = randi_range(min_attribute_value, max_attribute_value)
	
	# 确保至少有一个属性不为0（避免全0的情况）
	if causality_value == 0 and material_value == 0 and transcendence_value == 0:
		# 随机选择一个属性设置为非零值
		var random_attr = randi() % 3
		match random_attr:
			0:
				causality_value = randi_range(1, max_attribute_value)
			1:
				material_value = randi_range(1, max_attribute_value)
			2:
				transcendence_value = randi_range(1, max_attribute_value)
	
	# 根据等级决定序列（等级0对应序列1，等级1对应序列2，以此类推，最高到序列5）
	var serial = min(cocoon_level + 1, 5)
	
	# 创建真理要素
	var element_data = inner_world_grid.create_truth_element(
		pos, 
		serial, 
		0.5,  # 默认密度
		causality_value, 
		material_value, 
		transcendence_value
	)
	
	if element_data:
		DebugLogger.debug("InnerWorldGridExploration: 在网格 " + str(pos) + " 生成真理要素，等级 " + str(cocoon_level) + "，序列 " + str(serial) + "，属性(因果:" + str(causality_value) + ", 物质:" + str(material_value) + ", 超然:" + str(transcendence_value) + ")", "InnerWorldGridExploration")
		truth_element_generated.emit(pos, element_data)
	else:
		DebugLogger.warning("InnerWorldGridExploration: 创建真理要素失败", "InnerWorldGridExploration")

# ========== 辅助函数 ==========
## 获取ResourceManager实例
func _get_resource_manager():
	if has_node("/root/ResourceManager"):
		return get_node("/root/ResourceManager")
	return null
