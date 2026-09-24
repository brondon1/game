class_name Explosion
extends Node2D
## 爆炸：对范围内的目标造成伤害（玩家的爆炸也能炸碎木箱），带火光、闪光和震屏。

var radius := 36.0
var _t := 0.0


static func spawn(parent: Node, pos: Vector2, p_radius: float, damage: int, team: Bullet.Team) -> void:
	var fx := Explosion.new()
	fx.position = pos
	fx.radius = p_radius
	parent.add_child.call_deferred(fx)
	fx._deal_damage.call_deferred(parent, pos, p_radius, damage, team)


func _deal_damage(parent: Node, pos: Vector2, p_radius: float, damage: int, team: Bullet.Team) -> void:
	var tree := parent.get_tree()
	var targets := tree.get_nodes_in_group("player")
	if team == Bullet.Team.PLAYER:
		targets = tree.get_nodes_in_group("enemies") + tree.get_nodes_in_group("breakables")
	for node in targets:
		var target := node as Node2D
		if target == null or not target.has_method("take_damage"):
			continue
		if target is Enemy and not target.is_targetable():
			continue
		var offset := target.global_position + Vector2(0, -4) - pos
		if offset.length() <= p_radius + 6.0:
			target.take_damage(damage, offset.normalized() * 1.5)


func _ready() -> void:
	z_index = 5
	material = preload("res://common/unshaded.tres")
	Sound.play(Sound.EXPLOSION)
	Events.screen_shake.emit(5.0)
	HitEffect.spawn(get_parent(), position, Color("f77622"), 18, 1.6)
	HitEffect.spawn(get_parent(), position, Color("fee761"), 10, 1.0)
	var light := PointLight2D.new()
	light.texture = preload("res://common/light_texture.tres")
	light.color = Color(1, 0.6, 0.3)
	light.texture_scale = radius / 40.0
	light.energy = 1.6
	add_child(light)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "_t", 1.0, 0.3)
	tween.tween_property(light, "energy", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := radius * (0.4 + _t * 0.6)
	draw_circle(Vector2.ZERO, r, Color(1, 0.55, 0.2, 0.5 * (1.0 - _t)))
	draw_arc(Vector2.ZERO, r, 0, TAU, 24, Color(1, 0.9, 0.5, 1.0 - _t), 2.0)
