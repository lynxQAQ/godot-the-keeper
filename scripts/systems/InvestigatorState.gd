extends RefCounted
class_name InvestigatorState

## 调查员状态管理类
## 管理调查员的状态数值、异常效果等

# ========== 状态数值 ==========
var health: int = 10
var health_max: int = 10
var sanity: int = 10
var sanity_max: int = 10

# ========== 异常效果 ==========
## 异常效果数据结构：{effect_id: String, effect_type: String, duration: float, value: int}
## effect_type: "damage_over_time"（持续伤害）、"movement_block"（移动阻碍）等
var status_effects: Array[Dictionary] = []

# ========== 信号 ==========
## 状态变化信号（通过Investigator节点发射）
signal health_changed(current: int, max: int)
signal sanity_changed(current: int, max: int)
signal status_effect_added(effect_id: String, effect_type: String)
signal status_effect_removed(effect_id: String)
signal investigator_died()

# ========== 初始化 ==========
func _init(
	p_health: int = Constants.DEFAULT_INVESTIGATOR_HEALTH,
	p_sanity: int = Constants.DEFAULT_INVESTIGATOR_SANITY
) -> void:
	health = p_health
	health_max = p_health
	sanity = p_sanity
	sanity_max = p_sanity
	status_effects = []

# ========== 状态数值管理 ==========
## 设置生命值
func set_health(value: int, emit_signal: bool = true) -> void:
	var old_health = health
	health = clamp(value, 0, health_max)
	
	if emit_signal and health != old_health:
		health_changed.emit(health, health_max)
		
		# 检查是否死亡
		if health <= 0:
			investigator_died.emit()

## 设置理智值
func set_sanity(value: int, emit_signal: bool = true) -> void:
	var old_sanity = sanity
	sanity = clamp(value, 0, sanity_max)
	
	if emit_signal and sanity != old_sanity:
		sanity_changed.emit(sanity, sanity_max)
		
		# 检查是否死亡
		if sanity <= 0:
			investigator_died.emit()

## 增加生命值
func add_health(amount: int, emit_signal: bool = true) -> void:
	set_health(health + amount, emit_signal)

## 减少生命值
func reduce_health(amount: int, emit_signal: bool = true) -> void:
	set_health(health - amount, emit_signal)

## 增加理智值
func add_sanity(amount: int, emit_signal: bool = true) -> void:
	set_sanity(sanity + amount, emit_signal)

## 减少理智值
func reduce_sanity(amount: int, emit_signal: bool = true) -> void:
	set_sanity(sanity - amount, emit_signal)

## 设置最大生命值
func set_health_max(value: int) -> void:
	health_max = max(1, value)
	health = min(health, health_max)
	health_changed.emit(health, health_max)

## 设置最大理智值
func set_sanity_max(value: int) -> void:
	sanity_max = max(1, value)
	sanity = min(sanity, sanity_max)
	sanity_changed.emit(sanity, sanity_max)

## 检查是否死亡
func is_dead() -> bool:
	return health <= 0 or sanity <= 0

## 检查是否存活
func is_alive() -> bool:
	return not is_dead()

# ========== 异常效果管理 ==========
## 添加异常效果
func add_status_effect(effect_id: String, effect_type: String, duration: float, value: int = 0) -> void:
	# 检查是否已存在相同ID的效果
	remove_status_effect(effect_id)
	
	status_effects.append({
		"effect_id": effect_id,
		"effect_type": effect_type,
		"duration": duration,
		"value": value,
		"elapsed_time": 0.0
	})
	
	status_effect_added.emit(effect_id, effect_type)

## 移除异常效果
func remove_status_effect(effect_id: String) -> void:
	var index = -1
	for i in range(status_effects.size()):
		if status_effects[i].get("effect_id") == effect_id:
			index = i
			break
	
	if index >= 0:
		var effect = status_effects[index]
		status_effects.remove_at(index)
		status_effect_removed.emit(effect_id)

## 检查是否有特定类型的异常效果
func has_status_effect_type(effect_type: String) -> bool:
	for effect in status_effects:
		if effect.get("effect_type") == effect_type:
			return true
	return false

## 获取所有特定类型的异常效果
func get_status_effects_by_type(effect_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect in status_effects:
		if effect.get("effect_type") == effect_type:
			result.append(effect.duplicate())
	return result

## 更新异常效果（在每帧调用）
func update_status_effects(delta: float) -> void:
	var to_remove: Array[String] = []
	
	for effect in status_effects:
		var elapsed = effect.get("elapsed_time", 0.0) + delta
		effect["elapsed_time"] = elapsed
		
		# 处理持续伤害
		if effect.get("effect_type") == "damage_over_time":
			# 每秒造成伤害（可以根据需要调整频率）
			if int(elapsed) > int(elapsed - delta):
				var damage = effect.get("value", 0)
				if damage > 0:
					reduce_health(damage, true)
		
		# 检查持续时间
		var duration = effect.get("duration", 0.0)
		if duration > 0 and elapsed >= duration:
			to_remove.append(effect.get("effect_id"))
	
	# 移除过期的效果
	for effect_id in to_remove:
		remove_status_effect(effect_id)

## 清除所有异常效果
func clear_all_status_effects() -> void:
	var effect_ids: Array[String] = []
	for effect in status_effects:
		effect_ids.append(effect.get("effect_id"))
	
	for effect_id in effect_ids:
		remove_status_effect(effect_id)

# ========== 移动阻碍检查 ==========
## 检查是否被移动阻碍
func is_movement_blocked() -> bool:
	return has_status_effect_type("movement_block")

# ========== 工具函数 ==========
## 从InvestigatorData初始化
func initialize_from_data(data: InvestigatorData) -> void:
	if not data:
		return
	
	health = data.health
	health_max = data.health_max
	sanity = data.sanity
	sanity_max = data.sanity_max

## 同步到InvestigatorData
func sync_to_data(data: InvestigatorData) -> void:
	if not data:
		return
	
	data.health = health
	data.health_max = health_max
	data.sanity = sanity
	data.sanity_max = sanity_max
