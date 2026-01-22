extends ConstructEffect
class_name DamageEffect

## 伤害效果
## 对调查员造成生命值伤害

func _init(p_base_value: float = 0.0, p_modifiers: Dictionary = {}) -> void:
	super._init(Constants.EFFECT_TYPE_DAMAGE, p_base_value, p_modifiers)

func _execute_effect(target, value: float, check_result: int) -> void:
	if not target:
		return
	
	# 假设target有health属性或get_health/set_health方法
	if target.has_method("take_damage"):
		target.take_damage(int(value))
	elif target.has("health"):
		target.health = max(0, target.health - int(value))
	
	DebugLogger.debug("DamageEffect: 造成 " + str(int(value)) + " 点伤害", "DamageEffect")
