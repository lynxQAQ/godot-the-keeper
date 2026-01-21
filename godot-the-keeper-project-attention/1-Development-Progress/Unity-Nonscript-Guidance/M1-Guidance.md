# M1 里程碑 - Godot引擎独立操作指南

本文档记录M1里程碑中需要在Godot引擎编辑器中手动完成的配置操作。

## 概述

M1里程碑包含以下任务：
- ✅ T1.2 实现Constants常量定义类
- ✅ T1.3 实现基础工具类（Extensions、Helpers）
- ✅ T1.4 实现信号总线（SignalBus）
- ✅ T1.5 实现数据层基础框架
- ✅ T1.6 实现日志系统

所有脚本文件已创建完成，但需要在Godot引擎中配置autoload单例。

---

## 操作步骤

### 1. 配置Autoload单例

需要在Godot引擎中将以下脚本配置为autoload单例：

#### 1.1 Constants单例

1. 打开Godot引擎编辑器
2. 点击菜单栏：`项目(Project)` → `项目设置(Project Settings) → Globals`
3. 在左侧列表中选择 `Autoload` 标签页
4. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/core/Constants.gd`
5. 在 `节点名称(Node Name)` 列下输入：`Constants`
6. 确保 `单例(Singleton)` 选项已勾选
7. 点击 `添加(Add)` 按钮

#### 1.2 SignalBus单例

1. 在同一个 `Autoload` 标签页中
2. 点击 `路径(Path)` 列下的输入框，输入：`res://autoload/SignalBus.gd`
3. 在 `节点名称(Node Name)` 列下输入：`SignalBus`
4. 确保 `单例(Singleton)` 选项已勾选
5. 点击 `添加(Add)` 按钮

#### 1.3 Logger单例

1. 在同一个 `Autoload` 标签页中
2. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/utils/Logger.gd`
3. 在 `节点名称(Node Name)` 列下输入：`DebugLogger`
4. 确保 `单例(Singleton)` 选项已勾选
5. 点击 `添加(Add)` 按钮

#### 1.4 DataManager单例（可选）

如果需要全局数据管理器，可以添加：

1. 在同一个 `Autoload` 标签页中
2. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/data/DataManager.gd`
3. 在 `节点名称(Node Name)` 列下输入：`DataManager`
4. 确保 `单例(Singleton)` 选项已勾选
5. 点击 `添加(Add)` 按钮

---

## 验证配置

### 方法1：在脚本中测试

创建一个测试脚本（例如 `test_autoload.gd`），添加以下代码：

```gdscript
extends Node

# 预加载工具类（Extensions和Helpers不是autoload，需要预加载）
const Extensions = preload("res://scripts/utils/Extensions.gd")
const Helpers = preload("res://scripts/utils/Helpers.gd")

func _ready():
	# 测试Constants
	print("测试Constants:")
	print("准备阶段: ", Constants.PREPARATION_PHASE)
	print("网格类型-未开垦: ", Constants.GRID_TYPE_UNEXPLORED)
	
	# 测试SignalBus
	print("\n测试SignalBus:")
	print("SignalBus节点: ", SignalBus)
	
	# 测试Logger
	print("\n测试Logger:")
	DebugLogger.info("这是一条测试日志", "Test")
	
	# 测试Extensions（静态调用）
	print("\n测试Extensions:")
	var test_pos = Vector2i(5, 5)
	var neighbors = Extensions.get_neighbor_grids(test_pos)
	print("相邻网格: ", neighbors)
	
	# 测试Helpers（静态调用）
	print("\n测试Helpers:")
	var distance = Helpers.distance(Vector2(0, 0), Vector2(3, 4))
	print("距离: ", distance)
```

### 方法2：在场景中测试

1. 创建一个新场景（`test_scene.tscn`）
2. 添加一个Node节点
3. 将上述测试脚本附加到节点上
4. 运行场景，查看输出面板

---

## 预期结果

配置完成后，应该能够：

1. ✅ 在任何脚本中通过 `Constants` 访问常量（autoload单例）
2. ✅ 在任何脚本中通过 `SignalBus` 连接和发射信号（autoload单例）
3. ✅ 在任何脚本中通过 `DebugLogger` 输出日志（autoload单例）
4. ✅ 使用 `Extensions` 和 `Helpers` 的工具函数（需要预加载后使用）

---

## 注意事项

### 1. 单例命名

- 单例的 `节点名称(Node Name)` 必须与脚本中访问的名称一致
- 例如：如果节点名称是 `Constants`，则在脚本中使用 `Constants.PREPARATION_PHASE`
- 如果节点名称是 `SignalBus`，则在脚本中使用 `SignalBus.phase_changed`

