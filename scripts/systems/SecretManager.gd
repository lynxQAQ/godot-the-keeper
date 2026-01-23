extends Node
class_name SecretManager

## 秘密管理系统
## 负责管理表世界中的秘密放置、拾起、移除等操作

# ========== 预加载 ==========
const SecretScene = preload("res://scenes/entities/Secret.tscn")

# ========== 信号 ==========
## 秘密位置被发现
signal secret_found(grid_pos: Vector2i)
## 秘密被拾起
signal secret_picked_up()
## 秘密被放置
signal secret_placed(grid_pos: Vector2i)

# ========== 导出属性 ==========
## 网格系统引用（需要外部设置）
var grid_system: GridSystemSurface = null

# ========== 内部状态 ==========
## 当前秘密节点（如果为null表示玩家持有秘密）
var _secret_node: Secret = null

## 秘密容器节点
var _secret_container: Node2D = null

## 是否持有秘密（玩家已拾起但未放置）
var _has_secret_in_hand: bool = false

# ========== 生命周期 ==========
func _ready():
	# 创建秘密容器节点
	_secret_container = Node2D.new()
	_secret_container.name = "SecretContainer"
	
	# 如果grid_system已设置，添加到grid_system
	if grid_system:
		grid_system.add_child(_secret_container)
	else:
		# 否则添加到当前节点
		add_child(_secret_container)

# ========== 初始化 ==========
## 设置网格系统引用（必须在调用其他方法前调用）
func set_grid_system(system: GridSystemSurface) -> void:
	grid_system = system
	# 如果容器已创建，移动到grid_system下
	if _secret_container:
		var old_parent = _secret_container.get_parent()
		if old_parent != grid_system:
			if old_parent:
				old_parent.remove_child(_secret_container)
			# 确保 grid_system 在场景树中
			if grid_system and is_instance_valid(grid_system):
				grid_system.add_child(_secret_container)
				DebugLogger.debug("SecretManager: SecretContainer 已移动到 grid_system", "SecretManager")
			else:
				DebugLogger.warning("SecretManager: grid_system 无效，无法移动容器", "SecretManager")

# ========== 秘密操作 ==========
## 放置秘密（创建Secret场景节点）
func place_secret(pos: Vector2i) -> bool:
	if not grid_system or not _secret_container:
		return false
	
	# 检查是否持有秘密
	if not _has_secret_in_hand:
		return false
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		return false
	
	var grid_data = grid_manager.get_grid(pos)
	if not grid_data:
		return false
	
	# 检查是否已经是已开垦的网格
	if not grid_data.get_is_explored_type():
		DebugLogger.warning("SecretManager: 无法在未开垦的网格上放置秘密", "SecretManager")
		return false
	
	# 如果之前有秘密节点，先移除（理论上不应该有，因为已经拾起了）
	if _secret_node:
		_remove_secret()
	
	# 从场景文件实例化Secret节点
	var secret = SecretScene.instantiate()
	if not secret:
		DebugLogger.error("SecretManager: 无法实例化Secret场景", "SecretManager")
		return false
	
	# 计算世界坐标
	var world_pos = grid_system.grid_to_world(pos)
	
	# 先添加到容器（确保节点在场景树中）
	_secret_container.add_child(secret)
	
	# 然后设置位置
	secret.grid_pos = pos
	secret.world_pos = world_pos
	secret.position = world_pos
	
	# 延迟连接点击信号，确保 Secret 的 _ready() 已执行，Area2D 已设置好
	# 使用 call_deferred 确保节点完全初始化后再连接信号
	call_deferred("_connect_secret_signal", secret)
	
	# 更新状态
	_secret_node = secret
	_has_secret_in_hand = false
	
	secret_found.emit(pos)
	secret_placed.emit(pos)
	DebugLogger.debug("SecretManager: 秘密已放置在 " + str(pos), "SecretManager")
	return true

## 移除秘密节点
func _remove_secret() -> void:
	if _secret_node:
		_secret_node.queue_free()
		_secret_node = null

## 拾起秘密
func pickup_secret() -> bool:
	if not _secret_node:
		return false
	
	# 移除秘密节点
	_remove_secret()
	
	# 更新状态：玩家持有秘密
	_has_secret_in_hand = true
	
	secret_picked_up.emit()
	DebugLogger.debug("SecretManager: 秘密已拾起", "SecretManager")
	return true

