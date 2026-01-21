extends Node2D
class_name GridSystem

## 可复用网格系统
## 管理网格地图的可视化和交互
## 可在子窗口场景中实例化使用

# ========== 预加载 ==========
const Extensions = preload("res://scripts/utils/Extensions.gd")
const GridCellScene = preload("res://scenes/worlds/GridCell.tscn")

# ========== 信号 ==========
## 网格被点击
signal grid_clicked(grid_pos: Vector2i, grid_data: GridData)
## 网格被悬停
signal grid_hovered(grid_pos: Vector2i, grid_data: GridData)
## 网格状态改变
signal grid_state_changed(grid_pos: Vector2i, grid_data: GridData)
## 网格地图初始化完成
signal grid_map_initialized()

# ========== 导出属性 ==========
## 网格地图尺寸
@export var grid_size: Vector2i = Vector2i(20, 20)

## 网格单元大小（等距网格使用2:1比例，例如64x32）
@export var cell_size: Vector2 = Vector2(64, 32)

## 是否启用交互
@export var enable_interaction: bool = true

## 是否显示网格线
@export var show_grid_lines: bool = true

# ========== 内部属性 ==========
## 网格地图管理器
var grid_manager: GridMapManager

## 网格Cell节点字典：key为坐标字符串，value为GridCell节点
var grid_cells: Dictionary = {}

## 当前选中的网格
var selected_grid: Vector2i = Vector2i(-1, -1)

## 当前悬停的网格
var hovered_grid: Vector2i = Vector2i(-1, -1)

## GridCell容器节点（使用Control以便正确显示ColorRect）
var grid_container: Control = null

## 等距原点：逻辑(0,0)在容器中的位置
## 应该位于容器顶部中心
var iso_origin: Vector2 = Vector2.ZERO

# ========== 生命周期 ==========
func _ready():
	# 获取GridContainer节点（应该在场景中已存在）
	grid_container = get_node_or_null("GridContainer") as Control
	if not grid_container:
		push_error("GridSystem: GridContainer节点不存在，请在场景中添加")
		return
	
	# 初始化网格地图管理器
	grid_manager = GridMapManager.new(grid_size, cell_size)
	
	# 计算等距原点（延迟到容器大小确定后）
	call_deferred("_update_iso_origin")
	
	# 监听容器大小变化
	if grid_container:
		if not grid_container.resized.is_connected(_on_container_resized):
			grid_container.resized.connect(_on_container_resized)
	
	# 初始化网格地图
	_initialize_grid_map()

# ========== 初始化 ==========
## 更新等距原点
func _update_iso_origin() -> void:
	if not grid_container or not grid_manager:
		return
	
	# 使用容器的实际大小计算
	var container_size = grid_container.size
	if container_size.x <= 0 or container_size.y <= 0:
		# 如果容器大小还未确定，使用rect
		var rect = grid_container.get_rect()
		container_size = rect.size
	
	# 计算网格的实际范围（等距投影后的范围）
	# 网格范围：
	# - 最左：grid_pos = (0, grid_size.y-1) -> x = (0 - (grid_size.y-1)) * cell_size.x / 2
	# - 最右：grid_pos = (grid_size.x-1, 0) -> x = ((grid_size.x-1) - 0) * cell_size.x / 2
	# - 最上：grid_pos = (0, 0) -> y = (0 + 0) * cell_size.y / 2 = 0
	# - 最下：grid_pos = (grid_size.x-1, grid_size.y-1) -> y = ((grid_size.x-1) + (grid_size.y-1)) * cell_size.y / 2
	
	var min_x = (0 - (grid_size.y - 1)) * cell_size.x * 0.5
	var max_x = ((grid_size.x - 1) - 0) * cell_size.x * 0.5
	var min_y = 0.0
	var max_y = ((grid_size.x - 1) + (grid_size.y - 1)) * cell_size.y * 0.5
	
	# 网格的实际中心（在等距投影空间中）
	var grid_center_x = (min_x + max_x) / 2.0
	var grid_center_y = (min_y + max_y) / 2.0
	
	# 等距原点：使网格在容器中居中
	# 容器中心 - 网格中心 = 偏移量
	iso_origin = Vector2(
		container_size.x / 2.0 - grid_center_x,
		container_size.y / 2.0 - grid_center_y
	)
	
	# 如果网格已经创建，需要重新定位
	if not grid_cells.is_empty():
		_reposition_all_grid_cells()

## 容器大小变化回调
func _on_container_resized() -> void:
	_update_iso_origin()

## 初始化网格地图
func _initialize_grid_map() -> void:
	if not grid_manager:
		grid_manager = GridMapManager.new(grid_size, cell_size)
	
	# 确保等距原点已计算
	if iso_origin == Vector2.ZERO and grid_container:
		_update_iso_origin()
	
	# 创建所有网格Cell
	_create_all_grid_cells()
	
	# 发射初始化完成信号
	grid_map_initialized.emit()

## 创建所有网格Cell
func _create_all_grid_cells() -> void:
	# 清除现有Cell
	_clear_all_grid_cells()
	
	# 创建新的Cell
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)
			_create_grid_cell(pos)

