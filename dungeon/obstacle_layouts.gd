class_name ObstacleLayouts
extends RefCounted
## 房间障碍物布局。石柱会变成墙（挡路、挡子弹，可以当掩体），木箱可以打碎。
## 所有布局都会避开房间中央连接四扇门的十字通道（中央石墩除外，但它四周都能绕过去），
## 所以门口永远不会被堵住。新增布局：在 _battle_pillars() 的 match 里加一个分支。

## 返回 {"pillars": Array[Vector2i], "crates": Array[Vector2i]}，都是瓦片坐标。
## r 是房间内部范围（瓦片坐标）。
static func plan(type: Room.Type, r: Rect2i) -> Dictionary:
	var pillars: Array[Vector2i] = []
	var crates: Array[Vector2i] = []
	match type:
		Room.Type.BATTLE:
			pillars = _battle_pillars(r)
			crates = _random_crates(r, pillars, randi_range(2, 5))
		Room.Type.BOSS:
			# Boss 房：四根单格石柱，躲弹幕用
			var c := _center(r)
			var q := r.size / 4
			for s: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				pillars.append(c + s * q)
	return {"pillars": pillars, "crates": crates}


static func _battle_pillars(r: Rect2i) -> Array[Vector2i]:
	var c := _center(r)
	var q := r.size / 4
	var cells: Array[Vector2i] = []
	var corners: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	match randi() % 4:
		0: # 四根 2×2 石柱，向房间外侧延伸
			for s in corners:
				var base := c + s * q
				cells.append_array([base, base + Vector2i(s.x, 0), base + Vector2i(0, s.y), base + s])
		1: # 中央 3×3 石墩
			for x in range(-1, 2):
				for y in range(-1, 2):
					cells.append(c + Vector2i(x, y))
		2: # 四道横向矮墙
			for s in corners:
				for x in range(-1, 2):
					cells.append(c + s * q + Vector2i(x, 0))
		_: # 只放木箱
			pass
	return cells


## 随机放木箱：不贴墙、不挡十字通道、不和石柱挨着。
static func _random_crates(r: Rect2i, pillars: Array[Vector2i], count: int) -> Array[Vector2i]:
	var c := _center(r)
	var area := r.grow(-2)
	var crates: Array[Vector2i] = []
	for attempt in 40:
		if crates.size() >= count:
			break
		var cell := Vector2i(randi_range(area.position.x, area.end.x - 1), randi_range(area.position.y, area.end.y - 1))
		if absi(cell.x - c.x) <= 1 or absi(cell.y - c.y) <= 1:
			continue
		if crates.has(cell) or _near_any(cell, pillars):
			continue
		crates.append(cell)
	return crates


static func _near_any(cell: Vector2i, cells: Array[Vector2i]) -> bool:
	for other in cells:
		if absi(cell.x - other.x) <= 1 and absi(cell.y - other.y) <= 1:
			return true
	return false


static func _center(r: Rect2i) -> Vector2i:
	return r.position + r.size / 2