## 处理秘密交互（拾起或放置）
func handle_secret_interaction(grid_pos: Vector2i, grid_data: GridData) -> bool:
	# 如果玩家持有秘密，尝试放置
	if _has_secret_in_hand:
		# 必须放置在已开垦的网格上
		if grid_data.get_is_explored_type():
			if place_secret(grid_pos):
				print("秘密已放置在: ", grid_pos)
				return true
			else:
				print("无法在此位置放置秘密")
				return false
		else:
			print("秘密只能放置在已开垦的网格上")
			return false
	
	return false

## 连接 Secret 的点击信号（延迟执行，确保节点完全初始化）
func _connect_secret_signal(secret: Secret) -> void:
	if secret and is_instance_valid(secret):
		if not secret.secret_clicked.is_connected(_on_secret_clicked):
			secret.secret_clicked.connect(_on_secret_clicked)
	else:
		DebugLogger.warning("SecretManager: Secret 节点无效，无法连接信号", "SecretManager")

## 秘密被点击时的处理
func _on_secret_clicked(secret: Secret) -> void:
	if secret == _secret_node:
		pickup_secret()

## 生成初始秘密（在已开垦的网格中随机选择一个）
func spawn_initial_secret() -> void:
	if not grid_system or not _secret_container:
		DebugLogger.warning("SecretManager: 无法生成初始秘密 - grid_system 或 _secret_container 为空", "SecretManager")
		return
	
	var grid_manager = grid_system.get_grid_manager()
	if not grid_manager:
		DebugLogger.warning("SecretManager: 无法生成初始秘密 - grid_manager 为空", "SecretManager")
		return
	
	# 收集所有已开垦的网格位置
	var explored_positions: Array[Vector2i] = []
	for x in range(grid_manager.grid_size.x):
		for y in range(grid_manager.grid_size.y):
			var pos = Vector2i(x, y)
			var grid_data = grid_manager.get_grid(pos)
			if grid_data and grid_data.get_is_explored_type():
				explored_positions.append(pos)
	
	# 如果没有已开垦的网格，无法生成秘密
	if explored_positions.is_empty():
		DebugLogger.warning("SecretManager: 没有已开垦的网格，无法生成秘密", "SecretManager")
		return
	
	# 随机选择一个已开垦的网格放置秘密
	var random_pos = explored_positions[randi() % explored_positions.size()]
	
	# 直接创建 Secret 节点，不需要检查 _has_secret_in_hand（因为这是初始生成）
	var grid_data = grid_manager.get_grid(random_pos)
	if not grid_data or not grid_data.get_is_explored_type():
		DebugLogger.warning("SecretManager: 选中的网格不是已开垦的网格", "SecretManager")
		return
	
	# 如果之前有秘密节点，先移除（理论上不应该有）
	if _secret_node:
		_remove_secret()
	
	# 从场景文件实例化Secret节点
	var secret = SecretScene.instantiate()
	if not secret:
		DebugLogger.error("SecretManager: 无法实例化Secret场景", "SecretManager")
		return
	
	# 计算世界坐标
	var world_pos = grid_system.grid_to_world(random_pos)
	
	# 先添加到容器（确保节点在场景树中）
	_secret_container.add_child(secret)
	
	# 然后设置位置
	secret.grid_pos = random_pos
	secret.world_pos = world_pos
	secret.position = world_pos
	
	# 延迟连接点击信号，确保 Secret 的 _ready() 已执行，Area2D 已设置好
	# 使用 call_deferred 确保节点完全初始化后再连接信号
	call_deferred("_connect_secret_signal", secret)
	
	# 更新状态（初始生成时，玩家不持有秘密，秘密直接放在网格上）
	_secret_node = secret
	_has_secret_in_hand = false
	
	secret_found.emit(random_pos)
	DebugLogger.debug("SecretManager: 初始秘密已生成在 " + str(random_pos), "SecretManager")

# ========== 查询接口 ==========
## 获取当前秘密节点
func get_secret_node() -> Secret:
	return _secret_node

## 获取秘密位置
func get_secret_position() -> Vector2i:
	if _secret_node:
		return _secret_node.get_grid_position()
	return Vector2i(-1, -1)

## 检查是否持有秘密
func has_secret_in_hand() -> bool:
	return _has_secret_in_hand

## 检查是否有秘密节点
func has_secret_node() -> bool:
	return _secret_node != null
