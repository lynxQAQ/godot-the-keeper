extends Node
class_name TruthCocoon

## 真理之茧系统
## 负责茧的生成、破茧与可视化管理

signal cocoon_created(cocoon_id: String, grid_pos: Vector2i, level: int)
signal cocoon_broken(cocoon_id: String, grid_pos: Vector2i, released_elements: Dictionary)

const CocoonVisual = preload("res://scripts/entities/TruthCocoonVisual.gd")

var inner_world_grid: InnerWorldGrid = null
var cocoon_container: Node2D = null
var cocoons: Dictionary = {}  # {id: {"pos": Vector2i, "level": int}}
var cocoon_nodes: Dictionary = {}  # {id: TruthCocoonVisual}

func initialize(world_grid: InnerWorldGrid) -> void:
	inner_world_grid = world_grid
	if not inner_world_grid:
		return
	var grid_system = inner_world_grid.get_grid_system()
	if grid_system:
		cocoon_container = Node2D.new()
		cocoon_container.name = "TruthCocoonContainer"
		grid_system.add_child(cocoon_container)
		sync_from_grid()

## 从网格数据同步真理之茧
func sync_from_grid() -> void:
	if not inner_world_grid:
		return
	var grid_manager = inner_world_grid.get_grid_manager()
	if not grid_manager:
		return

	# 清理旧数据
	for cocoon_id in cocoon_nodes.keys():
		var node = cocoon_nodes[cocoon_id]
		if node and is_instance_valid(node):
			node.queue_free()
	cocoons.clear()
	cocoon_nodes.clear()

	var all_positions = grid_manager.get_all_positions()
	for pos in all_positions:
		var grid_data = grid_manager.get_grid(pos)
		if grid_data and grid_data.has_truth_cocoon and grid_data.cocoon_level > 0:
			create_cocoon(pos, grid_data.cocoon_level)

## 创建真理之茧
func create_cocoon(pos: Vector2i, level: int = 1) -> String:
	if not inner_world_grid or not cocoon_container:
		return ""

	var cocoon_id = "cocoon_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 10000)
	cocoons[cocoon_id] = {"pos": pos, "level": level}

	var cocoon_node = CocoonVisual.new()
	cocoon_node.set_cocoon_data(cocoon_id, pos, level)
	var world_pos = inner_world_grid.get_grid_system().grid_to_world(pos)
	cocoon_node.set_world_position(world_pos)
	cocoon_container.add_child(cocoon_node)
	cocoon_nodes[cocoon_id] = cocoon_node

	cocoon_created.emit(cocoon_id, pos, level)
	return cocoon_id

## 破茧（按位置）
func break_cocoon_at(pos: Vector2i) -> bool:
	var cocoon_id = _find_cocoon_id_by_pos(pos)
	if cocoon_id.is_empty():
		return false
	return break_cocoon(cocoon_id)

## 破茧（按ID）
func break_cocoon(cocoon_id: String) -> bool:
	if not inner_world_grid or not cocoons.has(cocoon_id):
		return false

	var cocoon_info = cocoons[cocoon_id]
	var grid_pos: Vector2i = cocoon_info["pos"]
	var level: int = cocoon_info["level"]

	if GameManagers.ResourceManager == null:
		return false
	
	# 消耗里构造力
	if not GameManagers.ResourceManager.has_enough_inner_construct(Constants.COST_BREAK_COCOON):
		DebugLogger.warning("TruthCocoon: 里构造力不足，无法破茧", "TruthCocoon")
		return false
	if not GameManagers.ResourceManager.consume_inner_construct(Constants.COST_BREAK_COCOON):
		return false

	# 设置网格为已开垦
	var grid_manager = inner_world_grid.get_grid_manager()
	if grid_manager:
		var grid_data = grid_manager.get_grid(grid_pos)
		if grid_data:
			grid_data.set_explored()
			grid_data.has_truth_cocoon = false
			grid_data.cocoon_level = 0
			inner_world_grid.get_grid_system().set_grid(grid_pos, grid_data)

	# 释放真理要素
	var release_count = Constants.COCOON_RELEASE_BASE_COUNT + level * Constants.COCOON_RELEASE_PER_LEVEL
	var released: Dictionary = {}
	for i in range(release_count):
		var serial = randi() % Constants.TRUTH_SERIAL_COUNT + 1
		released[serial] = released.get(serial, 0) + 1
		var density = min(0.3 + (level * 0.1), 1.0)
		inner_world_grid.create_truth_element(grid_pos, serial, density)

	# 移除可视化
	if cocoon_nodes.has(cocoon_id):
		var node = cocoon_nodes[cocoon_id]
		if node and is_instance_valid(node):
			node.queue_free()

	cocoons.erase(cocoon_id)
	cocoon_nodes.erase(cocoon_id)

	SignalBus.cocoon_broken.emit(cocoon_id, released)
	cocoon_broken.emit(cocoon_id, grid_pos, released)
	DebugLogger.info("TruthCocoon: 破茧成功 " + cocoon_id + "，释放数量: " + str(release_count), "TruthCocoon")
	return true

func _find_cocoon_id_by_pos(pos: Vector2i) -> String:
	for cocoon_id in cocoons.keys():
		var info = cocoons[cocoon_id]
		if info["pos"] == pos:
			return cocoon_id
	return ""