## 等距坐标转换为本地坐标（等距投影）
## 这是纯数学转换，不包含原点偏移
func iso_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * cell_size.x * 0.5,
		(grid_pos.x + grid_pos.y) * cell_size.y * 0.5
	)

## 本地坐标转换为等距网格坐标（反向投影）
func local_to_iso(local_pos: Vector2) -> Vector2i:
	# 先减去原点偏移
	var relative_pos = local_pos - iso_origin
	# 然后进行反向等距转换
	var grid_x = int((relative_pos.x / cell_size.x) + (relative_pos.y / cell_size.y))
	var grid_y = int((relative_pos.y / cell_size.y) - (relative_pos.x / cell_size.x))
	return Vector2i(grid_x, grid_y)

## 创建单个网格Cell
func _create_grid_cell(pos: Vector2i) -> void:
	if not grid_manager or not grid_manager.is_valid_position(pos):
		return
	
	# 实例化GridCell场景
	var grid_cell = GridCellScene.instantiate()
	if not grid_cell:
		push_error("GridSystem: 无法实例化GridCell场景")
		return
	
	# 计算等距本地坐标（不包含原点）
	var iso_local = iso_to_local(pos)
	# 应用等距原点偏移，得到最终世界位置
	var world_pos = iso_origin + iso_local
	# ColorRect的position是左上角，需要从中心偏移
	grid_cell.position = world_pos - (cell_size / 2.0)
	grid_cell.size = cell_size
	grid_cell.mouse_filter = Control.MOUSE_FILTER_PASS  # 允许接收鼠标事件
	
	# 设置Cell数据
	var grid_data = grid_manager.get_grid(pos)
	if grid_cell.has_method("set_grid_data"):
		grid_cell.set_grid_data(grid_data)
	
	# 添加到容器
	grid_container.add_child(grid_cell)
	
	# 存储引用
	var key = _pos_to_key(pos)
	grid_cells[key] = grid_cell

## 重新定位所有网格Cell（当等距原点改变时）
func _reposition_all_grid_cells() -> void:
	for key in grid_cells:
		var cell = grid_cells[key]
		if not is_instance_valid(cell):
			continue
		
		# 从key恢复坐标
		var pos = _key_to_pos(key)
		# 重新计算位置
		var iso_local = iso_to_local(pos)
		var world_pos = iso_origin + iso_local
		cell.position = world_pos - (cell_size / 2.0)

## 清除所有网格Cell
func _clear_all_grid_cells() -> void:
	for key in grid_cells:
		var cell = grid_cells[key]
		if is_instance_valid(cell):
			cell.queue_free()
	grid_cells.clear()

## 坐标转换辅助函数
func _pos_to_key(pos: Vector2i) -> String:
	return str(pos.x) + "," + str(pos.y)

## 从key恢复坐标
func _key_to_pos(key: String) -> Vector2i:
	var parts = key.split(",")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

# ========== 网格数据访问 ==========
## 获取网格数据
func get_grid(pos: Vector2i) -> GridData:
	if not grid_manager:
		return null
	return grid_manager.get_grid(pos)

## 设置网格数据
func set_grid(pos: Vector2i, grid_data: GridData) -> void:
	if not grid_manager:
		return
	
	grid_manager.set_grid(pos, grid_data)
	_update_grid_cell(pos)
	grid_state_changed.emit(pos, grid_data)

## 更新网格Cell显示
func _update_grid_cell(pos: Vector2i) -> void:
	var key = _pos_to_key(pos)
	if not grid_cells.has(key):
		return
	
	var cell = grid_cells[key]
	var grid_data = grid_manager.get_grid(pos)
	
	if cell and cell.has_method("set_grid_data"):
		cell.set_grid_data(grid_data)

## 更新所有网格Cell显示
func update_all_grid_cells() -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos = Vector2i(x, y)
			_update_grid_cell(pos)

# ========== 输入处理 ==========
func _input(event: InputEvent) -> void:
	if not enable_interaction:
		return
	
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventMouseButton and event.pressed:
		_handle_mouse_click(event)

## 处理鼠标移动
func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var grid_pos = _world_to_grid(Vector2.ZERO)  # 使用get_local_mouse_position()
	
	if grid_pos != hovered_grid:
		# 取消之前的悬停
		if hovered_grid != Vector2i(-1, -1):
			_set_grid_hovered(hovered_grid, false)
		
		# 设置新的悬停
		if grid_manager and grid_manager.is_valid_position(grid_pos):
			hovered_grid = grid_pos
			_set_grid_hovered(hovered_grid, true)
			
			var grid_data = grid_manager.get_grid(grid_pos)
			grid_hovered.emit(grid_pos, grid_data)

