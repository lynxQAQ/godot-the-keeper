extends GridSystemRule
class_name GridSystemRule_Surface

## 表世界网格系统规则
## 实现表世界特有的规则：开垦必须组成一条通路

# ========== 属性 ==========
## 已开垦网格的连通区域（用于通路检查）
var explored_regions: Array[Array] = []

# ========== 构造函数 ==========
func _init(manager: GridMapManager = null):
	super._init(manager)
	explored_regions = []

# ========== 规则实现 ==========
## 检查是否可以开垦指定网格
## 表世界规则：必须与已开垦的网格相邻（形成通路）
func can_explore(pos: Vector2i) -> Dictionary:
	if not grid_manager:
		return {"can_explore": false, "reason": "网格管理器未初始化"}
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return {"can_explore": false, "reason": "无效的网格位置"}
	
	# 如果已经是已开垦状态，不能再次开垦
	if grid_data.grid_type == Constants.GRID_TYPE_EXPLORED:
		return {"can_explore": false, "reason": "该网格已经开垦"}
	
	# 检查是否有已开垦的相邻网格（形成通路）
	var neighbors = grid_manager.get_neighbor_positions(pos)
	var has_explored_neighbor = false
	
	for neighbor_pos in neighbors:
		var neighbor_data = grid_manager.get_grid(neighbor_pos)
		if neighbor_data and neighbor_data.grid_type == Constants.GRID_TYPE_EXPLORED:
			has_explored_neighbor = true
			break
	
	# 如果没有已开垦的相邻网格，检查是否是第一个开垦的网格
	if not has_explored_neighbor:
		var explored_count = grid_manager.get_positions_by_type(Constants.GRID_TYPE_EXPLORED).size()
		if explored_count == 0:
			# 第一个开垦的网格，允许
			return {"can_explore": true, "reason": ""}
		else:
			# 不是第一个，且没有相邻的已开垦网格，不允许
			return {"can_explore": false, "reason": "开垦必须与已开垦的网格相邻，形成通路"}
	
	return {"can_explore": true, "reason": ""}

## 执行开垦操作前的验证
func validate_explore(pos: Vector2i) -> Dictionary:
	var can_result = can_explore(pos)
	if not can_result.can_explore:
		return {"valid": false, "reason": can_result.reason}
	
	return {"valid": true, "reason": ""}

## 执行开垦操作后的处理
func on_explore(pos: Vector2i) -> void:
	# 表世界开垦后，可以更新连通区域信息
	# 这里暂时不需要特殊处理，通路检查在can_explore中已经完成
	pass

## 检查网格是否与已开垦区域连通
func is_connected_to_explored(pos: Vector2i) -> bool:
	if not grid_manager:
		return false
	
	var neighbors = grid_manager.get_neighbor_positions(pos)
	for neighbor_pos in neighbors:
		var neighbor_data = grid_manager.get_grid(neighbor_pos)
		if neighbor_data and neighbor_data.grid_type == Constants.GRID_TYPE_EXPLORED:
			return true
	
	return false

## 获取所有已开垦的网格
func get_all_explored_positions() -> Array[Vector2i]:
	if not grid_manager:
		return []
	return grid_manager.get_positions_by_type(Constants.GRID_TYPE_EXPLORED)

## 检查两个网格是否连通（通过已开垦的路径）
func are_connected(pos1: Vector2i, pos2: Vector2i) -> bool:
	if not grid_manager:
		return false
	
	# 使用BFS检查连通性
	var visited: Dictionary = {}
	var queue: Array[Vector2i] = [pos1]
	visited[_pos_to_key(pos1)] = true
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		if current == pos2:
			return true
		
		var neighbors = grid_manager.get_neighbor_positions(current)
		for neighbor_pos in neighbors:
			var key = _pos_to_key(neighbor_pos)
			if visited.has(key):
				continue
			
			var neighbor_data = grid_manager.get_grid(neighbor_pos)
			if neighbor_data and neighbor_data.grid_type == Constants.GRID_TYPE_EXPLORED:
				visited[key] = true
				queue.append(neighbor_pos)
	
	return false

## 辅助函数：坐标转key
func _pos_to_key(pos: Vector2i) -> String:
	return str(pos.x) + "," + str(pos.y)
