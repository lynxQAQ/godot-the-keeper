extends ConstructEffect
class_name StatusEffect

## 状态异常效果
## 对调查员施加持续伤害或其他debuff

# ========== 状态效果属性 ==========
var status_type: String = "poison"  # 状态类型（poison/burn/freeze等）
var duration: float = 0.0  # 持续时间（秒）
var tick_interval: float = 1.0  # 触发间隔（秒）
var tick_damage: float = 0.0  # 每次触发的伤害

func _init(
	p_status_type: String = "poison",
	p_duration: float = 0.0,
	p_tick_interval: float = 1.0,
	p_tick_damage: float = 0.0,
	p_modifiers: Dictionary = {}
) -> void:
	super._init(Constants.EFFECT_TYPE_STATUS, 0.0, p_modifiers)
	status_type = p_status_type
	duration = p_duration
	tick_interval = p_tick_interval
	tick_damage = p_tick_damage

func _execute_effect(target, value: float, check_result: int) -> void:
	if not target:
		return
	
	# 假设target有状态效果管理方法
	if target.has_method("apply_status_effect"):
		target.apply_status_effect(status_type, duration, tick_interval, tick_damage)
	elif target.has("status_effects"):
		# 简单的状态效果添加
		if not target.status_effects.has(status_type):
			target.status_effects[status_type] = {
				"duration": duration,
				"tick_interval": tick_interval,
				"tick_damage": tick_damage,
				"remaining_time": duration,
				"next_tick": tick_interval
			}
	
	DebugLogger.debug("StatusEffect: 应用状态效果 " + status_type + "，持续 " + str(duration) + " 秒", "StatusEffect")
