extends Resource
class_name TruthElementData

## 真理要素数据类
## 表示单个真理要素的数据，包含位置、状态等信息

# ========== 基础属性 ==========
## 唯一标识符
@export var id: String = ""

## 网格位置
@export var grid_pos: Vector2i = Vector2i.ZERO

## 世界位置（用于平滑移动）
@export var world_pos: Vector2 = Vector2.ZERO

## 真理要素状态（使用Constants中的常量）
## 0: 活跃, 1: 沉睡, 2: 寂灭, 3: 升华
@export var state: int = Constants.TRUTH_STATE_ACTIVE

## 序列（I-V，对应1-5）
@export var serial: int = 1

## 密度（0.0-1.0）
@export var density: float = 0.5

## 因果属性（0-100）
@export var causality: int = 0

## 物质属性（0-100）
@export var material: int = 0

## 超然属性（0-100）
@export var transcendence: int = 0

## 移动速度（网格/秒）
@export var move_speed: float = 0.5

## 移动目标位置（网格坐标）
@export var target_grid_pos: Vector2i = Vector2i(-1, -1)

## 移动冷却时间（秒）
@export var move_cooldown: float = 2.0

## 上次移动时间
var last_move_time: float = 0.0

# ========== 构造函数 ==========
func _init(pos: Vector2i = Vector2i.ZERO, serial_param: int = 1, density_param: float = 0.5, causality_param: int = 0, material_param: int = 0, transcendence_param: int = 0):
	grid_pos = pos
	world_pos = Vector2.ZERO
	state = Constants.TRUTH_STATE_ACTIVE
	serial = serial_param
	density = density_param
	causality = causality_param
	material = material_param
	transcendence = transcendence_param
	move_speed = 0.5
	target_grid_pos = Vector2i(-1, -1)
	move_cooldown = 2.0
	last_move_time = 0.0
	id = _generate_id()

## 生成唯一ID
func _generate_id() -> String:
	return "truth_element_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 10000)

# ========== 状态管理 ==========
## 设置状态
func set_state(new_state: int) -> void:
	state = new_state

## 检查是否可以移动
func can_move(current_time: float) -> bool:
	if state != Constants.TRUTH_STATE_ACTIVE:
		return false
	# 如果从未移动过，允许移动
	if last_move_time == 0.0:
		return true
	return (current_time - last_move_time) >= move_cooldown

## 更新移动时间
func update_move_time(current_time: float) -> void:
	last_move_time = current_time

## 获取最高属性类型（0: 因果, 1: 物质, 2: 超然）
func get_dominant_attribute() -> int:
	if causality >= material and causality >= transcendence:
		return 0  # 因果
	elif material >= transcendence:
		return 1  # 物质
	else:
		return 2  # 超然

# ========== 序列化接口 ==========
## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"grid_pos": {"x": grid_pos.x, "y": grid_pos.y},
		"world_pos": {"x": world_pos.x, "y": world_pos.y},
		"state": state,
		"serial": serial,
		"density": density,
		"causality": causality,
		"material": material,
		"transcendence": transcendence,
		"move_speed": move_speed,
		"target_grid_pos": {"x": target_grid_pos.x, "y": target_grid_pos.y},
		"move_cooldown": move_cooldown,
		"last_move_time": last_move_time
	}

## 从字典反序列化
func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	
	if data.has("grid_pos"):
		var pos_dict = data["grid_pos"]
		grid_pos = Vector2i(pos_dict.get("x", 0), pos_dict.get("y", 0))
	
	if data.has("world_pos"):
		var world_dict = data["world_pos"]
		world_pos = Vector2(world_dict.get("x", 0.0), world_dict.get("y", 0.0))
	
	state = data.get("state", Constants.TRUTH_STATE_ACTIVE)
	serial = data.get("serial", 1)
	density = data.get("density", 0.5)
	causality = data.get("causality", 0)
	material = data.get("material", 0)
	transcendence = data.get("transcendence", 0)
	move_speed = data.get("move_speed", 0.5)
	
	if data.has("target_grid_pos"):
		var target_dict = data["target_grid_pos"]
		target_grid_pos = Vector2i(target_dict.get("x", -1), target_dict.get("y", -1))
	
	move_cooldown = data.get("move_cooldown", 2.0)
	last_move_time = data.get("last_move_time", 0.0)

## 复制数据
func duplicate_data() -> TruthElementData:
	var new_data = TruthElementData.new(grid_pos, serial, density)
	new_data.from_dict(to_dict())
	return new_data
