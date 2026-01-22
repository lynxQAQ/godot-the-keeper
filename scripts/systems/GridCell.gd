extends Node2D
class_name GridCell

## 网格单元可视化组件（等距菱形）
## 表示单个网格的视觉表现，使用菱形绘制和Area2D碰撞检测

# ========== 信号 ==========
## 鼠标进入单元格
signal cell_mouse_entered(cell: GridCell)
## 鼠标离开单元格
signal cell_mouse_exited(cell: GridCell)
## 单元格被点击
signal cell_clicked(cell: GridCell, button_index: int)

# ========== 导出属性 ==========
## 单元格大小（等距网格使用2:1比例，例如64x32）
@export var cell_size: Vector2 = Vector2(64, 32)

## 默认颜色（未开垦）
@export var default_color: Color = Color(0.3, 0.3, 0.3, 0.5)

## 已开垦颜色
@export var explored_color: Color = Color(0.5, 0.5, 0.3, 0.7)

## 迷宫颜色
@export var maze_color: Color = Color(0.3, 0.1, 0.1, 0.8)

## 悬停颜色
@export var hover_color: Color = Color(1.0, 1.0, 0.0, 0.3)

## 选中颜色
@export var selected_color: Color = Color(0.0, 1.0, 0.0, 0.5)

## 边框颜色
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.2)

## 边框宽度
@export var border_width: float = 1.0


# ========== 内部属性 ==========
## 当前网格数据
var grid_data: GridData = null

## 是否悬停
var is_hovered: bool = false

## 是否选中
var is_selected: bool = false

## 当前显示颜色
var current_color: Color = Color(0.3, 0.3, 0.3, 0.5)

## Area2D节点引用（用于鼠标交互）
var area_2d: Area2D = null

## CollisionPolygon2D节点引用
var collision_polygon: CollisionPolygon2D = null

## 菱形顶点（局部坐标，相对于节点中心）
var diamond_points: PackedVector2Array = []

# ========== 生命周期 ==========
func _ready():
	# 初始化菱形顶点（相对于节点中心）
	_update_diamond_points()
	
	# 设置Area2D和碰撞多边形
	_setup_collision()
	
	# 连接Area2D信号
	_connect_area_signals()
	
	# 初始化颜色
	current_color = default_color

# ========== 菱形几何 ==========
## 更新菱形顶点（局部坐标）
## 菱形定义：
## - 左：   (-tile_width/2, 0)
## - 上：   (0, -tile_height/2)
## - 右：   (tile_width/2, 0)
## - 下：   (0, tile_height/2)
func _update_diamond_points() -> void:
	var half_width = cell_size.x / 2.0
	var half_height = cell_size.y / 2.0
	
	diamond_points = PackedVector2Array([
		Vector2(0, -half_height),      # 上
		Vector2(half_width, 0),        # 右
		Vector2(0, half_height),       # 下
		Vector2(-half_width, 0)        # 左
	])

## 设置碰撞检测
func _setup_collision() -> void:
	# 查找或创建Area2D
	area_2d = get_node_or_null("Area2D")
	if not area_2d:
		area_2d = Area2D.new()
		area_2d.name = "Area2D"
		area_2d.input_pickable = true  # 允许接收输入事件
		add_child(area_2d)
	else:
		area_2d.input_pickable = true  # 确保可以接收输入事件
	
	# 查找或创建CollisionPolygon2D
	collision_polygon = area_2d.get_node_or_null("CollisionPolygon2D")
	if not collision_polygon:
		collision_polygon = CollisionPolygon2D.new()
		collision_polygon.name = "CollisionPolygon2D"
		area_2d.add_child(collision_polygon)
	
	# 设置碰撞多边形为菱形
	collision_polygon.polygon = diamond_points

## 连接Area2D信号
func _connect_area_signals() -> void:
	if not area_2d:
		return
	
	# 连接鼠标进入和离开信号
	if not area_2d.mouse_entered.is_connected(_on_mouse_entered):
		area_2d.mouse_entered.connect(_on_mouse_entered)
	if not area_2d.mouse_exited.is_connected(_on_mouse_exited):
		area_2d.mouse_exited.connect(_on_mouse_exited)
	if not area_2d.input_event.is_connected(_on_input_event):
		area_2d.input_event.connect(_on_input_event)

# ========== 绘制 ==========
func _draw() -> void:
	# 绘制菱形填充
	draw_colored_polygon(diamond_points, current_color)
	
	# 绘制菱形边框
	if border_width > 0:
		draw_polyline(diamond_points, border_color, border_width, true)

# ========== 设置网格数据 ==========
## 设置网格数据并更新显示
func set_grid_data(data: GridData) -> void:
	grid_data = data
	_update_visual()

## 更新视觉表现
func _update_visual() -> void:
	if not grid_data:
		current_color = default_color
		queue_redraw()
		return
	
	# 根据网格类型设置基础颜色
	match grid_data.grid_type:
		Constants.GRID_TYPE_UNEXPLORED:
			# 未开垦网格：根据等级调整颜色
			current_color = _get_cocoon_level_color(grid_data.cocoon_level)
		Constants.GRID_TYPE_EXPLORED:
			current_color = explored_color
		Constants.GRID_TYPE_MAZE:
			current_color = maze_color
		_:
			current_color = default_color
	
	# 应用悬停和选中效果
	if is_selected:
		current_color = current_color.blend(selected_color)
	elif is_hovered:
		current_color = current_color.blend(hover_color)
	
	queue_redraw()

## 根据真理之茧等级获取颜色
## 等级越高，颜色越深，透明度越高
func _get_cocoon_level_color(level: int) -> Color:
	if level <= 0:
		# 等级0：默认颜色（较浅）
		return default_color
	
	# 等级大于0：根据等级调整颜色深度和透明度
	# 基础颜色（深紫色/深蓝色调）
	var base_color = Color(0.2, 0.1, 0.3, 0.6)  # 深紫色，透明度0.6
	
	# 等级越高，颜色越深，透明度越高
	# 使用等级作为系数，最大等级假设为10
	var max_level = 10.0
	var level_factor = min(float(level) / max_level, 1.0)
	
	# 颜色深度：等级越高，RGB值越低（更暗）
	var color_multiplier = 1.0 - (level_factor * 0.5)  # 最多变暗50%
	
	# 透明度：等级越高，透明度越高（更不透明）
	var alpha = 0.5 + (level_factor * 0.5)  # 从0.5到1.0
	
	return Color(
		base_color.r * color_multiplier,
		base_color.g * color_multiplier,
		base_color.b * color_multiplier,
		alpha
	)

# ========== 状态设置 ==========
## 设置悬停状态
func set_hovered(hovered: bool) -> void:
	is_hovered = hovered
	_update_visual()

## 设置选中状态
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visual()

## 设置高亮（用于预览等）
func set_highlighted(highlighted: bool, highlight_color: Color = Color.YELLOW) -> void:
	if highlighted:
		current_color = current_color.blend(highlight_color)
		queue_redraw()
	else:
		_update_visual()

## 设置单元格大小（用于动态调整）
func set_cell_size(new_size: Vector2) -> void:
	cell_size = new_size
	_update_diamond_points()
	if collision_polygon:
		collision_polygon.polygon = diamond_points
	queue_redraw()

# ========== 鼠标事件处理 ==========
func _on_mouse_entered() -> void:
	is_hovered = true
	_update_visual()
	cell_mouse_entered.emit(self)

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_visual()
	cell_mouse_exited.emit(self)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		cell_clicked.emit(self, event.button_index)
