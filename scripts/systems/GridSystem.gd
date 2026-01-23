extends Node2D
class_name GridSystem

## 可复用网格系统
## 管理网格地图的可视化和交互
## 适配 SubViewport 架构

# 核心设计：数据与表现分离
# GridMapManager：纯数据层，存储网格状态
# GridCell：视觉表现（Sprite/等距瓦片）
# GridSystem：协调两者 + 处理输入交互

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

## 网格系统规则（用于区分表里世界的不同规则）
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
	# 确保 GridSystem 节点的 position 为 (0,0)，避免坐标偏移
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
# 在等距（Isometric）坐标系下，计算一个“视觉原点 iso_origin”，让整个网格在当前视口中居中显示，并据此创建并摆放所有网格单元。
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
	
	# 计算网格整体的物理宽高（世界坐标系下） 计算整个等距网格的“物理边界”
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
	# ... (保留原有逻辑，只要位置计算正确即可) ...
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
	
	# 这里依然可以保留信号连接，作为备用交互方式
	# 但主要的交互我们将通过 Direct Math 在 _input 中处理
	
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
		DebugLogger.debug("GridSystem: _input 收到事件但 camera 为空", "GridSystem")
		return
	
	# 添加调试日志（仅记录鼠标按钮事件，不记录鼠标移动）
	if event is InputEventMouseButton:
		var mb_event = event as InputEventMouseButton
		if mb_event.button_index == MOUSE_BUTTON_LEFT and mb_event.pressed:
			DebugLogger.debug("GridSystem: _input 收到左键按下事件 - enable_interaction: " + str(enable_interaction) + ", is_dragging: " + str(is_dragging) + ", enable_drag: " + str(enable_drag) + ", space_pressed: " + str(Input.is_key_pressed(KEY_SPACE)), "GridSystem")
	
	# 1. 处理拖拽 (Pan)
	var was_dragging_before_pan = is_dragging
	if enable_drag:
		_handle_pan_input(event)
		if was_dragging_before_pan != is_dragging:
			DebugLogger.debug("GridSystem: 拖拽状态改变 - is_dragging: " + str(was_dragging_before_pan) + " -> " + str(is_dragging), "GridSystem")
	
	# 2. 处理缩放 (Zoom)
	if enable_zoom:
		_handle_zoom_input(event)
	
	# 3. 处理交互 (Hover/Click/Continuous Explore) - 仅在未拖拽时
	if not enable_interaction:
		DebugLogger.debug("GridSystem: enable_interaction 为 false，跳过交互处理", "GridSystem")
	elif is_dragging:
		DebugLogger.debug("GridSystem: is_dragging 为 true，跳过交互处理", "GridSystem")
	elif enable_interaction and not is_dragging:
		# 检查鼠标是否在视口范围内
		var mouse_in_viewport = _is_mouse_in_viewport()
		DebugLogger.debug("GridSystem: _is_mouse_in_viewport() = " + str(mouse_in_viewport), "GridSystem")
		if not mouse_in_viewport:
			DebugLogger.debug("GridSystem: 鼠标不在视口内，跳过处理", "GridSystem")
			# 鼠标移出视口，清除 hover 状态和连续开垦状态
			if hovered_grid != Vector2i(-1, -1):
				_set_grid_hovered_state(hovered_grid, false)
				hovered_grid = Vector2i(-1, -1)
			if is_continuous_exploring:
				_end_continuous_explore()
		else:
			# 鼠标在视口内，正常处理 hover 和点击
			DebugLogger.debug("GridSystem: 鼠标在视口内，处理事件类型: " + str(event.get_class()), "GridSystem")
			if event is InputEventMouseMotion:
				# 使用 get_global_mouse_position() 获取正确的世界坐标（自动处理 Camera 变换）
				var mouse_world = get_global_mouse_position()
				_handle_hover_logic(mouse_world)
				# 如果正在连续开垦，检查当前网格
				if is_continuous_exploring:
					_handle_continuous_explore(mouse_world)
			elif event is InputEventMouseButton:
				var mb_event = event as InputEventMouseButton
				DebugLogger.debug("GridSystem: 处理鼠标按钮事件 - button_index: " + str(mb_event.button_index) + ", pressed: " + str(mb_event.pressed), "GridSystem")
				if mb_event.button_index == MOUSE_BUTTON_LEFT:
					if mb_event.pressed:
						# 左键按下：开始连续开垦模式
						var mouse_world = get_global_mouse_position()
						DebugLogger.debug("GridSystem: 左键按下，开始处理点击 - mouse_world: " + str(mouse_world), "GridSystem")
						_start_continuous_explore(mouse_world)
						# 同时处理点击逻辑（立即开垦当前网格）
						_handle_click_logic(event, mouse_world)
					else:
						# 左键松开：结束连续开垦模式
						_end_continuous_explore()
			else:
				DebugLogger.debug("GridSystem: 事件类型不是鼠标移动或按钮: " + str(event.get_class()), "GridSystem")
	elif is_dragging:
		# 拖拽时清除 hover 状态和连续开垦状态
		if hovered_grid != Vector2i(-1, -1):
			_set_grid_hovered_state(hovered_grid, false)
			hovered_grid = Vector2i(-1, -1)
		if is_continuous_exploring:
			_end_continuous_explore()

