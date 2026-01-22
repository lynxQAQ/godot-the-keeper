extends Control

## 资源显示UI
## 显示表构造力、里构造力等资源的当前值、上限，以及资源变化动画

# ========== 节点引用 ==========
@onready var table_construct_label: Label = get_node("VBoxContainer/TableConstructContainer/TableConstructLabel")
@onready var table_construct_max_label: Label = get_node("VBoxContainer/TableConstructContainer/TableConstructMaxLabel")
@onready var inner_construct_label: Label = get_node("VBoxContainer/InnerConstructContainer/InnerConstructLabel")
@onready var inner_construct_max_label: Label = get_node("VBoxContainer/InnerConstructContainer/InnerConstructMaxLabel")
@onready var truth_element_container: VBoxContainer = get_node("VBoxContainer/TruthElementContainer")

# ========== 动画节点 ==========
var _table_construct_animation_player: AnimationPlayer = null
var _inner_construct_animation_player: AnimationPlayer = null
var _change_indicators: Dictionary = {}  # 存储变化提示节点

# ========== 内部变量 ==========
var _last_table_construct: int = 0
var _last_inner_construct: int = 0
var _truth_element_labels: Dictionary = {}  # {serial: Label}

# ========== 初始化 ==========
func _ready() -> void:
	# 连接资源变化信号
	SignalBus.table_construct_changed.connect(_on_table_construct_changed)
	SignalBus.inner_construct_changed.connect(_on_inner_construct_changed)
	SignalBus.truth_element_changed.connect(_on_truth_element_changed)
	
	# 初始化显示
	_update_table_construct_display()
	_update_inner_construct_display()
	_setup_truth_element_display()
	
	# 获取初始值
	# 注意：ResourceManager需要配置为autoload单例才能直接访问
	if has_node("/root/ResourceManager"):
		var rm = get_node("/root/ResourceManager")
		_last_table_construct = rm.get_table_construct()
		_last_inner_construct = rm.get_inner_construct()
	elif ResourceManager:  # 如果配置为autoload，可以直接访问
		_last_table_construct = ResourceManager.get_table_construct()
		_last_inner_construct = ResourceManager.get_inner_construct()
	
	DebugLogger.info("ResourceDisplay: UI初始化完成", "ResourceDisplay")

# ========== 表构造力显示 ==========
func _update_table_construct_display() -> void:
	var rm = _get_resource_manager()
	if not rm:
		return
	
	var current = rm.get_table_construct()
	var max_value = rm.get_table_construct_max()
	
	if table_construct_label:
		table_construct_label.text = "表构造力: " + str(current)
	
	if table_construct_max_label:
		table_construct_max_label.text = "/" + str(max_value)
	
	# 检查资源不足警告
	if current == 0:
		_show_resource_warning("table_construct", true)
	else:
		_show_resource_warning("table_construct", false)

func _on_table_construct_changed(current_value: int, max_value: int) -> void:
	var old_value = _last_table_construct
	_last_table_construct = current_value
	
	_update_table_construct_display()
	
	# 显示变化动画
	if current_value > old_value:
		_show_change_indicator("table_construct", current_value - old_value, true)
	elif current_value < old_value:
		_show_change_indicator("table_construct", old_value - current_value, false)

# ========== 里构造力显示 ==========
func _update_inner_construct_display() -> void:
	var rm = _get_resource_manager()
	if not rm:
		return
	
	var current = rm.get_inner_construct()
	var max_value = rm.get_inner_construct_max()
	
	if inner_construct_label:
		inner_construct_label.text = "里构造力: " + str(current)
	
	if inner_construct_max_label:
		inner_construct_max_label.text = "/" + str(max_value)
	
	# 检查资源不足警告
	if current == 0:
		_show_resource_warning("inner_construct", true)
	else:
		_show_resource_warning("inner_construct", false)

