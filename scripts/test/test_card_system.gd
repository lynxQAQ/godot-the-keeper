extends Node

## 卡牌系统测试脚本
## 用于测试卡牌库、手牌、卡牌UI等功能

# ========== 节点引用 ==========
var hand_display: HandDisplay = null

# ========== 测试数据 ==========
var test_hand: Hand = null

# ========== 初始化 ==========
func _ready() -> void:
	print("========== 卡牌系统测试开始 ==========")
	
	# 等待一帧，确保所有autoload单例都已初始化
	await get_tree().process_frame
	
	# 运行测试
	_test_card_library()
	_test_hand_system()
	_test_card_ui()
	
	print("========== 卡牌系统测试完成 ==========")

# ========== 测试卡牌库 ==========
func _test_card_library() -> void:
	print("\n--- 测试CardLibrary ---")
	
	# 测试获取卡牌
	var card1 = CardLibrary.get_card("entity_totem_01")
	if card1:
		print("✓ 找到卡牌: " + card1.name + " (ID: " + card1.id + ")")
	else:
		print("✗ 未找到卡牌: entity_totem_01")
	
	var card2 = CardLibrary.get_card("virtual_omen_01")
	if card2:
		print("✓ 找到卡牌: " + card2.name + " (ID: " + card2.id + ")")
	else:
		print("✗ 未找到卡牌: virtual_omen_01")
	
	# 测试获取所有卡牌
	var all_cards = CardLibrary.get_all_cards()
	print("✓ 卡牌库中共有 " + str(all_cards.size()) + " 张卡牌")

# ========== 测试手牌系统 ==========
func _test_hand_system() -> void:
	print("\n--- 测试Hand系统 ---")
	
	# 创建手牌实例
	test_hand = Hand.new(5)
	print("✓ 创建手牌实例，上限: " + str(test_hand.get_max_size()))
	
	# 添加卡牌
	if test_hand.add_card("entity_totem_01"):
		print("✓ 添加卡牌: entity_totem_01")
	else:
		print("✗ 添加卡牌失败: entity_totem_01")
	
	if test_hand.add_card("virtual_omen_01"):
		print("✓ 添加卡牌: virtual_omen_01")
	else:
		print("✗ 添加卡牌失败: virtual_omen_01")
	
	print("✓ 当前手牌数量: " + str(test_hand.get_size()) + "/" + str(test_hand.get_max_size()))
	
	# 测试获取所有手牌
	var hand_cards = test_hand.get_all_cards()
	print("✓ 手牌列表: " + str(hand_cards))

# ========== 测试卡牌UI ==========
func _test_card_ui() -> void:
	print("\n--- 测试CardUI ---")
	
	# 检查CardUI场景是否存在
	if ResourceLoader.exists("res://scenes/cards/CardUI.tscn"):
		print("✓ CardUI场景存在")
	else:
		print("✗ CardUI场景不存在")
	
	# 检查HandDisplay场景是否存在
	if ResourceLoader.exists("res://scenes/ui/HandDisplay.tscn"):
		print("✓ HandDisplay场景存在")
	else:
		print("✗ HandDisplay场景不存在")
