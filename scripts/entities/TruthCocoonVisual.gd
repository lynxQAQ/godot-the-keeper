extends Node2D
class_name TruthCocoonVisual

## 真理之茧可视化节点

@export var base_radius: float = 10.0
@export var cocoon_color: Color = Color(0.4, 0.2, 0.6, 0.9)

var cocoon_id: String = ""
var grid_pos: Vector2i = Vector2i.ZERO
var level: int = 0

func set_cocoon_data(id: String, pos: Vector2i, level_value: int) -> void:
	cocoon_id = id
	grid_pos = pos
	level = level_value
	_update_color()
	queue_redraw()

func set_world_position(world_pos: Vector2) -> void:
	position = world_pos

func _update_color() -> void:
	var level_factor = clamp(float(level) / 5.0, 0.0, 1.0)
	var alpha = 0.6 + level_factor * 0.4
	cocoon_color = Color(0.4, 0.2, 0.6, alpha).darkened(level_factor * 0.3)

func _draw() -> void:
	var radius = base_radius + float(level) * 2.0
	draw_circle(Vector2.ZERO, radius, cocoon_color)
	var border_color = cocoon_color.lightened(0.2)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, border_color, 2.0)