## 检查鼠标是否在视口范围内
func _is_mouse_in_viewport() -> bool:
	var parent = get_parent()
	if parent is Control:
		# 如果 GridSystem 是 Control 的子节点，检查鼠标是否在 Control 的 rect 内
		var mouse_local = parent.get_local_mouse_position()
		var control_rect = Rect2(Vector2.ZERO, parent.size)
		return control_rect.has_point(mouse_local)
	else:
		# 如果 GridSystem 不是 Control 的子节点，检查鼠标是否在视口内
		var viewport = get_viewport()
		if not viewport:
			return false
		var mouse_screen = viewport.get_mouse_position()
		var viewport_rect = Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
		return viewport_rect.has_point(mouse_screen)

## 获取鼠标的世界坐标（适配 SubViewport 架构）
func _get_mouse_world_position() -> Vector2:
	# 在 SubViewport 中，需要正确获取鼠标坐标
	var viewport = get_viewport()
	if not viewport:
		return get_global_mouse_position()
	
	# 关键修复：如果 GridSystem 是 Control 节点的子节点（如 SurfaceWorldGrid/InnerWorldGrid）
	# 需要使用 Control 的 get_local_mouse_position() 来获取相对于 Control 的坐标
	# 然后转换为 GridSystem 的世界坐标
	var parent = get_parent()
	if parent is Control:
		# Control 的 get_local_mouse_position() 返回相对于 Control 的坐标
		# 这个坐标可以直接作为 GridSystem 的本地坐标（因为 GridSystem 是 Control 的直接子节点）
		# Control 的坐标空间和 Node2D 的坐标空间是独立的，但 GridSystem 作为子节点，
		# Control 的 (0,0) 对应 GridSystem 的世界坐标 (0,0)
		var control_local = parent.get_local_mouse_position()
		# 将 Control 的本地坐标直接作为 GridSystem 的本地坐标
		# 然后使用 canvas_transform 转换为相机世界坐标
		# 注意：这里不需要考虑 GridSystem 的 position，因为 canvas_transform 已经考虑了相机的变换
		return viewport.canvas_transform.affine_inverse() * control_local
	else:
		# 如果 GridSystem 不是 Control 的子节点，使用视口的鼠标位置
		var mouse_screen = viewport.get_mouse_position()
		# 使用 canvas_transform 的逆变换将屏幕坐标转换为世界坐标
		# 这考虑了相机的 zoom、position 等变换
		return viewport.canvas_transform.affine_inverse() * mouse_screen

# ========== 修复后的拖拽逻辑 ==========
var drag_start_mouse_world: Vector2 = Vector2.ZERO
var drag_start_mouse_pos: Vector2 = Vector2.ZERO  # 拖拽开始时的鼠标位置（屏幕坐标）
var drag_start_camera_pos: Vector2 = Vector2.ZERO

