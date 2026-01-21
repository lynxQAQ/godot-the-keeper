extends Node

## 数据管理器
## 负责加载和管理游戏数据

# ========== 数据缓存 ==========
var _data_cache: Dictionary = {}
var _json_cache: Dictionary = {}

# ========== 数据加载 ==========
## 从JSON文件加载数据
func load_json_file(file_path: String) -> Dictionary:
	# 检查缓存
	if _json_cache.has(file_path):
		return _json_cache[file_path]
	
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		push_error("DataManager: File not found: " + file_path)
		return {}
	
	# 读取文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("DataManager: Failed to open file: " + file_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("DataManager: Failed to parse JSON from file: " + file_path)
		return {}
	
	if not json.data is Dictionary:
		push_error("DataManager: JSON data is not a Dictionary: " + file_path)
		return {}
	
	# 缓存结果
	_json_cache[file_path] = json.data
	return json.data

## 从JSON文件加载数组数据
func load_json_array(file_path: String) -> Array:
	var data = load_json_file(file_path)
	if data.has("items") and data["items"] is Array:
		return data["items"]
	elif data.has("data") and data["data"] is Array:
		return data["data"]
	else:
		push_error("DataManager: JSON file does not contain array data: " + file_path)
		return []

## 从Resource文件加载数据
func load_resource_file(file_path: String) -> Resource:
	# 检查缓存
	if _data_cache.has(file_path):
		return _data_cache[file_path]
	
	# 加载资源
	var resource = load(file_path)
	if resource == null:
		push_error("DataManager: Failed to load resource: " + file_path)
		return null
	
	# 缓存结果
	_data_cache[file_path] = resource
	return resource

## 保存数据到JSON文件
func save_json_file(file_path: String, data: Dictionary) -> bool:
	var json_string = JSON.stringify(data, "\t")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("DataManager: Failed to open file for writing: " + file_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	# 更新缓存
	_json_cache[file_path] = data
	
	return true

## 保存数组数据到JSON文件
func save_json_array(file_path: String, array: Array, root_key: String = "items") -> bool:
	var data = {root_key: array}
	return save_json_file(file_path, data)

# ========== 缓存管理 ==========
## 清除指定文件的缓存
func clear_cache(file_path: String = "") -> void:
	if file_path.is_empty():
		_data_cache.clear()
		_json_cache.clear()
	else:
		_data_cache.erase(file_path)
		_json_cache.erase(file_path)

## 获取缓存大小
func get_cache_size() -> Dictionary:
	return {
		"resource_cache": _data_cache.size(),
		"json_cache": _json_cache.size()
	}

# ========== 数据验证 ==========
## 验证数据字典是否包含必需的键
func validate_data(data: Dictionary, required_keys: Array) -> bool:
	for key in required_keys:
		if not data.has(key):
			push_error("DataManager: Missing required key: " + str(key))
			return false
	return true

## 验证数据数组
func validate_data_array(array: Array, validator: Callable) -> bool:
	for i in range(array.size()):
		if not validator.call(array[i]):
			push_error("DataManager: Validation failed at index: " + str(i))
			return false
	return true
