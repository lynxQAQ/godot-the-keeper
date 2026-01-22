
你正在协助重构一个基于 Godot 4.x 的 **自定义 isometric 网格系统（非 TileMap）**。
当前目标是：**从混合 Control / Node2D 的实现，迁移为“纯 Node2D 世界空间”结构**，
以彻底修复缩放（zoom）后鼠标 hover 错位的问题。

---

## 一、重构动机（问题背景）

### 已确认的问题
- 当使用缩放（zoom）时，鼠标 hover 网格单元发生错位
- pan 正常，zoom 后偏移量随缩放比例变化
- 问题已定位为 **Control 坐标体系与 Node2D 世界坐标体系混用**

### 根本结论
- Control（UI）不参与 Node2D 的 transform / scale
- 任意 “世界几何 + Control” 的混合，在 zoom 时都是反模式
- 必须统一到 **唯一的世界坐标体系（Node2D）**

---

## 二、重构目标（必须严格满足）

1. **GridSystem 完全运行在 Node2D 世界空间**
2. **移除所有 Control 节点对网格几何的参与**
3. **缩放只通过 Camera2D.zoom 实现**
4. **iso_origin 定义为世界坐标（Vector2）**
5. **鼠标 → Grid 的逻辑与 zoom 完全解耦**

---

## 三、最终节点结构（唯一允许的结构）

```text
GameRoot (Node)
├─ Camera2D
└─ WorldRoot (Node2D)
   ├─ GridSystem (Node2D)
   │  ├─ GridCell (Node2D)
   │  └─ ...
   ├─ Units (Node2D)
   └─ Effects (Node2D)

结构约束

不允许 GridSystem 之上存在 Control

不允许 Control 作为 GridCell 的父节点

所有世界几何必须在 WorldRoot 之下

四、相机与视图控制（最佳实践）
缩放

使用 Camera2D.zoom

不允许通过 Node2D.scale 实现 zoom

平移

修改 Camera2D.position

不允许平移 GridSystem 来模拟 pan

五、坐标空间规则（非常关键）
鼠标坐标获取（唯一正确方式）
var mouse_world = camera.get_screen_to_world(
    get_viewport().get_mouse_position()
)


禁止使用：

Control.get_local_mouse_position()

get_global_mouse_position()

手动补偿 zoom / offset

六、GridSystem 的职责划分
GridSystem（Node2D）

管理网格尺寸（tile_width / tile_height）

维护 iso_origin（世界坐标）

负责：

world → grid

grid → world

hover 单元计算

不直接处理 Camera 输入

GridCell（Node2D）

只负责：

菱形绘制（_draw）

状态显示（hover / selected）

不自行计算鼠标位置

七、核心数学（需保持与 zoom 无关）
world → grid（逆 isometric）
func world_to_grid(world: Vector2) -> Vector2i:
	var gx = (world.x / (tile_width / 2) + world.y / (tile_height / 2)) / 2
	var gy = (world.y / (tile_height / 2) - world.x / (tile_width / 2)) / 2
	return Vector2i(floor(gx), floor(gy))

grid → world（中心点）
func grid_to_world(grid: Vector2i) -> Vector2:
	return Vector2(
		(grid.x - grid.y) * (tile_width / 2),
		(grid.x + grid.y) * (tile_height / 2)
	)

八、hover 判断流程（标准版）
Mouse Screen
  ↓ Camera2D
Mouse World
  ↓ world_to_grid
Grid Coord
  ↓ grid_to_world
Cell Center World
  ↓ 菱形检测
Hover Cell

菱形检测（世界空间）
func is_inside_iso_diamond(offset: Vector2) -> bool:
	var dx = abs(offset.x)
	var dy = abs(offset.y)
	return dx / (tile_width / 2) + dy / (tile_height / 2) <= 1

九、反模式（必须指出并避免）

使用 Control 作为网格容器

在 hover 逻辑中除以 zoom

在缩放时调整 iso_origin

使用 Rect2 做命中判断

每个 GridCell 自行计算鼠标 hover

十、你的任务

给出完整的 GridSystem 重构设计

提供示例 GDScript（Camera / GridSystem / GridCell）

明确说明旧结构如何迁移到新结构

确保：

pan 正确

zoom 后 hover 仍精准

架构可支持单位放置与编辑器操作

请将该任务视为 一次“架构级重构”而非局部修补。