# ========== 修复后的拖拽逻辑（锚点跟随版） ==========
func _handle_pan_input(event: InputEvent) -> void:
	# 1. 监测空格键松开：任何时候松开空格都应停止拖拽
	if event is InputEventKey and event.keycode == KEY_SPACE:
		if not event.pressed and is_dragging:
			is_dragging = false
			# 如果松开空格时左键还按着，可以开始连续开垦
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and enable_interaction:
				var mouse_world = get_global_mouse_position()
				_start_continuous_explore(mouse_world)
	
	# 2. 监测鼠标按键
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 按住空格 + 左键按下 = 开始拖拽
			if event.pressed and Input.is_key_pressed(KEY_SPACE):
				is_dragging = true
				# 关键点：记录“起飞前”的坐标状态
				# get_mouse_position() 获取的是 Viewport 内的坐标，非常稳定
				drag_start_mouse_pos = get_viewport().get_mouse_position()
				drag_start_camera_pos = camera.position
			else:
				# 左键松开 = 停止拖拽和连续开垦
				if not event.pressed:
					is_dragging = false
					if is_continuous_exploring:
						_end_continuous_explore()
	
	# 3. 处理拖拽移动（仅在 is_dragging 为真时）
	if event is InputEventMouseMotion and is_dragging:
		# 获取当前鼠标位置
		var current_mouse_pos = get_viewport().get_mouse_position()
		
		# 计算鼠标移动了多少距离
		var diff = current_mouse_pos - drag_start_mouse_pos
		
		# 核心公式：
		# 目标相机位置 = 初始相机位置 - (鼠标移动距离 / 缩放倍率)
		# 比如鼠标向右移了100px，相机就应该向左移100px（让画面看起来向右动）
		camera.position = drag_start_camera_pos - diff / camera.zoom.x

# ========== 修复后的缩放逻辑 ==========
func _handle_zoom_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		# 按下ctrl
		#if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
			#if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				#_set_zoom(camera.zoom.x + zoom_step)
			#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				#_set_zoom(camera.zoom.x - zoom_step)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(camera.zoom.x + zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(camera.zoom.x - zoom_step)

func _set_zoom(target_zoom: float) -> void:
	target_zoom = clamp(target_zoom, min_zoom, max_zoom)
	if target_zoom == camera.zoom.x: return

	# 1. 获取缩放前鼠标指向的世界坐标（使用 get_global_mouse_position() 自动处理 Camera 变换）
	var mouse_world_before = get_global_mouse_position()
	
	# 2. 应用缩放
	camera.zoom = Vector2(target_zoom, target_zoom)
	
	# 3. 获取缩放后鼠标指向的新世界坐标（因为 zoom 变了，这个值会变）
	var mouse_world_after = get_global_mouse_position()
	
	# 4. 移动相机，抵消坐标变化，实现"以鼠标为中心缩放"
	# 公式：相机需要移动的距离 = 缩放导致的偏移差值
	camera.position -= (mouse_world_after - mouse_world_before)

# ========== 交互逻辑 (基于直接数学计算) ==========
func _handle_hover_logic(mouse_world_pos: Vector2) -> void:
	var target_grid = _find_grid_at_position(mouse_world_pos)
	
	if target_grid != hovered_grid:
		# 退出旧的
		if hovered_grid != Vector2i(-1, -1):
			_set_grid_hovered_state(hovered_grid, false)
		
		# 进入新的
		if target_grid != Vector2i(-1, -1):
			hovered_grid = target_grid
			_set_grid_hovered_state(hovered_grid, true)
			var data = grid_manager.get_grid(target_grid)
			grid_hovered.emit(target_grid, data)
		else:
			hovered_grid = Vector2i(-1, -1)

