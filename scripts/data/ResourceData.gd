extends Resource
class_name ResourceData

## 资源数据类
## 定义资源的类型、数量、上限、生成速率等属性

# ========== 资源属性 ==========
@export var resource_type: String = Constants.RESOURCE_TABLE_CONSTRUCT  # 资源类型
@export var current_value: int = 0  # 当前值
@export var max_value: int = 0  # 上限值
@export var generation_rate: float = 0.0  # 生成速率（每秒）

# ========== 初始化 ==========
func _init(
	p_type: String = Constants.RESOURCE_TABLE_CONSTRUCT,
	p_current: int = 0,
	p_max: int = 0,
	p_rate: float = 0.0
) -> void:
	resource_type = p_type
	current_value = p_current
	max_value = p_max
	generation_rate = p_rate

# ========== 资源操作 ==========
## 增加资源
## amount: 增加的数量
## 返回实际增加的数量（受上限限制）
func add(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var old_value = current_value
	current_value = min(current_value + amount, max_value)
	return current_value - old_value

## 减少资源
## amount: 减少的数量
## 返回实际减少的数量（不能小于0）
func subtract(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var old_value = current_value
	current_value = max(current_value - amount, 0)
	return old_value - current_value

## 设置资源值
## value: 目标值
func set_value(value: int) -> void:
	current_value = clamp(value, 0, max_value)

## 设置上限
## value: 新的上限值
func set_max(value: int) -> void:
	max_value = max(0, value)
	current_value = min(current_value, max_value)

## 检查是否有足够的资源
## amount: 需要的数量
func has_enough(amount: int) -> bool:
	return current_value >= amount

## 获取资源百分比（0.0-1.0）
func get_percentage() -> float:
	if max_value <= 0:
		return 0.0
	return float(current_value) / float(max_value)

# ========== 序列化接口 ==========
## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"resource_type": resource_type,
		"current_value": current_value,
		"max_value": max_value,
		"generation_rate": generation_rate
	}

## 从字典反序列化
func from_dict(data: Dictionary) -> void:
	resource_type = data.get("resource_type", Constants.RESOURCE_TABLE_CONSTRUCT)
	current_value = data.get("current_value", 0)
	max_value = data.get("max_value", 0)
	generation_rate = data.get("generation_rate", 0.0)

## 验证数据有效性
func validate() -> bool:
	if resource_type.is_empty():
		push_warning("ResourceData: resource_type is empty")
		return false
	if max_value < 0:
		push_warning("ResourceData: max_value is negative")
		return false
	if current_value < 0:
		push_warning("ResourceData: current_value is negative")
		return false
	if current_value > max_value:
		push_warning("ResourceData: current_value exceeds max_value")
		current_value = max_value
	return true

## 复制数据
func duplicate_data() -> ResourceData:
	var new_data = ResourceData.new()
	new_data.from_dict(to_dict())
	return new_data
