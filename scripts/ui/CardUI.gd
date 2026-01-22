extends Control
class_name CardUI

## 卡牌UI组件
## 负责卡牌的视觉表现、交互、悬停效果等

# ========== 节点引用 ==========
@onready var card_name_label: Label = $VBoxContainer/CardNameLabel
@onready var card_type_label: Label = $VBoxContainer/CardTypeLabel
@onready var card_cost_label: Label = $VBoxContainer/CardCostLabel
@onready var card_description_label: Label = $VBoxContainer/CardDescriptionLabel
@onready var card_icon: TextureRect = $VBoxContainer/CardIcon

# ========== 卡牌数据 ==========
var card_id: String = ""
var card_data: CardData = null
var is_selected: bool = false

# ========== 悬停状态 ==========
var original_position: Vector2 = Vector2.ZERO  # 原始位置
var original_z_index: int = 0  # 原始z-index
var hover_offset_y: float = -30.0  # hover时向上移动的距离
var hover_scale: Vector2 = Vector2(1.1, 1.1)  # hover时的放大倍数
var is_hovering: bool = false  # 是否正在hover
var current_tween: Tween = null  # 当前动画

# ========== 信号 ==========
signal card_clicked(card_id: String)
signal card_hovered(card_id: String)
signal card_unhovered(card_id: String)

# ========== 初始化 ==========
func _ready() -> void:
	# 设置鼠标过滤，允许接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 记录原始z-index
	original_z_index = z_index
	
	# 连接鼠标事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	# 延迟更新原始位置（确保已添加到容器并完成布局）
	call_deferred("_update_original_position")
	
	# 调试输出
	if card_data:
		DebugLogger.debug("CardUI: 初始化完成，卡牌: " + card_data.name, "CardUI")

## 更新原始位置（延迟执行，确保已添加到父容器）
func _update_original_position() -> void:
	if not is_hovering:
		original_position = position
		original_z_index = z_index

# ========== 设置卡牌数据 ==========
func set_card(card: CardData) -> void:
	card_data = card
	if card_data:
		card_id = card_data.id
		_update_display()
	else:
		card_id = ""
		_clear_display()

func _update_display() -> void:
	if not card_data:
		return
	
	# 更新名称
	if card_name_label:
		card_name_label.text = card_data.name
	
	# 更新类型和序列
	if card_type_label:
		card_type_label.text = card_data.get_card_type_name() + " - " + card_data.get_serial_name()
	
	# 更新消耗
	if card_cost_label:
		var cost_text = ""
		if card_data.cost_table_construct > 0:
			cost_text += "表:" + str(card_data.cost_table_construct) + " "
		if card_data.cost_inner_construct > 0:
			cost_text += "里:" + str(card_data.cost_inner_construct)
		card_cost_label.text = cost_text
	
	# 更新描述
	if card_description_label:
		card_description_label.text = card_data.description
	
	# 更新图标（如果有）
	# if card_icon and card_data.has("icon_path"):
	#     var icon_texture = load(card_data.icon_path)
	#     if icon_texture:
	#         card_icon.texture = icon_texture

func _clear_display() -> void:
	if card_name_label:
		card_name_label.text = ""
	if card_type_label:
		card_type_label.text = ""
	if card_cost_label:
		card_cost_label.text = ""
	if card_description_label:
		card_description_label.text = ""

# ========== 选中状态 ==========
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_selected_visual()

func _update_selected_visual() -> void:
	if is_selected:
		modulate = Color(1.2, 1.2, 1.0)  # 高亮
		# 可以添加边框或其他视觉效果
	else:
		modulate = Color.WHITE

# ========== 悬停效果 ==========
func _on_mouse_entered() -> void:
	if card_id.is_empty() or is_hovering:
		return
	
	# 停止之前的动画（如果有）
	if current_tween:
		current_tween.kill()
	
	is_hovering = true
	
	# 更新原始位置（在hover开始时记录，防止容器布局改变位置）
	original_position = position
	original_z_index = z_index
	
	# 提升层级（置顶）
	z_index = 100
	
	# 设置缩放中心点为顶部中心，这样放大时不会向下偏移
	pivot_offset = Vector2(size.x / 2.0, 0.0)
	
	# 创建动画
	current_tween = create_tween()
	current_tween.set_parallel(true)  # 并行执行多个动画
	
	# 放大效果
	current_tween.tween_property(self, "scale", hover_scale, 0.2)
	
	# 向上移动（修改position.y）
	var target_position = original_position + Vector2(0, hover_offset_y)
	current_tween.tween_property(self, "position", target_position, 0.2)
	
	# 显示详情（可以触发信号让其他UI显示详情）
	card_hovered.emit(card_id)

func _on_mouse_exited() -> void:
	if card_id.is_empty() or not is_hovering:
		return
	
	# 停止之前的动画（如果有）
	if current_tween:
		current_tween.kill()
	
	# 创建恢复动画
	current_tween = create_tween()
	current_tween.set_parallel(true)  # 并行执行多个动画
	
	# 恢复大小
	current_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 恢复位置
	current_tween.tween_property(self, "position", original_position, 0.2)
	
	# 动画完成后恢复层级和缩放中心点
	current_tween.tween_callback(_on_restore_complete)
	
	# 隐藏详情
	card_unhovered.emit(card_id)

## 恢复完成回调
func _on_restore_complete() -> void:
	is_hovering = false
	z_index = original_z_index
	pivot_offset = Vector2.ZERO  # 恢复缩放中心点
	current_tween = null
	
	# 延迟更新原始位置（等待容器可能重新布局）
	call_deferred("_update_original_position")

# ========== 点击事件 ==========
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not card_id.is_empty():
				card_clicked.emit(card_id)
