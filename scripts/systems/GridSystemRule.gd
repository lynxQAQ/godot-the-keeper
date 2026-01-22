extends RefCounted
class_name GridSystemRule

## 网格系统规则基类
## 定义网格系统的规则接口，用于区分表里世界的不同规则

# ========== 属性 ==========
## 关联的网格管理器
var grid_manager: GridMapManager = null

# ========== 构造函数 ==========
func _init(manager: GridMapManager = null):
	grid_manager = manager

# ========== 规则接口 ==========
## 检查是否可以开垦指定网格
## 返回: (can_explore: bool, reason: String)
func can_explore(pos: Vector2i) -> Dictionary:
	return {"can_explore": true, "reason": ""}

## 执行开垦操作前的验证
## 返回: (valid: bool, reason: String)
func validate_explore(pos: Vector2i) -> Dictionary:
	return {"valid": true, "reason": ""}

## 执行开垦操作后的处理
func on_explore(pos: Vector2i) -> void:
	pass

## 检查网格是否满足特定条件
func check_condition(pos: Vector2i, condition: String) -> bool:
	return true
