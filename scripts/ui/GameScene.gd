extends Control
class_name GameScene

## 游戏主场景
## 负责布局两个子窗口（表世界和里世界）

# ========== 节点引用 ==========
@onready var control_top: Control = get_node("Control (top)")
@onready var sub_win_area: HBoxContainer = get_node("HBoxContainer (sub_win_area)")
@onready var sub_viewport_surface: SubViewport = get_node("HBoxContainer (sub_win_area)/PanelContainer_Surface/SubViewportContainer_Surface/SubViewport_Surface")
@onready var sub_viewport_inner: SubViewport = get_node("HBoxContainer (sub_win_area)/PanelContainer_Inner/SubViewportContainer_Inner/SubViewport_Inner")
@onready var control_bottom: Control = get_node("Control (bottom)")

# ========== 预加载 ==========
const SubworldSurfaceScene = preload("res://scenes/subworld_surface.tscn")
const SubwordInnerScene = preload("res://scenes/subword_inner.tscn")
const HandDisplayScene = preload("res://scenes/ui/HandDisplay.tscn")

# ========== 导出属性 ==========

# ========== 内部属性 ==========
## 表世界子窗口
var subworld_surface: SurfaceWorldGrid = null

## 里世界子窗口
var subword_inner: InnerWorldGrid = null

## 手牌显示UI
var hand_display: HandDisplay = null

## 手牌数据
var hand: Hand = null

# ========== 生命周期 ==========
func _ready():
	# 设置全屏布局
	_setup_layout()
	
	# 实例化子窗口
	_instantiate_subwindows()
	
	# 初始化手牌系统
	_initialize_hand_system()

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
		sub_viewport_surface.add_child(subworld_surface)
	
	# 实例化里世界子窗口
	subword_inner = SubwordInnerScene.instantiate()
	if subword_inner:
		sub_viewport_inner.add_child(subword_inner)

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

# ========== 手牌系统 ==========
## 初始化手牌系统
func _initialize_hand_system() -> void:
	# 创建手牌实例
	hand = Hand.new(Constants.DEFAULT_HAND_SIZE)
	
	# 等待一帧，确保CardLibrary已加载卡牌数据
	await get_tree().process_frame
	
	# 添加测试卡牌（如果卡牌库中有数据）
	_add_test_cards_to_hand()
	
	# 实例化HandDisplay
	_instantiate_hand_display()
	
	# 将手牌数据设置到HandDisplay
	if hand_display and hand:
		hand_display.set_hand(hand)
		DebugLogger.info("GameScene: 手牌系统初始化完成，手牌数量: " + str(hand.get_size()), "GameScene")

## 添加测试卡牌到手牌
func _add_test_cards_to_hand() -> void:
	if not hand:
		return
	
	# 尝试添加卡牌库中的卡牌
	var test_card_ids = ["entity_totem_01", "virtual_omen_01"]
	
	for card_id in test_card_ids:
		var card = CardLibrary.get_card(card_id)
		if card:
			if hand.add_card(card_id):
				DebugLogger.debug("GameScene: 添加测试卡牌到手牌: " + card_id, "GameScene")
			else:
				DebugLogger.warning("GameScene: 无法添加卡牌到手牌（手牌可能已满）: " + card_id, "GameScene")
		else:
			DebugLogger.warning("GameScene: 卡牌不存在: " + card_id, "GameScene")

## 实例化HandDisplay
func _instantiate_hand_display() -> void:
	if not control_bottom:
		DebugLogger.error("GameScene: Control (bottom) 节点未找到", "GameScene")
		return
	
	# 实例化HandDisplay场景
	hand_display = HandDisplayScene.instantiate()
	if hand_display:
		control_bottom.add_child(hand_display)
		# 确保HandDisplay填充整个底部区域
		hand_display.set_anchors_preset(Control.PRESET_FULL_RECT)
		DebugLogger.info("GameScene: HandDisplay已添加到Control (bottom)，位置: " + str(control_bottom.get_rect()), "GameScene")
	else:
		DebugLogger.error("GameScene: 无法实例化HandDisplay场景", "GameScene")

## 获取手牌显示UI引用
func get_hand_display() -> HandDisplay:
	return hand_display

## 获取手牌数据引用
func get_hand() -> Hand:
	return hand
