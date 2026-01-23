extends Control
class_name GameScene

## 游戏主场景
## 负责布局两个子窗口（表世界和里世界）
## 表世界和里世界的实例化由各自的初始化器脚本负责

# ========== 生命周期 ==========
func _ready() -> void:
	# 设置全屏布局
	anchors_preset = Control.PRESET_FULL_RECT
	size = get_viewport_rect().size
