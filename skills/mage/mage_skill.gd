class_name MageSkill
extends Skill
## 法术类技能的基类（法师各流派、女巫都用）：放一些技能都要用的小工具（找敌人、清子弹、按伤害倍率算伤害……）。
## 每个技能在 _init() 里写自己的名字、说明、冷却和持续时间。

const SKILL_SPRITES := "res://assets/sprites/skills/"


## 技能放出来的东西挂在哪（和玩家同一层，参与 Y 排序）
func world() -> Node:
	return player.get_parent()


## 算上伤害加成之后的伤害
func dmg(base: int) -> int:
	return maxi(1, roundi(base * GameState.damage_mult))


## 玩家身体中心
func center() -> Vector2:
	return player.global_position + Vector2(0, -4)


func enemies_near(pos: Vector2, radius: float) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.is_targetable() and enemy.global_position.distance_to(pos) <= radius:
			result.append(enemy)
	return result


## 离 pos 最近的几个敌人（由近到远）
func nearest_enemies(pos: Vector2, radius: float, count: int) -> Array[Enemy]:
	var list := enemies_near(pos, radius)
	list.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.global_position.distance_squared_to(pos) < b.global_position.distance_squared_to(pos))
	return list.slice(0, count)


## 放范围技能的落点：附近敌人最扎堆的地方；没有敌人就是瞄准方向前方 ahead 像素
func target_spot(radius := 180.0, ahead := 60.0) -> Vector2:
	var best := center() + player.aim_direction * ahead
	var best_count := 0
	var candidates := enemies_near(player.global_position, radius)
	for enemy in candidates:
		var count := 0
		for other in candidates:
			if other.global_position.distance_to(enemy.global_position) < 40.0:
				count += 1
		if count > best_count:
			best_count = count
			best = enemy.global_position
	return best


## 清掉 pos 附近 radius 以内的敌方子弹，返回清掉了几颗
func clear_bullets(pos: Vector2, radius: float) -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Bullet
		if bullet and not bullet.is_queued_for_deletion() and bullet.global_position.distance_to(pos) <= radius:
			bullet.destroy()
			count += 1
	return count


## 从 from 往 dir 方向最多走 distance，碰到墙就停在墙前面
func reach_point(from: Vector2, dir: Vector2, distance: float, margin := 8.0) -> Vector2:
	var to := from + dir * distance
	var query := PhysicsRayQueryParameters2D.create(from, to, Bullet.LAYER_WORLD)
	var hit := player.get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return to
	return hit.position - dir * margin


## 范围伤害（不带爆炸动画），返回打到了几个
func hurt_area(pos: Vector2, radius: float, amount: int, push := 0.6) -> int:
	var list := enemies_near(pos, radius)
	for enemy in list:
		enemy.take_damage(amount, pos.direction_to(enemy.global_position) * push)
	return list.size()


## 生成一个地面效果区域（见 SkillZone）
func zone(pos: Vector2, radius: float, time: float, kind: SkillZone.Kind, amount := 1) -> SkillZone:
	var z := SkillZone.new()
	z.radius = radius
	z.lifetime = time
	z.kind = kind
	z.amount = amount
	z.position = pos
	world().add_child(z)
	return z


## 贴图精灵（特效用），自动挂到 parent 下
func sprite_fx(file: String, parent: Node, pos: Vector2, frames := 1) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(SKILL_SPRITES + file)
	s.hframes = frames
	s.position = pos
	parent.add_child(s)
	return s


## 在敌人身上挂一个状态贴图（泡泡、藤蔓），time 秒后消失
func overlay(enemy: Enemy, file: String, time: float, offset := Vector2(0, -8)) -> void:
	var s := sprite_fx(file, enemy, offset)
	s.z_index = 1
	var tween := s.create_tween()
	tween.tween_interval(time * (0.5 if enemy is Boss else 1.0))
	tween.tween_property(s, "modulate:a", 0.0, 0.2)
	tween.tween_callback(s.queue_free)
