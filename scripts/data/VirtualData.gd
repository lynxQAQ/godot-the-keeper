extends ConstructData
class_name VirtualData

## 虚体数据类
## 定义虚体的特有属性：持续时间等

# ========== 虚体特有属性 ==========
@export var duration: float = -1.0  # 持续时间（秒），-1表示永久
@export var remaining_time: float = -1.0  # 剩余时间（秒）
@export var center_position: Vector2i = Vector2i.ZERO  # 中心位置（用于范围效果）

# ========== 初始化 ==========
func _init(
	p_id: String = "",
	p_name: String = "",
	p_serial: int = 1,
	p_duration: float = -1.0,
	p_center: Vector2i = Vector2i.ZERO
) -> void:
	super._init(p_id, p_name, Constants.CONSTRUCT_TYPE_VIRTUAL, p_serial)
	duration = p_duration
	remaining_time = p_duration
	center_position = p_center

# ========== 序列化接口 ==========
func to_dict() -> Dictionary:
	var data = super.to_dict()
	data["duration"] = duration
	data["remaining_time"] = remaining_time
	data["center_position"] = {"x": center_position.x, "y": center_position.y}
	return data

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	duration = data.get("duration", -1.0)
	remaining_time = data.get("remaining_time", duration)
	if data.has("center_position"):
		var pos_data = data["center_position"]
		center_position = Vector2i(pos_data.get("x", 0), pos_data.get("y", 0))

# ========== 时间管理 ==========
## 更新剩余时间
func update_time(delta: float) -> bool:
	if duration < 0:
		return true  # 永久存在
	
	remaining_time -= delta
	if remaining_time <= 0:
		remaining_time = 0
		return false  # 时间耗尽
	return true  # 仍然存在

## 检查是否已过期
func is_expired() -> bool:
	if duration < 0:
		return false  # 永久存在
	return remaining_time <= 0

## 获取剩余时间百分比
func get_time_percentage() -> float:
	if duration < 0:
		return 1.0
	if duration <= 0:
		return 0.0
	return remaining_time / duration

# ========== 工具函数 ==========
## 设置中心位置
func set_center_position(pos: Vector2i) -> void:
	center_position = pos

## 获取中心位置
func get_center_position() -> Vector2i:
	return center_position
