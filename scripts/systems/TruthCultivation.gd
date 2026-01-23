extends Node
class_name TruthCultivation

## 真理要素培育系统
## 管理真理要素状态转换与自动培育逻辑

@export var update_interval: float = 3.0
@export var sleeping_threshold: float = 0.4
@export var extinct_threshold: float = 0.2
@export var sublimated_threshold: float = 0.85

var inner_world_grid: InnerWorldGrid = null
var _timer: float = 0.0

func initialize(world_grid: InnerWorldGrid) -> void:
	inner_world_grid = world_grid

func _process(delta: float) -> void:
	if not inner_world_grid:
		return
	_timer += delta
	if _timer < update_interval:
		return
	_timer = 0.0
	_update_truth_states()

func _update_truth_states() -> void:
	var grid_manager = inner_world_grid.get_grid_manager()
	if not grid_manager:
		return
	if GameManagers.ResourceManager == null:
		return
	var truth_resource = GameManagers.ResourceManager.get_truth_element_resource()

	for element_id in inner_world_grid.truth_elements.keys():
		var element_data: TruthElementData = inner_world_grid.truth_elements[element_id]
		if not element_data:
			continue
		var grid_data = grid_manager.get_grid(element_data.grid_pos)
		if not grid_data:
			continue

		var target_state = _calculate_state(grid_data.truth_density, grid_data.activity_level)
		if target_state != element_data.state:
			var from_state = element_data.state
			element_data.state = target_state
			if truth_resource:
				truth_resource.change_truth_element_state(element_data.serial, 1, from_state, target_state)
			inner_world_grid.refresh_truth_element_visual(element_id)

func _calculate_state(density: float, activity: float) -> int:
	if density <= extinct_threshold:
		return Constants.TRUTH_STATE_EXTINCT
	if activity >= sublimated_threshold and density >= sublimated_threshold:
		return Constants.TRUTH_STATE_SUBLIMATED
	if density <= sleeping_threshold:
		return Constants.TRUTH_STATE_SLEEPING
	return Constants.TRUTH_STATE_ACTIVE
