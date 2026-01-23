extends Node2D
class_name TruthElement

## 真理要素可视化节点
## 显示为圆形，能够在网格上移动

# ========== 导出属性 ==========
## 真理要素数据
var element_data: TruthElementData = null

## 半径
@export var radius: float = 8.0

## 颜色（根据序列和状态变化）
@export var element_color: Color = Color(0.5, 0.3, 0.8, 0.8)

## 移动动画时长（秒）
@export var move_duration: float = 1.0

# ========== 内部属性 ==========
## 是否正在移动
var is_moving: bool = false

## 移动起始位置
var move_start_pos: Vector2 = Vector2.ZERO

## 移动目标位置
var move_target_pos: Vector2 = Vector2.ZERO

## 移动开始时间
var move_start_time: float = 0.0

# ========== 生命周期 ==========
func _ready():
	pass

func _process(delta: float):
	if is_moving:
		_update_movement(delta)

# ========== 初始化 ==========
## 设置真理要素数据
func set_element_data(data: TruthElementData) -> void:
	element_data = data
	if element_data:
		# 根据序列设置颜色
		_update_color()
		# 设置初始位置
		position = element_data.world_pos

## 更新颜色（根据最高属性）
func _update_color() -> void:
	if not element_data:
		return
	
	# 根据最高属性设置颜色
	var dominant_attr = element_data.get_dominant_attribute()
	match dominant_attr:
		0:  # 因果 - 蓝色系
			element_color = Color(0.3, 0.5, 0.9, 0.8)  # 蓝色
		1:  # 物质 - 红色系
			element_color = Color(0.9, 0.3, 0.3, 0.8)  # 红色
		2:  # 超然 - 紫色系
			element_color = Color(0.7, 0.3, 0.9, 0.8)  # 紫色
		_:
			element_color = Color(0.5, 0.5, 0.5, 0.8)  # 灰色（默认）

	# 根据状态调整颜色
	match element_data.state:
		Constants.TRUTH_STATE_SLEEPING:
			element_color = element_color.darkened(0.4)
		Constants.TRUTH_STATE_EXTINCT:
			element_color = Color(0.2, 0.2, 0.2, 0.5)
		Constants.TRUTH_STATE_SUBLIMATED:
			element_color = element_color.lightened(0.4)

## 开始移动到目标位置
func start_move_to(target_world_pos: Vector2) -> void:
	if is_moving:
		return
	
	move_start_pos = position
	move_target_pos = target_world_pos
	move_start_time = 0.0
	is_moving = true

## 更新移动
func _update_movement(delta: float) -> void:
	if not is_moving:
		return
	
	# 累计移动时间
	move_start_time += delta
	
	# 计算移动进度（0.0-1.0）
	var progress = min(move_start_time / move_duration, 1.0)
	
	# 使用平滑插值
	var t = _ease_in_out_quad(progress)
	position = move_start_pos.lerp(move_target_pos, t)
	
	# 更新数据中的世界位置
	if element_data:
		element_data.world_pos = position
	
	# 移动完成
	if progress >= 1.0:
		is_moving = false
		position = move_target_pos
		if element_data:
			element_data.world_pos = position

## 缓动函数（二次缓入缓出）
func _ease_in_out_quad(t: float) -> float:
	if t < 0.5:
		return 2.0 * t * t
	else:
		return -1.0 + (4.0 - 2.0 * t) * t

# ========== 绘制 ==========
func _draw() -> void:
	# 绘制圆形
	draw_circle(Vector2.ZERO, radius, element_color)
	
	# 绘制边框
	var border_color = element_color.darkened(0.3)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, border_color, 2.0)

## 设置网格位置（立即移动到目标位置）
func set_grid_position(grid_pos: Vector2i, world_pos: Vector2) -> void:
	if element_data:
		element_data.grid_pos = grid_pos
		element_data.world_pos = world_pos
	
	position = world_pos
	is_moving = false

## 刷新状态显示
func refresh_state() -> void:
	_update_color()
	queue_redraw()
