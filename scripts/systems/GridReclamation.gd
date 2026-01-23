extends Node
class_name GridReclamation

## 网格开垦系统
## 负责管理表世界网格的开垦逻辑和初始路径创建

# ========== 信号 ==========
## 网格被开垦
signal grid_explored(grid_pos: Vector2i)

# ========== 导出属性 ==========
## 网格系统引用（需要外部设置）
var grid_system: GridSystemSurface = null

# ========== 内部状态 ==========
## 是否已创建初始路径（防止重复创建）
var _initial_path_created: bool = false

# ========== 生命周期 ==========
func _ready():
	pass

# ========== 初始化 ==========
## 设置网格系统引用（必须在调用其他方法前调用）
func set_grid_system(system: GridSystemSurface) -> void:
	grid_system = system

# ========== 网格开垦 ==========
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
			DebugLogger.warning("GridReclamation: 表构造力不足，无法开垦网格", "GridReclamation")
			print("表构造力不足，需要 " + str(Constants.COST_EXPLORE_SURFACE_GRID) + " 点表构造力")
			return false
		
		# 消耗表构造力
		if not resource_manager.consume_table_construct(Constants.COST_EXPLORE_SURFACE_GRID):
			DebugLogger.warning("GridReclamation: 消耗表构造力失败", "GridReclamation")
			return false
	
	# 开垦网格
	grid_data.set_explored()
	grid_system.set_grid(pos, grid_data)
	
	# 执行规则系统的后处理
	if grid_rule:
		grid_rule.on_explore(pos)
	
	grid_explored.emit(pos)
	DebugLogger.debug("GridReclamation: 成功开垦网格 " + str(pos) + "，消耗 " + str(Constants.COST_EXPLORE_SURFACE_GRID) + " 点表构造力", "GridReclamation")
	return true

## 直接开垦网格（绕过规则检查，用于初始化等特殊情况）
func explore_grid_direct(pos: Vector2i) -> bool:
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

## 创建初始的5格开垦通路
func create_initial_path() -> void:
	if not grid_system:
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return
	
	# 如果已经创建过初始路径，不再创建
	if _initial_path_created:
		return
	
	_initial_path_created = true
	
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
		explore_grid_direct(pos)
	
	DebugLogger.debug("GridReclamation: 初始路径已创建，共 " + str(path_positions.size()) + " 个网格", "GridReclamation")

# ========== 辅助函数 ==========
## 获取ResourceManager实例
func _get_resource_manager():
	if GameManagers.ResourceManager != null:
		return GameManagers.ResourceManager
	# 向后兼容：尝试从节点树获取
	if has_node("/root/ResourceManager"):
		return get_node("/root/ResourceManager")
	return null

## 检查是否已创建初始路径
func is_initial_path_created() -> bool:
	return _initial_path_created
