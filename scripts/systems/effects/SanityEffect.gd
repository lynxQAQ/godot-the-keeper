extends ConstructEffect
class_name SanityEffect

## 理智损失效果
## 对调查员造成理智值损失

func _init(p_base_value: float = 0.0, p_modifiers: Dictionary = {}) -> void:
	super._init(Constants.EFFECT_TYPE_SANITY, p_base_value, p_modifiers)

func _execute_effect(target, value: float, check_result: int) -> void:
	if not target:
		return
	
	# 假设target有sanity属性或get_sanity/set_sanity方法
	if target.has_method("lose_sanity"):
		target.lose_sanity(int(value))
	elif target.has("sanity"):
		target.sanity = max(0, target.sanity - int(value))
	
	DebugLogger.debug("SanityEffect: 造成 " + str(int(value)) + " 点理智损失", "SanityEffect")
