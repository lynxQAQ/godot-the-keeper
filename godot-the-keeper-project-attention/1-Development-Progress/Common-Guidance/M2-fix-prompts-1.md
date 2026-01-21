# Goal
Implement a 2:1 isometric grid system in Godot (GDScript) with correct positioning
and UI-based visual clipping (not logical clipping).

# Coordinate Model (Must Follow)
The isometric grid must use THREE coordinate spaces:

1. Logical grid coordinates (Vector2i): (x, y)
2. Isometric local coordinates (Vector2): projected diamond space
3. Parent Control coordinates: applied via iso_origin offset

Logical (0,0) MUST NOT be assumed to be the top-left of the screen.

# Isometric Projection (2:1)
Given:
- tile_width = 2 * tile_height

Projection formula (DO NOT MODIFY):

func iso_to_local(pos: Vector2i) -> Vector2:
    return Vector2(
        (pos.x - pos.y) * tile_width * 0.5,
        (pos.x + pos.y) * tile_height * 0.5
    )

# Isometric Origin (Critical)
Define an iso_origin that maps logical (0,0) to screen space.

BEST PRACTICE:
- Logical (0,0) must appear at the TOP-CENTER of the container.

iso_origin MUST be computed from the parent Control's rect:

iso_origin = Vector2(container_rect.size.x / 2, 0)

Final world position:
world_pos = iso_origin + iso_to_local(grid_pos)

Never place isometric tiles without applying iso_origin.

# Visual Clipping (UI-Based, Required)
The grid system MUST be visually clipped by its parent Control.

Rules:
- The grid system does NOT read viewport size directly
- The grid system ONLY uses its parent Control's rect
- Parent Control must enable clipping:
    - Use Panel / Control with clip_contents = true
- Grid tiles may exist outside the visible area but are not rendered

DO NOT:
- Remove tiles logically
- Prevent tile creation based on bounds
- Clamp grid positions manually

# Scene Structure (Recommended)
GameScene (Control)
└─ GridViewport (Panel / Control, clip_contents = true)
   └─ InnerWorldGrid (Control)
      └─ GridSystem (Node2D or Control)

GridViewport defines the visible region.
GridSystem content is clipped automatically.

# Architectural Constraints
- GridSystem handles rendering and input only
- GridMapManager handles grid data and neighbors
- InnerWorldGrid handles rules, density, activity, and signals
- Isometric math must remain independent of gameplay logic

# Expected Result
- Isometric grid is centered horizontally at the top
- No unexpected offset compared to rectangular grids
- Grid is confined to a windowed UI area via visual clipping
- System remains compatible with multi-window / embedded layouts
