# M2 里程碑 - Godot引擎独立操作指南

本文档记录M2里程碑中需要在Godot引擎编辑器中手动完成的配置操作。

## 概述

M2里程碑包含以下任务：
- ✅ T2.1 实现网格数据结构（GridData.gd）
- ✅ T2.2 实现网格地图管理器（GridMapManager.gd）
- ✅ T2.3 实现可复用网格系统Scene（GridSystem.tscn + GridSystem.gd）
- ✅ T2.4 实现网格可视化组件（GridCell.tscn）
- ✅ T2.5 实现表世界网格系统（SurfaceWorldGrid.gd + 集成到subworld_surface.tscn）
- ✅ T2.6 实现里世界网格系统（InnerWorldGrid.gd + 集成到subword_inner.tscn）
- ✅ T2.7 实现网格交互系统（输入处理、坐标转换、选择高亮）
- ✅ T2.8 实现主场景布局（GameScene.gd + 完善game_scene.tscn）

所有脚本和场景文件已创建完成，但需要在Godot引擎中验证和测试。

---
## 实现说明
游戏主场景 game_scene.tscn 通过脚本加载，对 subworld_surface.tscn 和 subworld_inner.tscn 进行实例化；subworld的实例化在其场景挂载的脚本中会对 GridSystem.tscn 进行实例化，GridSystem的实例化会在其场景挂载的脚本中对 GridCell.tscn 进行实例化。

1. subworld_surface.tscn（表世界子窗口）
   - 包含 SurfaceWorldGrid 脚本（继承 Control）
   - 在 _ready() 中实例化 GridSystem.tscn
   - 负责表世界的业务逻辑（开垦、迷宫、秘密位置等）
2. GridSystem.tscn（可复用网格系统）
   - 包含 GridSystem 脚本（继承 Node2D）
   - 包含一个 GridContainer（Control 节点）
   - 负责网格的创建、管理和交互
   - 在运行时动态创建 GridCell 实例
4. GridCell.tscn（单个网格单元）
   - 包含 GridCell 脚本（继承 ColorRect）
   - 负责单个网格的视觉表现（颜色、状态显示）
   - 由 GridSystem 在运行时批量实例化

关系链：subworld_surface → 实例化 → GridSystem → 动态创建 → GridCell

由于节点没有使用TileMap，网格实则是在 _ready() 中通过 _create_all_grid_cells() 动态创建，编辑时无法预览
- 灵活性：每个网格是独立节点，便于自定义逻辑和交互
- 动态性：网格状态在运行时频繁变化，ColorRect 更易更新
- 简单性：初期实现更直接，无需处理 TileSet 配置

---

## 操作步骤

### 1. 验证场景文件

#### 1.1 检查GridSystem场景

1. 打开Godot引擎编辑器
2. 打开场景：`scenes/worlds/GridSystem.tscn`
3. 检查场景结构：
   - 根节点：`GridSystem` (Node2D)，已附加 `scripts/systems/GridSystem.gd` 脚本
   - 子节点：`GridContainer` (Control) - 用于容纳GridCell节点
4. 在Inspector面板中检查GridSystem节点的导出属性：
   - `grid_size`: Vector2i(20, 20)
   - `cell_size`: Vector2(64, 64)
   - `enable_interaction`: true
   - `show_grid_lines`: true

#### 1.2 检查GridCell场景

1. 打开场景：`scenes/worlds/GridCell.tscn`
2. 检查场景结构：
   - 根节点：`GridCell` (ColorRect)，已附加 `scripts/systems/GridCell.gd` 脚本
3. 在Inspector面板中检查GridCell节点的属性：
   - `custom_minimum_size`: Vector2(64, 64)
   - `color`: Color(0.3, 0.3, 0.3, 0.5) - 默认灰色半透明

#### 1.3 检查子窗口场景

**表世界子窗口 (subworld_surface.tscn)**：

1. 打开场景：`scenes/subworld_surface.tscn`
2. 检查场景结构：
   - 根节点：`SubworldSurface` (Control)，已附加 `scripts/systems/SurfaceWorldGrid.gd` 脚本
   - 布局：全屏（anchors_preset = 15）

**里世界子窗口 (subword_inner.tscn)**：

1. 打开场景：`scenes/subword_inner.tscn`
2. 检查场景结构：
   - 根节点：`SubwordInner` (Control)，已附加 `scripts/systems/InnerWorldGrid.gd` 脚本
   - 布局：全屏（anchors_preset = 15）

#### 1.4 检查主场景

1. 打开场景：`scenes/game_scene.tscn`
2. 检查场景结构：
   - 根节点：`GameScene` (Control)，已附加 `scripts/ui/GameScene.gd` 脚本
   - 布局：全屏（anchors_preset = 15）
3. 子窗口场景会在运行时动态实例化，不需要在场景编辑器中添加

---

### 2. 验证脚本引用

#### 2.1 检查GridData类

1. 打开脚本：`scripts/data/GridData.gd`
2. 确认脚本继承自 `Resource` 并定义了 `class_name GridData`
3. 确认脚本可以正常编译（无语法错误）

