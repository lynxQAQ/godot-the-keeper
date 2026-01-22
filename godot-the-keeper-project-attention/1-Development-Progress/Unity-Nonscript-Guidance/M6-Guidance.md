# M6 里程碑 - 调查员系统配置指南

本文档记录M6里程碑中需要在Godot引擎编辑器中手动完成的配置操作。

## 概述

M6里程碑包含以下任务：
- ✅ T6.1 实现调查员数据定义 (InvestigatorData.gd)
- ✅ T6.2 实现调查员状态管理 (InvestigatorState.gd)
- ✅ T6.3 实现调查员移动规则 (InvestigatorMovement.gd)
- ✅ T6.4 实现调查员寻路系统 (InvestigatorPathfinding.gd)
- ✅ T6.5 实现调查员场景 (Investigator.tscn 和 Investigator.gd)
- ✅ T6.6 实现调查员管理器 (InvestigatorManager.gd)
- ✅ T6.7 实现调查员预览系统 (InvestigatorPreview.tscn)

所有脚本文件已创建完成，但需要在Godot引擎中配置autoload单例和创建UI场景。

---

## 操作步骤

### 1. 配置Autoload单例

需要在Godot引擎中将以下脚本配置为autoload单例：

#### 1.1 InvestigatorManager单例

1. 打开Godot引擎编辑器
2. 点击菜单栏：`项目(Project)` → `项目设置(Project Settings)` → `Globals`
3. 在左侧列表中选择 `Autoload` 标签页
4. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/managers/InvestigatorManager.gd`
5. 在 `节点名称(Node Name)` 列下输入：`InvestigatorManager`
6. 确保 `单例(Singleton)` 选项已勾选
7. 点击 `添加(Add)` 按钮

**重要提示**：
- InvestigatorManager会自动管理所有注册的调查员实例
- 调查员需要在初始化后调用InvestigatorManager的注册方法
- 注意：InvestigatorManager没有使用`class_name`，因为它是一个autoload单例

---

### 2. 完善Investigator场景

#### 2.1 检查Investigator场景

1. 打开 `scenes/entities/Investigator.tscn` 场景
2. 确认根节点 `Investigator` 已附加 `scripts/entities/Investigator.gd` 脚本
3. 检查节点结构：
   - `ColorRect` - 调查员视觉表现（临时占位符，可后续替换为Sprite2D）
     - **注意**：调查员占据一个网格单位，视觉表现应适配网格大小
   - `Area2D` - 碰撞检测区域
     - `CollisionShape2D` - 碰撞形状（应匹配网格大小）
   - `HealthBar` (ProgressBar) - 生命值显示条
   - `SanityBar` (ProgressBar) - 理智值显示条

**网格占用说明**：
- 调查员在网格地图上占据一个网格位置
- 视觉表现（ColorRect或Sprite2D）的大小应适配网格单元大小
- 碰撞形状应设置为与网格大小匹配，确保精确的网格对齐

#### 2.2 可选：替换ColorRect为Sprite2D

如果需要使用纹理而不是颜色矩形：

1. 删除 `ColorRect` 节点
2. 添加 `Sprite2D` 节点
3. 在Inspector中为 `Sprite2D` 设置纹理
4. 更新 `Investigator.gd` 脚本中的节点引用：
   ```gdscript
   @onready var sprite: Sprite2D = get_node("Sprite2D") if has_node("Sprite2D") else null
   ```

#### 2.3 配置进度条样式

1. 选中 `HealthBar` 节点
2. 在Inspector中检查 `Theme Override Styles`：
   - `Background` - 应设置为红色样式（已配置）
   - `Fill` - 应设置为红色样式（已配置）
3. 选中 `SanityBar` 节点
4. 在Inspector中检查 `Theme Override Styles`：
   - `Background` - 应设置为蓝色样式（已配置）
   - `Fill` - 应设置为蓝色样式（已配置）

---

### 3. 创建调查员预览UI场景

#### 3.1 创建InvestigatorPreview.tscn场景

**创建步骤**：
1. 在 `scenes/ui/` 目录下创建新场景
2. 添加一个 `Control` 节点作为根节点，命名为 `InvestigatorPreview`
3. 将根节点的脚本设置为 `scripts/ui/InvestigatorPreview.gd`
4. 设置根节点的布局：
   - `Anchors Preset` 设置为 `Full Rect`（或根据需要设置位置）
   - 设置合适的大小（例如：400x300）
5. 添加子节点结构：
   ```
   InvestigatorPreview (Control)
   └── VBoxContainer
       ├── NameLabel (Label) - 调查员名称
       ├── DescriptionLabel (Label) - 调查员描述
       ├── StatsContainer (HBoxContainer)
       │   ├── HealthLabel (Label) - 生命值显示
       │   └── SanityLabel (Label) - 理智值显示
       ├── ExpandButton (Button) - 展开/收起按钮
       └── DetailsContainer (VBoxContainer) - 详细信息容器（默认隐藏）
           ├── AttributesContainer (VBoxContainer)
           │   └── AttributesLabel (Label) - 基础数值显示
           ├── SkillsContainer (VBoxContainer)
           │   └── SkillsLabel (Label) - 技能列表显示
           └── ExperiencesContainer (VBoxContainer)
               └── ExperiencesLabel (Label) - 经历列表显示
   ```
6. 配置各个Label的文本对齐和字体大小
7. 设置 `DetailsContainer` 的 `Visible` 属性为 `false`（默认收起）
8. 连接 `ExpandButton` 的 `pressed` 信号到脚本的 `_on_expand_button_pressed` 方法
9. 保存场景为 `scenes/ui/InvestigatorPreview.tscn`

**节点配置说明**：
- `NameLabel`：显示调查员名称，建议使用较大的字体
- `DescriptionLabel`：显示调查员描述，建议启用 `Autowrap` 自动换行
- `HealthLabel` 和 `SanityLabel`：显示格式为 "生命值: 10 / 10"
- `AttributesLabel`：显示格式为 "力量: 50 | 敏捷: 50 | 智力: 50 | 意志: 50"
- `SkillsLabel`：显示格式为 "技能: 技能1 (Lv.1), 技能2 (Lv.2)"
- `ExperiencesLabel`：显示格式为 "经历 (2): 经历1 | 经历2"

---

### 4. 验证调查员系统

运行游戏，测试以下功能：

#### 4.1 检查InvestigatorManager初始化

1. **检查autoload配置**：
   - 游戏启动后，InvestigatorManager应该自动初始化
   - 查看控制台日志，确认初始化成功：
     ```
     InvestigatorManager: 初始化完成
     ```

#### 4.2 测试调查员创建

```gdscript
# 创建调查员数据
var investigator_data = InvestigatorData.new("inv_001", "测试调查员", 10, 10)
investigator_data.strength = 60
investigator_data.agility = 55
investigator_data.intelligence = 70
investigator_data.willpower = 65

