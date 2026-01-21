extends Control
class_name GameScene

## 游戏主场景
## 负责布局两个子窗口（表世界和里世界）

# ========== 节点引用 ==========
@onready var control_top: Control = get_node("Control (top)")
@onready var sub_win_area: HBoxContainer = get_node("HBoxContainer (sub_win_area)")
@onready var control_bottom: Control = get_node("Control (bottom)")

# ========== 预加载 ==========
const SubworldSurfaceScene = preload("res://scenes/subworld_surface.tscn")
const SubwordInnerScene = preload("res://scenes/subword_inner.tscn")

# ========== 导出属性 ==========

# ========== 内部属性 ==========
## 表世界子窗口
var subworld_surface: SurfaceWorldGrid = null

## 里世界子窗口
var subword_inner: InnerWorldGrid = null

# ========== 生命周期 ==========
func _ready():
	# 设置全屏布局
	_setup_layout()
	
	# 实例化子窗口
	_instantiate_subwindows()

# ========== 布局设置 ==========
## 设置主场景布局
func _setup_layout() -> void:
	# 设置全屏
	anchors_preset = Control.PRESET_FULL_RECT
	size = get_viewport_rect().size

## 实例化子窗口 并放入布局容器
func _instantiate_subwindows() -> void:
	# 实例化表世界子窗口
	subworld_surface = SubworldSurfaceScene.instantiate()
	if subworld_surface:
		sub_win_area.add_child(subworld_surface)
	
	# 实例化里世界子窗口
	subword_inner = SubwordInnerScene.instantiate()
	if subword_inner:
		sub_win_area.add_child(subword_inner)

# ========== 窗口大小改变处理 ==========
func _notification(what):
	if what == NOTIFICATION_RESIZED:
		pass

# ========== 公共接口 ==========
## 获取表世界子窗口引用
func get_surface_world() -> SurfaceWorldGrid:
	return subworld_surface

## 获取里世界子窗口引用
func get_inner_world() -> InnerWorldGrid:
	return subword_inner
