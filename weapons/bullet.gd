class_name Bullet
extends Area2D
## 子弹：直线飞行，撞墙或命中目标后消失。阵营决定它和谁发生碰撞。

enum Team { PLAYER, ENEMY }

const PLAYER_TEXTURE := preload("res://assets/sprites/bullet_player.png")
const ENEMY_TEXTURE := preload("res://assets/sprites/bullet_enemy.png")

# 碰撞层（与 项目设置 → Layer Names → 2D Physics 对应）
const LAYER_WORLD := 1
const LAYER_PLAYER := 2
const LAYER_ENEMY := 4
const LAYER_PLAYER_BULLET := 8
const LAYER_ENEMY_BULLET := 16

var team := Team.PLAYER
var damage := 1
var piercing := false

var _velocity := Vector2.ZERO
var _range_left := 300.0
var _already_hit: Array[Node2D] = []
var _done := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(p_team: Team, pos: Vector2, angle: float, speed: float, p_damage: int,
		max_range: float, p_piercing := false) -> void:
	team = p_team
	global_position = pos
	rotation = angle
	damage = p_damage
	piercing = p_piercing
	_velocity = Vector2.from_angle(angle) * speed
	_range_left = max_range
	var is_player := team == Team.PLAYER
	collision_layer = LAYER_PLAYER_BULLET if is_player else LAYER_ENEMY_BULLET
	collision_mask = LAYER_WORLD | (LAYER_ENEMY if is_player else LAYER_PLAYER)
	sprite.texture = PLAYER_TEXTURE if is_player else ENEMY_TEXTURE


func _physics_process(delta: float) -> void:
	var step := _velocity * delta
	position += step
	_range_left -= step.length()
	if _range_left <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _done:
		return
	if body.has_method("take_damage"):
		if body in _already_hit:
			return
		_already_hit.append(body)
		body.take_damage(damage, _velocity.normalized())
		if piercing:
			return
	_done = true
	var color := Color("ffcd75") if team == Team.PLAYER else Color("ef7d57")
	HitEffect.spawn(get_parent(), global_position, color)
	queue_free()
