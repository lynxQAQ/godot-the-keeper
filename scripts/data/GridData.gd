extends Resource
class_name GridData

## 网格数据类
## 表示单个网格单元的数据，包含坐标、类型、状态等信息

# ========== 基础属性 ==========
## 网格坐标
@export var grid_pos: Vector2i = Vector2i.ZERO

## 网格类型（使用Constants中的常量）
## 0: 未开垦, 1: 已开垦, 2: 迷宫
@export var grid_type: int = Constants.GRID_TYPE_UNEXPLORED

## 网格状态（扩展状态，用于特殊标记）
## 例如：是否有秘密、是否有构造体等
@export var state: Dictionary = {}

## 是否可通行（用于寻路）
@export var is_passable: bool = true

## 是否可见（用于视野系统）
@export var is_visible: bool = false

## 是否已探索
@export var is_explored: bool = false

# ========== 表世界特有属性 ==========
## 是否有迷宫
@export var has_maze: bool = false

## 是否有秘密位置
@export var has_secret: bool = false

## 是否有构造体
@export var has_construct: bool = false

# ========== 里世界特有属性 ==========
## 是否有真理之茧
@export var has_truth_cocoon: bool = false

## 真理要素密度（0.0-1.0）
@export var truth_density: float = 0.0

## 网格活跃度（0.0-1.0）
@export var activity_level: float = 0.0

# ========== 构造函数 ==========
func _init(pos: Vector2i = Vector2i.ZERO, type: int = Constants.GRID_TYPE_UNEXPLORED):
	grid_pos = pos
	grid_type = type
	state = {}
	is_passable = true
	is_visible = false
	is_explored = false

# ========== 网格类型转换 ==========
## 设置为未开垦网格
func set_unexplored() -> void:
	grid_type = Constants.GRID_TYPE_UNEXPLORED
	is_explored = false
	is_passable = true

## 设置为已开垦网格
func set_explored() -> void:
	grid_type = Constants.GRID_TYPE_EXPLORED
	is_explored = true
	is_passable = true

## 设置为迷宫网格
func set_maze() -> void:
	grid_type = Constants.GRID_TYPE_MAZE
	has_maze = true
	is_passable = false  # 迷宫通常不可通行

## 检查是否为未开垦网格
func is_unexplored() -> bool:
	return grid_type == Constants.GRID_TYPE_UNEXPLORED

## 检查是否为已开垦网格
func get_is_explored_type() -> bool:
	return grid_type == Constants.GRID_TYPE_EXPLORED

## 检查是否为迷宫网格
func is_maze() -> bool:
	return grid_type == Constants.GRID_TYPE_MAZE

# ========== 状态管理 ==========
## 设置状态值
func set_state(key: String, value: Variant) -> void:
	state[key] = value

## 获取状态值
func get_state(key: String, default_value: Variant = null) -> Variant:
	return state.get(key, default_value)

## 检查是否有状态
func has_state(key: String) -> bool:
	return state.has(key)

## 移除状态
func remove_state(key: String) -> void:
	state.erase(key)

## 清空所有状态
func clear_state() -> void:
	state.clear()

# ========== 序列化接口 ==========
## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"grid_pos": {"x": grid_pos.x, "y": grid_pos.y},
		"grid_type": grid_type,
		"state": state,
		"is_passable": is_passable,
		"is_visible": is_visible,
		"is_explored": is_explored,
		"has_maze": has_maze,
		"has_secret": has_secret,
		"has_construct": has_construct,
		"has_truth_cocoon": has_truth_cocoon,
		"truth_density": truth_density,
		"activity_level": activity_level
	}

## 从字典反序列化
func from_dict(data: Dictionary) -> void:
	if data.has("grid_pos"):
		var pos_dict = data["grid_pos"]
		grid_pos = Vector2i(pos_dict.get("x", 0), pos_dict.get("y", 0))
	
	grid_type = data.get("grid_type", Constants.GRID_TYPE_UNEXPLORED)
	state = data.get("state", {})
	is_passable = data.get("is_passable", true)
	is_visible = data.get("is_visible", false)
	is_explored = data.get("is_explored", false)
	has_maze = data.get("has_maze", false)
	has_secret = data.get("has_secret", false)
	has_construct = data.get("has_construct", false)
	has_truth_cocoon = data.get("has_truth_cocoon", false)
	truth_density = data.get("truth_density", 0.0)
	activity_level = data.get("activity_level", 0.0)

## 复制网格数据
func duplicate_data() -> GridData:
	var new_data = GridData.new(grid_pos, grid_type)
	new_data.from_dict(to_dict())
	return new_data

# ========== 验证 ==========
## 验证数据有效性
func validate() -> bool:
	if grid_type < 0 or grid_type > 2:
		push_warning("GridData: 无效的网格类型: " + str(grid_type))
		return false
	
	if truth_density < 0.0 or truth_density > 1.0:
		push_warning("GridData: 真理要素密度超出范围: " + str(truth_density))
		return false
	
	if activity_level < 0.0 or activity_level > 1.0:
		push_warning("GridData: 活跃度超出范围: " + str(activity_level))
		return false
	
	return true
