extends ColorRect
class_name GridCell

## 网格单元可视化组件
## 表示单个网格的视觉表现

# ========== 导出属性 ==========
## 默认颜色（未开垦）
@export var default_color: Color = Color(0.3, 0.3, 0.3, 0.5)

## 已开垦颜色
@export var explored_color: Color = Color(0.5, 0.5, 0.3, 0.7)

## 迷宫颜色
@export var maze_color: Color = Color(0.3, 0.1, 0.1, 0.8)

## 悬停颜色
@export var hover_color: Color = Color(1.0, 1.0, 0.0, 0.3)

## 选中颜色
@export var selected_color: Color = Color(0.0, 1.0, 0.0, 0.5)

# ========== 内部属性 ==========
## 当前网格数据
var grid_data: GridData = null

## 是否悬停
var is_hovered: bool = false

## 是否选中
var is_selected: bool = false

# ========== 生命周期 ==========
func _ready():
	# 设置默认大小（等距网格使用2:1比例，例如64x32）
	custom_minimum_size = Vector2(64, 32)
	
	# 设置默认颜色
	color = default_color
	
	# 启用鼠标输入
	mouse_filter = MOUSE_FILTER_PASS

# ========== 设置网格数据 ==========
## 设置网格数据并更新显示
func set_grid_data(data: GridData) -> void:
	grid_data = data
	_update_visual()

## 更新视觉表现
func _update_visual() -> void:
	if not grid_data:
		color = default_color
		return
	
	# 根据网格类型设置颜色
	match grid_data.grid_type:
		Constants.GRID_TYPE_UNEXPLORED:
			color = default_color
		Constants.GRID_TYPE_EXPLORED:
			color = explored_color
		Constants.GRID_TYPE_MAZE:
			color = maze_color
		_:
			color = default_color
	
	# 应用悬停和选中效果
	if is_selected:
		color = color.blend(selected_color)
	elif is_hovered:
		color = color.blend(hover_color)

# ========== 状态设置 ==========
## 设置悬停状态
func set_hovered(hovered: bool) -> void:
	is_hovered = hovered
	_update_visual()

## 设置选中状态
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visual()

## 设置高亮（用于预览等）
func set_highlighted(highlighted: bool, highlight_color: Color = Color.YELLOW) -> void:
	if highlighted:
		color = color.blend(highlight_color)
	else:
		_update_visual()
