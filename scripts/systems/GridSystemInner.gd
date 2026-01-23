extends Node2D
class_name GridSystemInner

## 里世界网格系统
## 管理里世界的网格地图可视化和交互
## 适配 SubViewport 架构

# 核心设计：数据与表现分离
# GridMapManager：纯数据层，存储网格状态
# GridCell：视觉表现（Sprite/等距瓦片）
# GridSystemInner：协调两者 + 处理输入交互（里世界专用）

# ========== 预加载 ==========
const Extensions = preload("res://scripts/utils/Extensions.gd")
const GridCellScene = preload("res://scenes/worlds/GridCell.tscn")

# ========== 信号 ==========
signal grid_clicked(grid_pos: Vector2i, grid_data: GridData)
signal grid_hovered(grid_pos: Vector2i, grid_data: GridData)
signal grid_state_changed(grid_pos: Vector2i, grid_data: GridData)
signal grid_map_initialized()

# ========== 导出属性 ==========
@export var grid_size: Vector2i = Vector2i(20, 20)
@export var cell_size: Vector2 = Vector2(64, 32)
@export var enable_interaction: bool = true
@export var show_grid_lines: bool = true
@export var enable_drag: bool = true
@export var enable_zoom: bool = true
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_step: float = 0.1

# ========== 内部属性 ==========
var grid_manager: GridMapManager
var grid_cells: Dictionary = {}
var selected_grid: Vector2i = Vector2i(-1, -1)
var hovered_grid: Vector2i = Vector2i(-1, -1)
var camera: Camera2D = null
var grid_cell_container: Node2D = null

## 网格系统规则（用于里世界规则）
var grid_rule: GridSystemRule = null

## 等距原点：世界坐标，网格(0,0)在世界空间中的位置
## 视觉原点——让网格在屏幕中居中显示
var iso_origin: Vector2 = Vector2.ZERO

## 拖拽状态
var is_dragging: bool = false

## 连续开垦状态（长按拖动开垦）
var is_continuous_exploring: bool = false
var explored_grids_in_drag: Dictionary = {}  # 本次拖动中已处理的网格（避免重复）

# ========== 生命周期 ==========
func _ready():
	# 确保 GridSystemInner 节点的 position 为 (0,0)，避免坐标偏移
	position = Vector2.ZERO
	
	# 获取或创建Camera2D
	camera = get_node_or_null("Camera2D") as Camera2D
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	
	# 确保相机启用，这对 SubViewport 很重要
	camera.enabled = true
	
	grid_cell_container = get_node_or_null("GridCellContainer") as Node2D
	if not grid_cell_container:
		grid_cell_container = Node2D.new()
		grid_cell_container.name = "GridCellContainer"
		add_child(grid_cell_container)
	
	grid_manager = GridMapManager.new(grid_size, cell_size)
	
	# 监听视口大小变化（如果父容器调整大小，我们需要重新居中）
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	
	call_deferred("_init_after_frame")

func _init_after_frame():
	_update_iso_origin()
	_initialize_grid_map()
	_set_zoom(1.0) # 初始化缩放
	
	# 如果规则系统已设置，更新其grid_manager引用
	if grid_rule:
		grid_rule.grid_manager = grid_manager

func _process(_delta: float) -> void:
	# 持续检查鼠标是否在视口内，如果不在则清除 hover 状态
	# 这样可以处理鼠标快速移出视口的情况
	if enable_interaction and not is_dragging:
		if not _is_mouse_in_viewport():
			if hovered_grid != Vector2i(-1, -1):
				_set_grid_hovered_state(hovered_grid, false)
				hovered_grid = Vector2i(-1, -1)

func _on_viewport_size_changed():
	# 当窗口大小改变时，可以选择重新居中，或者保持原样
	# 这里暂不自动重算，避免玩家操作时突然跳动
	pass 

