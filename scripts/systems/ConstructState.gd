extends RefCounted
class_name ConstructState

## 构造体状态管理
## 管理构造体的状态转换和持续时间

# ========== 状态属性 ==========
var current_state: int = Constants.CONSTRUCT_STATE_INACTIVE
var state_duration: float = -1.0  # 状态持续时间（秒），-1表示永久
var remaining_time: float = -1.0  # 剩余时间
var state_start_time: float = 0.0  # 状态开始时间

# ========== 初始化 ==========
func _init(initial_state: int = Constants.CONSTRUCT_STATE_INACTIVE) -> void:
	current_state = initial_state
	state_duration = -1.0
	remaining_time = -1.0
	state_start_time = Time.get_ticks_msec() / 1000.0

# ========== 状态转换 ==========
## 转换状态
func change_state(new_state: int, duration: float = -1.0) -> bool:
	if not _can_transition_to(new_state):
		DebugLogger.warning("ConstructState: 无法从状态 " + str(current_state) + " 转换到 " + str(new_state), "ConstructState")
		return false
	
	var old_state = current_state
	current_state = new_state
	state_duration = duration
	remaining_time = duration
	state_start_time = Time.get_ticks_msec() / 1000.0
	
	DebugLogger.debug("ConstructState: 状态从 " + str(old_state) + " 转换到 " + str(new_state), "ConstructState")
	return true

## 检查是否可以转换到指定状态
func _can_transition_to(new_state: int) -> bool:
	match current_state:
		Constants.CONSTRUCT_STATE_INACTIVE:
			return new_state == Constants.CONSTRUCT_STATE_ACTIVE
		Constants.CONSTRUCT_STATE_ACTIVE:
			return new_state in [Constants.CONSTRUCT_STATE_DISABLED, Constants.CONSTRUCT_STATE_DESTROYED]
		Constants.CONSTRUCT_STATE_DISABLED:
			return new_state in [Constants.CONSTRUCT_STATE_ACTIVE, Constants.CONSTRUCT_STATE_DESTROYED]
		Constants.CONSTRUCT_STATE_DESTROYED:
			return false  # 已销毁无法转换
		_:
			return false

# ========== 状态更新 ==========
## 更新状态（每帧调用）
func update(delta: float) -> void:
	if state_duration < 0:
		return  # 永久状态
	
	remaining_time -= delta
	if remaining_time <= 0:
		remaining_time = 0
		_on_state_timeout()

## 状态超时处理
func _on_state_timeout() -> void:
	match current_state:
		Constants.CONSTRUCT_STATE_ACTIVE:
			# 激活状态超时后可以转为失效
			change_state(Constants.CONSTRUCT_STATE_DISABLED)
		Constants.CONSTRUCT_STATE_DISABLED:
			# 失效状态超时后可以转为激活
			change_state(Constants.CONSTRUCT_STATE_ACTIVE)
		_:
			pass

# ========== 状态查询 ==========
## 获取当前状态
func get_state() -> int:
	return current_state

## 检查是否处于指定状态
func is_state(state: int) -> bool:
	return current_state == state

## 检查是否激活
func is_active() -> bool:
	return current_state == Constants.CONSTRUCT_STATE_ACTIVE

## 检查是否已销毁
func is_destroyed() -> bool:
	return current_state == Constants.CONSTRUCT_STATE_DESTROYED

## 获取状态剩余时间百分比
func get_state_percentage() -> float:
	if state_duration < 0:
		return 1.0
	if state_duration <= 0:
		return 0.0
	return remaining_time / state_duration

## 获取状态名称
func get_state_name() -> String:
	match current_state:
		Constants.CONSTRUCT_STATE_INACTIVE:
			return "未激活"
		Constants.CONSTRUCT_STATE_ACTIVE:
			return "激活"
		Constants.CONSTRUCT_STATE_DISABLED:
			return "失效"
		Constants.CONSTRUCT_STATE_DESTROYED:
			return "销毁"
		_:
			return "未知状态"
