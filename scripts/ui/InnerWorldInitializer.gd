extends SubViewport

## 里世界初始化器
## 挂载到 SubViewport_Inner 节点，负责实例化里世界场景

# ========== 预加载 ==========
const SubwordInnerScene = preload("res://scenes/subword_inner.tscn")

# ========== 内部属性 ==========
var subword_inner: Control = null
var inner_world: InnerWorld = null

# ========== 初始化 ==========
func _ready() -> void:
	_instantiate_inner_world()

# ========== 实例化里世界 ==========
func _instantiate_inner_world() -> void:
	subword_inner = SubwordInnerScene.instantiate()
	if subword_inner:
		add_child(subword_inner)
		inner_world = subword_inner.get_node_or_null("InnerWorld") as InnerWorld
		if inner_world:
			DebugLogger.info("InnerWorldInitializer: 里世界场景已实例化", "InnerWorldInitializer")
		else:
			DebugLogger.warning("InnerWorldInitializer: 未找到InnerWorld节点", "InnerWorldInitializer")
	else:
		DebugLogger.error("InnerWorldInitializer: 无法实例化里世界场景", "InnerWorldInitializer")

# ========== 公共接口 ==========
## 获取里世界场景引用
func get_inner_world_scene() -> Control:
	return subword_inner

## 获取里世界引用
func get_inner_world() -> InnerWorld:
	return inner_world