# ========== 初始化核心逻辑 ==========
# 在等距（Isometric）坐标系下，计算一个"视觉原点 iso_origin"，让整个网格在当前视口中居中显示，并据此创建并摆放所有网格单元。
func _update_iso_origin() -> void:
	if not grid_manager: return
	
	# 获取当前 Viewport 的实际可视矩形大小
	# 在 SubViewport 中，使用 get_visible_rect() 获取正确的尺寸
	var viewport = get_viewport()
	var view_size: Vector2
	if viewport:
		view_size = viewport.get_visible_rect().size
	else:
		view_size = get_viewport_rect().size
	
	# 计算网格整体的物理宽高（世界坐标系下） 计算整个等距网格的"物理边界"
	# 在不创建任何节点的情况下，直接用数学推导出：左右上下的最远端
	var min_x = (0 - (grid_size.y - 1)) * cell_size.x * 0.5
	var max_x = ((grid_size.x - 1) - 0) * cell_size.x * 0.5
	var min_y = 0.0
	var max_y = ((grid_size.x - 1) + (grid_size.y - 1)) * cell_size.y * 0.5
	
	# 计算网格中心点
	var grid_center_x = (min_x + max_x) / 2.0
	var grid_center_y = (min_y + max_y) / 2.0
	
	# 计算原点偏移量，使网格整体居中
	iso_origin = Vector2(
		view_size.x / 2.0 - grid_center_x,
		view_size.y / 2.0 - grid_center_y
	)
	
	# 初始时将相机对准屏幕中心
	if camera:
		camera.position = view_size / 2.0
	
	if not grid_cells.is_empty():
		_reposition_all_grid_cells()

func _initialize_grid_map() -> void:
	if not grid_manager:
		grid_manager = GridMapManager.new(grid_size, cell_size)
	if iso_origin == Vector2.ZERO:
		_update_iso_origin()
	_create_all_grid_cells()
	grid_map_initialized.emit()

func _create_all_grid_cells() -> void:
	_clear_all_grid_cells()
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			_create_grid_cell(Vector2i(x, y))

func _create_grid_cell(pos: Vector2i) -> void:
	if not grid_manager.is_valid_position(pos): return
	
	var grid_cell = GridCellScene.instantiate()
	# 计算位置：原点 + 等距偏移
	grid_cell.position = iso_origin + iso_to_local(pos)
	
	if grid_cell.has_method("set_cell_size"):
		grid_cell.set_cell_size(cell_size)
	else:
		grid_cell.cell_size = cell_size
	
	var grid_data = grid_manager.get_grid(pos)
	if grid_cell.has_method("set_grid_data"):
		grid_cell.set_grid_data(grid_data)
	
	grid_cell_container.add_child(grid_cell)
	grid_cells[_pos_to_key(pos)] = grid_cell

# ========== 核心坐标转换 (数学部分) ==========
## 等距坐标 -> 本地物理坐标 (不含 iso_origin)
func iso_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		(grid_pos.x - grid_pos.y) * cell_size.x * 0.5,
		(grid_pos.x + grid_pos.y) * cell_size.y * 0.5
	)

## 世界坐标 -> 网格坐标
func world_to_grid(world_pos: Vector2) -> Vector2i:
	var relative_pos = world_pos - iso_origin
	var gx = (relative_pos.x / (cell_size.x / 2) + relative_pos.y / (cell_size.y / 2)) / 2
	var gy = (relative_pos.y / (cell_size.y / 2) - relative_pos.x / (cell_size.x / 2)) / 2
	return Vector2i(floor(gx), floor(gy))

