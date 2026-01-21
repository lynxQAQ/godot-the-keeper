extends Resource
class_name BaseData

## 数据基类
## 所有游戏数据的基类，提供序列化/反序列化接口

# ========== 基础属性 ==========
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""

# ========== 序列化接口 ==========
## 序列化为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description
	}

## 从字典反序列化
func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")

## 序列化为JSON字符串
func to_json() -> String:
	return JSON.stringify(to_dict())

## 从JSON字符串反序列化
func from_json(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse JSON: " + json_string)
		return false
	
	if json.data is Dictionary:
		from_dict(json.data)
		return true
	else:
		push_error("JSON data is not a Dictionary")
		return false

## 验证数据有效性
func validate() -> bool:
	if id.is_empty():
		push_warning("BaseData: id is empty")
		return false
	return true

## 复制数据
func duplicate_data() -> BaseData:
	var new_data = BaseData.new()
	new_data.from_dict(to_dict())
	return new_data
