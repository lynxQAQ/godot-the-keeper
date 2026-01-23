extends SubViewport

## 表世界初始化器
## 挂载到 SubViewport_Surface 节点，负责实例化表世界场景

# ========== 预加载 ==========
const SubworldSurfaceScene = preload("res://scenes/subworld_surface.tscn")

# ========== 内部属性 ==========
var subworld_surface: SurfaceWorldGrid = null

# ========== 初始化 ==========
func _ready() -> void:
	_instantiate_surface_world()

# ========== 实例化表世界 ==========
func _instantiate_surface_world() -> void:
	subworld_surface = SubworldSurfaceScene.instantiate()
	if subworld_surface:
		add_child(subworld_surface)
		DebugLogger.info("SurfaceWorldInitializer: 表世界场景已实例化", "SurfaceWorldInitializer")
	else:
		DebugLogger.error("SurfaceWorldInitializer: 无法实例化表世界场景", "SurfaceWorldInitializer")

# ========== 公共接口 ==========
## 获取表世界引用
func get_surface_world() -> SurfaceWorldGrid:
	return subworld_surface
