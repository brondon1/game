class_name MushroomMine
extends Node2D
## 剧毒法师种下的毒蘑菇：0.4 秒后生效，敌人走近就炸开，造成伤害并留下一团毒雾。持续 lifetime 秒。

const TRIGGER_RADIUS := 22.0

var damage := 6
var lifetime := 20.0
var _armed := 0.4
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/sprites/skills/mushroom.png")
	_sprite.offset = Vector2(0, -5)
	add_child(_sprite)
	BlobShadow.add_to(self, 0.7)
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	_armed -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	_sprite.scale.y = 1.0 + sin(lifetime * 6.0) * 0.06 # 一鼓一鼓的
	if _armed > 0.0:
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.is_targetable() and enemy.global_position.distance_to(global_position) <= TRIGGER_RADIUS:
			_burst()
			return


func _burst() -> void:
	set_physics_process(false)
	Explosion.spawn(get_parent(), global_position, 28.0, damage, Bullet.Team.PLAYER)
	var cloud := SkillZone.new()
	cloud.kind = SkillZone.Kind.POISON
	cloud.radius = 30.0
	cloud.lifetime = 3.0
	cloud.amount = 2
	cloud.position = global_position
	get_parent().add_child(cloud)
	queue_free()
