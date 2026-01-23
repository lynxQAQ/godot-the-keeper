extends Node

## 场景管理器
## 负责场景切换和管理

# ========== 场景路径常量 ==========
const SCENE_MAIN_MENU: String = "res://MainMenu.tscn"
const SCENE_LOAD_GAME: String = "res://scenes/load_game.tscn"
const SCENE_GAME: String = "res://scenes/game_scene.tscn"
const SCENE_GALLERY: String = "res://scenes/gallery.tscn"

# ========== 内部变量 ==========
var _current_scene: Node = null
var _is_switching: bool = false

# ========== 初始化 ==========
func _ready() -> void:
	DebugLogger.info("SceneManager: 初始化完成", "SceneManager")
	# 不再使用 current_scene_changed 信号
	# _current_scene 可以通过 change_scene 手动更新

# ========== 场景切换 ==========
## 切换到指定场景
## scene_path: 场景文件路径
## fade_out: 是否淡出（暂未实现）
## fade_in: 是否淡入（暂未实现）
func change_scene(scene_path: String, fade_out: bool = false, fade_in: bool = false) -> void:
	if _is_switching:
		DebugLogger.warning("SceneManager: 场景切换中，忽略重复请求", "SceneManager")
		return
	
	if not FileAccess.file_exists(scene_path):
		DebugLogger.error("SceneManager: 场景文件不存在: " + scene_path, "SceneManager")
		return
	
	_is_switching = true
	DebugLogger.info("SceneManager: 切换到场景: " + scene_path, "SceneManager")
	
	# 发射场景切换信号
	SignalBus.scene_changing.emit(scene_path)
	
	# 切换场景
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		DebugLogger.error("SceneManager: 场景切换失败，错误代码: " + str(error), "SceneManager")
		_is_switching = false
		return
	
	# Godot 4 不再有 current_scene_changed 信号，手动更新 _current_scene
	_current_scene = get_tree().current_scene
	_is_switching = false
	
	if _current_scene:
		DebugLogger.info("SceneManager: 场景切换完成: " + _current_scene.scene_file_path, "SceneManager")
		SignalBus.scene_changed.emit(_current_scene.scene_file_path)
	else:
		DebugLogger.warning("SceneManager: 当前场景为空", "SceneManager")

## 切换到主菜单
func go_to_main_menu() -> void:
	change_scene(SCENE_MAIN_MENU)

## 开始新游戏
func start_new_game() -> void:
	DebugLogger.info("SceneManager: 开始新游戏", "SceneManager")
	# 先跳转到加载场景，加载场景会初始化所有管理器后跳转到游戏场景
	change_scene(SCENE_LOAD_GAME)

## 继续游戏
func continue_game() -> void:
	DebugLogger.info("SceneManager: 继续游戏", "SceneManager")
	if has_save_file():
		# TODO: 加载保存数据
		# 先跳转到加载场景，加载场景会初始化所有管理器后跳转到游戏场景
		change_scene(SCENE_LOAD_GAME)
	else:
		DebugLogger.warning("SceneManager: 没有找到保存文件", "SceneManager")
		SignalBus.dialog_shown.emit("no_save_file")

## 打开图鉴
func open_gallery() -> void:
	DebugLogger.info("SceneManager: 打开图鉴", "SceneManager")
	change_scene(SCENE_GALLERY)

## 退出游戏
func quit_game() -> void:
	DebugLogger.info("SceneManager: 退出游戏", "SceneManager")
	SignalBus.game_quit.emit()
	get_tree().quit()

# ========== 场景状态检查 ==========
func has_save_file() -> bool:
	var save_path = "user://save_game.dat"
	return FileAccess.file_exists(save_path)

func get_current_scene_name() -> String:
	if _current_scene:
		return _current_scene.scene_file_path.get_file().get_basename()
	return ""
