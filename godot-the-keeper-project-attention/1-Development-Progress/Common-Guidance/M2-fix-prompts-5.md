
目前我的游戏操作界面有：

game_scene.tscn
GameScene (脚本：GameScene.gd)
|—— Control (top)
|—— HBoxContainer (sub_win_area)
|—— Control (bottom)

GameScene.gd脚本在游戏运行时会在HBoxContainer实例化两个子场景：
subworld_surface.tscn
subworld_inner.tscn


subworld_surface.tscn
SubworldSurface (Panel) (脚本：SurfaceWorldGrid.gd)

subworld_inner.tscn
SubworldInner (Panel) (脚本：InnerWorldGrid.gd)

SurfaceWorldGrid.gd / InnerWorldGrid.gd 会在游戏运行时实例化 GridSystem.tscn

GridSystem.tscn
GridSystem (Node2D) (GridSystem.gd)
|—— Camera2D (Camera2D)
|—— GridCellContainer (Node2D)

GridSystem.gd 会在游戏运行时实例化 GridCell.tscn 

GridCell.tscn
GridCell (Node2D) (脚本：GridCell.gd)
|—— Area2D
|—— CollisionPolygon2D


我预期实现的效果是：
游戏主界面中有两个子窗口：
- subworld_surface.tscn
- subworld_inner.tscn

该展示不能溢出窗口，并且每个窗口中的内容是完全独立且分离的。
这意味着我希望它们内部实例化出来的GridSystem也是各自独立的，不会我操作一边另一边也跟着变化。

并且我希望子窗口能有
- 空格+鼠标左键移动（Pan）
- ctrl+鼠标滚轮缩放（Zoom）
的相关实现。

但目前的实现过程中有以下问题：
- HBoxContainer的定位好像对网格无效
- 网格移动和缩放都能溢出窗口，穿到区域容器之外
- 当我缩放过后，鼠标悬浮就会偏离鼠标的实际位置

请告诉我，我的设计合理吗，以及为什么会有这些错误，并告诉我我该怎么修复