# 添加技能
investigator_data.add_skill("调查", 3)
investigator_data.add_skill("战斗", 2)

# 获取网格管理器（需要从SurfaceWorldGrid获取）
var surface_world = get_node("路径/到/SurfaceWorldGrid")
var grid_manager = surface_world.get_grid_manager()

# 设置初始位置
investigator_data.set_position(Vector2i(5, 5))

# 生成调查员
var investigator = InvestigatorManager.spawn_investigator(
    investigator_data,
    grid_manager,
    surface_world.grid_system  # 或合适的父节点
)

# 设置目标位置（秘密位置）
investigator.set_target_position(Vector2i(10, 10))
```

#### 4.3 测试状态管理

```gdscript
# 获取调查员
var investigator = InvestigatorManager.get_investigator("inv_001")

# 应用伤害
investigator.apply_damage(3)
# 应该看到生命值减少，进度条更新

# 应用理智损失
investigator.apply_sanity_loss(2)
# 应该看到理智值减少，进度条更新

# 添加状态效果（持续伤害）
investigator.add_status_effect("dot_001", "damage_over_time", 5.0, 1)
# 每秒造成1点伤害，持续5秒

# 添加移动阻碍效果
investigator.add_status_effect("block_001", "movement_block", 3.0, 0)
# 阻碍移动3秒
```

#### 4.4 测试移动和寻路

```gdscript
# 获取调查员
var investigator = InvestigatorManager.get_investigator("inv_001")

