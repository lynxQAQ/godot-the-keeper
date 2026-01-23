extends Panel
class_name RitualPanel

## 仪式UI面板

@onready var ritual_selector: OptionButton = $MarginContainer/VBoxContainer/RitualSelector
@onready var requirement_label: RichTextLabel = $MarginContainer/VBoxContainer/RequirementLabel
@onready var reserve_label: Label = $MarginContainer/VBoxContainer/ReserveLabel
@onready var execute_button: Button = $MarginContainer/VBoxContainer/ExecuteButton
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel

var ritual_system: Ritual = null

func _ready() -> void:
	if execute_button and not execute_button.pressed.is_connected(_on_execute_pressed):
		execute_button.pressed.connect(_on_execute_pressed)
	if ritual_selector and not ritual_selector.item_selected.is_connected(_on_ritual_selected):
		ritual_selector.item_selected.connect(_on_ritual_selected)
	_refresh()

func set_ritual_system(system: Ritual) -> void:
	ritual_system = system
	_refresh()

func _refresh() -> void:
	if not ritual_selector:
		return
	
	ritual_selector.clear()
	if ritual_system == null:
		return
	
	var rituals = ritual_system.get_rituals()
	for ritual in rituals:
		var ritual_id = ritual.get("id", "")
		var ritual_name = ritual.get("name", ritual_id)
		ritual_selector.add_item(ritual_name)
		ritual_selector.set_item_metadata(ritual_selector.get_item_count() - 1, ritual_id)
	
	_update_requirement_display()
	_update_reserve_display()

func _on_ritual_selected(index: int) -> void:
	_update_requirement_display()

func _on_execute_pressed() -> void:
	if ritual_system == null:
		return
	var ritual_id = _get_selected_ritual_id()
	if ritual_id.is_empty():
		return
	
	var can_result = ritual_system.can_perform(ritual_id)
	if not can_result["valid"]:
		status_label.text = "无法执行: " + can_result["error"]
		return
	
	if ritual_system.perform_ritual(ritual_id):
		status_label.text = "仪式成功"
	else:
		status_label.text = "仪式失败"
	
	_update_requirement_display()
	_update_reserve_display()

func _get_selected_ritual_id() -> String:
	if ritual_selector.get_item_count() == 0:
		return ""
	var index = ritual_selector.selected
	return ritual_selector.get_item_metadata(index)

func _update_requirement_display() -> void:
	if ritual_system == null or requirement_label == null:
		return
	var ritual_id = _get_selected_ritual_id()
	var ritual = ritual_system.get_ritual(ritual_id)
	if ritual.is_empty():
		requirement_label.text = ""
		return
	
	var required = ritual.get("required_elements", {})
	var cost_table = int(ritual.get("cost_table_construct", 0))
	var cost_inner = int(ritual.get("cost_inner_construct", 0))
	var card_id = ritual.get("output_card_id", "")
	
	var text = "[b]需求真理要素[/b]\n"
	for serial in required.keys():
		text += "序列 " + str(serial) + ": " + str(required[serial]) + "\n"
	text += "\n[b]消耗[/b]\n表构造力: " + str(cost_table) + "\n里构造力: " + str(cost_inner)
	text += "\n\n[b]产出卡牌[/b]\n" + card_id
	requirement_label.text = text

func _update_reserve_display() -> void:
	if ritual_system == null or reserve_label == null:
		return
	var reserve = ritual_system.get_card_reserve()
	if reserve:
		reserve_label.text = "预备区: " + str(reserve.get_size()) + "/" + str(reserve.get_max_capacity())
