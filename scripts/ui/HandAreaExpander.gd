extends Control

## 手牌区域展开器
## 挂载到 Control (bottom) 节点，处理鼠标悬浮时的展开/收起动画

# ========== 常量 ==========
const COLLAPSED_HEIGHT: float = 100.0  # 收起时的高度
const EXPANDED_HEIGHT: float = 360.0   # 展开时的高度
const ANIMATION_DURATION: float = 0.3  # 动画持续时间（秒）

# ========== 内部变量 ==========
var _is_expanded: bool = false
var _tween: Tween = null

# ========== 初始化 ==========
func _ready() -> void:
	# 设置初始状态（收起）
	_set_collapsed_state()
	
	# 确保可以接收鼠标事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接鼠标信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 监听窗口大小变化
	get_viewport().size_changed.connect(_on_viewport_size_changed)

# ========== 鼠标事件处理 ==========
func _on_mouse_entered() -> void:
	if not _is_expanded:
		_expand()

func _on_mouse_exited() -> void:
	if _is_expanded:
		# 延迟检查，避免快速移动时闪烁
		await get_tree().create_timer(0.1).timeout
		if not _is_mouse_in_area():
			_collapse()

# ========== 检查鼠标是否在区域内 ==========
func _is_mouse_in_area() -> bool:
	var mouse_pos = get_global_mouse_position()
	var rect = Rect2(get_global_position(), size)
	return rect.has_point(mouse_pos)

# ========== 展开动画 ==========
func _expand() -> void:
	if _is_expanded:
		return
	
	_is_expanded = true
	
	# 停止之前的动画
	if _tween:
		_tween.kill()
	
	# 创建新的动画
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	
	# 动画化高度和位置
	var current_height = size.y
	var target_height = EXPANDED_HEIGHT
	var current_offset = offset_top
	var target_offset = -EXPANDED_HEIGHT
	
	_tween.parallel().tween_method(_set_height, current_height, target_height, ANIMATION_DURATION)
	_tween.parallel().tween_method(_set_offset_top, current_offset, target_offset, ANIMATION_DURATION)
	
	DebugLogger.debug("HandAreaExpander: 展开手牌区域", "HandAreaExpander")

# ========== 收起动画 ==========
func _collapse() -> void:
	if not _is_expanded:
		return
	
	_is_expanded = false
	
	# 停止之前的动画
	if _tween:
		_tween.kill()
	
	# 创建新的动画
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_CUBIC)
	
	# 动画化高度和位置
	var current_height = size.y
	var target_height = COLLAPSED_HEIGHT
	var current_offset = offset_top
	var target_offset = -COLLAPSED_HEIGHT
	
	_tween.parallel().tween_method(_set_height, current_height, target_height, ANIMATION_DURATION)
	_tween.parallel().tween_method(_set_offset_top, current_offset, target_offset, ANIMATION_DURATION)
	
	DebugLogger.debug("HandAreaExpander: 收起手牌区域", "HandAreaExpander")

# ========== 设置高度 ==========
func _set_height(height: float) -> void:
	size.y = height

# ========== 设置顶部偏移 ==========
func _set_offset_top(offset: float) -> void:
	offset_top = offset

# ========== 设置收起状态 ==========
func _set_collapsed_state() -> void:
	size.y = COLLAPSED_HEIGHT
	offset_top = -COLLAPSED_HEIGHT

# ========== 窗口大小变化处理 ==========
func _on_viewport_size_changed() -> void:
	# 如果正在动画中，不处理
	if _tween and _tween.is_valid():
		return
	
	# 根据当前状态更新位置
	if _is_expanded:
		size.y = EXPANDED_HEIGHT
		offset_top = -EXPANDED_HEIGHT
	else:
		size.y = COLLAPSED_HEIGHT
		offset_top = -COLLAPSED_HEIGHT