### 2. Extensions和Helpers的使用

- `Extensions` 和 `Helpers` **不是autoload单例**，它们是静态工具类（继承自RefCounted）
- **必须在使用前预加载**：在脚本顶部添加preload语句
  ```gdscript
  const Extensions = preload("res://scripts/utils/Extensions.gd")
  const Helpers = preload("res://scripts/utils/Helpers.gd")
  ```
- **使用方式**：通过预加载的常量调用静态方法
  ```gdscript
  # 在脚本顶部预加载
  const Extensions = preload("res://scripts/utils/Extensions.gd")
  const Helpers = preload("res://scripts/utils/Helpers.gd")
  
  # 然后就可以使用了
  var neighbors = Extensions.get_neighbor_grids(Vector2i(5, 5))
  var dist = Helpers.distance(Vector2(0, 0), Vector2(3, 4))
  ```
- **也可以实例化后使用**（但不推荐，因为会创建不必要的对象）：
  ```gdscript
  var ext = Extensions.new()
  var neighbors = ext.get_neighbor_grids(Vector2i(5, 5))
  ```
- **重要提示**：如果不预加载就直接使用，会出现 "Identifier not declared" 错误

### 3. Logger日志文件位置

- Logger默认将日志文件保存在 `user://logs/game.log`
- 在Windows上，这通常是：`%APPDATA%\Godot\app_userdata\Godot-The-Keeper\logs\game.log`
- 日志文件大小超过10MB时会自动轮转

### 4. 信号连接示例

```gdscript
# 连接信号
SignalBus.phase_changed.connect(_on_phase_changed)

# 发射信号
SignalBus.phase_changed.emit(Constants.PREPARATION_PHASE)

# 信号处理函数
func _on_phase_changed(phase: String):
	print("阶段切换到: ", phase)
```

---

## 故障排除

### 问题1：找不到Constants/SignalBus/DebugLogger

**原因**：autoload未正确配置

**解决方法**：
1. 检查 `项目设置` → `Autoload` 中是否正确添加了单例
2. 检查路径是否正确（注意大小写）
3. 重启Godot编辑器

### 问题1.1：找不到Extensions/Helpers（Identifier not declared）

**原因**：Extensions和Helpers不是autoload，需要预加载

**解决方法**：
1. 在脚本顶部添加preload语句：
   ```gdscript
   const Extensions = preload("res://scripts/utils/Extensions.gd")
   const Helpers = preload("res://scripts/utils/Helpers.gd")
   ```
2. 确保路径正确（注意大小写）
3. 然后通过预加载的常量使用：`Extensions.get_neighbor_grids(...)`

### 问题2：找不到Extensions/Helpers（Identifier not declared）

**原因**：Extensions和Helpers不是autoload单例，需要在使用前预加载

**解决方法**：
1. 在脚本顶部添加preload语句：
   ```gdscript
   const Extensions = preload("res://scripts/utils/Extensions.gd")
   const Helpers = preload("res://scripts/utils/Helpers.gd")
   ```
2. 确保路径正确（注意大小写）
3. 然后通过预加载的常量使用静态方法

### 问题3：脚本语法错误

**原因**：Godot版本不匹配或脚本有错误

**解决方法**：
1. 确保使用Godot 4.5或更高版本
2. 检查脚本文件是否有语法错误（在脚本编辑器中查看）
3. 查看 `输出(Output)` 面板的错误信息

### 问题4：DebugLogger无法写入日志文件

**原因**：文件权限问题或路径错误

**解决方法**：
1. 检查 `user://` 目录的写入权限
2. 查看Logger的日志文件路径设置
3. 可以在Logger中设置 `log_to_file = false` 来禁用文件输出

---

## 下一步

完成M1里程碑的autoload配置后，可以：

1. 开始M2里程碑：世界网格系统
2. 测试各个单例的功能是否正常
3. 在后续开发中使用这些基础框架

---

## 相关文件

- `scripts/core/Constants.gd` - 常量定义类
- `scripts/utils/Extensions.gd` - 扩展方法类
- `scripts/utils/Helpers.gd` - 工具函数类
- `autoload/SignalBus.gd` - 信号总线
- `scripts/data/BaseData.gd` - 数据基类
- `scripts/data/DataManager.gd` - 数据管理器
- `scripts/utils/DebugLogger.gd` - 日志系统

---

## 场景连接系统配置

### 1. 配置SceneManager单例

场景管理器用于处理场景切换，需要配置为autoload单例：