func _on_inner_construct_changed(current_value: int, max_value: int) -> void:
	var old_value = _last_inner_construct
	_last_inner_construct = current_value
	
	_update_inner_construct_display()
	
	# 显示变化动画
	if current_value > old_value:
		_show_change_indicator("inner_construct", current_value - old_value, true)
	elif current_value < old_value:
		_show_change_indicator("inner_construct", old_value - current_value, false)

# ========== 真理要素显示 ==========
func _setup_truth_element_display() -> void:
	if not truth_element_container:
		return
	
	# 为每个序列创建标签
	for serial in range(1, Constants.TRUTH_SERIAL_COUNT + 1):
		var serial_name = _get_serial_name(serial)
		var label = Label.new()
		label.name = "TruthElementLabel_" + str(serial)
		label.text = serial_name + ": 0"
		truth_element_container.add_child(label)
		_truth_element_labels[serial] = label
	
	# 更新显示
	_update_all_truth_elements()

func _update_all_truth_elements() -> void:
	if not has_node("/root/ResourceManager"):
		return
	
	var rm = get_node("/root/ResourceManager")
	var truth_resource = rm.get_truth_element_resource()
	if not truth_resource:
		return
	
	for serial in range(1, Constants.TRUTH_SERIAL_COUNT + 1):
		var count = truth_resource.get_truth_element_count(serial)
		_update_truth_element_display(serial, count)

func _update_truth_element_display(serial: int, count: int) -> void:
	if not _truth_element_labels.has(serial):
		return
	
	var label = _truth_element_labels[serial]
	var serial_name = _get_serial_name(serial)
	label.text = serial_name + ": " + str(count)

func _on_truth_element_changed(serial: int, count: int) -> void:
	_update_truth_element_display(serial, count)

func _get_serial_name(serial: int) -> String:
	match serial:
		1: return "序列 I"
		2: return "序列 II"
		3: return "序列 III"
		4: return "序列 IV"
		5: return "序列 V"
		_: return "序列 " + str(serial)

# ========== 工具函数 ==========
## 获取ResourceManager实例
func _get_resource_manager():
	if has_node("/root/ResourceManager"):
		return get_node("/root/ResourceManager")
	elif ResourceManager:  # 如果配置为autoload，可以直接访问
		return ResourceManager
	return null

# ========== 动画和提示 ==========
## 显示资源变化指示器
func _show_change_indicator(resource_type: String, amount: int, is_positive: bool) -> void:
	# 创建变化提示标签
	var indicator = Label.new()
	indicator.name = "ChangeIndicator_" + resource_type + "_" + str(Time.get_ticks_msec())
	var prefix = "+" if is_positive else "-"
	indicator.text = prefix + str(amount)
	indicator.modulate = Color.GREEN if is_positive else Color.RED
	indicator.add_theme_font_size_override("font_size", 20)
	
	# 添加到场景
	add_child(indicator)
	
	# 设置位置（可以根据resource_type调整）
	var base_pos = Vector2(50, 50)
	if resource_type == "table_construct":
		base_pos = Vector2(50, 50)
	elif resource_type == "inner_construct":
		base_pos = Vector2(50, 100)
	
	indicator.position = base_pos
	
	# 创建动画
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(indicator, "position", base_pos + Vector2(0, -50), 1.0)
	tween.tween_property(indicator, "modulate:a", 0.0, 1.0)
	tween.tween_callback(indicator.queue_free)

## 显示资源不足警告
func _show_resource_warning(resource_type: String, show: bool) -> void:
	# 这里可以实现资源不足时的警告效果
	# 例如：改变标签颜色、显示警告图标等
	if show:
		if resource_type == "table_construct" and table_construct_label:
			table_construct_label.modulate = Color.RED
		elif resource_type == "inner_construct" and inner_construct_label:
			inner_construct_label.modulate = Color.RED
	else:
		if resource_type == "table_construct" and table_construct_label:
			table_construct_label.modulate = Color.WHITE
		elif resource_type == "inner_construct" and inner_construct_label:
			inner_construct_label.modulate = Color.WHITE