#### 2.2 检查GridMapManager类

1. 打开脚本：`scripts/managers/GridMapManager.gd`
2. 确认脚本继承自 `RefCounted` 并定义了 `class_name GridMapManager`
3. 确认脚本可以正常编译

#### 2.3 检查GridSystem类

1. 打开脚本：`scripts/systems/GridSystem.gd`
2. 确认脚本继承自 `Node2D` 并定义了 `class_name GridSystem`
3. 检查预加载的资源：
   - `GridCellScene` 路径：`res://scenes/worlds/GridCell.tscn`
4. 确认脚本可以正常编译

#### 2.4 检查GridCell类

1. 打开脚本：`scripts/systems/GridCell.gd`
2. 确认脚本继承自 `ColorRect` 并定义了 `class_name GridCell`
3. 确认脚本可以正常编译

#### 2.5 检查子窗口脚本

**SurfaceWorldGrid**：

1. 打开脚本：`scripts/systems/SurfaceWorldGrid.gd`
2. 确认脚本继承自 `Control` 并定义了 `class_name SurfaceWorldGrid`
3. 检查预加载的资源：
   - `GridSystemScene` 路径：`res://scenes/worlds/GridSystem.tscn`
4. 确认脚本可以正常编译

**InnerWorldGrid**：

1. 打开脚本：`scripts/systems/InnerWorldGrid.gd`
2. 确认脚本继承自 `Control` 并定义了 `class_name InnerWorldGrid`
3. 检查预加载的资源：
   - `GridSystemScene` 路径：`res://scenes/worlds/GridSystem.tscn`
4. 确认脚本可以正常编译

#### 2.6 检查GameScene脚本

1. 打开脚本：`scripts/ui/GameScene.gd`
2. 确认脚本继承自 `Control` 并定义了 `class_name GameScene`
3. 检查预加载的资源：
   - `SubworldSurfaceScene` 路径：`res://scenes/subworld_surface.tscn`
   - `SubwordInnerScene` 路径：`res://scenes/subword_inner.tscn`
4. 确认脚本可以正常编译

---

### 3. 测试场景运行

#### 3.1 测试GridSystem场景（可选）

1. 打开场景：`scenes/worlds/GridSystem.tscn`
2. 点击运行场景按钮（F6）
3. 应该能看到：
   - 20x20的网格地图
   - 每个网格显示为灰色半透明的矩形
   - 鼠标悬停时网格会高亮
   - 点击网格会在输出面板显示坐标信息

#### 3.2 测试主场景

1. 打开场景：`scenes/game_scene.tscn`
2. 点击运行场景按钮（F6）
3. 应该能看到：
   - 屏幕被分为两个区域（左右分屏或上下分屏）
   - 左侧/上方：表世界网格系统（灰色网格）
   - 右侧/下方：里世界网格系统（灰色网格）
   - 两个网格系统独立运行，互不干扰
   - 鼠标悬停和点击功能正常工作

---

### 4. 验证功能

#### 4.1 验证网格数据

在Godot编辑器的调试控制台中运行以下代码（或创建测试脚本）：

```gdscript
extends Node

func _ready():
	# 测试GridData
	var grid_data = GridData.new(Vector2i(5, 5), Constants.GRID_TYPE_UNEXPLORED)
	print("网格坐标: ", grid_data.grid_pos)
	print("网格类型: ", Constants.get_grid_type_name(grid_data.grid_type))
	
	# 测试网格类型转换
	grid_data.set_explored()
	print("转换后类型: ", Constants.get_grid_type_name(grid_data.grid_type))
	
	# 测试GridMapManager
	var manager = GridMapManager.new(Vector2i(10, 10))
	var test_grid = manager.get_grid(Vector2i(5, 5))
	print("获取网格: ", test_grid.grid_pos)
	
	# 测试网格查询
	var neighbors = manager.get_neighbor_positions(Vector2i(5, 5))
	print("相邻网格数量: ", neighbors.size())
```

#### 4.2 验证场景实例化

在主场景运行时，检查：

1. **表世界子窗口**：
   - 在场景树中应该能看到 `SubworldSurface` 节点
   - 其子节点应该包含 `GridSystem` 节点
   - `GridSystem` 的子节点应该包含 `GridContainer` 节点
   - `GridContainer` 下应该有400个 `GridCell` 节点（20x20）

2. **里世界子窗口**：
   - 在场景树中应该能看到 `SubwordInner` 节点
   - 其子节点应该包含 `GridSystem` 节点
   - `GridSystem` 的子节点应该包含 `GridContainer` 节点
   - `GridContainer` 下应该有400个 `GridCell` 节点（20x20）

---

## 预期结果

配置完成后，应该能够：

1. ✅ 主场景可以正确布局两个子窗口（左右或上下分屏）
2. ✅ 表世界和里世界网格系统独立运行，互不干扰
3. ✅ 网格系统Scene可以在子窗口中正确实例化
4. ✅ 网格数据可以正确存储和查询
5. ✅ 网格状态转换逻辑正确（未开垦→已开垦→迷宫）
6. ✅ 网格可视化清晰，状态区分明显
7. ✅ 网格交互响应及时，坐标转换准确
8. ✅ 子窗口脚本可以正确管理各自的网格系统实例

