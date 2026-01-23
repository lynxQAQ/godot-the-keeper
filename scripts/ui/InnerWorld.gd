extends Control
class_name InnerWorld

## 里世界场景
## 组合里世界网格、真理之茧系统、培育系统与仪式UI

@onready var inner_world_grid: InnerWorldGrid = $InnerWorldGrid
@onready var ritual_panel: RitualPanel = $RitualPanel

var truth_cocoon_system: TruthCocoon = null
var truth_cultivation_system: TruthCultivation = null
var ritual_system: Ritual = null

func _ready() -> void:
	_setup_systems()

func _setup_systems() -> void:
	# 真理之茧系统
	truth_cocoon_system = TruthCocoon.new()
	add_child(truth_cocoon_system)
	if inner_world_grid:
		truth_cocoon_system.initialize(inner_world_grid)
		inner_world_grid.set_truth_cocoon_system(truth_cocoon_system)

	# 真理要素培育系统
	truth_cultivation_system = TruthCultivation.new()
	add_child(truth_cultivation_system)
	if inner_world_grid:
		truth_cultivation_system.initialize(inner_world_grid)

	# 仪式系统
	ritual_system = Ritual.new()
	add_child(ritual_system)
	if inner_world_grid:
		ritual_system.initialize(inner_world_grid)

	# 绑定UI
	if ritual_panel:
		ritual_panel.set_ritual_system(ritual_system)

## 获取里世界网格
func get_inner_world_grid() -> InnerWorldGrid:
	return inner_world_grid
