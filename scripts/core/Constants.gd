extends Node

## 常量定义类
## 提供游戏中所有常量定义，作为autoload单例使用

# ========== 游戏阶段常量 ==========
const PREPARATION_PHASE: String = "preparation"
const COMBAT_PHASE: String = "combat"
const SETTLEMENT_PHASE: String = "settlement"

# ========== 网格类型常量 ==========
const GRID_TYPE_UNEXPLORED: int = 0  # 未开垦
const GRID_TYPE_EXPLORED: int = 1    # 已开垦
const GRID_TYPE_MAZE: int = 2        # 迷宫

# ========== 构造体类型常量 ==========
const CONSTRUCT_TYPE_ENTITY: int = 0  # 实体
const CONSTRUCT_TYPE_VIRTUAL: int = 1  # 虚体

# ========== 构造体序列常量 ==========
# 实体序列
const ENTITY_SERIAL_TOTEM: int = 1        # 图腾
const ENTITY_SERIAL_CREATURE: int = 2     # 造物
const ENTITY_SERIAL_ABOMINATION: int = 3  # 魔物
const ENTITY_SERIAL_MALEVOLENCE: int = 4  # 邪祟
const ENTITY_SERIAL_DIVINE: int = 5       # 神祇

# 虚体序列
const VIRTUAL_SERIAL_OMEN: int = 1        # 预兆
const VIRTUAL_SERIAL_ABERRATION: int = 2  # 异象
const VIRTUAL_SERIAL_REVELATION: int = 3  # 启示
const VIRTUAL_SERIAL_CATACLYSM: int = 4  # 灾厄
const VIRTUAL_SERIAL_ORACLE: int = 5     # 神谕

# ========== 构造体状态常量 ==========
const CONSTRUCT_STATE_INACTIVE: int = 0  # 未激活
const CONSTRUCT_STATE_ACTIVE: int = 1    # 激活
const CONSTRUCT_STATE_DISABLED: int = 2  # 失效
const CONSTRUCT_STATE_DESTROYED: int = 3 # 销毁

# ========== 效果类型常量 ==========
const EFFECT_TYPE_DAMAGE: String = "damage"           # 伤害
const EFFECT_TYPE_SANITY: String = "sanity"           # 理智损失
const EFFECT_TYPE_MOVEMENT: String = "movement"      # 移动阻碍
const EFFECT_TYPE_STATUS: String = "status"          # 状态异常

# ========== 真理要素状态常量 ==========
const TRUTH_STATE_ACTIVE: int = 0      # 活跃
const TRUTH_STATE_SLEEPING: int = 1    # 沉睡
const TRUTH_STATE_EXTINCT: int = 2     # 寂灭
const TRUTH_STATE_SUBLIMATED: int = 3  # 升华

# ========== 检定结果常量 ==========
const CHECK_RESULT_CRITICAL_SUCCESS: int = 0  # 大成功
const CHECK_RESULT_SUCCESS: int = 1           # 成功
const CHECK_RESULT_FAILURE: int = 2           # 失败
const CHECK_RESULT_CRITICAL_FAILURE: int = 3  # 大失败

# ========== 默认数值常量 ==========
# 准备阶段
const DEFAULT_PREPARATION_TIME: float = 300.0  # 准备阶段默认时长（秒），5分钟

# 初始资源
const DEFAULT_TABLE_CONSTRUCT: int = 10        # 初始表构造力
const DEFAULT_INNER_CONSTRUCT: int = 10        # 初始里构造力
const DEFAULT_TABLE_CONSTRUCT_MAX: int = 20   # 初始表构造力上限
const DEFAULT_INNER_CONSTRUCT_MAX: int = 20   # 初始里构造力上限

# 资源消耗
const COST_EXPLORE_SURFACE_GRID: int = 1      # 开垦表世界网格消耗的表构造力
const COST_EXPLORE_INNER_GRID: int = 1        # 开垦里世界网格消耗的里构造力
const COST_BREAK_COCOON: int = 2              # 破茧消耗的里构造力

# 真理之茧释放
const COCOON_RELEASE_BASE_COUNT: int = 1      # 破茧基础释放数量
const COCOON_RELEASE_PER_LEVEL: int = 1       # 每级额外释放数量

# 资源自动生成
const AUTO_GENERATION_INTERVAL: float = 5.0   # 自动生成间隔（秒）
const AUTO_GENERATION_TABLE_CONSTRUCT: int = 1  # 每次自动生成的表构造力
const AUTO_GENERATION_INNER_CONSTRUCT: int = 1   # 每次自动生成的里构造力

