class_name Minimap
extends Control
## 小地图：显示去过的房间，以及和它们相连、还没去过的房间（暗色）。
## 以玩家所在的房间为中心，地图大了也能显示。
## 勾选 fit_all 后变成全图模式（全屏大地图用）：把所有已知房间缩放到铺满整个控件。

## 每个房间方块的大小，以及相邻房间中心之间的距离
const ROOM_SIZE := Vector2(10, 7)
const SPACING := Vector2(15, 11)

const COLOR_BACKGROUND := Color(0.1, 0.11, 0.17, 0.75)
const COLOR_UNKNOWN := Color("333c57")
const COLOR_VISITED := Color("566c86")
const COLOR_CURRENT := Color("94b0c2")
const COLOR_OUTLINE := Color("1a1c2c")
const COLOR_CORRIDOR := Color("566c86")
const COLOR_PLAYER := Color("73eff7")
const ICON_COLORS := {
	Room.Type.CHEST: Color("ffcd75"),
	Room.Type.BOSS: Color("b13e53"),
	Room.Type.SHOP: Color("38b764"),
}

@export var fit_all := false
@export var draw_background := true

var _rooms := {} # 格子坐标 → Room
var _links: Array = []
var _neighbors := {} # 格子坐标 → 相邻格子数组
var _current: Room
var _player: Node2D


func setup(rooms: Dictionary, links: Array) -> void:
	_rooms = rooms
	_links = links
	_neighbors.clear()
	for link: Array in links:
		_neighbors.get_or_add(link[0], []).append(link[1])
		_neighbors.get_or_add(link[1], []).append(link[0])
	_current = null
	queue_redraw()


func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return
	for room: Room in _rooms.values():
		# 稍微扩大一圈，让站在门口也算进了房间
		if room.rect.grow(8.0).has_point(_player.global_position):
			_current = room
			room.visited = true
			break
	queue_redraw()


## 去过的房间，以及和去过的房间直接相连的房间，才会出现在小地图上。
func is_known(cell: Vector2i) -> bool:
	if _rooms[cell].visited:
		return true
	for n: Vector2i in _neighbors.get(cell, []):
		if _rooms[n].visited:
			return true
	return false


func _draw() -> void:
	if draw_background:
		draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKGROUND)
	if _current == null:
		return
	# 小地图以当前房间为中心；全图模式以所有已知房间的中心为中心，并按整数倍放大
	var focus := Vector2(_current.cell)
	var zoom := 1.0
	if fit_all:
		var bounds := Rect2(focus, Vector2.ZERO)
		for cell: Vector2i in _rooms:
			if is_known(cell):
				bounds = bounds.expand(Vector2(cell))
		focus = bounds.get_center()
		var needed := bounds.size * SPACING + ROOM_SIZE * 2.0
		zoom = clampf(floorf(minf(size.x / needed.x, size.y / needed.y)), 1.0, 4.0)
	draw_set_transform(size / 2.0, 0.0, Vector2.ONE * zoom)
	var origin := -focus * SPACING

	# 走廊：至少有一头去过才画
	for link: Array in _links:
		var a: Vector2i = link[0]
		var b: Vector2i = link[1]
		if _rooms[a].visited or _rooms[b].visited:
			draw_line(origin + Vector2(a) * SPACING, origin + Vector2(b) * SPACING, COLOR_CORRIDOR, 2.0)

	# 房间
	for cell: Vector2i in _rooms:
		if not is_known(cell):
			continue
		var room: Room = _rooms[cell]
		var center := origin + Vector2(cell) * SPACING
		var rect := Rect2(center - ROOM_SIZE / 2.0, ROOM_SIZE)
		var fill := COLOR_UNKNOWN
		if room == _current:
			fill = COLOR_CURRENT
		elif room.visited:
			fill = COLOR_VISITED
		draw_rect(rect, fill)
		draw_rect(rect, COLOR_OUTLINE, false, 1.0)
		if ICON_COLORS.has(room.type):
			draw_rect(Rect2(center - Vector2(2, 2), Vector2(4, 4)), ICON_COLORS[room.type])

	# 玩家在当前房间里的大致位置
	var local := (_player.global_position - _current.rect.get_center()) / _current.rect.size
	local = local.clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5))
	draw_rect(Rect2(origin + Vector2(_current.cell) * SPACING + local * ROOM_SIZE - Vector2.ONE, Vector2(2, 2)), COLOR_PLAYER)