1. 打开Godot引擎编辑器
2. 点击菜单栏：`项目(Project)` → `项目设置(Project Settings) → Globals`
3. 在左侧列表中选择 `Autoload` 标签页
4. 点击 `路径(Path)` 列下的输入框，输入：`res://scripts/managers/SceneManager.gd`
5. 在 `节点名称(Node Name)` 列下输入：`SceneManager`
6. 确保 `单例(Singleton)` 选项已勾选
7. 点击 `添加(Add)` 按钮

### 2. 配置主菜单场景

主菜单场景已经配置好脚本，但需要确保：

1. **检查MainMenu.tscn场景**：
   - 打开 `MainMenu.tscn` 场景
   - 确认根节点 `Control (MainMenuRoot)` 已附加 `scripts/ui/MainMenu.gd` 脚本
   - 如果没有，在Inspector面板中点击脚本图标，选择 `scripts/ui/MainMenu.gd`

2. **检查按钮节点路径**：
   - 确认按钮节点路径正确：
     - `Button (StartGameButton)` - 开始游戏
     - `Button (ContinueGameButton)` - 继续游戏
     - `Button (GalleryButton)` - 我的图鉴
     - `Button (QuitButton)` - 退出游戏

3. **设置主场景**：
   - 在项目设置中，将 `MainMenu.tscn` 设置为主场景：
     - `项目(Project)` → `项目设置(Project Settings)` → `应用(Application)` → `运行(Run)` → `主场景(Main Scene)`
     - 设置为：`res://MainMenu.tscn`

### 3. 创建占位场景（如果不存在）

如果 `game_scene.tscn` 和 `gallery.tscn` 不存在，需要创建占位场景：

1. **创建game_scene.tscn**：
   - 在 `scenes/` 目录下创建新场景
   - 添加一个Node2D节点作为根节点
   - 添加一个Label节点显示"游戏场景(待实现)"
   - 保存为 `scenes/game_scene.tscn`

2. **创建gallery.tscn**：
   - 在 `scenes/` 目录下创建新场景
   - 添加一个Control节点作为根节点
   - 设置布局为全屏（anchors_preset = 15）
   - 添加一个Label节点显示"图鉴场景(待实现)"
   - 保存为 `scenes/gallery.tscn`

### 4. 验证场景连接

运行游戏，测试以下功能：

1. **开始游戏按钮**：
   - 点击后应该切换到 `game_scene.tscn`
   - 查看输出面板，应该看到日志："SceneManager: 开始新游戏"

2. **继续游戏按钮**：
   - 如果没有保存文件，按钮应该是禁用状态（灰色）
   - 如果有保存文件，点击后应该切换到 `game_scene.tscn`

3. **我的图鉴按钮**：
   - 点击后应该切换到 `gallery.tscn`
   - 查看输出面板，应该看到日志："SceneManager: 打开图鉴"

4. **退出游戏按钮**：
   - 点击后应该退出应用（在编辑器中会停止运行）
   - 查看输出面板，应该看到日志："SceneManager: 退出游戏"

### 5. 场景切换信号使用示例

```gdscript
extends Node

func _ready():
	# 监听场景切换信号
	SignalBus.scene_changing.connect(_on_scene_changing)
	SignalBus.scene_changed.connect(_on_scene_changed)

func _on_scene_changing(scene_path: String):
	print("场景切换中: ", scene_path)

func _on_scene_changed(scene_path: String):
	print("场景切换完成: ", scene_path)
```

### 6. 故障排除

#### 问题1：SceneManager找不到

**原因**：autoload未正确配置

**解决方法**：
1. 检查 `项目设置` → `Autoload` 中是否正确添加了SceneManager
2. 检查路径是否正确：`res://scripts/managers/SceneManager.gd`
3. 重启Godot编辑器

#### 问题2：按钮点击无反应

**原因**：脚本未正确附加或节点路径错误

**解决方法**：
1. 检查MainMenu.tscn根节点是否附加了 `scripts/ui/MainMenu.gd` 脚本
2. 检查按钮节点的路径是否正确（注意空格和特殊字符）
3. 查看输出面板的错误信息

#### 问题3：场景切换失败（错误代码）

**原因**：场景文件不存在或路径错误

**解决方法**：
1. 检查场景文件是否存在：
   - `res://scenes/game_scene.tscn`
   - `res://scenes/gallery.tscn`
2. 检查SceneManager中的场景路径常量是否正确
3. 查看输出面板的详细错误信息

#### 问题4：继续游戏按钮始终禁用

**原因**：has_save_file()函数未实现或保存文件路径错误

**解决方法**：
1. 这是正常行为，因为保存系统还未实现
2. 如果需要测试，可以临时修改SceneManager中的has_save_file()函数返回true
3. 等待M9里程碑实现游戏保存系统后，此功能会自动工作

---

**最后更新**：2026/01/21
