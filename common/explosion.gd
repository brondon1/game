class_name Explosion
extends Node2D
## 爆炸：对范围内的目标造成伤害（玩家的爆炸也能炸碎木箱），播放 6 帧像素爆炸动画，带闪光和震屏。

const TEXTURE := preload("res://assets/sprites/explosion.png")
const FRAMES := 6
## 动画贴图里火球最大时的半径（像素），用来按实际爆炸半径缩放
const TEXTURE_RADIUS := 28.0
const DURATION := 0.42

var radius := 36.0


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
	Sound.play(Sound.EXPLOSION)
	Events.screen_shake.emit(5.0)
	HitEffect.spawn(get_parent(), position, Color("ee8e2e"), 14, 1.6)
	var sprite := Sprite2D.new()
	sprite.texture = TEXTURE
	sprite.hframes = FRAMES
	sprite.scale = Vector2.ONE * radius / TEXTURE_RADIUS
	sprite.material = preload("res://common/unshaded.tres")
	add_child(sprite)
	var light := PointLight2D.new()
	light.texture = preload("res://common/light_texture.tres")
	light.color = Color(1, 0.6, 0.3)
	light.texture_scale = radius / 40.0
	light.energy = 1.6
	add_child(light)
	var tween := create_tween().set_parallel()
	tween.tween_method(func(f: float) -> void: sprite.frame = mini(int(f), FRAMES - 1), 0.0, float(FRAMES), DURATION)
	tween.tween_property(light, "energy", 0.0, DURATION)
	tween.chain().tween_callback(queue_free)
