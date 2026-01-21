extends RefCounted
class_name GridMapManager

## 网格地图管理器
## 管理网格地图的数据存储、查询和更新
## 设计为普通类（非单例），可被网格系统Scene引用

# ========== 属性 ==========
## 网格地图尺寸
var grid_size: Vector2i = Vector2i(20, 20)

## 网格数据字典：key为Vector2i坐标的字符串表示，value为GridData
var grid_data_map: Dictionary = {}

## 网格单元大小（用于坐标转换）
## 等距网格使用2:1比例，例如64x32
var cell_size: Vector2 = Vector2(64, 32)

# ========== 构造函数 ==========
func _init(size: Vector2i = Vector2i(20, 20), cell_size_param: Vector2 = Vector2(64, 32)):
	grid_size = size
	cell_size = cell_size_param
	_initialize_grid_map()

# ========== 初始化 ==========
## 初始化网格地图
func _initialize_grid_map() -> void:
	grid_data_map.clear()
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)
			var grid_data = GridData.new(pos, Constants.GRID_TYPE_UNEXPLORED)
			grid_data_map[_pos_to_key(pos)] = grid_data

## 将Vector2i坐标转换为字典key
func _pos_to_key(pos: Vector2i) -> String:
	return str(pos.x) + "," + str(pos.y)

## 将字典key转换为Vector2i坐标
func _key_to_pos(key: String) -> Vector2i:
	var parts = key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

# ========== 网格获取和设置 ==========
## 获取指定坐标的网格数据
func get_grid(pos: Vector2i) -> GridData:
	if not is_valid_position(pos):
		push_warning("GridMapManager: 无效的坐标: " + str(pos))
		return null
	
	var key = _pos_to_key(pos)
	return grid_data_map.get(key, null)

## 设置指定坐标的网格数据
func set_grid(pos: Vector2i, grid_data: GridData) -> void:
	if not is_valid_position(pos):
		push_warning("GridMapManager: 无效的坐标: " + str(pos))
		return
	
	var key = _pos_to_key(pos)
	grid_data.grid_pos = pos
	grid_data_map[key] = grid_data

## 创建并设置网格数据
func create_grid(pos: Vector2i, grid_type: int = Constants.GRID_TYPE_UNEXPLORED) -> GridData:
	var grid_data = GridData.new(pos, grid_type)
	set_grid(pos, grid_data)
	return grid_data

# ========== 网格查询 ==========
## 检查坐标是否有效（在边界内）
func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

## 检查坐标是否在边界上
func is_on_boundary(pos: Vector2i) -> bool:
	return pos.x == 0 or pos.x == grid_size.x - 1 or pos.y == 0 or pos.y == grid_size.y - 1

## 获取所有网格坐标
func get_all_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			positions.append(Vector2i(x, y))
	return positions

## 获取指定类型的所有网格坐标
func get_positions_by_type(grid_type: int) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for key in grid_data_map:
		var grid_data: GridData = grid_data_map[key]
		if grid_data and grid_data.grid_type == grid_type:
			positions.append(grid_data.grid_pos)
	return positions

## 获取可通行的网格坐标
func get_passable_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for key in grid_data_map:
		var grid_data: GridData = grid_data_map[key]
		if grid_data and grid_data.is_passable:
			positions.append(grid_data.grid_pos)
	return positions

## 获取相邻网格坐标（四方向）
func get_neighbor_positions(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	
	for dir in directions:
		var neighbor_pos = pos + dir
		if is_valid_position(neighbor_pos):
			neighbors.append(neighbor_pos)
	
	return neighbors

## 获取相邻网格坐标（八方向）
func get_neighbor_positions_8(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)
	]
	
	for dir in directions:
		var neighbor_pos = pos + dir
		if is_valid_position(neighbor_pos):
			neighbors.append(neighbor_pos)
	
	return neighbors

