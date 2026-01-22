extends Control
class_name InvestigatorPreview

## 调查员预览系统
## 显示调查员信息（数值、技能、经历）

# ========== 节点引用 ==========
@onready var name_label: Label = get_node("VBoxContainer/NameLabel") if has_node("VBoxContainer/NameLabel") else null
@onready var description_label: Label = get_node("VBoxContainer/DescriptionLabel") if has_node("VBoxContainer/DescriptionLabel") else null
@onready var health_label: Label = get_node("VBoxContainer/StatsContainer/HealthLabel") if has_node("VBoxContainer/StatsContainer/HealthLabel") else null
@onready var sanity_label: Label = get_node("VBoxContainer/StatsContainer/SanityLabel") if has_node("VBoxContainer/StatsContainer/SanityLabel") else null
@onready var attributes_label: Label = get_node("VBoxContainer/AttributesContainer/AttributesLabel") if has_node("VBoxContainer/AttributesContainer/AttributesLabel") else null
@onready var skills_label: Label = get_node("VBoxContainer/SkillsContainer/SkillsLabel") if has_node("VBoxContainer/SkillsContainer/SkillsLabel") else null
@onready var experiences_label: Label = get_node("VBoxContainer/ExperiencesContainer/ExperiencesLabel") if has_node("VBoxContainer/ExperiencesContainer/ExperiencesLabel") else null
@onready var expand_button: Button = get_node("VBoxContainer/ExpandButton") if has_node("VBoxContainer/ExpandButton") else null
@onready var details_container: VBoxContainer = get_node("VBoxContainer/DetailsContainer") if has_node("VBoxContainer/DetailsContainer") else null

# ========== 状态 ==========
var investigator_data: InvestigatorData = null
var is_expanded: bool = false

# ========== 初始化 ==========
func _ready() -> void:
	if expand_button:
		expand_button.pressed.connect(_on_expand_button_pressed)
	
	# 默认收起详细信息
	if details_container:
		details_container.visible = false

# ========== 显示接口 ==========
## 设置调查员数据并更新显示
func set_investigator_data(data: InvestigatorData) -> void:
	investigator_data = data
	_update_display()

## 更新显示
func _update_display() -> void:
	if not investigator_data:
		return
	
	# 更新名称
	if name_label:
		name_label.text = investigator_data.name
	
	# 更新描述
	if description_label:
		description_label.text = investigator_data.description if investigator_data.description else "无描述"
	
	# 更新状态数值
	if health_label:
		health_label.text = "生命值: %d / %d" % [investigator_data.health, investigator_data.health_max]
	
	if sanity_label:
		sanity_label.text = "理智值: %d / %d" % [investigator_data.sanity, investigator_data.sanity_max]
	
	# 更新基础数值
	if attributes_label:
		var attributes_text = "力量: %d | 敏捷: %d | 智力: %d | 意志: %d" % [
			investigator_data.strength,
			investigator_data.agility,
			investigator_data.intelligence,
			investigator_data.willpower
		]
		attributes_label.text = attributes_text
	
	# 更新技能
	if skills_label:
		if investigator_data.skills.is_empty():
			skills_label.text = "技能: 无"
		else:
			var skills_text = "技能: "
			var skill_list: Array[String] = []
			for skill in investigator_data.skills:
				var skill_name = skill.get("skill_name", "")
				var skill_level = skill.get("level", 0)
				skill_list.append("%s (Lv.%d)" % [skill_name, skill_level])
			skills_label.text = skills_text + ", ".join(skill_list)
	
	# 更新经历
	if experiences_label:
		if investigator_data.experiences.is_empty():
			experiences_label.text = "经历: 无"
		else:
			var experiences_text = "经历 (%d): " % investigator_data.experiences.size()
			var exp_list: Array[String] = []
			for exp in investigator_data.experiences:
				var exp_desc = exp.get("description", "")
				exp_list.append(exp_desc)
			experiences_label.text = experiences_text + " | ".join(exp_list)

# ========== 展开/收起交互 ==========
func _on_expand_button_pressed() -> void:
	is_expanded = not is_expanded
	
	if details_container:
		details_container.visible = is_expanded
	
	if expand_button:
		expand_button.text = "收起" if is_expanded else "展开"

## 展开详细信息
func expand() -> void:
	if not is_expanded:
		_on_expand_button_pressed()

## 收起详细信息
func collapse() -> void:
	if is_expanded:
		_on_expand_button_pressed()

# ========== 显示/隐藏 ==========
## 显示预览
func show_preview() -> void:
	visible = true

## 隐藏预览
func hide_preview() -> void:
	visible = false

## 切换显示状态
func toggle_visibility() -> void:
	visible = not visible
