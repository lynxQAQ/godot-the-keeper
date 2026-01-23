extends Control

## 加载场景脚本
## 负责初始化游戏所需的管理器，然后跳转到游戏主场景

# ========== 节点引用 ==========
@onready var resource_manager_node: Node = get_node("Managers/ResourceManager")
@onready var construct_manager_node: Node = get_node("Managers/ConstructManager")
@onready var investigator_manager_node: Node = get_node("Managers/InvestigatorManager")
@onready var card_library_node: Node = get_node("Managers/CardLibrary")
@onready var card_usage_node: Node = get_node("Managers/CardUsage")

# ========== 初始化 ==========
func _ready() -> void:
	DebugLogger.info("LoadGame: 开始加载游戏管理器", "LoadGame")
	
	# 等待一帧，确保所有节点都已准备好
	await get_tree().process_frame
	
	# 注册所有管理器到GameManagers
	_register_managers()
	
	# 等待所有管理器初始化完成
	await _wait_for_managers_ready()
	
	# 跳转到游戏主场景
	_transition_to_game()

# ========== 注册管理器 ==========
func _register_managers() -> void:
	if resource_manager_node:
		GameManagers.register_resource_manager(resource_manager_node)
	
	if construct_manager_node:
		GameManagers.register_construct_manager(construct_manager_node)
	
	if investigator_manager_node:
		GameManagers.register_investigator_manager(investigator_manager_node)
	
	if card_library_node:
		GameManagers.register_card_library(card_library_node)
	
	if card_usage_node:
		GameManagers.register_card_usage(card_usage_node)
	
	DebugLogger.info("LoadGame: 所有管理器已注册", "LoadGame")

# ========== 等待管理器就绪 ==========
func _wait_for_managers_ready() -> void:
	# 等待所有管理器节点完成_ready()
	# 由于_ready()是同步的，这里主要是等待一些异步初始化（如果有的话）
	await get_tree().process_frame
	await get_tree().process_frame
	
	# 验证所有管理器都已注册
	if GameManagers.are_managers_loaded():
		DebugLogger.info("LoadGame: 所有管理器已就绪", "LoadGame")
	else:
		DebugLogger.error("LoadGame: 部分管理器未成功加载", "LoadGame")

# ========== 跳转到游戏场景 ==========
func _transition_to_game() -> void:
	DebugLogger.info("LoadGame: 跳转到游戏主场景", "LoadGame")
	SceneManager.change_scene(SceneManager.SCENE_GAME)
