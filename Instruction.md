
# 运行机制与时序说明（M6 版本）

本文基于 `godot-the-keeper-project-attention` 需求与当前 Godot 工程实现，说明**游戏运行时后台脚本如何工作、节点如何被调用、以及时间顺序**。重点覆盖已完成的系统：网格、资源、卡牌、调查员。

## 1. 游戏概念与运行框架

- **表世界**：迷宫与防御（网格、秘密、调查员）
- **里世界**：真理要素培育（网格、要素移动）
- **卡牌系统**：实体/虚体卡牌与使用
- **资源系统**：表构造力、里构造力、真理要素

当前主入口场景与脚本：

- 主场景：`MainMenu.tscn`（`project.godot` → `run/main_scene`）
- 游戏场景：`scenes/game_scene.tscn`
- 子视口场景：`scenes/subworld_surface.tscn` / `scenes/subword_inner.tscn`

## 2. Autoload（全局单例）启动顺序与职责

`project.godot` 注册的 Autoload 会在主场景之前加载进 `/root`，并执行 `_ready()`：

- `Constants`：常量定义（阶段、网格类型、默认数值）
- `SignalBus`：全局信号总线
- `DataManager`：JSON/Resource 加载与缓存
- `DebugLogger`：日志系统
- `SceneManager`：场景切换
- `ResourceManager`：表/里构造力与真理要素资源
- `ConstructManager`：实体/虚体管理
- `InvestigatorManager`：调查员管理
- `CardLibrary`：卡牌库（尝试加载 `data/cards.json`）
- `CardUsage`：卡牌使用逻辑

这些单例确保后续任意场景可直接访问资源与系统。

## 3. 启动流程与时间顺序

### 3.1 引擎启动

1. Godot 读取 `project.godot`。
2. Autoload 进入场景树并执行 `_ready()`：
   - `DebugLogger` 初始化日志
   - `ResourceManager` 初始化资源数值与自动生成计时器
   - `CardLibrary` 尝试加载卡牌数据
   - 其他管理器准备就绪

### 3.2 主菜单加载

1. 加载 `MainMenu.tscn`（根节点 `Control (MainMenuRoot)`）。
2. `scripts/ui/MainMenu.gd` 的 `_ready()`：
   - 连接 Start/Continue/Gallery/Quit 按钮信号
   - 调用 `SceneManager.has_save_file()`，无存档则禁用 Continue

### 3.3 进入游戏场景

1. 点击 Start → `SceneManager.start_new_game()` → `SceneManager.change_scene()`
2. 加载 `scenes/game_scene.tscn`（脚本 `scripts/ui/GameScene.gd`）
3. `GameScene._ready()` 执行：
   1. `_setup_layout()`：设置全屏布局
   2. `_instantiate_subwindows()`：
      - 创建 `subworld_surface.tscn` → `SurfaceWorldGrid`
      - 创建 `subword_inner.tscn` → `InnerWorldGrid`
      - 二者加入各自的 `SubViewport`
   3. `_initialize_hand_system()`：
      - 创建 `Hand`
      - 等一帧（确保 `CardLibrary` 已加载）
      - 添加测试卡牌（`entity_totem_01` / `virtual_omen_01`）
      - 实例化 `HandDisplay` 并绑定手牌

## 4. 表世界（SurfaceWorldGrid）运行时序

### 4.1 初始化流程

1. `SurfaceWorldGrid._ready()`
2. 实例化 `GridSystem.tscn` 并添加到子视口
3. 创建 `SecretContainer` 并作为 `GridSystem` 子节点
4. 连接 `GridSystem` 信号：`grid_clicked` / `grid_hovered` / `grid_map_initialized`
5. 延迟加载规则：`GridSystemRule_Surface`
6. 延迟初始化网格尺寸（默认 20x20）

### 4.2 网格系统核心逻辑（GridSystem）

`GridSystem` 在 `_ready()` 中：

- 创建 `Camera2D` 与 `GridCellContainer`
- 构建 `GridMapManager`（网格数据）
- 延迟 `_init_after_frame()`：
  - 计算等距坐标原点
  - 初始化全部 `GridCell`
  - 设置缩放

输入处理由 `GridSystem._input()` 完成：

- 空格 + 鼠标左键：拖拽视图
- Ctrl + 滚轮：缩放
- 左键点击：触发 `grid_clicked`（表世界用来开垦）
- 左键拖拽：连续开垦

### 4.3 表世界业务逻辑

- 点击未开垦网格 → `SurfaceWorldGrid.explore_grid()`
  - 调用规则 `GridSystemRule_Surface.validate_explore()`（必须与已开垦网格相邻）
  - 消耗表构造力（`ResourceManager.consume_table_construct()`）
  - 变更网格数据并更新显示

- 初始开垦完成后：
  - `_create_initial_path()` 自动生成 5 格通路
  - `_spawn_initial_secret()` 在已开垦格子中放置秘密

