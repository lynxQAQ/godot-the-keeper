extends RefCounted
class_name InvestigatorPathfinding

## 调查员寻路系统
## 实现A*寻路算法，基于表世界网格

# ========== A*节点数据结构 ==========
class AStarNode:
	var position: Vector2i
	var g_cost: float = 0.0  # 从起点到当前节点的实际代价
	var h_cost: float = 0.0  # 从当前节点到终点的启发式代价
	var f_cost: float = 0.0  # 总代价 f = g + h
	var parent: AStarNode = null
	
	func _init(pos: Vector2i):
		position = pos
	
	func calculate_f_cost() -> void:
		f_cost = g_cost + h_cost

# ========== 寻路参数 ==========
var grid_manager: GridMapManager = null  # 网格管理器引用
var target_position: Vector2i = Vector2i(-1, -1)  # 目标位置（秘密位置）
var current_path: Array[Vector2i] = []  # 当前计算的路径
var path_index: int = 0  # 当前路径索引

# ========== 初始化 ==========
func _init(p_grid_manager: GridMapManager = null) -> void:
	grid_manager = p_grid_manager

# ========== A*寻路算法 ==========
## 计算从起点到终点的路径
## 返回路径数组，如果无法到达则返回空数组
func find_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if not grid_manager:
		push_error("InvestigatorPathfinding: grid_manager 未设置")
		return []
	
	if not grid_manager.is_valid_position(start) or not grid_manager.is_valid_position(end):
		push_error("InvestigatorPathfinding: 起点或终点位置无效")
		return []
	
	# 如果起点和终点相同，返回单点路径
	if start == end:
		return [start]
	
	# 初始化开放列表和关闭列表
	var open_list: Array[AStarNode] = []
	var closed_list: Dictionary = {}  # {Vector2i: AStarNode}
	
	# 创建起始节点
	var start_node = AStarNode.new(start)
	start_node.g_cost = 0.0
	start_node.h_cost = _heuristic_distance(start, end)
	start_node.calculate_f_cost()
	open_list.append(start_node)
	
	# A*主循环
	while not open_list.is_empty():
		# 找到f_cost最小的节点
		var current_node = _get_lowest_f_cost_node(open_list)
		
		# 从开放列表移除，加入关闭列表
		open_list.erase(current_node)
		closed_list[_pos_to_key(current_node.position)] = current_node
		
		# 如果到达终点，重构路径
		if current_node.position == end:
			return _reconstruct_path(current_node)
		
		# 检查所有邻居
		var neighbors = _get_passable_neighbors(current_node.position)
		for neighbor_pos in neighbors:
			var neighbor_key = _pos_to_key(neighbor_pos)
			
			# 如果已在关闭列表中，跳过
			if closed_list.has(neighbor_key):
				continue
			
			# 计算到邻居的代价
			var movement_cost = _get_movement_cost(current_node.position, neighbor_pos)
			var new_g_cost = current_node.g_cost + movement_cost
			
			# 检查是否已在开放列表中
			var neighbor_node = _find_node_in_list(open_list, neighbor_pos)
			
			if neighbor_node == null:
				# 创建新节点
				neighbor_node = AStarNode.new(neighbor_pos)
				neighbor_node.g_cost = new_g_cost
				neighbor_node.h_cost = _heuristic_distance(neighbor_pos, end)
				neighbor_node.calculate_f_cost()
				neighbor_node.parent = current_node
				open_list.append(neighbor_node)
			elif new_g_cost < neighbor_node.g_cost:
				# 找到更优路径，更新节点
				neighbor_node.g_cost = new_g_cost
				neighbor_node.calculate_f_cost()
				neighbor_node.parent = current_node
	
	# 无法找到路径
	return []

## 获取可通行的邻居
func _get_passable_neighbors(pos: Vector2i) -> Array[Vector2i]:
	if not grid_manager:
		return []
	
	var neighbors = grid_manager.get_neighbor_positions(pos)
	var passable_neighbors: Array[Vector2i] = []
	
	for neighbor_pos in neighbors:
		if not grid_manager.is_valid_position(neighbor_pos):
			continue
		
		var grid_data = grid_manager.get_grid(neighbor_pos)
		if grid_data and grid_data.is_passable:
			passable_neighbors.append(neighbor_pos)
	
	return passable_neighbors

