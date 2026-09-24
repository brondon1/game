class_name DungeonGenerator
extends RefCounted
## 随机地牢布局：从起点开始在网格上随机游走，走过的格子就是房间。
## 随机游走经过的相邻两格之间一定有通道，所以所有房间天然连通。

const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


## 返回 { "rooms": {格子坐标: Room.Type}, "links": [[格子A, 格子B], ...] }
static func generate(room_count: int) -> Dictionary:
	var rooms := {Vector2i.ZERO: Room.Type.START}
	var links := {}
	var pos := Vector2i.ZERO
	var steps := 0
	while rooms.size() < room_count and steps < 1000:
		steps += 1
		var next: Vector2i = pos + DIRECTIONS.pick_random()
		if not rooms.has(next):
			rooms[next] = Room.Type.BATTLE
		links[_link_key(pos, next)] = [pos, next]
		pos = next

	# 广度优先搜索：算出每个房间离起点的步数
	var neighbors := {}
	for pair: Array in links.values():
		neighbors.get_or_add(pair[0], []).append(pair[1])
		neighbors.get_or_add(pair[1], []).append(pair[0])
	var dist := {Vector2i.ZERO: 0}
	var parent := {}
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		for n: Vector2i in neighbors[cur]:
			if not dist.has(n):
				dist[n] = dist[cur] + 1
				parent[n] = cur
				queue.append(n)

	# 离起点最远的房间作为 Boss 房，并且只保留一条通往它的路（死胡同）
	var boss := Vector2i.ZERO
	for cell: Vector2i in dist:
		if dist[cell] > dist[boss]:
			boss = cell
	rooms[boss] = Room.Type.BOSS
	for key: String in links.keys():
		var pair: Array = links[key]
		if pair.has(boss) and not pair.has(parent[boss]):
			links.erase(key)

	# 挑一个离起点不太近的战斗房改成宝箱房
	var candidates: Array[Vector2i] = []
	for cell: Vector2i in rooms:
		if rooms[cell] == Room.Type.BATTLE and dist[cell] >= 2:
			candidates.append(cell)
	if not candidates.is_empty():
		rooms[candidates.pick_random()] = Room.Type.CHEST

	return {"rooms": rooms, "links": links.values()}


static func _link_key(a: Vector2i, b: Vector2i) -> String:
	return "%s-%s" % [a, b] if a < b else "%s-%s" % [b, a]