func _handle_click_logic(event: InputEventMouseButton, mouse_world_pos: Vector2) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		# 先检查是否点击了 Area2D（如 Secret）
		# 使用物理查询检查鼠标位置是否有 Area2D
		var space_state = get_world_2d().direct_space_state
		if space_state:
			var query = PhysicsPointQueryParameters2D.new()
			query.position = mouse_world_pos
			query.collision_mask = 0xFFFFFFFF
			var results = space_state.intersect_point(query)
			
			# 检查是否有可交互的 Area2D（input_pickable = true）
			# 并且鼠标确实在 Area2D 的碰撞形状内
			for result in results:
				if result.collider is Area2D:
					var area = result.collider as Area2D
					if area.input_pickable:
						# 获取 Area2D 的父节点（可能是 Secret）
						var area_parent = area.get_parent()
						if area_parent and area_parent.has_method("get_grid_position"):
							# 这可能是 Secret，检查鼠标是否真的在 Secret 的圆形范围内
							var secret_pos = area_parent.global_position
							var distance = mouse_world_pos.distance_to(secret_pos)
							# 如果 Secret 有 radius 属性，使用它；否则使用默认值
							var secret_radius = 8.0
							if area_parent.has("radius"):
								secret_radius = area_parent.radius
							
							# 只有当鼠标在 Secret 的圆形范围内时才拦截
							if distance <= secret_radius:
								# 点击了 Secret，手动触发 Secret 的点击信号
								# 因为 _input 事件会阻止 Area2D 的 input_event 信号触发
								if area_parent is Secret:
									area_parent.secret_clicked.emit(area_parent)
									return
						else:
							# 其他类型的 Area2D，直接拦截（可能是其他交互对象）
							return
		
		# 如果没有点击到可交互的 Area2D，处理网格点击
		var target_grid = _find_grid_at_position(mouse_world_pos)
		if target_grid != Vector2i(-1, -1):
			selected_grid = target_grid
			var data = grid_manager.get_grid(target_grid)
			DebugLogger.debug("GridSystem: 点击网格 " + str(target_grid) + " - grid_type: " + str(data.grid_type if data else "null") + ", is_unexplored: " + str(data.is_unexplored() if data else "null"), "GridSystem")
			grid_clicked.emit(target_grid, data)
		else:
			DebugLogger.warning("GridSystem: 未找到有效网格位置", "GridSystem")

## 开始连续开垦模式
func _start_continuous_explore(mouse_world_pos: Vector2) -> void:
	is_continuous_exploring = true
	explored_grids_in_drag.clear()
	
	# 记录初始网格（如果存在）
	var initial_grid = _find_grid_at_position(mouse_world_pos)
	if initial_grid != Vector2i(-1, -1):
		var key = _pos_to_key(initial_grid)
		explored_grids_in_drag[key] = true

## 结束连续开垦模式
func _end_continuous_explore() -> void:
	is_continuous_exploring = false
	explored_grids_in_drag.clear()

## 处理连续开垦（在鼠标移动时调用）
func _handle_continuous_explore(mouse_world_pos: Vector2) -> void:
	if not is_continuous_exploring:
		return
	
	var target_grid = _find_grid_at_position(mouse_world_pos)
	if target_grid == Vector2i(-1, -1):
		return
	
	# 检查是否已经处理过这个网格
	var key = _pos_to_key(target_grid)
	if explored_grids_in_drag.has(key):
		return
	
	# 标记为已处理
	explored_grids_in_drag[key] = true
	
	# 触发点击事件（让SurfaceWorldGrid/InnerWorldGrid处理开垦逻辑）
	var data = grid_manager.get_grid(target_grid)
	if data:
		grid_clicked.emit(target_grid, data)

