extends Control

## 主菜单脚本
## 处理主菜单的按钮点击和场景切换

# ========== 节点引用 ==========
@onready var start_game_button: Button = get_node("Panel (DimLayer)/CenterContainer/VBoxContainer (MenuButtons)/Button (StartGameButton)")
@onready var continue_game_button: Button = get_node("Panel (DimLayer)/CenterContainer/VBoxContainer (MenuButtons)/Button (ContinueGameButton)")
@onready var gallery_button: Button = get_node("Panel (DimLayer)/CenterContainer/VBoxContainer (MenuButtons)/Button (GalleryButton)")
@onready var quit_button: Button = get_node("Panel (DimLayer)/CenterContainer/VBoxContainer (MenuButtons)/Button (QuitButton)")

# ========== 初始化 ==========
func _ready() -> void:
	# 连接按钮信号
	if start_game_button:
		start_game_button.pressed.connect(_on_start_game_pressed)
	
	if continue_game_button:
		continue_game_button.pressed.connect(_on_continue_game_pressed)
		# 检查是否有保存文件，如果没有则禁用继续游戏按钮
		if not SceneManager.has_save_file():
			continue_game_button.disabled = true
	
	if gallery_button:
		gallery_button.pressed.connect(_on_gallery_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	DebugLogger.info("MainMenu: 主菜单已加载", "MainMenu")

# ========== 按钮处理函数 ==========
func _on_start_game_pressed() -> void:
	DebugLogger.info("MainMenu: 点击开始游戏按钮", "MainMenu")
	SceneManager.start_new_game()

func _on_continue_game_pressed() -> void:
	DebugLogger.info("MainMenu: 点击继续游戏按钮", "MainMenu")
	SceneManager.continue_game()

func _on_gallery_pressed() -> void:
	DebugLogger.info("MainMenu: 点击我的图鉴按钮", "MainMenu")
	SceneManager.open_gallery()

func _on_quit_pressed() -> void:
	DebugLogger.info("MainMenu: 点击退出游戏按钮", "MainMenu")
	SceneManager.quit_game()
