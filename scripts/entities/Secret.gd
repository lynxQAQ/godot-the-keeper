extends Node2D
class_name Secret

## 秘密可视化节点
## 显示为静态圆形，支持点击交互（拾起/放置）

# ========== 信号 ==========
## 秘密被点击
signal secret_clicked(secret: Secret)

# ========== 导出属性 ==========
## 半径（相对于网格大小，应该较小以避免干扰网格点击）
@export var radius: float = 8.0

## 颜色（金色）
@export var secret_color: Color = Color(1.0, 0.84, 0.0, 0.9)

## 边框颜色
@export var border_color: Color = Color(0.8, 0.6, 0.0, 1.0)

## 边框宽度
@export var border_width: float = 2.0

## 悬停时的高亮颜色
@export var hover_color: Color = Color(1.0, 1.0, 0.5, 1.0)

# ========== 内部属性 ==========
## 网格位置（使用setter检测放置）
var _grid_pos_internal: Vector2i = Vector2i(-1, -1)
var grid_pos: Vector2i:
	get:
		return _grid_pos_internal
	set(value):
		var old_pos = _grid_pos_internal
		_grid_pos_internal = value
		# 如果从无效位置变为有效位置，说明秘密被放置
		if old_pos == Vector2i(-1, -1) and value != Vector2i(-1, -1):
			print("秘密被放置")

## 世界位置
var world_pos: Vector2 = Vector2.ZERO

## 是否悬停
var is_hovered: bool = false

## Area2D节点引用（用于鼠标交互）
var area_2d: Area2D = null

## CollisionShape2D节点引用
var collision_shape: CollisionShape2D = null

# ========== 生命周期 ==========
func _ready():
	# 设置碰撞检测
	_setup_collision()
	
	# 连接Area2D信号
	_connect_area_signals()

# ========== 碰撞检测设置 ==========
func _setup_collision() -> void:
	# 从场景中获取Area2D（场景文件中已创建）
	area_2d = get_node_or_null("Area2D")
	if not area_2d:
		# 如果场景中没有，则创建（向后兼容）
		area_2d = Area2D.new()
		area_2d.name = "Area2D"
		area_2d.input_pickable = true
		area_2d.monitorable = true
		area_2d.monitoring = false
		area_2d.z_index = 10
		add_child(area_2d)
	else:
		# 确保属性正确设置
		area_2d.input_pickable = true
		area_2d.monitorable = true
		area_2d.z_index = 10
	
	# 从场景中获取CollisionShape2D（场景文件中已创建）
	collision_shape = area_2d.get_node_or_null("CollisionShape2D")
	if not collision_shape:
		# 如果场景中没有，则创建（向后兼容）
		collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		area_2d.add_child(collision_shape)
	
	# 更新碰撞形状的半径（使用脚本中的 radius 值）
	if collision_shape.shape:
		if collision_shape.shape is CircleShape2D:
			var circle_shape = collision_shape.shape as CircleShape2D
			circle_shape.radius = radius
		else:
			# 如果形状不是圆形，创建新的圆形形状
			var circle_shape = CircleShape2D.new()
			circle_shape.radius = radius
			collision_shape.shape = circle_shape
	else:
		# 如果没有形状，创建新的圆形形状
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = radius
		collision_shape.shape = circle_shape

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
	# 绘制圆形填充
	var draw_color = hover_color if is_hovered else secret_color
	draw_circle(Vector2.ZERO, radius, draw_color)
	
	# 绘制边框
	if border_width > 0:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, border_color, border_width)

# ========== 位置设置 ==========
## 设置网格位置和世界位置（避免与父类 set_position 冲突）
func set_secret_position(grid_position: Vector2i, world_position: Vector2) -> void:
	grid_pos = grid_position
	world_pos = world_position
	position = world_position

## 获取网格位置
func get_grid_position() -> Vector2i:
	return _grid_pos_internal

## 获取世界位置
func get_world_position() -> Vector2:
	return world_pos

# ========== 鼠标事件处理 ==========
func _on_mouse_entered() -> void:
	is_hovered = true
	queue_redraw()

func _on_mouse_exited() -> void:
	is_hovered = false
	queue_redraw()

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("秘密被拾起")
			secret_clicked.emit(self)
