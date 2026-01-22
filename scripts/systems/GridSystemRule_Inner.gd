extends GridSystemRule
class_name GridSystemRule_Inner

## 里世界网格系统规则
## 实现里世界特有的规则：开垦无通路限制

# ========== 构造函数 ==========
func _init(manager: GridMapManager = null):
	super._init(manager)

# ========== 规则实现 ==========
## 检查是否可以开垦指定网格
## 里世界规则：无通路限制，可以任意开垦
func can_explore(pos: Vector2i) -> Dictionary:
	if not grid_manager:
		return {"can_explore": false, "reason": "网格管理器未初始化"}
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return {"can_explore": false, "reason": "无效的网格位置"}
	
	# 如果已经是已开垦状态，不能再次开垦
	if grid_data.grid_type == Constants.GRID_TYPE_EXPLORED:
		return {"can_explore": false, "reason": "该网格已经开垦"}
	
	# 里世界无通路限制，只要未开垦就可以开垦
	return {"can_explore": true, "reason": ""}

## 执行开垦操作前的验证
func validate_explore(pos: Vector2i) -> Dictionary:
	var can_result = can_explore(pos)
	if not can_result.can_explore:
		return {"valid": false, "reason": can_result.reason}
	
	return {"valid": true, "reason": ""}

## 执行开垦操作后的处理
func on_explore(pos: Vector2i) -> void:
	# 里世界开垦后，可以更新真理要素密度等
	# 这里暂时不需要特殊处理
	pass
