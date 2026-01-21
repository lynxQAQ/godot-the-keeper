extends Node

## 日志系统
## 提供分级日志功能，支持文件输出和控制台输出

# ========== 日志级别 ==========
enum LogLevel {
	DEBUG = 0,
	INFO = 1,
	WARNING = 2,
	ERROR = 3
}

# ========== 配置 ==========
var log_to_file: bool = true
var log_to_console: bool = true
var log_file_path: String = "user://logs/game.log"
var min_log_level: LogLevel = LogLevel.DEBUG
var max_log_file_size: int = 10485760  # 10MB

# ========== 内部变量 ==========
var _log_file: FileAccess = null
var _log_buffer: Array[String] = []
var _buffer_size: int = 100

# ========== 初始化 ==========
func _ready() -> void:
	if log_to_file:
		_setup_log_file()

func _exit_tree() -> void:
	_close_log_file()

# ========== 日志文件管理 ==========
func _setup_log_file() -> void:
	# 创建日志目录
	var dir_path = log_file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.open("user://").make_dir_recursive(dir_path)
	
	# 检查文件大小，如果太大则轮转
	_check_log_file_size()
	
	# 打开日志文件
	_log_file = FileAccess.open(log_file_path, FileAccess.WRITE)
	if _log_file == null:
		push_error("Logger: Failed to open log file: " + log_file_path)
		log_to_file = false

func _check_log_file_size() -> void:
	if FileAccess.file_exists(log_file_path):
		var file = FileAccess.open(log_file_path, FileAccess.READ)
		if file != null:
			var file_size = file.get_length()
			file.close()
			
			if file_size > max_log_file_size:
				_rotate_log_file()

func _rotate_log_file() -> void:
	# 重命名旧日志文件
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var old_log_path = log_file_path + "." + timestamp
	DirAccess.rename_absolute(log_file_path, old_log_path)

func _close_log_file() -> void:
	_flush_buffer()
	if _log_file != null:
		_log_file.close()
		_log_file = null

func _flush_buffer() -> void:
	if _log_file == null:
		return
	
	for log_entry in _log_buffer:
		_log_file.store_string(log_entry + "\n")
	
	_log_file.flush()
	_log_buffer.clear()

# ========== 日志输出 ==========
func _log(level: LogLevel, message: String, category: String = "") -> void:
	if level < min_log_level:
		return
	
	var level_name = _get_level_name(level)
	var timestamp = Time.get_datetime_string_from_system()
	var category_str = "[" + category + "]" if category != "" else ""
	var log_entry = "[%s] [%s] %s %s" % [timestamp, level_name, category_str, message]
	
	# 控制台输出
	if log_to_console:
		match level:
			LogLevel.DEBUG:
				print(log_entry)
			LogLevel.INFO:
				print(log_entry)
			LogLevel.WARNING:
				push_warning(log_entry)
			LogLevel.ERROR:
				push_error(log_entry)
	
	# 文件输出
	if log_to_file:
		_log_buffer.append(log_entry)
		if _log_buffer.size() >= _buffer_size:
			_flush_buffer()

func _get_level_name(level: LogLevel) -> String:
	match level:
		LogLevel.DEBUG:
			return "DEBUG"
		LogLevel.INFO:
			return "INFO"
		LogLevel.WARNING:
			return "WARNING"
		LogLevel.ERROR:
			return "ERROR"
		_:
			return "UNKNOWN"

# ========== 公共接口 ==========
## 输出DEBUG级别日志
func debug(message: String, category: String = "") -> void:
	_log(LogLevel.DEBUG, message, category)

## 输出INFO级别日志
func info(message: String, category: String = "") -> void:
	_log(LogLevel.INFO, message, category)

## 输出WARNING级别日志
func warning(message: String, category: String = "") -> void:
	_log(LogLevel.WARNING, message, category)

## 输出ERROR级别日志
func error(message: String, category: String = "") -> void:
	_log(LogLevel.ERROR, message, category)

# ========== 配置接口 ==========
## 设置日志级别
func set_log_level(level: LogLevel) -> void:
	min_log_level = level

## 设置是否输出到文件
func set_log_to_file(enabled: bool) -> void:
	log_to_file = enabled
	if enabled and _log_file == null:
		_setup_log_file()
	elif not enabled:
		_close_log_file()

## 设置是否输出到控制台
func set_log_to_console(enabled: bool) -> void:
	log_to_console = enabled

## 设置日志文件路径
func set_log_file_path(path: String) -> void:
	log_file_path = path
	if log_to_file:
		_close_log_file()
		_setup_log_file()

## 立即刷新日志缓冲区
func flush() -> void:
	_flush_buffer()