# ========== 简化的输入处理 ==========
# 使用 _input 确保能接收到所有输入事件（包括在 SubViewport 中）
func _input(event: InputEvent) -> void:
	if not camera:
		return
	
	# 1. 处理拖拽 (Pan)
	var was_dragging_before_pan = is_dragging
	if enable_drag:
		_handle_pan_input(event)
	
	# 2. 处理缩放 (Zoom)
	if enable_zoom:
		_handle_zoom_input(event)
	
	# 3. 处理交互 (Hover/Click/Continuous Explore) - 仅在未拖拽时
	if enable_interaction and not is_dragging:
		# 检查鼠标是否在里世界视口范围内
		var mouse_in_viewport = _is_mouse_in_viewport()
		if not mouse_in_viewport:
			# 鼠标移出视口，清除 hover 状态和连续开垦状态
			if hovered_grid != Vector2i(-1, -1):
				_set_grid_hovered_state(hovered_grid, false)
				hovered_grid = Vector2i(-1, -1)
			if is_continuous_exploring:
				_end_continuous_explore()
		else:
			# 鼠标在视口内，正常处理 hover 和点击
			if event is InputEventMouseMotion:
				# 关键修复：在 SubViewport 中，需要正确获取鼠标的世界坐标
				# get_global_mouse_position() 返回的是全局坐标，已经考虑了相机变换
				# 但需要确保坐标系统与 iso_origin 一致
				var mouse_world = _get_mouse_world_position()
				_handle_hover_logic(mouse_world)
				if is_continuous_exploring:
					_handle_continuous_explore(mouse_world)
			elif event is InputEventMouseButton:
				var mb_event = event as InputEventMouseButton
				if mb_event.button_index == MOUSE_BUTTON_LEFT:
					if mb_event.pressed:
						var mouse_world = _get_mouse_world_position()
						_start_continuous_explore(mouse_world)
						_handle_click_logic(event, mouse_world)
					else:
						_end_continuous_explore()
	elif is_dragging:
		# 拖拽时清除 hover 状态和连续开垦状态
		if hovered_grid != Vector2i(-1, -1):
			_set_grid_hovered_state(hovered_grid, false)
			hovered_grid = Vector2i(-1, -1)
		if is_continuous_exploring:
			_end_continuous_explore()

## 检查鼠标是否在里世界视口范围内
func _is_mouse_in_viewport() -> bool:
	# 重要：由于 InnerWorldGrid 设置了 mouse_filter = MOUSE_FILTER_IGNORE，
	# get_local_mouse_position() 在 Control 节点上可能不准确
	# 在 SubViewport 架构下，Node2D 的 _input 通常只在视口内触发
	# 但为了更准确，我们使用视口来检查
	
	var viewport = get_viewport()
	if not viewport:
		return false
	
	# 获取视口的鼠标位置
	var mouse_pos = viewport.get_mouse_position()
	var viewport_size = viewport.get_visible_rect().size
	
	# 检查鼠标是否在视口范围内
	if viewport_size.x > 0 and viewport_size.y > 0:
		var result = Rect2(Vector2.ZERO, viewport_size).has_point(mouse_pos)
		return result
	
	# 如果视口大小无效，默认返回 true（因为 _input 已经被调用）
	return true

## 获取鼠标的世界坐标（适配 SubViewport 架构）
## 关键修复：确保返回的坐标与 iso_origin 使用的坐标系统一致
func _get_mouse_world_position() -> Vector2:
	if not camera:
		return get_global_mouse_position()
	
	# 在 SubViewport 中，需要手动将视口鼠标坐标转换为世界坐标
	# 这样可以确保坐标系统与 iso_origin 一致
	var viewport = get_viewport()
	if not viewport:
		return get_global_mouse_position()
	
	# 获取视口的鼠标位置（相对于视口的坐标）
	var mouse_screen = viewport.get_mouse_position()
	var view_size = viewport.get_visible_rect().size
	
	# 将屏幕坐标转换为世界坐标
	# 屏幕中心对应相机位置，需要考虑相机的位置和缩放
	var screen_center = view_size / 2.0
	var offset_from_center = mouse_screen - screen_center
	# 考虑相机缩放
	var world_offset = offset_from_center / camera.zoom.x
	# 相机位置就是世界坐标的中心点（因为 iso_origin 的计算也基于此）
	var mouse_world = camera.position + world_offset
	
	return mouse_world

# ========== 修复后的拖拽逻辑 ==========
var drag_start_mouse_world: Vector2 = Vector2.ZERO
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_camera_pos: Vector2 = Vector2.ZERO

