class_name SkillZone
extends Node2D
## 法师技能留在地上的一片区域，持续 lifetime 秒，每 tick 秒对里面的东西起一次作用：
## - BURN 火焰：烧伤敌人；POISON 毒雾：让敌人中毒；FROST 冰雹：伤害并减速
## - HEAL 泉水：玩家站在里面回血；TIME 时间结界：敌人和敌方子弹变慢；PULL 黑洞：把敌人往中心拖、吞掉子弹
## - SHIELD 护盾罩（机械师）：飞进罩子里的敌方子弹全部消失

enum Kind { BURN, POISON, FROST, HEAL, TIME, PULL, SHIELD }

## 时间到了、开始消失时发出（黑洞在这时炸开）
signal expired

const COLORS := {
	Kind.BURN: Color(0.93, 0.45, 0.18), Kind.POISON: Color(0.45, 0.75, 0.25), Kind.FROST: Color(0.7, 0.9, 1.0),
	Kind.HEAL: Color(0.35, 0.75, 0.95), Kind.TIME: Color(0.55, 0.5, 1.0), Kind.PULL: Color(0.35, 0.15, 0.45),
	Kind.SHIELD: Color(0.45, 0.85, 0.8),
}
const TICK := {Kind.BURN: 0.5, Kind.POISON: 0.5, Kind.FROST: 0.5, Kind.HEAL: 1.5, Kind.TIME: 0.0, Kind.PULL: 0.0,
	Kind.SHIELD: 0.0}

var radius := 30.0
var lifetime := 3.0
var kind := Kind.BURN
## 每次起作用的伤害 / 回血量
var amount := 1
## 拖拽速度（黑洞）
var pull_speed := 70.0

var _tick := 0.0
var _age := 0.0
var _slowed: Array[Bullet] = []


## 地面区域要画在地板之上、角色之下：放进场景里的 Decor 层（地牢和大厅都有），没有的话就放在 entities 里
static func ground_layer(entities: Node) -> Node:
	var decor := entities.get_parent().get_node_or_null("Decor")
	return decor if decor else entities


## 在 pos 生成一片区域
static func spawn(entities: Node, pos: Vector2, p_radius: float, time: float, p_kind: Kind, p_amount := 1) -> SkillZone:
	var z := SkillZone.new()
	z.radius = p_radius
	z.lifetime = time
	z.kind = p_kind
	z.amount = p_amount
	ground_layer(entities).add_child(z)
	z.global_position = pos
	return z


func _ready() -> void:
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)


func _physics_process(delta: float) -> void:
	_age += delta
	lifetime -= delta
	if lifetime <= 0.0:
		_finish()
		return
	match kind:
		Kind.TIME:
			_time_field()
		Kind.PULL:
			_pull()
		Kind.SHIELD:
			_block_bullets()
	if TICK[kind] > 0.0:
		_tick -= delta
		if _tick <= 0.0:
			_tick = TICK[kind]
			_apply()
	queue_redraw()


func _apply() -> void:
	if kind == Kind.HEAL:
		var player := get_tree().get_first_node_in_group("player") as Player
		if player and player.global_position.distance_to(global_position) <= radius and GameState.hp < GameState.max_hp:
			GameState.heal(amount)
			HitEffect.spawn(get_parent(), player.global_position + Vector2(0, -8), Color("72d6ce"), 6, 0.6)
		return
	for enemy in _enemies_inside():
		match kind:
			Kind.BURN:
				enemy.take_damage(amount)
			Kind.POISON:
				enemy.apply_poison(1.0, amount)
			Kind.FROST:
				enemy.take_damage(amount)
				enemy.apply_slow(0.6)
	if kind != Kind.HEAL:
		HitEffect.spawn(get_parent(), global_position + Vector2.from_angle(randf() * TAU) * randf() * radius, COLORS[kind], 3, 0.5)


## 时间结界：里面的敌人慢下来，敌方子弹只剩 30% 的速度，出了结界恢复
func _time_field() -> void:
	for enemy in _enemies_inside():
		enemy.apply_slow(0.1)
	var inside: Array[Bullet] = []
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Bullet
		if bullet and bullet.global_position.distance_to(global_position) <= radius:
			bullet.speed_scale = 0.3
			inside.append(bullet)
	for bullet in _slowed:
		if is_instance_valid(bullet) and not bullet in inside:
			bullet.speed_scale = 1.0
	_slowed = inside


## 黑洞：把附近敌人往中心拖，吞掉飞进来的敌方子弹
func _pull() -> void:
	for enemy in _enemies_inside():
		var offset := global_position - enemy.global_position
		if offset.length() > 4.0:
			enemy.pull(offset.normalized() * pull_speed)
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Bullet
		if bullet and not bullet.is_queued_for_deletion() and bullet.global_position.distance_to(global_position) <= radius:
			bullet.destroy()


func _block_bullets() -> void:
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Bullet
		if bullet and not bullet.is_queued_for_deletion() and bullet.global_position.distance_to(global_position) <= radius:
			HitEffect.spawn(get_parent(), bullet.global_position, COLORS[kind], 3, 0.5)
			bullet.destroy()


func _enemies_inside() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.is_targetable() and enemy.global_position.distance_to(global_position) <= radius:
			result.append(enemy)
	return result


func _finish() -> void:
	expired.emit()
	for bullet in _slowed:
		if is_instance_valid(bullet):
			bullet.speed_scale = 1.0
	_slowed.clear()
	set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


## 像素风的圆：半透明填充 + 一圈实线边，边上有一圈慢慢转的亮点
func _draw() -> void:
	var color: Color = COLORS[kind]
	draw_circle(Vector2.ZERO, radius, Color(color, 0.22 if kind != Kind.PULL else 0.45))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(color, 0.8), 1.0)
	var dots := 8
	var spin := _age * (3.0 if kind == Kind.PULL else 0.8)
	for i in dots:
		var p := Vector2.from_angle(spin + TAU * i / dots) * (radius - 3.0)
		draw_rect(Rect2(p.round() - Vector2.ONE, Vector2(2, 2)), Color(color.lightened(0.4), 0.9))
	if kind == Kind.PULL: # 黑洞中心
		draw_circle(Vector2.ZERO, 6.0, Color(0.05, 0.02, 0.08))
		draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 16, Color(0.86, 0.29, 0.48), 1.0)
