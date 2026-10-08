class_name Lightning
extends Line2D
## 闪电连锁：从被命中的敌人跳到附近的其他敌人，每跳一次伤害打七折，画一道一闪而过的锯齿电光。

const COLOR := Color("72d6ce")
const DURATION := 0.18


## 从 first 开始往外跳 count 次，每次找 jump_range 以内最近的、还没被电过的敌人。
static func chain(parent: Node, first: Node2D, damage: int, count: int, jump_range: float) -> void:
	var hit: Array[Node2D] = [first]
	var from := first.global_position + Vector2(0, -4)
	var amount := damage
	for i in count:
		amount = maxi(1, roundi(amount * 0.7))
		var next: Enemy = null
		var best := jump_range
		for node in parent.get_tree().get_nodes_in_group("enemies"):
			var enemy := node as Enemy
			if enemy == null or enemy in hit or not enemy.is_targetable():
				continue
			var dist := from.distance_to(enemy.global_position + Vector2(0, -4))
			if dist < best:
				best = dist
				next = enemy
		if next == null:
			return
		var to := next.global_position + Vector2(0, -4)
		_bolt(parent, from, to)
		next.take_damage(amount, from.direction_to(to) * 0.5)
		hit.append(next)
		from = to


static func _bolt(parent: Node, from: Vector2, to: Vector2) -> void:
	var line := Lightning.new()
	line.width = 1.0
	line.default_color = COLOR
	line.z_index = 5
	line.material = preload("res://common/unshaded.tres")
	# 每 6 像素一个折点，往两边随机偏一点，形成锯齿
	var steps := maxi(2, int(from.distance_to(to) / 6.0))
	var side := from.direction_to(to).orthogonal()
	for i in steps + 1:
		var p := from.lerp(to, float(i) / steps)
		if i > 0 and i < steps:
			p += side * randf_range(-3.0, 3.0)
		line.add_point(p.round())
	parent.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, DURATION)
	tween.tween_callback(line.queue_free)
