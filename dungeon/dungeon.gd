extends Node2D
## 游戏主场景：生成当前楼层的地牢，并处理 打败 Boss → 选 Buff → 下一层，以及死亡和通关结算。

const TILE_SIZE := 16
## 每个房间格子占多少瓦片（房间本身 + 走廊的空间）
const CELL_TILES := Vector2i(26, 20)
const FLOOR_TILE := Vector2i(0, 0)
const WALL_TILE := Vector2i(1, 0)
const BATTLE_ROOM_SIZES: Array[Vector2i] = [Vector2i(13, 11), Vector2i(15, 11), Vector2i(15, 13), Vector2i(17, 13)]

const DOOR_SCENE := preload("res://dungeon/door.tscn")
const PORTAL_SCENE := preload("res://dungeon/portal.tscn")

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var rooms_root: Node2D = $Rooms
@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player
@onready var hud: HUD = $HUD
@onready var buff_select: BuffSelect = $BuffSelect
@onready var game_over: GameOver = $GameOver


func _ready() -> void:
	Events.room_cleared.connect(_on_room_cleared)
	Events.player_died.connect(_on_player_died)
	buff_select.buff_chosen.connect(_on_buff_chosen)
	_build(DungeonGenerator.generate(GameState.room_count()))
	hud.show_message("第 %d 层" % GameState.current_floor)
	Sound.play_music(Sound.MUSIC_DUNGEON)


# ---------- 生成 ----------

func _build(layout: Dictionary) -> void:
	var rooms: Dictionary = layout.rooms
	var links: Array = layout.links

	# 1. 算出每个房间的内部范围（瓦片坐标），并铺地板
	var floor_cells := {}
	var room_rects := {}
	for cell: Vector2i in rooms:
		var size := _room_size(rooms[cell])
		var r := Rect2i(_cell_center(cell) - size / 2, size)
		room_rects[cell] = r
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				floor_cells[Vector2i(x, y)] = true

	# 2. 相连的房间之间挖 3 格宽的走廊
	for link: Array in links:
		_carve_corridor(link[0], link[1], floor_cells)

	# 3. 所有紧挨地板（含斜角）但本身不是地板的格子都是墙
	var wall_cells := {}
	for c: Vector2i in floor_cells:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var n := c + Vector2i(dx, dy)
				if not floor_cells.has(n):
					wall_cells[n] = true
	for c: Vector2i in floor_cells:
		tile_map.set_cell(c, 0, FLOOR_TILE)
	for c: Vector2i in wall_cells:
		tile_map.set_cell(c, 0, WALL_TILE)

	# 4. 创建房间节点，在每条通道的入口放门
	var room_by_cell := {}
	for cell: Vector2i in rooms:
		var r: Rect2i = room_rects[cell]
		var room := Room.new()
		room.name = "Room_%d_%d" % [cell.x, cell.y]
		room.cell = cell
		room_by_cell[cell] = room
		room.setup(rooms[cell], Rect2(Vector2(r.position * TILE_SIZE), Vector2(r.size * TILE_SIZE)), entities)
		for link: Array in links:
			if link.has(cell):
				var other: Vector2i = link[1] if link[0] == cell else link[0]
				room.doors.append(_create_door(r, other - cell))
		rooms_root.add_child(room)
		if room.type == Room.Type.START:
			player.global_position = room.rect.get_center()
			player.get_node("Camera2D").reset_smoothing()
	hud.minimap.setup(room_by_cell, links)


func _room_size(type: Room.Type) -> Vector2i:
	match type:
		Room.Type.BOSS:
			return Vector2i(19, 15)
		Room.Type.BATTLE:
			return BATTLE_ROOM_SIZES.pick_random()
	return Vector2i(9, 9)


func _cell_center(cell: Vector2i) -> Vector2i:
	return cell * CELL_TILES + CELL_TILES / 2


func _carve_corridor(a: Vector2i, b: Vector2i, floor_cells: Dictionary) -> void:
	var from := _cell_center(a)
	var to := _cell_center(b)
	var step := (to - from).sign()
	var side := Vector2i(1, 0) if step.x == 0 else Vector2i(0, 1)
	var p := from
	while true:
		for i in range(-1, 2):
			floor_cells[p + side * i] = true
		if p == to:
			break
		p += step


func _create_door(r: Rect2i, dir: Vector2i) -> Door:
	var center := r.position + r.size / 2
	var tile: Vector2i
	if dir == Vector2i.RIGHT:
		tile = Vector2i(r.end.x, center.y)
	elif dir == Vector2i.LEFT:
		tile = Vector2i(r.position.x - 1, center.y)
	elif dir == Vector2i.DOWN:
		tile = Vector2i(center.x, r.end.y)
	else:
		tile = Vector2i(center.x, r.position.y - 1)
	var door: Door = DOOR_SCENE.instantiate()
	door.position = Vector2(tile * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5
	if dir.x != 0:
		door.rotation = PI / 2.0 # 左右两侧的门是竖着的
	rooms_root.add_child(door)
	return door


# ---------- 流程 ----------

func _on_room_cleared(room: Room) -> void:
	if room.type == Room.Type.BOSS:
		_spawn_portal.call_deferred(room.rect.get_center())
		hud.show_message("传送门已开启")


func _spawn_portal(pos: Vector2) -> void:
	var portal: Portal = PORTAL_SCENE.instantiate()
	portal.position = pos
	entities.add_child(portal)
	portal.player_entered.connect(_on_portal_entered)
	Sound.play(Sound.PORTAL, 0.0, 0.0)


func _on_portal_entered() -> void:
	if GameState.is_final_floor():
		_finish(true)
	else:
		hud.hide()
		buff_select.open(GameState.random_buffs(3))


func _on_buff_chosen(id: String) -> void:
	Sound.play(Sound.BUFF, 0.0, 0.0)
	GameState.apply_buff(id)
	GameState.next_floor()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_player_died() -> void:
	await get_tree().create_timer(1.2).timeout
	_finish(false)


func _finish(won: bool) -> void:
	GameState.record_run(won)
	Sound.play_music(null)
	Sound.play(Sound.VICTORY if won else Sound.GAME_OVER, 0.0, 0.0)
	game_over.open(won)
