# M5 里程碑 - 卡牌系统配置指南

本文档记录M5里程碑中需要在Godot引擎编辑器中手动完成的配置操作。

## 概述

M5里程碑包含以下任务：
- ✅ T5.1 实现卡牌数据定义 (CardData.gd)
- ✅ T5.2 实现卡牌库系统 (CardLibrary.gd)
- ✅ T5.3 实现牌组系统 (Deck.gd)
- ✅ T5.4 实现手牌管理系统 (Hand.gd)
- ✅ T5.5 实现卡牌预备区系统 (CardReserve.gd)
- ✅ T5.6 实现卡牌UI场景
- ✅ T5.7 实现卡牌使用系统 (CardUsage.gd)

所有脚本文件已创建完成，但需要在Godot引擎中配置autoload单例和创建UI场景。

---

## 操作步骤

### 1. 配置Autoload单例

需要在Godot引擎中将以下脚本配置为autoload单例：

#### 1.1 CardLibrary单例

1. 打开Godot引擎编辑器
2. 点击菜单栏：`项目(Project)` → `项目设置(Project Settings) → Globals`
3. 在左侧列表中选择 `Autoload` 标签页
4. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/systems/CardLibrary.gd`
5. 在 `节点名称(Node Name)` 列下输入：`CardLibrary`
6. 确保 `单例(Singleton)` 选项已勾选
7. 点击 `添加(Add)` 按钮

#### 1.2 CardUsage单例

1. 在同一个 `Autoload` 标签页中
2. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/systems/CardUsage.gd`
3. 在 `节点名称(Node Name)` 列下输入：`CardUsage`
4. 确保 `单例(Singleton)` 选项已勾选
5. 点击 `添加(Add)` 按钮

---

### 2. 创建卡牌UI场景

#### 2.1 创建CardUI.tscn场景

**节点类型选择说明**：
- 使用 `Control` 节点作为根节点（而非 `Node2D`）
- **原因**：
  - 卡牌主要用于UI区域（手牌、预备区），`Control` 节点更适合UI交互（hover、点击、布局）
  - `Control` 节点内置 `mouse_entered`、`mouse_exited`、`gui_input` 信号，处理交互更方便
  - 与 `HandDisplay` 的架构一致（使用 `Control` 容器）
  - 即使卡牌需要在世界空间中显示（从真理要素转换），也可以通过 `CanvasLayer` + `global_position` 实现

**创建步骤**：
1. 在 `scenes/cards/` 目录下创建新场景
2. 添加一个 `Control` 节点作为根节点，命名为 `CardUI`
3. 将根节点的脚本设置为 `scripts/ui/CardUI.gd`
4. 设置根节点的大小（例如：200x300）
5. 添加子节点结构：
   - `VBoxContainer` (VBoxContainer)
     - `CardNameLabel` (Label) - 显示卡牌名称
     - `CardTypeLabel` (Label) - 显示卡牌类型和序列
     - `CardCostLabel` (Label) - 显示卡牌消耗
     - `CardDescriptionLabel` (Label) - 显示卡牌描述
     - `CardIcon` (TextureRect) - 显示卡牌图标（可选）
6. 配置各个Label的文本对齐和字体大小
7. 保存场景为 `scenes/cards/CardUI.tscn`

**世界空间卡牌显示（可选）**：
如果需要在世界空间中显示卡牌（例如：从真理要素转换后出现在屏幕上），有两种实现方式：

**方式1：使用 Control + CanvasLayer（推荐）**
- 将 `CardUI` 添加到独立的 `CanvasLayer` 中
- 使用 `global_position` 将卡牌定位到世界坐标位置
- 点击收集后，使用 Tween 动画移动到 UI 容器位置
- 优点：保持统一的 `Control` 架构，交互处理简单

**方式2：创建临时的 Node2D 包装器**
- 在世界空间阶段创建 `CardWorld2D`（`Node2D`）节点，内部包含 `CardUI` 作为子节点
- 点击收集后，销毁 `CardWorld2D`，创建新的 `CardUI` 并添加到 UI 容器
- 优点：可以直接使用世界坐标，但需要额外的转换逻辑

#### 2.2 创建HandDisplay.tscn场景

**说明**：手牌区和预备区使用同一个UI组件 `HandDisplay`，可以通过 `set_hand()` 或 `set_reserve()` 方法来切换显示的内容。

