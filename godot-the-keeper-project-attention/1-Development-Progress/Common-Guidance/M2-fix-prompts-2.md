### 当前实现状态
- 网格逻辑基于二维整数坐标 (grid_x, grid_y)
- 世界坐标通过 isometric 投影公式计算得到：
  - screen_x = (grid_x - grid_y) * (tile_width / 2)
  - screen_y = (grid_x + grid_y) * (tile_height / 2)
- tile_width : tile_height = 2 : 1（例如 64x32）
- 网格整体排列与等距投影是正确的

### 已发现的问题
- 每个单元格在视觉上仍然是 **2:1 的矩形**，而不是 isometric 应有的 **菱形**
- 鼠标 hover / 点击 的命中区域仍基于 Rect2
- 高亮显示区域与真实等距单元格不一致

### 关键认知
- isometric 只是 **坐标投影方式**
- 单元格是否呈现为菱形，取决于：
  - 绘制的几何形状（polygon 而非 rect）
  - 鼠标命中区域是否使用菱形多边形
- 单元格不能使用 Control / Panel / ColorRect
- 推荐使用 Node2D / Area2D / CollisionPolygon2D

### 目标实现方式
- 每个 isometric 单元格是一个 Node2D
- 单元格视觉使用 `_draw()` 绘制菱形（4 点 polygon）
- 鼠标交互使用 Area2D + CollisionPolygon2D（菱形）
- hover / selection 高亮与菱形完全一致
- 不使用 TileMap
- 网格可以被限制在一个可视区域（SubViewport / Clipping），但逻辑网格不裁切

### 菱形单元格几何定义（局部坐标）
- 左：   (0, tile_height / 2)
- 上：   (tile_width / 2, 0)
- 右：   (tile_width, tile_height / 2)
- 下：   (tile_width / 2, tile_height)

### 可选优化方向
- 对于大量格子，可使用数学方式判断点是否在菱形内：
  abs(dx)/(tile_width/2) + abs(dy)/(tile_height/2) <= 1
- hover 逻辑可集中在网格管理器而非单元格节点

### 你的任务
- 基于上述约束与目标，提供：
  - 正确的节点结构设计
  - 示例 GDScript（绘制、碰撞、hover）
  - 避免使用 Rect2 的错误实现
  - 符合 Godot 4.x 的最佳实践

请假设这是一个长期可扩展的 isometric 网格系统，而非 Demo。