# 设置目标位置（会自动计算路径）
investigator.set_target_position(Vector2i(15, 15))

# 检查路径
var path = investigator.investigator_pathfinding.get_current_path()
print("路径: ", path)

# 等待一段时间，观察调查员是否沿着路径移动
```

#### 4.5 测试调查员预览

```gdscript
# 创建预览UI
var preview_scene = preload("res://scenes/ui/InvestigatorPreview.tscn")
var preview = preview_scene.instantiate()

# 添加到场景树
add_child(preview)

# 设置调查员数据
var investigator_data = InvestigatorData.new("inv_001", "测试调查员", 10, 10)
preview.set_investigator_data(investigator_data)

# 显示预览
preview.show_preview()

# 测试展开/收起
preview.expand()  # 展开详细信息
preview.collapse()  # 收起详细信息
```

#### 4.6 测试胜利/失败判定

```gdscript
# 检查是否有调查员到达秘密位置
var secret_position = Vector2i(10, 10)
if InvestigatorManager.check_victory_condition(secret_position):
    print("调查员到达秘密位置，玩家失败！")

# 检查是否所有调查员都已死亡
if InvestigatorManager.check_all_dead():
    print("所有调查员已死亡，玩家胜利！")
```

---

### 5. 集成到游戏场景

#### 5.1 在GameScene中集成调查员系统

1. 打开 `scenes/game_scene.tscn` 场景
2. 找到 `SurfaceWorldGrid` 节点（表世界网格）
3. 在准备阶段，创建调查员：
   ```gdscript
   # 在准备阶段开始时
   func _on_preparation_phase_started():
       # 创建调查员数据
       var investigator_data = InvestigatorData.new("inv_001", "调查员1", 10, 10)
       investigator_data.set_position(Vector2i(0, 0))  # 设置起始位置
       
       # 获取网格管理器
       var grid_manager = surface_world_grid.get_grid_manager()
       
       # 生成调查员
       var investigator = InvestigatorManager.spawn_investigator(
           investigator_data,
           grid_manager,
           surface_world_grid.grid_system
       )
       
       # 设置目标位置（秘密位置）
       var secret_pos = get_secret_position()  # 获取秘密位置
       investigator.set_target_position(secret_pos)
   ```

#### 5.2 在准备阶段显示调查员预览

1. 在 `GameScene` 中添加 `InvestigatorPreview` 节点
2. 在准备阶段开始时显示预览：
   ```gdscript
   func _on_preparation_phase_started():
       # 创建调查员数据
       var investigator_data = InvestigatorData.new("inv_001", "调查员1", 10, 10)
       
       # 显示预览
       investigator_preview.set_investigator_data(investigator_data)
       investigator_preview.show_preview()
   ```

#### 5.3 在作战阶段更新调查员

调查员会在 `_process` 中自动更新移动和状态，无需手动调用。

---

## 注意事项

### 1. 调查员网格占用

**重要设计说明**：
- **调查员是一个仅占据一个单位网格的存在**
- 每个调查员在网格地图上占据一个网格位置（`Vector2i`）
- 多个调查员不能同时占据同一个网格位置（与实体Entity的设计一致）
- 调查员的移动是基于网格的，每次移动一个网格单位
- 调查员的位置必须对齐到网格中心，不能位于网格之间

**实现说明**：
- 调查员的位置存储在 `InvestigatorData.position` 中，类型为 `Vector2i`（网格坐标）
- 寻路系统基于网格坐标进行计算，返回的是网格位置数组
- 移动动画会平滑过渡，但最终位置必须对齐到网格中心
- 使用 `InvestigatorManager.get_investigators_at_position(pos)` 可以查询指定网格位置的调查员
- 如果需要在同一网格放置多个调查员，需要实现堆叠逻辑（当前实现不支持）

### 2. 网格管理器引用

- 调查员的寻路系统需要 `GridMapManager` 引用
- 确保在初始化调查员时传入正确的 `GridMapManager` 实例
- `GridMapManager` 可以从 `SurfaceWorldGrid` 的 `get_grid_manager()` 方法获取

### 3. 调查员位置同步

- 调查员的位置存储在 `InvestigatorData.position` 中
- 当调查员移动时，会自动更新 `InvestigatorData.position`
- 确保在查询调查员位置时使用 `investigator.get_grid_position()`
- 使用 `InvestigatorManager.get_investigators_at_position(pos)` 可以查询指定网格位置的所有调查员

### 4. 状态效果持续时间

- 状态效果的持续时间以秒为单位
- 持续伤害效果每秒触发一次
- 状态效果会在 `InvestigatorState.update_status_effects()` 中自动更新

### 5. 移动规则选择

- 默认使用 `SHORTEST_PATH`（最短路径）
- 可以通过 `investigator.investigator_movement.set_movement_rule()` 更改移动规则
- 移动规则包括：
  - `SHORTEST_PATH` - 最短路径
  - `RANDOM_EXPLORE` - 随机探索
  - `CAUTIOUS_ADVANCE` - 谨慎前进（避开危险区域）
  - `FOLLOW_PATH` - 跟随路径

### 6. 路径重新计算

- 当遇到动态障碍物时，路径会自动重新计算
- 可以通过 `investigator.investigator_pathfinding.recalculate_path()` 手动触发重新计算
- 寻路算法会避开不可通行的网格，确保路径有效

### 7. 胜利/失败判定

- 胜利条件：所有调查员死亡（生命值或理智值任一为0）
- 失败条件：有调查员到达秘密位置且存活
- 判定方法：
  - `InvestigatorManager.check_win_condition()` - 检查是否胜利
  - `InvestigatorManager.check_lose_condition(secret_position)` - 检查是否失败

---

## 故障排除

### 问题1：调查员不移动

**可能原因**：
1. 未设置目标位置
2. 网格管理器未正确传入
3. 路径计算失败

**解决方法**：
1. 检查是否调用了 `investigator.set_target_position()`
2. 确认 `grid_manager` 参数不为 `null`
3. 检查起点和终点是否都在可通行的网格上

### 问题2：调查员状态不更新

**可能原因**：
1. 状态效果未正确添加
2. `update_status_effects()` 未在 `_process` 中调用

**解决方法**：
1. 检查状态效果的参数是否正确
2. 确认 `Investigator._process()` 中调用了 `investigator_state.update_status_effects(delta)`

### 问题3：预览UI不显示

**可能原因**：
1. 场景未添加到场景树
2. 节点路径不正确
3. `visible` 属性为 `false`

**解决方法**：
1. 确认预览场景已添加到场景树
2. 检查脚本中的节点路径是否正确
3. 调用 `preview.show_preview()` 确保可见

---

## 文件清单

M6里程碑创建的文件：

**脚本文件**：
- `scripts/data/InvestigatorData.gd` - 调查员数据定义
- `scripts/systems/InvestigatorState.gd` - 调查员状态管理
- `scripts/systems/InvestigatorMovement.gd` - 调查员移动规则
- `scripts/systems/InvestigatorPathfinding.gd` - 调查员寻路系统
- `scripts/entities/Investigator.gd` - 调查员实体脚本
- `scripts/managers/InvestigatorManager.gd` - 调查员管理器
- `scripts/ui/InvestigatorPreview.gd` - 调查员预览UI脚本

**场景文件**：
- `scenes/entities/Investigator.tscn` - 调查员场景
- `scenes/ui/InvestigatorPreview.tscn` - 调查员预览UI场景

**配置文件**：
- `project.godot` - 已添加 `InvestigatorManager` autoload 配置

---

## 下一步

完成M6后，可以继续实现：
- M7: 仪式系统（真理要素到卡牌的转换）
- M8: 检定系统（克苏鲁跑团掷骰检定）
- M11: 表世界玩法整合（整合调查员系统到游戏流程）

---

## 参考

- [开发进度总览.md](../开发进度总览.md) - M6任务详细说明
- [产品总述.md](../../2-Product-Documentation/产品总述.md) - 游戏设计文档
- [M4-Guidance.md](./M4-Guidance.md) - 构造体系统配置指南
- [M5-Guidance.md](./M5-Guidance.md) - 卡牌系统配置指南
