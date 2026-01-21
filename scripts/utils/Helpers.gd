extends RefCounted

## 工具函数类
## 提供各种工具函数

# ========== 数学工具 ==========
## 计算两点之间的距离
static func distance(pos1: Vector2, pos2: Vector2) -> float:
	return pos1.distance_to(pos2)

## 计算两点之间的角度（弧度）
static func angle_between(pos1: Vector2, pos2: Vector2) -> float:
	return (pos2 - pos1).angle()

## 计算两点之间的角度（度）
static func angle_between_degrees(pos1: Vector2, pos2: Vector2) -> float:
	return rad_to_deg(angle_between(pos1, pos2))

## 检查值是否在范围内
static func in_range(value: float, min_value: float, max_value: float) -> bool:
	return value >= min_value and value <= max_value

## 将值限制在范围内
static func clamp_value(value: float, min_value: float, max_value: float) -> float:
	return clamp(value, min_value, max_value)

## 线性插值
static func lerp_value(from: float, to: float, weight: float) -> float:
	return lerpf(from, to, weight)

## 检查点是否在矩形范围内
static func point_in_rect(point: Vector2, rect: Rect2) -> bool:
	return rect.has_point(point)

## 检查点是否在圆形范围内
static func point_in_circle(point: Vector2, center: Vector2, radius: float) -> bool:
	return distance(point, center) <= radius

# ========== 随机工具 ==========
## 权重随机
## weights: 权重字典，key为选项，value为权重
static func weighted_random(weights: Dictionary) -> Variant:
	if weights.is_empty():
		return null
	
	var total_weight: float = 0.0
	for weight in weights.values():
		total_weight += weight
	
	if total_weight <= 0.0:
		return null
	
	var random_value = randf() * total_weight
	var current_weight: float = 0.0
	
	for key in weights:
		current_weight += weights[key]
		if random_value <= current_weight:
			return key
	
	return null

## 正态分布随机数（Box-Muller变换）
static func normal_random(mean: float = 0.0, std_dev: float = 1.0) -> float:
	var u1 = randf()
	var u2 = randf()
	var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	return z0 * std_dev + mean

## 随机整数范围
static func random_int(min_value: int, max_value: int) -> int:
	return randi_range(min_value, max_value)

## 随机浮点数范围
static func random_float(min_value: float, max_value: float) -> float:
	return randf_range(min_value, max_value)

# ========== 字符串工具 ==========
## 格式化字符串（类似Python的format）
## 使用 {0}, {1} 等占位符
static func format_string(format: String, args: Array) -> String:
	var result = format
	for i in range(args.size()):
		result = result.replace("{" + str(i) + "}", str(args[i]))
	return result

## 本地化字符串（占位符，实际需要实现本地化系统）
static func localize(key: String, default_value: String = "") -> String:
	# TODO: 实现本地化系统
	return default_value if default_value != "" else key

## 截断字符串
static func truncate_string(text: String, max_length: int, suffix: String = "...") -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length - suffix.length()) + suffix

## 首字母大写
static func capitalize(text: String) -> String:
	if text.is_empty():
		return text
	return text[0].to_upper() + text.substr(1)

## 驼峰命名转下划线命名
static func camel_to_snake(text: String) -> String:
	var result = ""
	for i in range(text.length()):
		var char = text[i]
		if char.is_upper_case() and i > 0:
			result += "_"
		result += char.to_lower()
	return result

## 下划线命名转驼峰命名
static func snake_to_camel(text: String, capitalize_first: bool = false) -> String:
	var parts = text.split("_")
	var result = ""
	for i in range(parts.size()):
		var part = parts[i]
		if i == 0 and not capitalize_first:
			result += part
		else:
			result += capitalize(part)
	return result

# ========== 时间工具 ==========
## 格式化时间（秒转字符串）
static func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

## 格式化时间（毫秒转字符串）
static func format_time_ms(milliseconds: float) -> String:
	var seconds = int(milliseconds / 1000)
	var ms = int(milliseconds) % 1000
	return "%02d:%02d.%03d" % [seconds / 60, seconds % 60, ms]

# ========== 颜色工具 ==========
## 十六进制颜色转Color
static func hex_to_color(hex: String) -> Color:
	hex = hex.replace("#", "")
	if hex.length() != 6:
		return Color.WHITE
	
	var r = hex.substr(0, 2).hex_to_int() / 255.0
	var g = hex.substr(2, 2).hex_to_int() / 255.0
	var b = hex.substr(4, 2).hex_to_int() / 255.0
	return Color(r, g, b)

## Color转十六进制字符串
static func color_to_hex(color: Color) -> String:
	var r = "%02x" % int(color.r * 255)
	var g = "%02x" % int(color.g * 255)
	var b = "%02x" % int(color.b * 255)
	return "#" + r + g + b
