## 当前系统特征

### 网格系统
- 使用 Node2D 自行生成 isometric 网格
- tile_width : tile_height = 2 : 1（例如 64x32）
- grid 坐标为整数 (x, y)
- 世界坐标通过 isometric 投影映射得到
- 单元格为菱形（polygon 绘制 + CollisionPolygon2D）

### 交互方式
- Space + 鼠标左键：平移视图（pan）
- Ctrl + 鼠标滚轮：缩放视图（zoom）
- 鼠标 hover 高亮当前网格单元
- 未来需要支持单位放置 / 编辑器式操作

---

## 已暴露的问题

1. 拖拽视图时，存在一层“固定不动”的网格或参考线
2. 视图平移 / 缩放后，鼠标 hover 无法准确对应网格单元
3. 当前实现中，hover 计算似乎未正确考虑相机或 transform 变化

---

## 核心设计原则（必须严格遵守）

### 1️⃣ 统一 Transform 链路
- 所有随视图移动 / 缩放的内容，必须处于同一 Node2D / Camera2D 变换链路下
- 不允许存在“视觉上属于世界，但 transform 不参与 pan / zoom”的节点
- Debug / UI 层应与世界层分离（CanvasLayer 或独立 Node）

### 2️⃣ 不手动修正鼠标坐标
- 不允许在代码中手动补偿 zoom / offset
- 必须使用 Godot 的世界坐标接口：
  - `get_global_mouse_position()`
  - 或 `Camera2D.get_screen_to_world()`

### 3️⃣ 鼠标 → Grid 的空间流程必须固定
```text
Screen Space
  ↓（Camera / Node2D Transform）
World Space
  ↓（isometric inverse transform）
Grid Space

### 4️⃣ 所有逻辑判断必须在 Grid Space 完成
- hover
- 单位放置
- 可行性校验
- 编辑器操作
- 世界坐标仅用于渲染结果
- 推荐节点结构（最佳实践）
```
GameRoot
├─ CameraRig (Node2D 或 Camera2D 持有者)
│  ├─ GridSystem
│  ├─ Units
│  └─ Effects
└─ DebugOverlay (CanvasLayer 或 Node2D)
```
- pan / zoom 只作用于 CameraRig 或 Camera2D
- GridSystem 不直接处理屏幕坐标

## 你的任务:
在遵循以上约束的前提下：
- 修复现有问题
- 提供示例 GDScript（pan / zoom / hover）
- 说明哪些做法是反模式（Anti-Pattern）
- 设计为长期可扩展的编辑器式 isometric 网格系统

---

## Hover 错位问题分析

### 问题根因：**坐标空间不一致（Coordinate Space Mismatch）**

**错误类型**：混合了"视觉坐标空间"和"逻辑坐标空间"

**具体表现**：
1. 使用 `to_local(get_global_mouse_position())` 获取鼠标在 GridSystem 的本地坐标
2. `to_local()` 返回的坐标已经考虑了 GridSystem 的 `scale`，这是**视觉坐标空间**（已缩放）
3. 但 `iso_origin` 和 `cell_size` 是在**逻辑坐标空间**中定义的（未缩放）
4. 计算 `relative_pos = pos - iso_origin` 时，混合了两种坐标空间：
   - `pos` 是视觉坐标（已缩放）
   - `iso_origin` 是逻辑坐标（未缩放）
5. 导致缩放后 hover 检测错位

**正确的坐标转换链路**：
```
Screen Space (鼠标屏幕坐标)
  ↓ get_global_mouse_position()
Global Space (全局世界坐标)
  ↓ get_global_transform().affine_inverse() * mouse_pos
GridSystem Local Space (逻辑坐标，未缩放)
  ↓ 减去 iso_origin
GridCellContainer Local Space (等距空间坐标)
  ↓ isometric inverse transform
