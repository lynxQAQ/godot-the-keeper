extends RefCounted

## 扩展方法类
## 提供常用类型的扩展方法

# ========== Vector2i 扩展 ==========
## 获取相邻网格坐标（四方向）
static func get_neighbor_grids(grid_pos: Vector2i) -> Array[Vector2i]:
	return [
		grid_pos + Vector2i(0, -1),  # 上
		grid_pos + Vector2i(1, 0),   # 右
		grid_pos + Vector2i(0, 1),   # 下
		grid_pos + Vector2i(-1, 0)   # 左
	]

## 获取相邻网格坐标（八方向）
static func get_neighbor_grids_8(grid_pos: Vector2i) -> Array[Vector2i]:
	return [
		grid_pos + Vector2i(-1, -1),  # 左上
		grid_pos + Vector2i(0, -1),   # 上
		grid_pos + Vector2i(1, -1),   # 右上
		grid_pos + Vector2i(1, 0),    # 右
		grid_pos + Vector2i(1, 1),    # 右下
		grid_pos + Vector2i(0, 1),    # 下
		grid_pos + Vector2i(-1, 1),   # 左下
		grid_pos + Vector2i(-1, 0)    # 左
	]

## 网格坐标转换为世界坐标（等距网格，2:1菱形）
## 等距网格转换公式：
## world_x = (grid_x - grid_y) * (tile_width / 2)
## world_y = (grid_x + grid_y) * (tile_height / 2)
static func grid_to_world(grid_pos: Vector2i, cell_size: Vector2 = Vector2(64, 32)) -> Vector2:
	var world_x = (grid_pos.x - grid_pos.y) * (cell_size.x / 2.0)
	var world_y = (grid_pos.x + grid_pos.y) * (cell_size.y / 2.0)
	return Vector2(world_x, world_y)

## 世界坐标转换为网格坐标（等距网格，2:1菱形）
## 等距网格反向转换公式：
## grid_x = (world_x / tile_width) + (world_y / tile_height)
## grid_y = (world_y / tile_height) - (world_x / tile_width)
static func world_to_grid(world_pos: Vector2, cell_size: Vector2 = Vector2(64, 32)) -> Vector2i:
	var grid_x = int((world_pos.x / cell_size.x) + (world_pos.y / cell_size.y))
	var grid_y = int((world_pos.y / cell_size.y) - (world_pos.x / cell_size.x))
	return Vector2i(grid_x, grid_y)

## 计算网格距离（曼哈顿距离）
static func grid_distance(pos1: Vector2i, pos2: Vector2i) -> int:
	return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

## 计算网格距离（欧几里得距离）
static func grid_distance_euclidean(pos1: Vector2i, pos2: Vector2i) -> float:
	return pos1.distance_to(pos2)

# ========== Array 扩展 ==========
## 随机选择一个元素
static func random_choice(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[randi() % array.size()]

## 权重随机选择
## weights: 权重数组，长度需与array相同
static func weighted_choice(array: Array, weights: Array) -> Variant:
	if array.is_empty() or weights.is_empty() or array.size() != weights.size():
		return null
	
	var total_weight: float = 0.0
	for weight in weights:
		total_weight += weight
	
	if total_weight <= 0.0:
		return random_choice(array)
	
	var random_value = randf() * total_weight
	var current_weight: float = 0.0
	
	for i in range(array.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return array[i]
	
	return array[array.size() - 1]

## 打乱数组（Fisher-Yates洗牌算法）
static func shuffle_array(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp

# ========== Dictionary 扩展 ==========
## 深度合并字典
## 将source的内容深度合并到target中
static func deep_merge(target: Dictionary, source: Dictionary) -> Dictionary:
	for key in source:
		if key in target:
			if target[key] is Dictionary and source[key] is Dictionary:
				target[key] = deep_merge(target[key], source[key])
			else:
				target[key] = source[key]
		else:
			target[key] = source[key]
	return target

## 安全获取字典值
## 如果key不存在，返回default_value
static func safe_get(dict: Dictionary, key: Variant, default_value: Variant = null) -> Variant:
	if dict.has(key):
		return dict[key]
	return default_value

## 安全设置字典值
## 如果key不存在，则创建
static func safe_set(dict: Dictionary, key: Variant, value: Variant) -> void:
	dict[key] = value

## 检查字典是否包含所有指定的键
static func has_all_keys(dict: Dictionary, keys: Array) -> bool:
	for key in keys:
		if not dict.has(key):
			return false
	return true
