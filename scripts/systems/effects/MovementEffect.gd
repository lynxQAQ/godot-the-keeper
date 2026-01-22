extends ConstructEffect
class_name MovementEffect

## 移动阻碍效果
## 影响调查员的移动速度或路径

# ========== 移动效果属性 ==========
var speed_reduction: float = 0.0  # 速度减少百分比（0.0-1.0）
var duration: float = 0.0  # 持续时间（秒）

func _init(
	p_base_value: float = 0.0,
	p_speed_reduction: float = 0.0,
	p_duration: float = 0.0,
	p_modifiers: Dictionary = {}
) -> void:
	super._init(Constants.EFFECT_TYPE_MOVEMENT, p_base_value, p_modifiers)
	speed_reduction = p_speed_reduction
	duration = p_duration

func _execute_effect(target, value: float, check_result: int) -> void:
	if not target:
		return
	
	# 假设target有移动速度相关的属性或方法
	if target.has_method("apply_movement_effect"):
		target.apply_movement_effect(speed_reduction, duration)
	elif target.has("movement_speed"):
		# 简单的速度减少
		var original_speed = target.get("original_movement_speed")
		if original_speed == null:
			target["original_movement_speed"] = target.movement_speed
		target.movement_speed = target.movement_speed * (1.0 - speed_reduction)
	
	DebugLogger.debug("MovementEffect: 应用移动阻碍，速度减少 " + str(speed_reduction * 100) + "%，持续 " + str(duration) + " 秒", "MovementEffect")