## 处理鼠标点击
func _handle_mouse_click(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	var grid_pos = _world_to_grid(Vector2.ZERO)  # 使用get_local_mouse_position()
	
	if grid_manager and grid_manager.is_valid_position(grid_pos):
		selected_grid = grid_pos
		var grid_data = grid_manager.get_grid(grid_pos)
		grid_clicked.emit(grid_pos, grid_data)

## 设置网格悬停状态
func _set_grid_hovered(pos: Vector2i, hovered: bool) -> void:
	var key = _pos_to_key(pos)
	if not grid_cells.has(key):
		return
	
	var cell = grid_cells[key]
	if cell and cell.has_method("set_hovered"):
		cell.set_hovered(hovered)

## 设置网格选中状态
func set_grid_selected(pos: Vector2i, selected: bool) -> void:
	var key = _pos_to_key(pos)
	if not grid_cells.has(key):
		return
	
	var cell = grid_cells[key]
	if cell and cell.has_method("set_selected"):
		cell.set_selected(selected)

# ========== 坐标转换 ==========
## 世界坐标转换为网格坐标
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	# 获取鼠标在GridContainer中的本地坐标
	if not grid_container:
		return Vector2i(-1, -1)
	
	# 将全局鼠标位置转换为GridContainer的本地坐标
	var local_pos = grid_container.get_local_mouse_position()
	
	# 使用等距反向转换
	return local_to_iso(local_pos)

## 网格坐标转换为世界坐标（相对于GridContainer的本地坐标）
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	# 使用等距转换并应用原点
	var iso_local = iso_to_local(grid_pos)
	return iso_origin + iso_local

# ========== 公共接口 ==========
## 初始化网格系统（外部调用）
func initialize(size: Vector2i, cell_size_param: Vector2 = Vector2(64, 32)) -> void:
	grid_size = size
	cell_size = cell_size_param
	
	if grid_manager:
		grid_manager.resize_map(size)
		grid_manager.cell_size = cell_size_param
	
	_initialize_grid_map()

## 获取网格管理器引用
func get_grid_manager() -> GridMapManager:
	return grid_manager

## 设置GridContainer的大小（由父Control调用）
func set_container_size(new_size: Vector2) -> void:
	if not grid_container:
		return
	
	grid_container.size = new_size
	# 更新等距原点
	_update_iso_origin()

## 重置网格地图
func reset_map() -> void:
	if grid_manager:
		grid_manager.reset_map()
	_initialize_grid_map()

## 检查点是否在容器rect内（带扩展边距）
func _is_in_container(point: Vector2, margin: float) -> bool:
	if not grid_container:
		return false
	var container_rect = Rect2(Vector2.ZERO, grid_container.size)
	container_rect = container_rect.grow(margin)
	return container_rect.has_point(point)

## 裁剪线条到容器rect内，返回裁剪后的起点和终点
## 如果线条完全在容器外，返回false
func _clip_line_to_rect(start: Vector2, end: Vector2, rect: Rect2) -> Array:
	# 简化实现：如果起点或终点在rect内，就绘制整条线
	# 如果都在外，检查中心点
	var start_in = rect.has_point(start)
	var end_in = rect.has_point(end)
	
	if start_in and end_in:
		return [start, end, true]
	elif start_in or end_in:
		# 至少有一个点在rect内，绘制整条线
		return [start, end, true]
	else:
		# 检查中心点
		var center = (start + end) / 2.0
		if rect.has_point(center):
			return [start, end, true]
		else:
			return [start, end, false]

## 绘制网格线（等距网格菱形线）
func _draw() -> void:
	if not show_grid_lines or not grid_manager or not grid_container:
		return
	
	var color = Color(1.0, 1.0, 1.0, 0.2)
	var container_rect = Rect2(Vector2.ZERO, grid_container.size)
	# 扩展rect以包含可能部分可见的网格
	var max_cell_dimension = max(cell_size.x, cell_size.y)
	var expanded_rect = container_rect.grow(max_cell_dimension)
	
	# 等距网格需要绘制菱形边界
	# 为每个网格绘制菱形轮廓（只绘制与容器相交的）
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var grid_pos = Vector2i(x, y)
			# 使用等距转换计算中心位置
			var iso_local = iso_to_local(grid_pos)
			var center = iso_origin + iso_local
			
			# 检查网格中心是否在扩展的可见区域内
			if not expanded_rect.has_point(center):
				continue
			
			# 等距网格的四个顶点（相对于中心点）
			var half_width = cell_size.x / 2.0
			var half_height = cell_size.y / 2.0
			
			var top = center + Vector2(0, -half_height)
			var right = center + Vector2(half_width, 0)
			var bottom = center + Vector2(0, half_height)
			var left = center + Vector2(-half_width, 0)
			
			# 绘制菱形四条边（只绘制在容器内的部分）
			var result = _clip_line_to_rect(top, right, container_rect)
			if result[2]:
				draw_line(result[0], result[1], color, 1.0)
			
			result = _clip_line_to_rect(right, bottom, container_rect)
			if result[2]:
				draw_line(result[0], result[1], color, 1.0)
			
			result = _clip_line_to_rect(bottom, left, container_rect)
			if result[2]:
				draw_line(result[0], result[1], color, 1.0)
			
			result = _clip_line_to_rect(left, top, container_rect)
			if result[2]:
				draw_line(result[0], result[1], color, 1.0)
