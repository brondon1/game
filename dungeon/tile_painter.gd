class_name TilePainter
extends RefCounted
## 用 0x72 素材包的瓦片把"哪些格子是地板、哪些是墙"铺成 2.5D 的地牢（地牢和大厅共用）。

# tiles.png 里各种瓦片的位置（贴图来自 0x72 素材包）：
# 第一行：8 种地板 + 墙根阴影；第二行：墙面（普通 / 4 色旗帜 / 2 种破洞）、墙顶、左侧墙、右侧墙、虚空
const FLOOR_TILES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0),
]
const FLOOR_WEIGHTS: Array[float] = [40.0, 3.0, 3.0, 3.0, 2.0, 2.0, 2.0, 2.0]
const FLOOR_SHADOW_TILE := Vector2i(8, 0)
const WALL_FACE_TILES: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
	Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1),
]
const WALL_FACE_WEIGHTS: Array[float] = [40.0, 1.0, 1.0, 1.0, 1.0, 1.5, 1.5]
const WALL_TOP_TILE := Vector2i(7, 1)
const WALL_SIDE_LEFT_TILE := Vector2i(8, 1)
const WALL_SIDE_RIGHT_TILE := Vector2i(9, 1)
const VOID_TILE := Vector2i(10, 1)

## 铺瓦片，形成 2.5D 的纵深感：
## - 下方是地板的墙 → 砖墙正面（偶尔有旗帜、破洞）
## - 上方是地板、或者下方是砖墙正面的墙 → 墙顶
## - 左右挨着地板的墙 → 侧墙；其余 → 虚空
## 墙面正下方的地板用带阴影的瓦片，其余地板随机选花纹。
static func paint(tile_map: TileMapLayer, floor_cells: Dictionary, wall_cells: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	for c: Vector2i in wall_cells:
		var tile := VOID_TILE
		if floor_cells.has(c + Vector2i.DOWN):
			tile = WALL_FACE_TILES[rng.rand_weighted(WALL_FACE_WEIGHTS)]
		elif floor_cells.has(c + Vector2i.UP) or floor_cells.has(c + Vector2i(0, 2)):
			tile = WALL_TOP_TILE
		elif floor_cells.has(c + Vector2i.RIGHT):
			tile = WALL_SIDE_LEFT_TILE
		elif floor_cells.has(c + Vector2i.LEFT):
			tile = WALL_SIDE_RIGHT_TILE
		tile_map.set_cell(c, 0, tile)
	for c: Vector2i in floor_cells:
		if wall_cells.has(c + Vector2i.UP):
			tile_map.set_cell(c, 0, FLOOR_SHADOW_TILE)
		else:
			tile_map.set_cell(c, 0, FLOOR_TILES[rng.rand_weighted(FLOOR_WEIGHTS)])


## 所有紧挨地板（含斜角）但本身不是地板的格子
static func walls_around(floor_cells: Dictionary) -> Dictionary:
	var wall_cells := {}
	for c: Vector2i in floor_cells:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var n := c + Vector2i(dx, dy)
				if not floor_cells.has(n):
					wall_cells[n] = true
	return wall_cells
