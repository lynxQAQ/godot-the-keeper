extends Node

## 游戏管理器引用系统
## 用于存储和访问从load_game场景加载的管理器实例
## 这些管理器不再是autoload，而是通过load_game场景初始化后注册到这里

# ========== 管理器引用 ==========
var ResourceManager: ResourceManager = null
var ConstructManager: ConstructManager = null
var InvestigatorManager: InvestigatorManager = null
var CardLibrary: CardLibrary = null
var CardUsage: CardUsage = null

# ========== 初始化 ==========
func _ready() -> void:
	DebugLogger.info("GameManagers: 初始化完成", "GameManagers")

# ========== 注册管理器 ==========
## 注册资源管理器
func register_resource_manager(manager: ResourceManager) -> void:
	ResourceManager = manager
	DebugLogger.info("GameManagers: ResourceManager已注册", "GameManagers")

## 注册构造体管理器
func register_construct_manager(manager: ConstructManager) -> void:
	ConstructManager = manager
	DebugLogger.info("GameManagers: ConstructManager已注册", "GameManagers")

## 注册调查员管理器
func register_investigator_manager(manager: InvestigatorManager) -> void:
	InvestigatorManager = manager
	DebugLogger.info("GameManagers: InvestigatorManager已注册", "GameManagers")

## 注册卡牌库
func register_card_library(manager: CardLibrary) -> void:
	CardLibrary = manager
	DebugLogger.info("GameManagers: CardLibrary已注册", "GameManagers")

## 注册卡牌使用系统
func register_card_usage(manager: CardUsage) -> void:
	CardUsage = manager
	DebugLogger.info("GameManagers: CardUsage已注册", "GameManagers")

# ========== 检查管理器是否已加载 ==========
## 检查所有管理器是否已加载
func are_managers_loaded() -> bool:
	return ResourceManager != null and \
		   ConstructManager != null and \
		   InvestigatorManager != null and \
		   CardLibrary != null and \
		   CardUsage != null

## 清理所有管理器引用
func clear_all() -> void:
	ResourceManager = null
	ConstructManager = null
	InvestigatorManager = null
	CardLibrary = null
	CardUsage = null
	DebugLogger.info("GameManagers: 所有管理器引用已清理", "GameManagers")
