# M3 里程碑 - Godot引擎独立操作指南

本文档记录M3里程碑中需要在Godot引擎编辑器中手动完成的配置操作。

## 概述

M3里程碑包含以下任务：
- ✅ T3.1 实现资源数据定义
- ✅ T3.2 实现资源管理器（ResourceManager）
- ✅ T3.3 实现表构造力系统
- ✅ T3.4 实现里构造力系统
- ✅ T3.5 实现真理要素资源系统
- ✅ T3.6 实现资源UI显示

所有脚本文件已创建完成，但需要在Godot引擎中配置autoload单例和场景。

---

## 操作步骤

### 1. 配置ResourceManager单例

资源管理器用于管理表构造力、里构造力等资源，需要配置为autoload单例：

1. 打开Godot引擎编辑器
2. 点击菜单栏：`项目(Project)` → `项目设置(Project Settings)` → `Globals`
3. 在左侧列表中选择 `Autoload` 标签页
4. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/managers/ResourceManager.gd`
5. 在 `节点名称(Node Name)` 列下输入：`ResourceManager`
6. 确保 `单例(Singleton)` 选项已勾选
7. 点击 `添加(Add)` 按钮

**重要提示**：
- ResourceManager会自动初始化TruthElementResource作为子节点
- ResourceManager会在准备阶段和回合开始时自动恢复资源（如果实现了相关逻辑）

### 2. 配置ResourceDisplay UI场景

资源显示UI需要在游戏场景中实例化：

#### 2.1 检查ResourceDisplay场景

1. 打开 `scenes/ui/ResourceDisplay.tscn` 场景
2. 确认根节点 `ResourceDisplay` 已附加 `scripts/ui/ResourceDisplay.gd` 脚本
3. 如果没有，在Inspector面板中点击脚本图标，选择 `scripts/ui/ResourceDisplay.gd`

#### 2.2 将ResourceDisplay添加到游戏场景

1. 打开 `scenes/game_scene.tscn` 场景
2. 在场景树中找到 `Control (top)` 节点（这是顶部控制区域）
3. 在 `Control (top)` 节点下添加子节点：
   - 右键点击 `Control (top)` → `实例化子场景(Instantiate Child Scene)`
   - 选择 `res://scenes/ui/ResourceDisplay.tscn`
4. 调整ResourceDisplay的位置和大小：
   - 在Inspector面板中设置 `Anchors Preset` 为右上角（例如：`Top Right`）
   - 调整 `Offset` 使其显示在合适的位置

**或者**，如果希望ResourceDisplay显示在其他位置：

1. 可以直接在 `game_scene.tscn` 的根节点下添加ResourceDisplay
2. 设置合适的锚点和偏移量

### 3. 验证资源系统

运行游戏，测试以下功能：

1. **检查资源初始化**：
   - 游戏启动后，ResourceManager应该自动初始化
   - 表构造力应该为默认值（10/20）
   - 里构造力应该为默认值（10/20）
   - 真理要素各序列应该为0

2. **检查UI显示**：
   - ResourceDisplay应该显示表构造力和里构造力的当前值/上限
   - 真理要素各序列应该显示为0

3. **测试资源变化**：
   - 在代码中调用 `ResourceManager.add_table_construct(5)` 应该增加表构造力
   - UI应该自动更新显示新的值
   - 应该看到资源变化的动画提示

4. **测试资源消耗**：
   - 调用 `ResourceManager.consume_table_construct(3)` 应该减少表构造力
   - 如果资源不足，应该返回false并显示警告日志

5. **测试真理要素**：
   - 调用 `ResourceManager.add_truth_element(1, 5)` 应该增加序列I的真理要素
   - UI应该更新显示序列I的数量

---

## 文件清单

M3里程碑创建的文件：

### 数据类
- `scripts/data/ResourceData.gd` - 资源数据类

### 管理器
- `scripts/managers/ResourceManager.gd` - 资源管理器单例

### 系统
- `scripts/systems/TruthElementResource.gd` - 真理要素资源系统

### UI
- `scripts/ui/ResourceDisplay.gd` - 资源显示UI脚本
- `scenes/ui/ResourceDisplay.tscn` - 资源显示UI场景

---

## 使用示例

### 在代码中使用ResourceManager

```gdscript
# 获取资源管理器（如果已配置为autoload）
# 注意：如果ResourceManager配置为autoload，可以直接使用ResourceManager
# 否则需要使用 get_node("/root/ResourceManager")

# 增加表构造力
ResourceManager.add_table_construct(5)

# 消耗表构造力（构建迷宫）
if ResourceManager.consume_table_construct(3):
    # 构建迷宫逻辑
    print("成功消耗3点表构造力")
else:
    print("表构造力不足")

# 增加里构造力
ResourceManager.add_inner_construct(2)

# 消耗里构造力（破茧）
if ResourceManager.consume_inner_construct(1):
    # 破茧逻辑
    print("成功消耗1点里构造力")

# 增加真理要素
ResourceManager.add_truth_element(1, 5, Constants.TRUTH_STATE_ACTIVE)  # 序列I，5个，活跃状态

# 获取真理要素数量
var count = ResourceManager.get_truth_element_count(1)  # 获取序列I的数量

# 改变真理要素状态
var truth_resource = ResourceManager.get_truth_element_resource()
truth_resource.change_truth_element_state(1, 3, Constants.TRUTH_STATE_ACTIVE, Constants.TRUTH_STATE_SLEEPING)
```

### 监听资源变化信号

```gdscript
func _ready():
    # 连接资源变化信号
    SignalBus.table_construct_changed.connect(_on_table_construct_changed)
    SignalBus.inner_construct_changed.connect(_on_inner_construct_changed)
    SignalBus.truth_element_changed.connect(_on_truth_element_changed)

func _on_table_construct_changed(current_value: int, max_value: int):
    print("表构造力变化: ", current_value, "/", max_value)

func _on_inner_construct_changed(current_value: int, max_value: int):
    print("里构造力变化: ", current_value, "/", max_value)

func _on_truth_element_changed(serial: int, count: int):
    print("真理要素序列 ", serial, " 数量: ", count)
```

---

## 故障排除

### 问题1：找不到ResourceManager

**原因**：autoload未正确配置

**解决方法**：
1. 检查 `项目设置` → `Autoload` 中是否正确添加了ResourceManager单例
2. 检查路径是否正确：`res://scripts/managers/ResourceManager.gd`
3. 检查节点名称是否为 `ResourceManager`
4. 重启Godot编辑器

### 问题2：ResourceDisplay不显示

**原因**：场景未正确实例化或节点路径错误

**解决方法**：
1. 检查 `game_scene.tscn` 中是否添加了ResourceDisplay场景
2. 检查ResourceDisplay的锚点和偏移量设置
3. 检查ResourceDisplay脚本中的节点路径是否正确
4. 确认ResourceDisplay场景的根节点类型为Control

### 问题3：资源变化时UI不更新

**原因**：信号未正确连接

**解决方法**：
1. 检查ResourceDisplay脚本中是否正确连接了信号
2. 检查ResourceManager是否正确发射了信号
3. 查看控制台日志，确认是否有错误信息

### 问题4：真理要素显示不正确

**原因**：TruthElementResource未正确初始化

**解决方法**：
1. 确认ResourceManager正确初始化了TruthElementResource
2. 检查TruthElementResource的_ready函数是否被调用
3. 查看DebugLogger的日志输出

---

## 下一步

M3完成后，可以继续开发：
- M4: 构造体基础系统
- M5: 调查员系统
- M6: 卡牌系统

资源管理系统为这些系统提供了基础支持。