## 菱形检测算法 (完全保留你的逻辑，只是入参明确为世界坐标)
func _find_grid_at_position(world_pos: Vector2) -> Vector2i:
	var grid_pos = world_to_grid(world_pos)
	
	# 九宫格检测优化
	var check_positions = [
		grid_pos,
		grid_pos + Vector2i(-1, -1), grid_pos + Vector2i(0, -1), grid_pos + Vector2i(1, -1),
		grid_pos + Vector2i(-1, 0), grid_pos + Vector2i(1, 0),
		grid_pos + Vector2i(-1, 1), grid_pos + Vector2i(0, 1), grid_pos + Vector2i(1, 1)
	]
	
	for check_pos in check_positions:
		if not grid_manager.is_valid_position(check_pos): continue
		
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
	_clear_all_grid_cells() # 简单起见，或者你可以只更新 position
	_create_all_grid_cells()

func _clear_all_grid_cells() -> void:
	for key in grid_cells:
		if is_instance_valid(grid_cells[key]):
			grid_cells[key].queue_free()
	grid_cells.clear()

# ========== 公共接口 ==========
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

## 获取网格管理器引用
func get_grid_manager() -> GridMapManager:
	return grid_manager

## 设置网格系统规则
func set_grid_rule(rule: GridSystemRule) -> void:
	grid_rule = rule
	if grid_rule:
		# 如果grid_manager已初始化，立即设置
		if grid_manager:
			grid_rule.grid_manager = grid_manager
		# 否则等待grid_map_initialized信号
		elif not grid_map_initialized.is_connected(_on_rule_grid_manager_ready):
			grid_map_initialized.connect(_on_rule_grid_manager_ready)

## 当网格地图初始化完成时，更新规则的grid_manager引用
func _on_rule_grid_manager_ready() -> void:
	if grid_rule and grid_manager:
		grid_rule.grid_manager = grid_manager

## 获取网格系统规则
func get_grid_rule() -> GridSystemRule:
	return grid_rule

## 网格坐标转换为世界坐标
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	var iso_local = iso_to_local(grid_pos)
	return iso_origin + iso_local

## 重新初始化网格地图（当 grid_size 改变时调用）
func resize_grid_map(new_size: Vector2i) -> void:
	grid_size = new_size
	if grid_manager:
		grid_manager.resize_map(grid_size)
		_update_iso_origin()
		_initialize_grid_map()

# ========== 绘图 (Grid Lines) ==========
func _draw() -> void:
	if not show_grid_lines or not grid_manager or iso_origin == Vector2.ZERO: 
		return
	
	var color = Color(1.0, 1.0, 1.0, 0.2)
	
	# 获取视口尺寸用于视锥剔除
	var viewport = get_viewport()
	var viewport_size: Vector2
	if viewport:
		viewport_size = viewport.get_visible_rect().size
	else:
		viewport_size = get_viewport_rect().size
	
	# 扩大一点渲染范围防止边缘闪烁
	var margin = max(cell_size.x, cell_size.y) * 3.0
	# 计算可见区域（基于 iso_origin 的位置）
	# iso_origin 是网格(0,0)在本地坐标系中的位置
	var visible_min_x = iso_origin.x - margin
	var visible_max_x = iso_origin.x + viewport_size.x + margin
	var visible_min_y = iso_origin.y - margin
	var visible_max_y = iso_origin.y + viewport_size.y + margin

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			# 计算网格中心位置（相对于GridSystem节点的本地坐标）
			# iso_origin 已经考虑了视口居中的偏移
			var center = iso_origin + iso_to_local(Vector2i(x, y))
			
			# 简单的视锥剔除：如果中心点不在可见范围内，不绘制
			if center.x < visible_min_x or center.x > visible_max_x:
				continue
			if center.y < visible_min_y or center.y > visible_max_y:
				continue
				
			var hw = cell_size.x * 0.5
			var hh = cell_size.y * 0.5
			
			# 计算菱形的四个顶点（相对于GridSystem节点的本地坐标）
			var top = center + Vector2(0, -hh)
			var right = center + Vector2(hw, 0)
			var bottom = center + Vector2(0, hh)
			var left = center + Vector2(-hw, 0)
			
			# 绘制菱形边框
			draw_line(top, right, color)
			draw_line(right, bottom, color)
			draw_line(bottom, left, color)
			draw_line(left, top, color)
