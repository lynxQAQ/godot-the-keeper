extends ConstructData
class_name EntityData

## 实体数据类
## 定义实体的特有属性：位置、移动规则等

# ========== 实体特有属性 ==========
@export var position: Vector2i = Vector2i.ZERO  # 位置
@export var movement_rule: String = "static"  # 移动规则（static/follow/patrol等）
@export var movement_speed: float = 0.0  # 移动速度（网格/秒）

# ========== 初始化 ==========
func _init(
	p_id: String = "",
	p_name: String = "",
	p_serial: int = 1,
	p_position: Vector2i = Vector2i.ZERO
) -> void:
	super._init(p_id, p_name, Constants.CONSTRUCT_TYPE_ENTITY, p_serial)
	position = p_position
	movement_rule = "static"
	movement_speed = 0.0

# ========== 序列化接口 ==========
func to_dict() -> Dictionary:
	var data = super.to_dict()
	data["position"] = {"x": position.x, "y": position.y}
	data["movement_rule"] = movement_rule
	data["movement_speed"] = movement_speed
	return data

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	if data.has("position"):
		var pos_data = data["position"]
		position = Vector2i(pos_data.get("x", 0), pos_data.get("y", 0))
	movement_rule = data.get("movement_rule", "static")
	movement_speed = data.get("movement_speed", 0.0)

# ========== 工具函数 ==========
## 设置位置
func set_position(pos: Vector2i) -> void:
	position = pos

## 获取位置
func get_position() -> Vector2i:
	return position

## 检查是否在指定位置
func is_at_position(pos: Vector2i) -> bool:
	return position == pos
