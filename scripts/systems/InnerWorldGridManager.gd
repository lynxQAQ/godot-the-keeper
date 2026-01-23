extends Control
class_name InnerWorldGridManager

## 里世界网格管理器
## 管理里世界的网格逻辑和交互，类似 SurfaceWorldGrid

# ========== 信号 ==========
## 网格被开垦
signal grid_explored(grid_pos: Vector2i)
## 真理之茧被创建
signal truth_cocoon_created(grid_pos: Vector2i)
## 真理要素被放置
signal truth_element_placed(grid_pos: Vector2i)

# ========== 组件引用 ==========
## 里世界网格系统
var inner_world_grid: InnerWorldGrid = null
## 真理之茧系统
var truth_cocoon_system: TruthCocoon = null
## 真理要素培育系统
var truth_cultivation_system: TruthCultivation = null
## 仪式系统
var ritual_system: Ritual = null

# ========== 生命周期 ==========
func _ready():
	# 重要：设置鼠标过滤模式为 IGNORE，让事件穿透到子节点
	# 由于 InnerWorldGridManager 挂载在 Panel 上，Panel 本身是 Control 节点
	# 我们需要确保事件能传递到 InnerWorldGrid -> GridSystem
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	DebugLogger.debug("InnerWorldGridManager: 设置 mouse_filter = MOUSE_FILTER_IGNORE", "InnerWorldGridManager")
	
	# 初始化组件
	_initialize_components()
	
	# 设置组件引用（延迟到 InnerWorldGrid 初始化完成）
	call_deferred("_setup_component_references")

# ========== 组件初始化 ==========
## 初始化所有组件
func _initialize_components() -> void:
	# 获取或创建组件节点
	inner_world_grid = get_node_or_null("InnerWorldGrid") as InnerWorldGrid
	if not inner_world_grid:
		push_error("InnerWorldGridManager: 未找到 InnerWorldGrid 节点")
		return
	
	truth_cocoon_system = get_node_or_null("TruthCocoon") as TruthCocoon
	if not truth_cocoon_system:
		truth_cocoon_system = TruthCocoon.new()
		truth_cocoon_system.name = "TruthCocoon"
		add_child(truth_cocoon_system)
	
	truth_cultivation_system = get_node_or_null("TruthCultivation") as TruthCultivation
	if not truth_cultivation_system:
		truth_cultivation_system = TruthCultivation.new()
		truth_cultivation_system.name = "TruthCultivation"
		add_child(truth_cultivation_system)
	
	ritual_system = get_node_or_null("Ritual") as Ritual
	if not ritual_system:
		ritual_system = Ritual.new()
		ritual_system.name = "Ritual"
		add_child(ritual_system)

## 设置组件引用
func _setup_component_references() -> void:
	if not inner_world_grid:
		# 等待 InnerWorldGrid 初始化完成
		await get_tree().process_frame
		inner_world_grid = get_node_or_null("InnerWorldGrid") as InnerWorldGrid
	
	if inner_world_grid:
		# 等待 InnerWorldGrid 的网格系统初始化完成
		if not inner_world_grid.grid_system:
			var grid_system = inner_world_grid.get_grid_system()
			if grid_system:
				await grid_system.grid_map_initialized
		
		# 初始化真理之茧系统
		if truth_cocoon_system:
			truth_cocoon_system.initialize(inner_world_grid)
			inner_world_grid.set_truth_cocoon_system(truth_cocoon_system)
		
		# 初始化真理要素培育系统
		if truth_cultivation_system:
			truth_cultivation_system.initialize(inner_world_grid)
		
		# 初始化仪式系统
		if ritual_system:
			ritual_system.initialize(inner_world_grid)
		
		# 连接组件信号
		_connect_component_signals()

## 连接组件信号
func _connect_component_signals() -> void:
	if inner_world_grid:
		if not inner_world_grid.truth_cocoon_created.is_connected(_on_truth_cocoon_created):
			inner_world_grid.truth_cocoon_created.connect(_on_truth_cocoon_created)
		if not inner_world_grid.truth_element_placed.is_connected(_on_truth_element_placed):
			inner_world_grid.truth_element_placed.connect(_on_truth_element_placed)

## 组件信号转发
func _on_truth_cocoon_created(grid_pos: Vector2i) -> void:
	truth_cocoon_created.emit(grid_pos)

func _on_truth_element_placed(grid_pos: Vector2i) -> void:
	truth_element_placed.emit(grid_pos)


# ========== 公共接口 ==========
## 获取网格系统引用
func get_grid_system() -> GridSystemInner:
	if inner_world_grid:
		return inner_world_grid.get_grid_system()
	return null

## 获取网格管理器引用
func get_grid_manager() -> GridMapManager:
	if inner_world_grid:
		return inner_world_grid.get_grid_manager()
	return null

## 获取里世界网格引用
func get_inner_world_grid() -> InnerWorldGrid:
	return inner_world_grid