# 网格相关
const DEFAULT_GRID_SIZE_X: int = 20           # 默认网格地图宽度
const DEFAULT_GRID_SIZE_Y: int = 20           # 默认网格地图高度

# 卡牌相关
const DEFAULT_HAND_SIZE: int = 5              # 默认手牌数量
const DEFAULT_DECK_SIZE: int = 30              # 默认牌组大小

# 调查员相关
const DEFAULT_INVESTIGATOR_COUNT: int = 1     # 默认调查员数量
const DEFAULT_INVESTIGATOR_HEALTH: int = 10   # 默认调查员生命值
const DEFAULT_INVESTIGATOR_SANITY: int = 10   # 默认调查员理智值

# 真理要素相关
const DEFAULT_TRUTH_ELEMENT_COUNT: int = 0    # 默认真理要素数量
const TRUTH_SERIAL_COUNT: int = 5             # 真理要素序列数量（I-V）

# ========== 日志级别常量 ==========
const LOG_LEVEL_DEBUG: int = 0
const LOG_LEVEL_INFO: int = 1
const LOG_LEVEL_WARNING: int = 2
const LOG_LEVEL_ERROR: int = 3

# ========== 资源类型常量 ==========
const RESOURCE_TABLE_CONSTRUCT: String = "table_construct"
const RESOURCE_INNER_CONSTRUCT: String = "inner_construct"
const RESOURCE_TRUTH_ELEMENT: String = "truth_element"

# ========== 工具函数 ==========
## 获取游戏阶段名称
static func get_phase_name(phase: String) -> String:
	match phase:
		PREPARATION_PHASE:
			return "准备阶段"
		COMBAT_PHASE:
			return "作战阶段"
		SETTLEMENT_PHASE:
			return "结算阶段"
		_:
			return "未知阶段"

## 获取网格类型名称
static func get_grid_type_name(type: int) -> String:
	match type:
		GRID_TYPE_UNEXPLORED:
			return "未开垦"
		GRID_TYPE_EXPLORED:
			return "已开垦"
		GRID_TYPE_MAZE:
			return "迷宫"
		_:
			return "未知类型"

## 获取构造体类型名称
static func get_construct_type_name(type: int) -> String:
	match type:
		CONSTRUCT_TYPE_ENTITY:
			return "实体"
		CONSTRUCT_TYPE_VIRTUAL:
			return "虚体"
		_:
			return "未知类型"

## 获取真理要素状态名称
static func get_truth_state_name(state: int) -> String:
	match state:
		TRUTH_STATE_ACTIVE:
			return "活跃"
		TRUTH_STATE_SLEEPING:
			return "沉睡"
		TRUTH_STATE_EXTINCT:
			return "寂灭"
		TRUTH_STATE_SUBLIMATED:
			return "升华"
		_:
			return "未知状态"

## 获取检定结果名称
static func get_check_result_name(result: int) -> String:
	match result:
		CHECK_RESULT_CRITICAL_SUCCESS:
			return "大成功"
		CHECK_RESULT_SUCCESS:
			return "成功"
		CHECK_RESULT_FAILURE:
			return "失败"
		CHECK_RESULT_CRITICAL_FAILURE:
			return "大失败"
		_:
			return "未知结果"

## 获取实体序列名称
static func get_entity_serial_name(serial: int) -> String:
	match serial:
		ENTITY_SERIAL_TOTEM:
			return "图腾"
		ENTITY_SERIAL_CREATURE:
			return "造物"
		ENTITY_SERIAL_ABOMINATION:
			return "魔物"
		ENTITY_SERIAL_MALEVOLENCE:
			return "邪祟"
		ENTITY_SERIAL_DIVINE:
			return "神祇"
		_:
			return "未知序列"

## 获取虚体序列名称
static func get_virtual_serial_name(serial: int) -> String:
	match serial:
		VIRTUAL_SERIAL_OMEN:
			return "预兆"
		VIRTUAL_SERIAL_ABERRATION:
			return "异象"
		VIRTUAL_SERIAL_REVELATION:
			return "启示"
		VIRTUAL_SERIAL_CATACLYSM:
			return "灾厄"
		VIRTUAL_SERIAL_ORACLE:
			return "神谕"
		_:
			return "未知序列"

## 获取构造体状态名称
static func get_construct_state_name(state: int) -> String:
	match state:
		CONSTRUCT_STATE_INACTIVE:
			return "未激活"
		CONSTRUCT_STATE_ACTIVE:
			return "激活"
		CONSTRUCT_STATE_DISABLED:
			return "失效"
		CONSTRUCT_STATE_DESTROYED:
			return "销毁"
		_:
			return "未知状态"