Grid Space (网格坐标)
```

**唯一正确的鼠标世界坐标获取方式**：

```gdscript
# 方法1：使用 get_global_transform().affine_inverse() 手动转换
var global_mouse = get_global_mouse_position()
var local_mouse = get_global_transform().affine_inverse() * global_mouse
# 此时 local_mouse 是 GridSystem 的逻辑坐标空间（未缩放）

# 方法2：使用 to_local() 然后除以 scale（如果 to_local 考虑了 scale）
var global_mouse = get_global_mouse_position()
var visual_local = to_local(global_mouse)  # 已缩放的视觉坐标
var logical_local = visual_local / scale   # 逻辑坐标（未缩放）

# 推荐使用方法1，因为它直接得到逻辑坐标，避免混淆
```

**关键原则**：
- 所有逻辑计算（hover、点击、放置）必须在**逻辑坐标空间**（未缩放）中进行
- `iso_origin`、`cell_size`、网格位置都在逻辑坐标空间
- 只有渲染时才使用视觉坐标空间（已缩放）

---

## 当前解决思路（临时方案，未完全成功）

### 问题分析

**节点结构**：
```
GridSystem (Node2D, scale 用于 zoom)
└─ GridContainer (Control, 不受 GridSystem scale 影响)
    └─ GridCellContainer (Node2D, 受 GridSystem scale 影响)
        └─ GridCell (Node2D, 菱形绘制)
```

**坐标空间关系**：
- `iso_origin` 在 **GridContainer 坐标空间**（Control 坐标，不受 scale 影响）
- `GridCell.position` 在 **GridCellContainer 坐标空间**（Node2D 坐标，受 scale 影响）
- 鼠标位置通过 `grid_container.get_local_mouse_position()` 获取，在 **GridContainer 坐标空间**

### 当前实现思路

1. **鼠标坐标获取**：使用 `grid_container.get_local_mouse_position()` 获取 GridContainer 坐标
2. **坐标转换**：
   - `relative_pos = pos - iso_origin`（都在 GridContainer 坐标空间，可直接相减）
   - `logical_relative_pos = relative_pos / current_zoom`（转换为逻辑坐标）
3. **网格查找**：在逻辑坐标空间中进行等距转换和菱形检测
4. **菱形检测**：
   - 计算网格中心：`cell_center = iso_origin + cell_center_logical * current_zoom`
   - 计算偏移：`offset = pos - cell_center`（GridContainer 坐标）
   - 转换为逻辑坐标：`logical_offset = offset / current_zoom`
   - 使用逻辑坐标进行菱形检测

### 存在的问题

1. **缩放函数中的坐标空间混乱**：
   - `_set_zoom()` 使用 `get_global_transform().affine_inverse()` 获取逻辑坐标
   - 但 `iso_origin` 是在 GridContainer 坐标空间中定义的
   - 缩放时调整 `iso_origin` 的逻辑可能不正确

2. **坐标空间不一致的根本问题**：
   - GridContainer（Control）和 GridSystem（Node2D）的坐标系统是独立的
   - `iso_origin` 在 Control 坐标空间，但 GridCell 的实际渲染受 Node2D 的 scale 影响
   - 需要明确：GridCell 的视觉位置 = `(iso_origin + iso_local) * scale`（在 GridContainer 坐标空间中）

3. **可能的正确方案**：
   - 方案A：将 `iso_origin` 也定义在 GridSystem 的逻辑坐标空间中，而不是 GridContainer 坐标空间
   - 方案B：完全统一坐标空间，移除 Control 节点，使用纯 Node2D 结构
   - 方案C：正确理解 Control 和 Node2D 的坐标转换关系，建立正确的映射

### 待验证的假设

- GridContainer 的坐标空间是否真的不受 GridSystem 的 scale 影响？
- GridCellContainer 作为 GridContainer 的子节点（Node2D），其坐标如何映射到 GridContainer 坐标空间？
- 缩放时，GridCell 的视觉位置变化是否应该通过调整 `iso_origin` 来补偿？