# ========== 批量更新 ==========
## 批量设置网格类型
func set_grids_type(positions: Array[Vector2i], grid_type: int) -> void:
	for pos in positions:
		var grid_data = get_grid(pos)
		if grid_data:
			match grid_type:
				Constants.GRID_TYPE_UNEXPLORED:
					grid_data.set_unexplored()
				Constants.GRID_TYPE_EXPLORED:
					grid_data.set_explored()
				Constants.GRID_TYPE_MAZE:
					grid_data.set_maze()

## 批量设置网格通行性
func set_grids_passable(positions: Array[Vector2i], passable: bool) -> void:
	for pos in positions:
		var grid_data = get_grid(pos)
		if grid_data:
			grid_data.is_passable = passable

## 批量设置网格可见性
func set_grids_visible(positions: Array[Vector2i], visible: bool) -> void:
	for pos in positions:
		var grid_data = get_grid(pos)
		if grid_data:
			grid_data.is_visible = visible

# ========== 坐标转换 ==========
## 网格坐标转换为世界坐标（等距网格，2:1菱形）
## 等距网格转换公式：
## world_x = (grid_x - grid_y) * (tile_width / 2)
## world_y = (grid_x + grid_y) * (tile_height / 2)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	var world_x = (grid_pos.x - grid_pos.y) * (cell_size.x / 2.0)
	var world_y = (grid_pos.x + grid_pos.y) * (cell_size.y / 2.0)
	return Vector2(world_x, world_y)

## 世界坐标转换为网格坐标（等距网格，2:1菱形）
## 等距网格反向转换公式：
## grid_x = (world_x / tile_width) + (world_y / tile_height)
## grid_y = (world_y / tile_height) - (world_x / tile_width)
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var grid_x = int((world_pos.x / cell_size.x) + (world_pos.y / cell_size.y))
	var grid_y = int((world_pos.y / cell_size.y) - (world_pos.x / cell_size.x))
	return Vector2i(grid_x, grid_y)

# ========== 地图操作 ==========
## 重置地图（所有网格变为未开垦）
func reset_map() -> void:
	_initialize_grid_map()

## 清空地图
func clear_map() -> void:
	grid_data_map.clear()

## 调整地图尺寸
func resize_map(new_size: Vector2i) -> void:
	grid_size = new_size
	_initialize_grid_map()

## 获取地图统计信息
func get_map_stats() -> Dictionary:
	var stats = {
		"total_grids": grid_size.x * grid_size.y,
		"unexplored": 0,
		"explored": 0,
		"maze": 0,
		"passable": 0,
		"visible": 0
	}
	
	for key in grid_data_map:
		var grid_data: GridData = grid_data_map[key]
		if grid_data:
			match grid_data.grid_type:
				Constants.GRID_TYPE_UNEXPLORED:
					stats.unexplored += 1
				Constants.GRID_TYPE_EXPLORED:
					stats.explored += 1
				Constants.GRID_TYPE_MAZE:
					stats.maze += 1
			
			if grid_data.is_passable:
				stats.passable += 1
			if grid_data.is_visible:
				stats.visible += 1
	
	return stats

# ========== 序列化 ==========
## 序列化为字典
func to_dict() -> Dictionary:
	var grids_dict = {}
	for key in grid_data_map:
		var grid_data: GridData = grid_data_map[key]
		if grid_data:
			grids_dict[key] = grid_data.to_dict()
	
	return {
		"grid_size": {"x": grid_size.x, "y": grid_size.y},
		"cell_size": {"x": cell_size.x, "y": cell_size.y},
		"grids": grids_dict
	}

## 从字典反序列化
func from_dict(data: Dictionary) -> void:
	if data.has("grid_size"):
		var size_dict = data["grid_size"]
		grid_size = Vector2i(size_dict.get("x", 20), size_dict.get("y", 20))
	
	if data.has("cell_size"):
		var cell_dict = data["cell_size"]
		cell_size = Vector2(cell_dict.get("x", 64), cell_dict.get("y", 32))
	
	grid_data_map.clear()
	if data.has("grids"):
		var grids_dict = data["grids"]
		for key in grids_dict:
			var grid_dict = grids_dict[key]
			var grid_data = GridData.new()
			grid_data.from_dict(grid_dict)
			grid_data_map[key] = grid_data
