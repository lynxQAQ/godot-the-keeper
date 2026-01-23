extends SubViewport

## 里世界初始化器
## 挂载到 SubViewport_Inner 节点，负责实例化里世界场景

# ========== 预加载 ==========
const SubwordInnerScene = preload("res://scenes/subword_inner.tscn")

# ========== 内部属性 ==========
var subword_inner: Control = null
var inner_world_grid_manager: InnerWorldGridManager = null

# ========== 初始化 ==========
func _ready() -> void:
	_instantiate_inner_world()

# ========== 实例化里世界 ==========
func _instantiate_inner_world() -> void:
	subword_inner = SubwordInnerScene.instantiate()
	if subword_inner:
		add_child(subword_inner)
		inner_world_grid_manager = subword_inner as InnerWorldGridManager
		if inner_world_grid_manager:
			DebugLogger.info("InnerWorldInitializer: 里世界场景已实例化", "InnerWorldInitializer")
		else:
			DebugLogger.warning("InnerWorldInitializer: 未找到InnerWorldGridManager节点", "InnerWorldInitializer")
	else:
		DebugLogger.error("InnerWorldInitializer: 无法实例化里世界场景", "InnerWorldInitializer")

# ========== 公共接口 ==========
## 获取里世界场景引用
func get_inner_world_scene() -> Control:
	return subword_inner

## 获取里世界网格管理器引用
func get_inner_world_grid_manager() -> InnerWorldGridManager:
	return inner_world_grid_manager