---

## 注意事项

### 1. 场景节点类型

- **GridSystem** 使用 `Node2D` 作为根节点，因为需要处理2D坐标和绘制
- **GridCell** 使用 `ColorRect` 作为根节点，用于显示颜色
- **子窗口场景** 使用 `Control` 作为根节点，便于布局管理
- **主场景** 使用 `Control` 作为根节点，便于UI布局

### 2. 坐标系统

- **网格坐标**：使用 `Vector2i` 表示，从 (0,0) 开始
- **世界坐标**：使用 `Vector2` 表示，相对于GridSystem节点的本地坐标
- **坐标转换**：GridMapManager提供 `grid_to_world()` 和 `world_to_grid()` 方法

### 3. 网格Cell创建

- GridCell在GridSystem初始化时自动创建
- GridCell的位置通过 `grid_to_world()` 计算
- GridCell的大小由 `cell_size` 属性决定（默认64x64）

### 4. 交互系统

- GridSystem自动处理鼠标输入
- 鼠标悬停会触发 `grid_hovered` 信号
- 鼠标点击会触发 `grid_clicked` 信号
- 子窗口脚本可以连接这些信号来处理业务逻辑

### 5. 布局模式

- 主场景默认使用左右分屏（layout_mode = 0）
- 可以通过 `GameScene.switch_layout_mode()` 切换布局
- 子窗口间距由 `subwindow_spacing` 属性控制（默认10像素）

---

## 故障排除

### 问题1：GridSystem场景无法加载

**原因**：场景文件路径错误或脚本引用错误

**解决方法**：
1. 检查 `scenes/worlds/GridSystem.tscn` 文件是否存在
2. 检查场景文件中的脚本路径是否正确：`res://scripts/systems/GridSystem.gd`
3. 检查 `GridCell.tscn` 场景是否存在：`res://scenes/worlds/GridCell.tscn`

### 问题2：GridCell不显示

**原因**：GridCell位置或大小设置错误

**解决方法**：
1. 检查GridSystem的 `cell_size` 属性（默认64x64）
2. 检查GridCell的 `custom_minimum_size` 是否与 `cell_size` 一致
3. 检查GridCell的 `position` 是否正确计算
4. 确认GridCell的 `color` 不是完全透明（alpha > 0）

### 问题3：子窗口场景无法实例化

**原因**：场景路径错误或脚本错误

**解决方法**：
1. 检查 `scenes/subworld_surface.tscn` 和 `scenes/subword_inner.tscn` 是否存在
2. 检查GameScene脚本中的预加载路径是否正确
3. 查看输出面板的错误信息
4. 确认子窗口场景的根节点类型正确（Control）

### 问题4：网格交互无响应

**原因**：输入处理被禁用或坐标转换错误

**解决方法**：
1. 检查GridSystem的 `enable_interaction` 属性是否为true
2. 检查GridSystem是否在场景树中（需要添加到场景才能接收输入）
3. 检查鼠标坐标转换是否正确
4. 确认GridSystem的 `mouse_filter` 设置正确

### 问题5：布局不正确

**原因**：Control节点布局设置错误

**解决方法**：
1. 检查主场景和子窗口场景的 `anchors_preset` 设置
2. 检查 `anchor_right` 和 `anchor_bottom` 是否为1.0
3. 检查 `grow_horizontal` 和 `grow_vertical` 设置
4. 确认子窗口在运行时正确添加到场景树

### 问题6：两个网格系统互相干扰

**原因**：GridSystem使用全局坐标或单例管理器

**解决方法**：
1. 确认每个子窗口都有独立的GridSystem实例
2. 确认GridMapManager不是单例，每个GridSystem有自己的实例
3. 检查坐标转换是否使用本地坐标（相对于GridSystem节点）

---

## 下一步

完成M2里程碑的验证后，可以：

1. 开始M3里程碑：资源管理系统
2. 测试网格系统的各种功能（开垦、创建迷宫等）
3. 根据游戏需求调整网格大小和布局
4. 添加更多网格状态和可视化效果

---

## 相关文件

### 数据层
- `scripts/data/GridData.gd` - 网格数据类
- `scripts/managers/GridMapManager.gd` - 网格地图管理器

### 系统层
- `scripts/systems/GridSystem.gd` - 可复用网格系统
- `scripts/systems/GridCell.gd` - 网格单元可视化组件
- `scripts/systems/SurfaceWorldGrid.gd` - 表世界网格系统
- `scripts/systems/InnerWorldGrid.gd` - 里世界网格系统

### 场景文件
- `scenes/worlds/GridSystem.tscn` - 可复用网格系统场景
- `scenes/worlds/GridCell.tscn` - 网格单元场景
- `scenes/subworld_surface.tscn` - 表世界子窗口场景
- `scenes/subword_inner.tscn` - 里世界子窗口场景
- `scenes/game_scene.tscn` - 游戏主场景

### UI层
- `scripts/ui/GameScene.gd` - 游戏主场景脚本

---

**最后更新**：2026/01/21
