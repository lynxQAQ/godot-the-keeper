extends BaseData
class_name InvestigatorData

## 调查员数据类
## 定义调查员的所有属性：基础属性、状态数值、基础数值、技能、经历

# ========== 基础属性 ==========
# ID、名称、描述已在BaseData中定义

# ========== 状态数值 ==========
@export var health: int = 10  # 当前生命值
@export var health_max: int = 10  # 最大生命值
@export var sanity: int = 10  # 当前理智值
@export var sanity_max: int = 10  # 最大理智值

# ========== 基础数值（用于检定） ==========
@export var strength: int = 50  # 力量（默认50，范围1-100）
@export var agility: int = 50  # 敏捷
@export var intelligence: int = 50  # 智力
@export var willpower: int = 50  # 意志

# ========== 技能列表 ==========
## 技能数据结构：{skill_name: String, level: int}
@export var skills: Array[Dictionary] = []

# ========== 经历列表 ==========
## 经历数据结构：{experience_id: String, description: String, timestamp: float}
## 记录已触发的效果和事件
@export var experiences: Array[Dictionary] = []

# ========== 位置信息 ==========
@export var position: Vector2i = Vector2i.ZERO  # 当前网格位置

# ========== 初始化 ==========
func _init(
	p_id: String = "",
	p_name: String = "",
	p_health: int = Constants.DEFAULT_INVESTIGATOR_HEALTH,
	p_sanity: int = Constants.DEFAULT_INVESTIGATOR_SANITY
) -> void:
	# Resource 的 _init() 不是虚函数，不能调用 super._init()
	id = p_id
	name = p_name
	health = p_health
	health_max = p_health
	sanity = p_sanity
	sanity_max = p_sanity
	strength = 50
	agility = 50
	intelligence = 50
	willpower = 50
	skills = []
	experiences = []
	position = Vector2i.ZERO

# ========== 序列化接口 ==========
func to_dict() -> Dictionary:
	var data = super.to_dict()
	data["health"] = health
	data["health_max"] = health_max
	data["sanity"] = sanity
	data["sanity_max"] = sanity_max
	data["strength"] = strength
	data["agility"] = agility
	data["intelligence"] = intelligence
	data["willpower"] = willpower
	data["skills"] = skills.duplicate()
	data["experiences"] = experiences.duplicate()
	data["position"] = {"x": position.x, "y": position.y}
	return data

func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	health = data.get("health", Constants.DEFAULT_INVESTIGATOR_HEALTH)
	health_max = data.get("health_max", Constants.DEFAULT_INVESTIGATOR_HEALTH)
	sanity = data.get("sanity", Constants.DEFAULT_INVESTIGATOR_SANITY)
	sanity_max = data.get("sanity_max", Constants.DEFAULT_INVESTIGATOR_SANITY)
	strength = data.get("strength", 50)
	agility = data.get("agility", 50)
	intelligence = data.get("intelligence", 50)
	willpower = data.get("willpower", 50)
	skills = data.get("skills", []).duplicate()
	experiences = data.get("experiences", []).duplicate()
	if data.has("position"):
		var pos_data = data["position"]
		position = Vector2i(pos_data.get("x", 0), pos_data.get("y", 0))

# ========== 状态数值接口 ==========
## 设置生命值
func set_health(value: int) -> void:
	health = clamp(value, 0, health_max)

## 设置理智值
func set_sanity(value: int) -> void:
	sanity = clamp(value, 0, sanity_max)

## 增加生命值
func add_health(amount: int) -> void:
	set_health(health + amount)

## 减少生命值
func reduce_health(amount: int) -> void:
	set_health(health - amount)

## 增加理智值
func add_sanity(amount: int) -> void:
	set_sanity(sanity + amount)

## 减少理智值
func reduce_sanity(amount: int) -> void:
	set_sanity(sanity - amount)

## 检查是否死亡（生命值或理智值任一为0）
func is_dead() -> bool:
	return health <= 0 or sanity <= 0

# ========== 基础数值接口 ==========
## 获取基础数值（根据检定类型）
func get_base_value(check_type: String) -> int:
	match check_type:
		"strength":
			return strength
		"agility":
			return agility
		"intelligence":
			return intelligence
		"willpower":
			return willpower
		_:
			return 50  # 默认值

# ========== 技能接口 ==========
## 添加技能
func add_skill(skill_name: String, level: int = 1) -> void:
	# 检查是否已存在该技能
	for skill in skills:
		if skill.get("skill_name") == skill_name:
			# 更新等级
			skill["level"] = level
			return
	
	# 添加新技能
	skills.append({
		"skill_name": skill_name,
		"level": level
	})

## 获取技能等级
func get_skill_level(skill_name: String) -> int:
	for skill in skills:
		if skill.get("skill_name") == skill_name:
			return skill.get("level", 0)
	return 0

## 移除技能
func remove_skill(skill_name: String) -> void:
	var index = -1
	for i in range(skills.size()):
		if skills[i].get("skill_name") == skill_name:
			index = i
			break
	
	if index >= 0:
		skills.remove_at(index)

# ========== 经历接口 ==========
## 添加经历
func add_experience(experience_id: String, description: String) -> void:
	experiences.append({
		"experience_id": experience_id,
		"description": description,
		"timestamp": Time.get_ticks_msec() / 1000.0
	})

## 检查是否有特定经历
func has_experience(experience_id: String) -> bool:
	for exp in experiences:
		if exp.get("experience_id") == experience_id:
			return true
	return false

# ========== 位置接口 ==========
## 设置位置
func set_position(pos: Vector2i) -> void:
	position = pos

## 获取位置
func get_position() -> Vector2i:
	return position

## 检查是否在指定位置
func is_at_position(pos: Vector2i) -> bool:
	return position == pos

# ========== 验证接口 ==========
func validate() -> bool:
	if not super.validate():
		return false
	
	if health_max <= 0 or sanity_max <= 0:
		push_warning("InvestigatorData: 最大生命值或最大理智值无效")
		return false
	
	if health < 0 or health > health_max:
		push_warning("InvestigatorData: 当前生命值超出范围")
		return false
	
	if sanity < 0 or sanity > sanity_max:
		push_warning("InvestigatorData: 当前理智值超出范围")
		return false
	
	return true
