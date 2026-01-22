extends RefCounted
class_name ConstructEffect

## 构造体效果基类
## 定义效果的通用接口和基础属性

# ========== 效果属性 ==========
var effect_type: String = Constants.EFFECT_TYPE_DAMAGE  # 效果类型
var base_value: float = 0.0  # 基础值
var check_result_modifiers: Dictionary = {}  # 检定结果修正值 {check_result: modifier}

# ========== 初始化 ==========
func _init(
	p_type: String = Constants.EFFECT_TYPE_DAMAGE,
	p_base_value: float = 0.0,
	p_modifiers: Dictionary = {}
) -> void:
	effect_type = p_type
	base_value = p_base_value
	check_result_modifiers = p_modifiers.duplicate()

# ========== 效果应用接口 ==========
## 应用效果
## target: 目标对象（调查员数据等）
## check_result: 检定结果
## 返回应用的效果值
func apply_effect(target, check_result: int) -> float:
	var final_value = _calculate_value(check_result)
	_execute_effect(target, final_value, check_result)
	return final_value

## 计算效果值（根据检定结果）
func _calculate_value(check_result: int) -> float:
	var modifier = check_result_modifiers.get(check_result, 0.0)
	return base_value + modifier

## 执行效果（子类实现）
func _execute_effect(target, value: float, check_result: int) -> void:
	push_warning("ConstructEffect: _execute_effect not implemented in subclass")

# ========== 工具函数 ==========
## 设置检定结果修正值
func set_check_result_modifier(check_result: int, modifier: float) -> void:
	check_result_modifiers[check_result] = modifier

## 获取检定结果修正值
func get_check_result_modifier(check_result: int) -> float:
	return check_result_modifiers.get(check_result, 0.0)

## 复制效果
func duplicate_effect() -> ConstructEffect:
	var new_effect = ConstructEffect.new(effect_type, base_value, check_result_modifiers)
	return new_effect