- 秘密交互：
  - 点击秘密节点 → `Secret.secret_clicked` → `SurfaceWorldGrid._pickup_secret()`
  - 玩家持有秘密后，可在已开垦格子上放置

- 调查员生成：
  - `_start_investigator_spawn_timer()` 20 秒后执行
  - 在边缘已开垦格子中生成调查员
  - 排除秘密所在位置
  - 设置目标为秘密位置

## 5. 里世界（InnerWorldGrid）运行时序

### 5.1 初始化流程

- 与表世界类似，创建 `GridSystem` 并加载 `GridSystemRule_Inner`
- 默认网格 20x20
- `_initialize_cocoon_levels()`：为未开垦格子随机分配茧等级（70% 为 0，30% 为 1）
- `update_all_activities()` 初始化活跃度

### 5.2 真理要素移动

- `_process(delta)` 中调用 `_update_truth_elements_movement()`
- 每 `move_update_interval` 秒更新一次移动
- 活跃状态的要素随机移动至相邻已开垦格子
- 真理要素使用平滑移动动画（`TruthElement.start_move_to()`）

### 5.3 里世界开垦逻辑

- 点击未开垦格子 → `InnerWorldGrid.explore_grid()`
- 调用规则 `GridSystemRule_Inner.validate_explore()`（无限制）
- 消耗里构造力
- 若茧等级 > 0：生成真理要素并更新密度

## 6. 调查员系统时序

### 6.1 生成

- `SurfaceWorldGrid._spawn_investigator_at_edge()` 调用
- `InvestigatorManager.spawn_investigator()`：
  - 实例化 `Investigator.tscn`
  - 初始化数据、位置、寻路系统
  - 注册到 `InvestigatorManager`

### 6.2 寻路与移动

- `Investigator._process()`：
  - 更新状态效果
  - 调用 `_process_movement()`
- `InvestigatorPathfinding` 使用 A* 计算路径
- 每隔 `move_interval` 执行一步
- 进入目标格（秘密）后触发 `SignalBus.investigator_victory`

### 6.3 状态与死亡

- `InvestigatorState` 维护生命/理智与异常状态
- 任一数值为 0 → 触发死亡信号

## 7. 资源系统时序

`ResourceManager` 在 `_process(delta)` 中：

- 处理表构造力/里构造力的 **generation_rate** 生成
- 每 5 秒自动生成一次（`Constants.AUTO_GENERATION_INTERVAL`）
- 资源变化通过 `SignalBus.resource_changed` 广播

`ResourceDisplay` 通过信号更新 UI：

- 表构造力、里构造力即时更新
- 资源不足时标签变红

## 8. 卡牌系统时序

### 8.1 卡牌加载

- `CardLibrary._ready()` 尝试加载 `data/cards.json`
- 卡牌数据存于 `CardData`，支持解锁/收集状态

### 8.2 手牌显示

- `GameScene._initialize_hand_system()` 创建手牌并添加测试卡
- `HandDisplay` 实例化 `CardUI` 并展示
- 点击卡牌会触发 `card_selected` 信号（但当前尚未与“放置/使用” UI 绑定）

### 8.3 卡牌使用（逻辑已实现，交互尚未接入）

- `CardUsage.use_card()`：验证资源、验证位置、消耗资源
- 实体卡牌：生成 `Entity` 并注册 `ConstructManager`
- 虚体卡牌：生成 `Virtual` 并注册 `ConstructManager`

## 9. 运行中的节点层级概览（关键部分）

```
MainMenu.tscn
└─ Control (MainMenuRoot)

game_scene.tscn
└─ GameScene (Control)
   ├─ ResourceDisplay
   ├─ SubViewportContainer_Surface
   │  └─ SubViewport_Surface
   │     └─ SubworldSurface (SurfaceWorldGrid)
   │        └─ GridSystem
   │           ├─ Camera2D
   │           ├─ GridCellContainer (多个 GridCell)
   │           └─ SecretContainer (Secret)
   ├─ SubViewportContainer_Inner
   │  └─ SubViewport_Inner
   │     └─ SubwordInner (InnerWorldGrid)
   │        └─ GridSystem
   │           ├─ Camera2D
   │           └─ TruthElementContainer (TruthElement)
   └─ HandDisplay
```

## 10. 现阶段功能范围（M6）

已实现：

- 主菜单与场景切换
- 表/里世界网格系统 + 输入交互
- 资源管理与 UI 展示
- 卡牌数据与手牌显示
- 调查员生成与寻路
- 秘密生成与拾取/放置

尚未完整接入（后续里程碑）：

- 回合/阶段管理（准备/作战/结算）
- 卡牌使用与布防的完整交互流程
- 战斗检定与构造体效果触发
- 结算与成长系统

如需进一步补充某个系统的细节（例如作战阶段逻辑或 UI 操作链路），可以在此文档基础上继续扩展。
