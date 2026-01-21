extends Node

## 信号总线
## 全局信号管理器，用于跨系统通信

# ========== 游戏阶段信号 ==========
## 游戏阶段切换信号
## phase: 新阶段名称（Constants中的阶段常量）
signal phase_changed(phase: String)

## 准备阶段开始
signal preparation_phase_started()

## 作战阶段开始
signal combat_phase_started()

## 结算阶段开始
signal settlement_phase_started()

# ========== 资源信号 ==========
## 资源变化信号
## resource_type: 资源类型（Constants中的资源类型常量）
## current_value: 当前值
## max_value: 最大值
signal resource_changed(resource_type: String, current_value: int, max_value: int)

## 表构造力变化
signal table_construct_changed(current_value: int, max_value: int)

## 里构造力变化
signal inner_construct_changed(current_value: int, max_value: int)

## 真理要素变化
## serial: 序列（I-V，1-5）
## count: 数量
signal truth_element_changed(serial: int, count: int)

# ========== 构造体信号 ==========
## 构造体生成信号
## construct_id: 构造体ID
## construct_type: 构造体类型（实体/虚体）
## position: 位置
signal construct_spawned(construct_id: String, construct_type: int, position: Vector2i)

## 构造体销毁信号
## construct_id: 构造体ID
signal construct_destroyed(construct_id: String)

## 构造体状态变化信号
## construct_id: 构造体ID
## old_state: 旧状态
## new_state: 新状态
signal construct_state_changed(construct_id: String, old_state: int, new_state: int)

# ========== 调查员信号 ==========
## 调查员生成信号
## investigator_id: 调查员ID
## position: 位置
signal investigator_spawned(investigator_id: String, position: Vector2i)

## 调查员移动信号
## investigator_id: 调查员ID
## from_pos: 起始位置
## to_pos: 目标位置
signal investigator_moved(investigator_id: String, from_pos: Vector2i, to_pos: Vector2i)

## 调查员状态变化信号
## investigator_id: 调查员ID
## health: 当前生命值
## sanity: 当前理智值
signal investigator_state_changed(investigator_id: String, health: int, sanity: int)

## 调查员死亡信号
## investigator_id: 调查员ID
signal investigator_died(investigator_id: String)

## 调查员胜利信号
## investigator_id: 调查员ID
signal investigator_victory(investigator_id: String)

# ========== 网格信号 ==========
## 网格状态变化信号
## grid_pos: 网格位置
## old_type: 旧类型
## new_type: 新类型
signal grid_changed(grid_pos: Vector2i, old_type: int, new_type: int)

## 网格被选择信号
## grid_pos: 网格位置
signal grid_selected(grid_pos: Vector2i)

# ========== 卡牌信号 ==========
## 卡牌抽取信号
## card_id: 卡牌ID
signal card_drawn(card_id: String)

## 卡牌使用信号
## card_id: 卡牌ID
## position: 使用位置
signal card_used(card_id: String, position: Vector2i)

## 卡牌添加到手牌信号
## card_id: 卡牌ID
signal card_added_to_hand(card_id: String)

## 卡牌从手牌移除信号
## card_id: 卡牌ID
signal card_removed_from_hand(card_id: String)

# ========== 仪式信号 ==========
## 仪式执行信号
## ritual_id: 仪式ID
## truth_elements: 消耗的真理要素
signal ritual_performed(ritual_id: String, truth_elements: Dictionary)

## 破茧信号
## cocoon_id: 茧ID
## truth_elements: 释放的真理要素
signal cocoon_broken(cocoon_id: String, truth_elements: Dictionary)

# ========== 战斗信号 ==========
## 检定执行信号
## investigator_id: 调查员ID
## check_type: 检定类型
## result: 检定结果（Constants中的检定结果常量）
signal check_performed(investigator_id: String, check_type: String, result: int)

## 效果触发信号
## construct_id: 构造体ID
## investigator_id: 调查员ID
## effect_type: 效果类型
signal effect_triggered(construct_id: String, investigator_id: String, effect_type: String)

# ========== 游戏流程信号 ==========
## 回合开始信号
## round_number: 回合数
signal round_started(round_number: int)

## 回合结束信号
## round_number: 回合数
signal round_ended(round_number: int)

## 游戏开始信号
signal game_started()

## 游戏结束信号
## victory: 是否胜利
signal game_ended(victory: bool)

# ========== 场景切换信号 ==========
## 场景切换中信号
## scene_path: 目标场景路径
signal scene_changing(scene_path: String)

## 场景切换完成信号
## scene_path: 当前场景路径
signal scene_changed(scene_path: String)

## 游戏退出信号
signal game_quit()

# ========== UI信号 ==========
## UI显示信号
## ui_name: UI名称
signal ui_shown(ui_name: String)

## UI隐藏信号
## ui_name: UI名称
signal ui_hidden(ui_name: String)

## 对话框显示信号
## dialog_id: 对话框ID
signal dialog_shown(dialog_id: String)

## 对话框关闭信号
## dialog_id: 对话框ID
signal dialog_closed(dialog_id: String)
