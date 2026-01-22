extends BaseData
class_name CardData

## 卡牌数据类
## 定义卡牌的基础属性：ID、名称、类型、序列、描述、消耗等

# ========== 卡牌属性 ==========
@export var card_type: int = Constants.CONSTRUCT_TYPE_ENTITY  # 卡牌类型（实体/虚体）
@export var serial: int = 1  # 序列（1-5）
@export var cost_table_construct: int = 0  # 消耗的表构造力
@export var cost_inner_construct: int = 0  # 消耗的里构造力
@export var construct_data_ref: String = ""  # 关联的构造体数据ID引用

# ========== 卡牌状态 ==========
@export var is_unlocked: bool = true  # 是否已解锁
@export var is_collected: bool = false  # 是否已收集

# ========== 初始化 ==========
func _init(
	p_id: String = "",
	p_name: String = "",
	p_type: int = Constants.CONSTRUCT_TYPE_ENTITY,
	p_serial: int = 1,
	p_cost_table: int = 0,
	p_cost_inner: int = 0
) -> void:
	id = p_id
	name = p_name
	card_type = p_type
	serial = p_serial
	cost_table_construct = p_cost_table
	cost_inner_construct = p_cost_inner
	is_unlocked = true
	is_collected = false

# ========== 序列化接口 ==========
func to_dict() -> Dictionary:
	var data = super.to_dict()
	data["card_type"] = card_type
	data["serial"] = serial
	data["cost_table_construct"] = cost_table_construct
	data["cost_inner_construct"] = cost_inner_construct
	data["construct_data_ref"] = construct_data_ref
	data["is_unlocked"] = is_unlocked
	data["is_collected"] = is_collected
	return data

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	card_type = data.get("card_type", Constants.CONSTRUCT_TYPE_ENTITY)
	serial = data.get("serial", 1)
	cost_table_construct = data.get("cost_table_construct", 0)
	cost_inner_construct = data.get("cost_inner_construct", 0)
	construct_data_ref = data.get("construct_data_ref", "")
	is_unlocked = data.get("is_unlocked", true)
	is_collected = data.get("is_collected", false)

# ========== 验证 ==========
func validate() -> bool:
	if not super.validate():
		return false
	
	if card_type < 0 or card_type > 1:
		push_warning("CardData: 无效的卡牌类型: " + str(card_type))
		return false
	
	if serial < 1 or serial > 5:
		push_warning("CardData: 无效的序列: " + str(serial))
		return false
	
	if cost_table_construct < 0:
		push_warning("CardData: 表构造力消耗不能为负数: " + str(cost_table_construct))
		return false
	
	if cost_inner_construct < 0:
		push_warning("CardData: 里构造力消耗不能为负数: " + str(cost_inner_construct))
		return false
	
	return true

# ========== 工具函数 ==========
## 获取卡牌类型名称
func get_card_type_name() -> String:
	return Constants.get_construct_type_name(card_type)

## 获取序列名称
func get_serial_name() -> String:
	if card_type == Constants.CONSTRUCT_TYPE_ENTITY:
		return Constants.get_entity_serial_name(serial)
	else:
		return Constants.get_virtual_serial_name(serial)

## 获取总消耗（表构造力 + 里构造力）
func get_total_cost() -> int:
	return cost_table_construct + cost_inner_construct

## 检查是否有足够的资源使用此卡牌
func can_afford() -> bool:
	if not ResourceManager.has_enough_table_construct(cost_table_construct):
		return false
	if not ResourceManager.has_enough_inner_construct(cost_inner_construct):
		return false
	return true

## 解锁卡牌
func unlock() -> void:
	is_unlocked = true

## 锁定卡牌
func lock() -> void:
	is_unlocked = false

## 收集卡牌
func collect() -> void:
	is_collected = true

## 取消收集
func uncollect() -> void:
	is_collected = false

## 复制卡牌数据
func duplicate_card() -> CardData:
	var new_card = CardData.new()
	new_card.from_dict(to_dict())
	return new_card