**创建步骤**：
1. 在 `scenes/ui/` 目录下创建新场景
2. 添加一个 `Control` 节点作为根节点，命名为 `HandDisplay`
3. 将根节点的脚本设置为 `scripts/ui/HandDisplay.gd`
4. 设置根节点的大小和位置（例如：底部居中）
5. 添加子节点：
   - `HandContainer` (HBoxContainer) - 用于横向排列卡牌（手牌或预备区）
   - `CapacityLabel` (Label) - 可选：显示容量信息（手牌数量/上限 或 预备区数量/容量）
6. 配置HBoxContainer的对齐方式和间距
7. 如果添加了 `CapacityLabel`，设置其位置和样式
8. 保存场景为 `scenes/ui/HandDisplay.tscn`

**使用方式**：
- 显示手牌：调用 `hand_display.set_hand(hand_instance)`
- 显示预备区：调用 `hand_display.set_reserve(reserve_instance)`

---

### 3. 创建卡牌数据文件（可选）

如果需要测试卡牌系统，可以创建JSON格式的卡牌数据文件：

1. 在 `data/` 目录下创建 `cards.json` 文件
2. 使用以下格式：

```json
{
  "cards": [
    {
      "id": "entity_totem_01",
      "name": "图腾",
      "description": "基础实体单位",
      "card_type": 0,
      "serial": 1,
      "cost_table_construct": 2,
      "cost_inner_construct": 0,
      "construct_data_ref": "",
      "is_unlocked": true,
      "is_collected": false
    },
    {
      "id": "virtual_omen_01",
      "name": "预兆",
      "description": "基础虚体单位",
      "card_type": 1,
      "serial": 1,
      "cost_table_construct": 1,
      "cost_inner_construct": 1,
      "construct_data_ref": "",
      "is_unlocked": true,
      "is_collected": false
    }
  ]
}
```

3. 在游戏初始化时调用 `CardLibrary.load_cards_from_json("res://data/cards.json")`

**如何设置卡牌数据加载**：

有以下几种方式可以在游戏初始化时加载卡牌数据：

**方式1：在 CardLibrary 的 _ready() 中自动加载（推荐）**

1. 打开 `scripts/systems/CardLibrary.gd` 文件
2. 在 `_ready()` 方法中添加加载代码：

```gdscript
func _ready() -> void:
	# 连接信号
	_connect_signals()
	# 自动加载卡牌数据
	load_cards_from_json("res://data/cards.json")
	DebugLogger.info("CardLibrary: 初始化完成", "CardLibrary")
```

**优点**：简单直接，游戏启动时自动加载  
**缺点**：每次游戏启动都会加载，即使不需要卡牌数据

**方式2：在 GameScene 的 _ready() 中加载**

1. 打开 `scripts/ui/GameScene.gd` 文件
2. 在 `_ready()` 方法中添加加载代码：

```gdscript
func _ready():
	# 设置全屏布局
	_setup_layout()
	
	# 加载卡牌数据
	if CardLibrary:
		CardLibrary.load_cards_from_json("res://data/cards.json")
	
	# 实例化子窗口
	_instantiate_subwindows()
```

**优点**：只在进入游戏场景时加载，更灵活  
**缺点**：需要在每个需要卡牌的场景中手动加载

**方式3：通过游戏开始信号加载**

1. 打开 `scripts/systems/CardLibrary.gd` 文件
2. 在 `_on_game_started()` 方法中添加加载代码：

```gdscript
func _on_game_started() -> void:
	# 游戏开始时加载卡牌数据
	load_cards_from_json("res://data/cards.json")
	DebugLogger.info("CardLibrary: 游戏开始，初始化卡牌库", "CardLibrary")
```

3. 在游戏开始时发射信号（例如在 `GameScene._ready()` 中）：

```gdscript
func _ready():
	# ... 其他初始化代码 ...
	# 发射游戏开始信号
	SignalBus.game_started.emit()
```

**优点**：符合信号驱动的架构设计  
**缺点**：需要确保信号在正确的时机发射

**推荐使用方式1**，因为它最简单且能确保卡牌数据在游戏启动时就可用。

---

## 验证配置

### 方法1：使用测试脚本（推荐）

已创建测试脚本 `scripts/test/test_card_system.gd`，可以直接使用：

1. 创建一个测试场景（`test_card_scene.tscn`）
2. 添加一个 `Node` 节点作为根节点
3. 将脚本 `scripts/test/test_card_system.gd` 附加到节点上
4. 运行场景，查看输出面板

测试脚本会自动测试：
- ✅ CardLibrary 卡牌库加载和查询
- ✅ Hand 手牌系统添加和管理
- ✅ CardUI 和 HandDisplay 场景文件存在性

