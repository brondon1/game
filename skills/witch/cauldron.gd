class_name Cauldron
extends Node2D
## 女巫的魔法坩埚：站在旁边每秒回能量、每 2 秒回 1 点血（最多 3 点），坩埚自己往附近的敌人吐毒泡泡。

const BULLET_SCENE := preload("res://weapons/bullet.tscn")
const RANGE := 36.0

var lifetime := 8.0
var damage := 3
var _healed := 0
var _tick := 0.0
var _heal_tick := 0.0
var _fire_timer := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/sprites/skills/cauldron.png")
	_sprite.hframes = 2
	_sprite.offset = Vector2(0, -7)
	add_child(_sprite)
	BlobShadow.add_to(self, 1.2)
	var light := PointLight2D.new()
	light.texture = preload("res://common/light_texture.tres")
	light.color = Color(0.6, 1.0, 0.4)
	light.energy = 0.6
	light.position = Vector2(0, -10)
	add_child(light)
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		HitEffect.spawn(get_parent(), global_position, Color("97da3f"), 10, 1.0, true)
		queue_free()
		return
	_sprite.frame = int(lifetime * 4.0) % 2
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and player.global_position.distance_to(global_position) <= RANGE:
		_tick -= delta
		if _tick <= 0.0:
			_tick = 1.0
			GameState.add_energy(8)
		_heal_tick -= delta
		if _heal_tick <= 0.0 and _healed < 3 and GameState.hp < GameState.max_hp:
			_heal_tick = 2.0
			_healed += 1
			GameState.heal(1)
			HitEffect.spawn(get_parent(), player.global_position + Vector2(0, -8), Color("97da3f"), 6, 0.6)
	_fire_timer -= delta
	if _fire_timer > 0.0:
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.is_targetable() and enemy.global_position.distance_to(global_position) < 140.0:
			_fire_timer = 0.6
			var bullet: Bullet = BULLET_SCENE.instantiate()
			get_tree().current_scene.add_child(bullet)
			var from := global_position + Vector2(0, -14)
			bullet.setup(Bullet.Team.PLAYER, from, from.angle_to_point(enemy.global_position + Vector2(0, -4)), 150.0,
				maxi(1, roundi(damage * GameState.damage_mult)), 180.0)
			bullet.poison_duration = 2.0
			bullet.modulate = Color(0.7, 1.6, 0.5)
			Sound.play(Sound.ENEMY_SHOT, -14.0)
			return
