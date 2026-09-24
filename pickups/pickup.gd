class_name Pickup
extends Area2D
## 掉落物：金币、能量、生命药水。金币和能量靠近时会自动吸向玩家。

enum Kind { COIN, ENERGY, HEALTH }

const TEXTURES := {
	Kind.COIN: preload("res://assets/sprites/coin.png"),
	Kind.ENERGY: preload("res://assets/sprites/energy.png"),
	Kind.HEALTH: preload("res://assets/sprites/potion.png"),
}

@export var kind := Kind.COIN
@export var amount := 1
@export var magnet_radius := 60.0

var _speed := 0.0
var _player: Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = TEXTURES[kind]
	body_entered.connect(_on_body_entered)
	_player = get_tree().get_first_node_in_group("player") as Node2D
	# 掉出来时往随机方向弹一下
	var tween := create_tween()
	tween.tween_property(self, "position", position + Vector2.from_angle(randf() * TAU) * randf_range(4.0, 12.0), 0.2)


func _physics_process(delta: float) -> void:
	if kind == Kind.HEALTH or _player == null:
		return
	if global_position.distance_to(_player.global_position) < magnet_radius:
		_speed = minf(_speed + 500.0 * delta, 260.0)
		global_position = global_position.move_toward(_player.global_position, _speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	match kind:
		Kind.COIN:
			GameState.add_coins(amount)
		Kind.ENERGY:
			GameState.add_energy(amount)
		Kind.HEALTH:
			GameState.heal(amount)
	queue_free()
