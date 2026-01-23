extends Node
class_name Ritual

## 仪式系统
## 负责仪式配置加载、条件检查、执行与卡牌生成

@export var ritual_config_path: String = "res://data/rituals.json"

var _rituals: Array[Dictionary] = []
var _ritual_map: Dictionary = {}
var _card_reserve: CardReserve = CardReserve.new()
var _inner_world_grid: InnerWorldGrid = null

func initialize(world_grid: InnerWorldGrid) -> void:
	_inner_world_grid = world_grid

func _ready() -> void:
	load_rituals(ritual_config_path)

## 加载仪式配置
func load_rituals(file_path: String) -> int:
	var data = DataManager.load_json_file(file_path)
	_rituals.clear()
	_ritual_map.clear()

	var items: Array = []
	if data.has("rituals") and data["rituals"] is Array:
		items = data["rituals"]
	elif data.has("data") and data["data"] is Array:
		items = data["data"]
	else:
		DebugLogger.warning("Ritual: 仪式配置为空或格式错误: " + file_path, "Ritual")
		return 0

	for item in items:
		if item is Dictionary and item.has("id"):
			_rituals.append(item)
			_ritual_map[item["id"]] = item

	DebugLogger.info("Ritual: 加载仪式数量 " + str(_rituals.size()), "Ritual")
	return _rituals.size()

## 获取所有仪式
func get_rituals() -> Array[Dictionary]:
	return _rituals.duplicate()

## 获取仪式
func get_ritual(ritual_id: String) -> Dictionary:
	return _ritual_map.get(ritual_id, {})

## 获取预备区
func get_card_reserve() -> CardReserve:
	return _card_reserve

## 检查仪式条件
func can_perform(ritual_id: String) -> Dictionary:
	var ritual = get_ritual(ritual_id)
	if ritual.is_empty():
		return {"valid": false, "error": "仪式不存在", "missing": {}}

	if GameManagers.ResourceManager == null:
		return {"valid": false, "error": "ResourceManager未初始化", "missing": {}}
	
	var cost_table = int(ritual.get("cost_table_construct", 0))
	var cost_inner = int(ritual.get("cost_inner_construct", 0))
	if not GameManagers.ResourceManager.has_enough_table_construct(cost_table):
		return {"valid": false, "error": "表构造力不足", "missing": {}}
	if not GameManagers.ResourceManager.has_enough_inner_construct(cost_inner):
		return {"valid": false, "error": "里构造力不足", "missing": {}}

	var required = ritual.get("required_elements", {})
	var missing: Dictionary = {}
	for serial in required.keys():
		var need = int(required[serial])
		var available = GameManagers.ResourceManager.get_truth_element_count(int(serial))
		if available < need:
			missing[serial] = need - available
	
	if not missing.is_empty():
		return {"valid": false, "error": "真理要素不足", "missing": missing}

	return {"valid": true, "error": "", "missing": {}}

## 执行仪式
func perform_ritual(ritual_id: String) -> bool:
	var ritual = get_ritual(ritual_id)
	if ritual.is_empty():
		return false

	var validation = can_perform(ritual_id)
	if not validation["valid"]:
		DebugLogger.warning("Ritual: 仪式条件不满足: " + validation["error"], "Ritual")
		return false

	if GameManagers.ResourceManager == null:
		return false
	
	var cost_table = int(ritual.get("cost_table_construct", 0))
	var cost_inner = int(ritual.get("cost_inner_construct", 0))
	if cost_table > 0 and not GameManagers.ResourceManager.consume_table_construct(cost_table):
		return false
	if cost_inner > 0 and not GameManagers.ResourceManager.consume_inner_construct(cost_inner):
		if cost_table > 0:
			GameManagers.ResourceManager.add_table_construct(cost_table)
		return false

	var required = ritual.get("required_elements", {})
	if _inner_world_grid:
		var consume_result = _inner_world_grid.consume_truth_elements(required)
		if not consume_result.success:
			DebugLogger.warning("Ritual: 消耗真理要素失败", "Ritual")
			return false
	else:
		for serial in required.keys():
			GameManagers.ResourceManager.subtract_truth_element(int(serial), int(required[serial]))

	var card_id = ritual.get("output_card_id", "")
	if not card_id.is_empty() and GameManagers.CardLibrary:
		GameManagers.CardLibrary.collect_card(card_id)
		_card_reserve.add_card(card_id)

	SignalBus.ritual_performed.emit(ritual_id, required)
	DebugLogger.info("Ritual: 执行仪式成功 " + ritual_id + "，产出卡牌: " + card_id, "Ritual")
	return true
