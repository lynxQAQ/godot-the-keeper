extends BaseData
class_name ConstructData

## 构造体数据基类
## 定义构造体的基础属性

# ========== 基础属性 ==========
@export var construct_type: int = Constants.CONSTRUCT_TYPE_ENTITY  # 构造体类型（实体/虚体）
@export var serial: int = 1  # 序列（1-5）
@export var state: int = Constants.CONSTRUCT_STATE_INACTIVE  # 状态

# ========== 效果属性 ==========
@export var effect_range: int = 1  # 影响范围（网格数）
@export var trigger_probability: float = 1.0  # 生效概率（0.0-1.0）
@export var effects: Array[Dictionary] = []  # 效果列表 [{type, value, check_result}]

# ========== 初始化 ==========
func _init(
	p_id: String = "",
	p_name: String = "",
	p_type: int = Constants.CONSTRUCT_TYPE_ENTITY,
	p_serial: int = 1
) -> void:
	id = p_id
	name = p_name
	construct_type = p_type
	serial = p_serial
	state = Constants.CONSTRUCT_STATE_INACTIVE

# ========== 序列化接口 ==========
func to_dict() -> Dictionary:
	var data = super.to_dict()
	data["construct_type"] = construct_type
	data["serial"] = serial
	data["state"] = state
	data["effect_range"] = effect_range
	data["trigger_probability"] = trigger_probability
	data["effects"] = effects.duplicate()
	return data

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	construct_type = data.get("construct_type", Constants.CONSTRUCT_TYPE_ENTITY)
	serial = data.get("serial", 1)
	state = data.get("state", Constants.CONSTRUCT_STATE_INACTIVE)
	effect_range = data.get("effect_range", 1)
	trigger_probability = data.get("trigger_probability", 1.0)
	effects = data.get("effects", []).duplicate()

# ========== 验证 ==========
func validate() -> bool:
	if not super.validate():
		return false
	
	if construct_type < 0 or construct_type > 1:
		push_warning("ConstructData: 无效的构造体类型: " + str(construct_type))
		return false
	
	if serial < 1 or serial > 5:
		push_warning("ConstructData: 无效的序列: " + str(serial))
		return false
	
	if trigger_probability < 0.0 or trigger_probability > 1.0:
		push_warning("ConstructData: 生效概率超出范围: " + str(trigger_probability))
		return false
	
	return true

# ========== 工具函数 ==========
## 获取序列名称
func get_serial_name() -> String:
	if construct_type == Constants.CONSTRUCT_TYPE_ENTITY:
		match serial:
			1: return "图腾"
			2: return "造物"
			3: return "魔物"
			4: return "邪祟"
			5: return "神祇"
	else:
		match serial:
			1: return "预兆"
			2: return "异象"
			3: return "启示"
			4: return "灾厄"
			5: return "神谕"
	return "未知序列"

## 添加效果
func add_effect(effect_type: String, value: float, check_result: int = -1) -> void:
	effects.append({
		"type": effect_type,
		"value": value,
		"check_result": check_result  # -1表示对所有检定结果生效
	})

## 移除效果
func remove_effect(index: int) -> bool:
	if index >= 0 and index < effects.size():
		effects.remove_at(index)
		return true
	return false
