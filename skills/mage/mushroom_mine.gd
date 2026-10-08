class_name MushroomMine
extends Node2D
## 埋在地上的雷：0.4 秒后生效，敌人走近就炸开，持续 lifetime 秒。
## 默认是剧毒法师的毒蘑菇（炸开后留一团毒雾）；机械师的地雷换贴图、关掉毒雾、炸得更大。

const TRIGGER_RADIUS := 22.0

var damage := 6
var lifetime := 20.0
var texture: Texture2D = preload("res://assets/sprites/skills/mushroom.png")
var hframes := 1
var leaves_poison := true
var blast_radius := 28.0
var _armed := 0.4
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = texture
	_sprite.hframes = hframes
	_sprite.offset = Vector2(0, -texture.get_height() / 2.0 + 1.0)
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
	if hframes > 1:
		_sprite.frame = int(lifetime * 3.0) % hframes # 地雷的指示灯一闪一闪
	else:
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
	Explosion.spawn(get_parent(), global_position, blast_radius, damage, Bullet.Team.PLAYER)
	if not leaves_poison:
		queue_free()
		return
	SkillZone.spawn(get_parent(), global_position, 30.0, 4.0, SkillZone.Kind.POISON, 2)
	queue_free()
