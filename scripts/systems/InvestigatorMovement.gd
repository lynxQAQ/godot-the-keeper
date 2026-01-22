extends RefCounted
class_name InvestigatorMovement

## 调查员移动规则类
## 定义和实现不同的移动规则算法

# ========== 移动规则枚举 ==========
enum MovementRule {
	SHORTEST_PATH,      # 最短路径（直接向目标前进）
	RANDOM_EXPLORE,     # 随机探索（随机选择方向）
	CAUTIOUS_ADVANCE,   # 谨慎前进（避开危险区域）
	FOLLOW_PATH         # 跟随路径（使用预计算的路径）
}

# ========== 移动参数 ==========
var movement_rule: MovementRule = MovementRule.SHORTEST_PATH
var movement_speed: float = 1.0  # 移动速度（网格/秒）
var move_interval: float = 1.0  # 移动间隔（秒）
var last_move_time: float = 0.0  # 上次移动时间

# ========== 初始化 ==========
func _init(
	p_rule: MovementRule = MovementRule.SHORTEST_PATH,
	p_speed: float = 1.0,
	p_interval: float = 1.0
) -> void:
	movement_rule = p_rule
	movement_speed = p_speed
	move_interval = p_interval
	last_move_time = 0.0

# ========== 移动规则选择 ==========
## 根据规则选择下一个移动方向
## 返回下一个网格位置，如果无法移动则返回当前位置
func choose_next_position(
	current_pos: Vector2i,
	target_pos: Vector2i,
	passable_neighbors: Array[Vector2i],
	danger_zones: Array[Vector2i] = []
) -> Vector2i:
	if passable_neighbors.is_empty():
		return current_pos
	
	match movement_rule:
		MovementRule.SHORTEST_PATH:
			return _choose_shortest_path(current_pos, target_pos, passable_neighbors)
		MovementRule.RANDOM_EXPLORE:
			return _choose_random_explore(passable_neighbors)
		MovementRule.CAUTIOUS_ADVANCE:
			return _choose_cautious_advance(current_pos, target_pos, passable_neighbors, danger_zones)
		MovementRule.FOLLOW_PATH:
			# 跟随路径需要外部提供路径，这里使用最短路径作为后备
			return _choose_shortest_path(current_pos, target_pos, passable_neighbors)
		_:
			return current_pos

## 最短路径算法
func _choose_shortest_path(
	current_pos: Vector2i,
	target_pos: Vector2i,
	passable_neighbors: Array[Vector2i]
) -> Vector2i:
	if passable_neighbors.is_empty():
		return current_pos
	
	# 选择距离目标最近的邻居
	var best_pos = passable_neighbors[0]
	var best_distance = _manhattan_distance(best_pos, target_pos)
	
	for neighbor in passable_neighbors:
		var distance = _manhattan_distance(neighbor, target_pos)
		if distance < best_distance:
			best_distance = distance
			best_pos = neighbor
	
	return best_pos

## 随机探索算法
func _choose_random_explore(passable_neighbors: Array[Vector2i]) -> Vector2i:
	if passable_neighbors.is_empty():
		return Vector2i.ZERO
	
	return passable_neighbors[randi() % passable_neighbors.size()]

## 谨慎前进算法（避开危险区域）
func _choose_cautious_advance(
	current_pos: Vector2i,
	target_pos: Vector2i,
	passable_neighbors: Array[Vector2i],
	danger_zones: Array[Vector2i]
) -> Vector2i:
	if passable_neighbors.is_empty():
		return current_pos
	
	# 过滤掉危险区域的邻居
	var safe_neighbors: Array[Vector2i] = []
	for neighbor in passable_neighbors:
		var is_dangerous = false
		for danger_zone in danger_zones:
			if neighbor == danger_zone:
				is_dangerous = true
				break
		
		if not is_dangerous:
			safe_neighbors.append(neighbor)
	
	# 如果没有安全邻居，使用最短路径（即使危险）
	if safe_neighbors.is_empty():
		return _choose_shortest_path(current_pos, target_pos, passable_neighbors)
	
	# 在安全邻居中选择距离目标最近的
	return _choose_shortest_path(current_pos, target_pos, safe_neighbors)

# ========== 移动速度和时间管理 ==========
## 检查是否可以移动（基于移动间隔）
func can_move(current_time: float) -> bool:
	return (current_time - last_move_time) >= move_interval

## 更新移动时间
func update_move_time(current_time: float) -> void:
	last_move_time = current_time

## 设置移动速度
func set_movement_speed(speed: float) -> void:
	movement_speed = max(0.1, speed)

## 设置移动间隔
func set_move_interval(interval: float) -> void:
	move_interval = max(0.1, interval)

## 获取移动速度
func get_movement_speed() -> float:
	return movement_speed

## 获取移动间隔
func get_move_interval() -> float:
	return move_interval

# ========== 工具函数 ==========
## 计算曼哈顿距离
func _manhattan_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

## 设置移动规则
func set_movement_rule(rule: MovementRule) -> void:
	movement_rule = rule

## 获取移动规则
func get_movement_rule() -> MovementRule:
	return movement_rule