## 计算启发式距离（曼哈顿距离）
func _heuristic_distance(pos1: Vector2i, pos2: Vector2i) -> float:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

## 获取移动代价（可以用于处理不同地形的代价）
func _get_movement_cost(from: Vector2i, to: Vector2i) -> float:
	# 基础移动代价为1
	# 可以根据网格类型调整代价
	if grid_manager:
		var grid_data = grid_manager.get_grid(to)
		if grid_data:
			# 可以根据网格类型返回不同代价
			# 例如：迷宫网格代价更高
			if grid_data.grid_type == Constants.GRID_TYPE_MAZE:
				return 1.0  # 可以设置为更高值，如1.5
			else:
				return 1.0
	
	return 1.0

## 从开放列表中找到f_cost最小的节点
func _get_lowest_f_cost_node(open_list: Array[AStarNode]) -> AStarNode:
	if open_list.is_empty():
		return null
	
	var lowest_node = open_list[0]
	for node in open_list:
		if node.f_cost < lowest_node.f_cost:
			lowest_node = node
	
	return lowest_node

## 在列表中查找节点
func _find_node_in_list(node_list: Array[AStarNode], pos: Vector2i) -> AStarNode:
	for node in node_list:
		if node.position == pos:
			return node
	return null

## 重构路径（从终点回溯到起点）
func _reconstruct_path(end_node: AStarNode) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current: AStarNode = end_node
	
	while current != null:
		path.insert(0, current.position)  # 在开头插入，保持顺序
		current = current.parent
	
	return path

# ========== 路径管理 ==========
## 设置目标位置并计算路径
func set_target(target: Vector2i, start: Vector2i) -> bool:
	target_position = target
	current_path = find_path(start, target)
	path_index = 0
	return not current_path.is_empty()

## 获取下一个路径点
func get_next_path_point() -> Vector2i:
	if current_path.is_empty():
		return Vector2i(-1, -1)
	
	if path_index >= current_path.size():
		# 已到达终点
		return current_path[current_path.size() - 1]
	
	return current_path[path_index]

## 移动到下一个路径点
func move_to_next() -> bool:
	if current_path.is_empty():
		return false
	
	if path_index < current_path.size() - 1:
		path_index += 1
		return true
	
	return false

## 检查是否到达终点
func is_at_target(current_pos: Vector2i) -> bool:
	if current_path.is_empty():
		return false
	
	var last_point = current_path[current_path.size() - 1]
	return current_pos == last_point

## 获取当前路径
func get_current_path() -> Array[Vector2i]:
	return current_path.duplicate()

## 清除路径
func clear_path() -> void:
	current_path.clear()
	path_index = 0
	target_position = Vector2i(-1, -1)

# ========== 动态障碍物处理 ==========
## 重新计算路径（当遇到动态障碍物时）
func recalculate_path(current_pos: Vector2i) -> bool:
	if target_position == Vector2i(-1, -1):
		return false
	
	current_path = find_path(current_pos, target_position)
	path_index = 0
	return not current_path.is_empty()

## 检查路径是否仍然有效
func is_path_valid(current_pos: Vector2i) -> bool:
	if current_path.is_empty():
		return false
	
	# 检查当前路径上的所有点是否仍然可通行
	for i in range(path_index, current_path.size()):
		var path_pos = current_path[i]
		if not grid_manager or not grid_manager.is_valid_position(path_pos):
			return false
		
		var grid_data = grid_manager.get_grid(path_pos)
		if not grid_data or not grid_data.is_passable:
			return false
	
	return true

# ========== 路径可视化（调试用） ==========
## 获取路径可视化数据（用于绘制路径线）
func get_path_visualization_data() -> Array[Vector2]:
	# 返回路径点的世界坐标数组（需要外部提供坐标转换函数）
	# 这里只返回网格坐标，实际使用时需要转换为世界坐标
	var result: Array[Vector2] = []
	for pos in current_path:
		result.append(Vector2(pos.x, pos.y))
	return result

# ========== 工具函数 ==========
## 位置转键值
func _pos_to_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]

## 设置网格管理器
func set_grid_manager(manager: GridMapManager) -> void:
	grid_manager = manager