### 方法2：在游戏场景中测试

游戏场景（`game_scene.tscn`）已集成手牌系统：

1. 运行游戏场景（`scenes/game_scene.tscn`）
2. 游戏启动后会自动：
   - 加载卡牌数据（从 `data/cards.json`）
   - 创建手牌实例
   - 添加测试卡牌（`entity_totem_01` 和 `virtual_omen_01`）
   - 在底部区域（`Control (bottom)`）显示 `HandDisplay`
3. 查看底部区域，应该能看到手牌卡牌显示

**手牌显示位置**：
- `HandDisplay` 会自动添加到 `Control (bottom)` 节点
- 卡牌横向排列在 `HandContainer` 中
- 容量信息显示在 `CapacityLabel` 中（如果存在）

### 方法3：手动测试代码

如果需要手动测试，可以使用以下代码：

```gdscript
extends Node

func _ready():
	# 等待一帧，确保autoload单例已初始化
	await get_tree().process_frame
	
	# 测试CardLibrary
	print("测试CardLibrary:")
	var card = CardLibrary.get_card("entity_totem_01")
	if card:
		print("找到卡牌: " + card.name)
	
	# 测试Deck
	print("\n测试Deck:")
	var deck = Deck.new(["entity_totem_01", "virtual_omen_01"])
	print("牌组大小: " + str(deck.get_size()))
	var drawn_card = deck.draw_card()
	print("抽到的卡牌: " + drawn_card)
	
	# 测试Hand
	print("\n测试Hand:")
	var hand = Hand.new(5)
	hand.add_card("entity_totem_01")
	print("手牌大小: " + str(hand.get_size()))
	
	# 测试CardReserve
	print("\n测试CardReserve:")
	var reserve = CardReserve.new(10)
	reserve.add_card("virtual_omen_01")
	print("预备区大小: " + str(reserve.get_size()))
	
	# 测试HandDisplay（可以显示手牌或预备区）
	print("\n测试HandDisplay:")
	var hand_display = HandDisplay.new()
	hand_display.set_hand(hand)  # 显示手牌
	# 或者
	hand_display.set_reserve(reserve)  # 显示预备区
```

---

## 预期结果

配置完成后，应该能够：

1. ✅ 在任何脚本中通过 `CardLibrary` 访问卡牌库（autoload单例）
2. ✅ 在任何脚本中通过 `CardUsage` 使用卡牌（autoload单例）
3. ✅ 创建Deck、Hand、CardReserve实例并管理卡牌
4. ✅ 在UI场景中显示卡牌（使用HandDisplay可以显示手牌或预备区）
5. ✅ 使用卡牌生成构造体

---

## 注意事项

### 1. 单例命名

- 单例的 `节点名称(Node Name)` 必须与脚本中访问的名称一致
- 例如：如果节点名称是 `CardLibrary`，则在脚本中使用 `CardLibrary.get_card()`

### 2. 场景路径

- CardUI场景路径：`res://scenes/cards/CardUI.tscn`
- HandDisplay场景路径：`res://scenes/ui/HandDisplay.tscn`
- **注意**：手牌区和预备区使用同一个 `HandDisplay` 组件，通过调用不同的方法来切换显示内容

### 3. 节点引用

- 确保UI脚本中的节点路径与场景中的节点名称一致
- 如果节点名称不同，需要修改脚本中的 `@onready` 引用

### 4. 卡牌数据加载

- 卡牌数据可以通过JSON文件或Resource文件加载
- 需要在游戏初始化时调用 `CardLibrary.load_cards_from_json()` 或 `CardLibrary.load_card_from_resource()`

---

## 故障排除

### 问题1：找不到CardLibrary/CardUsage

**原因**：autoload未正确配置

**解决方法**：
1. 检查 `项目设置` → `Autoload` 中是否正确添加了单例
2. 检查路径是否正确（注意大小写）
3. 重启Godot编辑器

### 问题2：CardUI场景无法加载

**原因**：场景路径错误或场景未创建

**解决方法**：
1. 检查场景文件是否存在
2. 检查场景路径是否正确
3. 确保场景已保存

### 问题3：UI节点引用错误

**原因**：场景中的节点名称与脚本中的引用不匹配

**解决方法**：
1. 检查场景中的节点名称
2. 修改脚本中的 `@onready` 引用以匹配场景节点名称
3. 或者修改场景中的节点名称以匹配脚本引用
