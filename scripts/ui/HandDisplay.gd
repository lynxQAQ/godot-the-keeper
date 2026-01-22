extends Control
class_name HandDisplay

## 手牌/预备区显示UI
## 负责显示手牌或预备区卡牌列表、拖拽、选择等交互
## 注意：手牌区和预备区是同一个UI区域，可以显示手牌或预备区的数据

# ========== 节点引用 ==========
@onready var hand_container: HBoxContainer = $HandContainer
@onready var capacity_label: Label = get_node_or_null("CapacityLabel")  # 可选：容量标签
var card_prefab: PackedScene = null  # 延迟加载，避免场景不存在时报错

# ========== 数据 ==========
var hand: Hand = null  # 手牌数据（如果显示手牌）
var reserve: CardReserve = null  # 预备区数据（如果显示预备区）
var card_ui_list: Array[CardUI] = []

# ========== 信号 ==========
signal card_selected(card_id: String)
signal card_used(card_id: String)

# ========== 初始化 ==========
func _ready() -> void:
	if hand_container == null:
		push_error("HandDisplay: HandContainer节点未找到")

# ========== 设置手牌 ==========
func set_hand(hand_instance: Hand) -> void:
	hand = hand_instance
	reserve = null  # 清除预备区引用
	_update_display()

# ========== 设置预备区 ==========
func set_reserve(reserve_instance: CardReserve) -> void:
	reserve = reserve_instance
	hand = null  # 清除手牌引用
	_update_display()

# ========== 更新显示 ==========
func _update_display() -> void:
	if not hand_container:
		DebugLogger.warning("HandDisplay: HandContainer节点未找到，无法更新显示", "HandDisplay")
		return
	
	# 清空现有卡牌UI
	_clear_cards()
	
	# 更新容量显示（如果有容量标签）
	if capacity_label:
		if reserve:
			capacity_label.text = "预备区: " + str(reserve.get_size()) + "/" + str(reserve.get_max_capacity())
		elif hand:
			capacity_label.text = "手牌: " + str(hand.get_size()) + "/" + str(hand.get_max_size())
		else:
			capacity_label.text = ""
	
	# 获取要显示的卡牌列表
	var card_ids: Array[String] = []
	if hand:
		card_ids = hand.get_all_cards()
		DebugLogger.debug("HandDisplay: 显示手牌，数量: " + str(card_ids.size()), "HandDisplay")
	elif reserve:
		card_ids = reserve.get_all_cards()
		DebugLogger.debug("HandDisplay: 显示预备区，数量: " + str(card_ids.size()), "HandDisplay")
	else:
		DebugLogger.warning("HandDisplay: 没有手牌或预备区数据", "HandDisplay")
		return
	
	if card_ids.is_empty():
		DebugLogger.debug("HandDisplay: 卡牌列表为空，不显示任何卡牌", "HandDisplay")
		return
	
	# 创建卡牌UI
	for card_id in card_ids:
		var card = CardLibrary.get_card(card_id)
		if card:
			_create_card_ui(card)
		else:
			DebugLogger.warning("HandDisplay: 卡牌不存在: " + card_id, "HandDisplay")

func _create_card_ui(card: CardData) -> void:
	# 延迟加载场景
	if not card_prefab:
		if ResourceLoader.exists("res://scenes/cards/CardUI.tscn"):
			card_prefab = load("res://scenes/cards/CardUI.tscn")
		else:
			push_warning("HandDisplay: CardUI场景不存在，跳过创建")
			return
	
	if not card_prefab:
		return
	
	var card_ui = card_prefab.instantiate() as CardUI
	if not card_ui:
		push_error("HandDisplay: 无法实例化CardUI")
		return
	
	# 设置卡牌数据
	card_ui.set_card(card)
	
	# 连接信号
	card_ui.card_clicked.connect(_on_card_clicked)
	card_ui.card_hovered.connect(_on_card_hovered)
	card_ui.card_unhovered.connect(_on_card_unhovered)
	
	# 添加到容器
	hand_container.add_child(card_ui)
	card_ui_list.append(card_ui)
	
	# 延迟更新卡牌的原始位置（确保已添加到容器并完成布局）
	card_ui.call_deferred("_update_original_position")
	
	# 调试输出
	DebugLogger.debug("HandDisplay: 创建卡牌UI: " + card.id + " - " + card.name, "HandDisplay")

func _clear_cards() -> void:
	for card_ui in card_ui_list:
		if is_instance_valid(card_ui):
			card_ui.queue_free()
	card_ui_list.clear()

# ========== 卡牌交互 ==========
func _on_card_clicked(card_id: String) -> void:
	# 选中卡牌
	_select_card(card_id)
	card_selected.emit(card_id)

func _on_card_hovered(card_id: String) -> void:
	# 可以显示卡牌详情
	pass

func _on_card_unhovered(card_id: String) -> void:
	# 隐藏卡牌详情
	pass

func _select_card(card_id: String) -> void:
	# 取消所有选中
	for card_ui in card_ui_list:
		if is_instance_valid(card_ui):
			card_ui.set_selected(false)
	
	# 选中指定卡牌
	for card_ui in card_ui_list:
		if is_instance_valid(card_ui) and card_ui.card_id == card_id:
			card_ui.set_selected(true)
			break

# ========== 刷新显示 ==========
func refresh() -> void:
	_update_display()