func _handle_pan_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if not event.pressed and is_dragging:
			is_dragging = false
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and enable_interaction:
				var mouse_world = _get_mouse_world_position()
				_start_continuous_explore(mouse_world)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and Input.is_key_pressed(KEY_SPACE):
				is_dragging = true
				drag_start_mouse_pos = get_viewport().get_mouse_position()
				drag_start_camera_pos = camera.position
			else:
				if not event.pressed:
					is_dragging = false
					if is_continuous_exploring:
						_end_continuous_explore()
	
	if event is InputEventMouseMotion and is_dragging:
		var current_mouse_pos = get_viewport().get_mouse_position()
		var diff = current_mouse_pos - drag_start_mouse_pos
		camera.position = drag_start_camera_pos - diff / camera.zoom.x

# ========== 修复后的缩放逻辑 ==========
func _handle_zoom_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x + zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x - zoom_step)

func _set_zoom(target_zoom: float) -> void:
	target_zoom = clamp(target_zoom, min_zoom, max_zoom)
	if target_zoom == camera.zoom.x: return
	
	var mouse_world_before = _get_mouse_world_position()
	camera.zoom = Vector2(target_zoom, target_zoom)
	var mouse_world_after = _get_mouse_world_position()
	camera.position -= (mouse_world_after - mouse_world_before)

# ========== 交互逻辑 ==========
func _handle_hover_logic(mouse_world_pos: Vector2) -> void:
	var target_grid = _find_grid_at_position(mouse_world_pos)
	
	if target_grid != hovered_grid:
		if hovered_grid != Vector2i(-1, -1):
			_set_grid_hovered_state(hovered_grid, false)
		
		if target_grid != Vector2i(-1, -1):
			hovered_grid = target_grid
			_set_grid_hovered_state(hovered_grid, true)
			var data = grid_manager.get_grid(target_grid)
			grid_hovered.emit(target_grid, data)
		else:
			hovered_grid = Vector2i(-1, -1)

func _handle_click_logic(event: InputEventMouseButton, mouse_world_pos: Vector2) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		# 里世界不需要检查 Secret，直接处理网格点击
		var target_grid = _find_grid_at_position(mouse_world_pos)
		
		if target_grid != Vector2i(-1, -1):
			selected_grid = target_grid
			var data = grid_manager.get_grid(target_grid)
			if data:
				grid_clicked.emit(target_grid, data)

func _start_continuous_explore(mouse_world_pos: Vector2) -> void:
	is_continuous_exploring = true
	explored_grids_in_drag.clear()
	
	var initial_grid = _find_grid_at_position(mouse_world_pos)
	if initial_grid != Vector2i(-1, -1):
		var key = _pos_to_key(initial_grid)
		explored_grids_in_drag[key] = true

func _end_continuous_explore() -> void:
	is_continuous_exploring = false
	explored_grids_in_drag.clear()

func _handle_continuous_explore(mouse_world_pos: Vector2) -> void:
	if not is_continuous_exploring:
		return
	
	var target_grid = _find_grid_at_position(mouse_world_pos)
	if target_grid == Vector2i(-1, -1):
		return
	
	var key = _pos_to_key(target_grid)
	if explored_grids_in_drag.has(key):
		return
	
	explored_grids_in_drag[key] = true
	var data = grid_manager.get_grid(target_grid)
	if data:
		grid_clicked.emit(target_grid, data)

func _find_grid_at_position(world_pos: Vector2) -> Vector2i:
	if not grid_manager:
		return Vector2i(-1, -1)
	
	var grid_pos = world_to_grid(world_pos)
	
	var check_positions = [
		grid_pos,
		grid_pos + Vector2i(-1, -1), grid_pos + Vector2i(0, -1), grid_pos + Vector2i(1, -1),
		grid_pos + Vector2i(-1, 0), grid_pos + Vector2i(1, 0),
		grid_pos + Vector2i(-1, 1), grid_pos + Vector2i(0, 1), grid_pos + Vector2i(1, 1)
	]
	
	for check_pos in check_positions:
		if not grid_manager.is_valid_position(check_pos): 
			continue
		
		var cell_center = iso_origin + iso_to_local(check_pos)
		var offset = world_pos - cell_center
		
		var diamond_test = abs(offset.x) / (cell_size.x * 0.5) + abs(offset.y) / (cell_size.y * 0.5)
		if diamond_test <= 1.0:
			return check_pos
	
	return Vector2i(-1, -1)

