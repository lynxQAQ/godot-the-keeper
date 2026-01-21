extends Node
# 预加载工具类（Extensions和Helpers不是autoload，需要预加载）
const Extensions = preload("res://scripts/utils/Extensions.gd")
const Helpers = preload("res://scripts/utils/Helpers.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 测试Constants
	print("测试Constants:")
	print("准备阶段: ", Constants.PREPARATION_PHASE)
	print("网格类型-未开垦: ", Constants.GRID_TYPE_UNEXPLORED)
	
	# 测试SignalBus
	print("\n测试SignalBus:")
	print("SignalBus节点: ", SignalBus)
	
	# 测试Logger
	print("\n测试Logger:")
	DebugLogger.info("这是一条测试日志", "Test")
	
	# 测试Extensions（静态调用）
	print("\n测试Extensions:")
	var test_pos = Vector2i(5, 5)
	var neighbors = Extensions.get_neighbor_grids(test_pos)
	print("相邻网格: ", neighbors)
	
	# 测试Helpers（静态调用）
	print("\n测试Helpers:")
	var distance = Helpers.distance(Vector2(0, 0), Vector2(3, 4))
	print("距离: ", distance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