# ========== 辅助函数 ==========
func _set_grid_hovered_state(pos: Vector2i, state: bool) -> void:
	var key = _pos_to_key(pos)
	if grid_cells.has(key) and grid_cells[key].has_method("set_hovered"):
		grid_cells[key].set_hovered(state)

func _pos_to_key(pos: Vector2i) -> String:
	return "%d,%d" % [pos.x, pos.y]

func _key_to_pos(key: String) -> Vector2i:
	var p = key.split(",")
	return Vector2i(int(p[0]), int(p[1]))

func _reposition_all_grid_cells() -> void:
	for key in grid_cells:
		var pos = _key_to_pos(key)
		grid_cells[key].position = iso_origin + iso_to_local(pos)
	_clear_all_grid_cells()
	_create_all_grid_cells()

func _clear_all_grid_cells() -> void:
	for key in grid_cells:
		if is_instance_valid(grid_cells[key]):
			grid_cells[key].queue_free()
	grid_cells.clear()

# ========== 公共接口 ==========
func get_grid(pos: Vector2i) -> GridData:
	if not grid_manager:
		return null
	return grid_manager.get_grid(pos)

func set_grid(pos: Vector2i, grid_data: GridData) -> void:
	if not grid_manager:
		return
	
	grid_manager.set_grid(pos, grid_data)
	_update_grid_cell(pos)
	grid_state_changed.emit(pos, grid_data)

func _update_grid_cell(pos: Vector2i) -> void:
	var key = _pos_to_key(pos)
	if not grid_cells.has(key):
		return
	
	var cell = grid_cells[key]
	var grid_data = grid_manager.get_grid(pos)
	
	if cell and cell.has_method("set_grid_data"):
		cell.set_grid_data(grid_data)

func get_grid_manager() -> GridMapManager:
	return grid_manager

func set_grid_rule(rule: GridSystemRule) -> void:
	grid_rule = rule
	if grid_rule:
		if grid_manager:
			grid_rule.grid_manager = grid_manager
		elif not grid_map_initialized.is_connected(_on_rule_grid_manager_ready):
			grid_map_initialized.connect(_on_rule_grid_manager_ready)

func _on_rule_grid_manager_ready() -> void:
	if grid_rule and grid_manager:
		grid_rule.grid_manager = grid_manager

func get_grid_rule() -> GridSystemRule:
	return grid_rule

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	var iso_local = iso_to_local(grid_pos)
	return iso_origin + iso_local

func resize_grid_map(new_size: Vector2i) -> void:
	grid_size = new_size
	if grid_manager:
		grid_manager.resize_map(grid_size)
		_update_iso_origin()
		_initialize_grid_map()

# ========== 绘图 ==========
func _draw() -> void:
	if not show_grid_lines or not grid_manager or iso_origin == Vector2.ZERO: 
		return
	
	var color = Color(1.0, 1.0, 1.0, 0.2)
	
	var viewport = get_viewport()
	var viewport_size: Vector2
	if viewport:
		viewport_size = viewport.get_visible_rect().size
	else:
		viewport_size = get_viewport_rect().size
	
	var margin = max(cell_size.x, cell_size.y) * 3.0
	var visible_min_x = iso_origin.x - margin
	var visible_max_x = iso_origin.x + viewport_size.x + margin
	var visible_min_y = iso_origin.y - margin
	var visible_max_y = iso_origin.y + viewport_size.y + margin

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var center = iso_origin + iso_to_local(Vector2i(x, y))
			
			if center.x < visible_min_x or center.x > visible_max_x:
				continue
			if center.y < visible_min_y or center.y > visible_max_y:
				continue
				
			var hw = cell_size.x * 0.5
			var hh = cell_size.y * 0.5
			
			var top = center + Vector2(0, -hh)
			var right = center + Vector2(hw, 0)
			var bottom = center + Vector2(0, hh)
			var left = center + Vector2(-hw, 0)
			
			draw_line(top, right, color)
			draw_line(right, bottom, color)
			draw_line(bottom, left, color)
			draw_line(left, top, color)
