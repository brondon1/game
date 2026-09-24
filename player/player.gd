class_name Player
extends CharacterBody2D
## 玩家：移动、自动瞄准、射击、拾取和切换武器，受伤时先扣护盾再扣生命。

@export var base_speed := 100.0
## 自动瞄准视线内最近的敌人（类似元气骑士手机版）。没有敌人时朝鼠标方向瞄准。
@export var auto_aim := true
@export var aim_range := 220.0
@export var invincible_time := 0.8
## 多久没受伤后开始回复护盾（秒）
@export var shield_regen_delay := 3.0
@export var shield_regen_interval := 1.0

var aim_direction := Vector2.RIGHT

var _invincible := 0.0
var _since_hit := 0.0
var _regen_timer := 0.0
var _nearby_pickups: Array = []
var _dead := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon: Weapon = $WeaponPivot/Weapon


func _ready() -> void:
	add_to_group("player")
	GameState.weapons_changed.connect(_on_weapons_changed)
	_on_weapons_changed()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * base_speed * GameState.speed_mult
	move_and_slide()

	_update_aim()
	if Input.is_action_pressed("shoot"):
		shoot()
	_update_timers(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	if event.is_action_pressed("switch_weapon"):
		GameState.switch_weapon()
	elif event.is_action_pressed("interact"):
		_interact()


func is_dead() -> bool:
	return _dead


func shoot() -> void:
	if not weapon.is_ready_to_fire():
		return
	if not GameState.use_energy(weapon.data.energy_cost):
		return # 能量不足
	weapon.fire(Bullet.Team.PLAYER, GameState.damage_mult, GameState.fire_rate_mult)


func take_damage(amount: int, _direction := Vector2.ZERO) -> void:
	if _dead or _invincible > 0.0:
		return
	_invincible = invincible_time
	_since_hit = 0.0
	_regen_timer = 0.0
	GameState.apply_damage(amount)
	Events.screen_shake.emit(4.0)
	sprite.modulate = Color(1, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	if GameState.hp <= 0:
		_die()


# ---------- 瞄准 ----------

func _update_aim() -> void:
	var target: Enemy = _find_auto_aim_target() if auto_aim else null
	if target:
		aim_direction = global_position.direction_to(target.global_position)
	else:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			aim_direction = to_mouse.normalized()
	weapon_pivot.rotation = aim_direction.angle()
	# 朝左时翻转角色，并上下翻转枪，避免枪倒过来
	var facing_left := aim_direction.x < 0.0
	sprite.flip_h = facing_left
	weapon_pivot.scale.y = -1.0 if facing_left else 1.0


func _find_auto_aim_target() -> Enemy:
	var best: Enemy = null
	var best_dist := aim_range
	var space := get_world_2d().direct_space_state
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_targetable():
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist >= best_dist:
			continue
		# 被墙挡住的敌人不瞄准（只检测第 1 层：墙和门）
		var query := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, Bullet.LAYER_WORLD)
		if not space.intersect_ray(query).is_empty():
			continue
		best = enemy
		best_dist = dist
	return best


# ---------- 武器拾取 ----------

func add_nearby_pickup(pickup: WeaponPickup) -> void:
	if not _nearby_pickups.has(pickup):
		_nearby_pickups.append(pickup)


func remove_nearby_pickup(pickup: WeaponPickup) -> void:
	_nearby_pickups.erase(pickup)


func _interact() -> void:
	_nearby_pickups = _nearby_pickups.filter(is_instance_valid)
	if _nearby_pickups.is_empty():
		return
	var closest: WeaponPickup = _nearby_pickups[0]
	for p: WeaponPickup in _nearby_pickups:
		if global_position.distance_to(p.global_position) < global_position.distance_to(closest.global_position):
			closest = p
	var dropped := GameState.pick_up_weapon(closest.data)
	if dropped:
		closest.data = dropped # 背包满了：把换下来的武器留在原地
	else:
		_nearby_pickups.erase(closest)
		closest.queue_free()


func _on_weapons_changed() -> void:
	weapon.data = GameState.current_weapon()


# ---------- 计时 ----------

func _update_timers(delta: float) -> void:
	if _invincible > 0.0:
		_invincible = maxf(_invincible - delta, 0.0)
		sprite.visible = _invincible <= 0.0 or int(_invincible * 20.0) % 2 == 0 # 无敌时闪烁
	_since_hit += delta
	if _since_hit >= shield_regen_delay and GameState.shield < GameState.max_shield:
		_regen_timer += delta
		if _regen_timer >= shield_regen_interval:
			_regen_timer = 0.0
			GameState.restore_shield(1)


func _die() -> void:
	_dead = true
	sprite.visible = true
	sprite.modulate = Color(0.5, 0.5, 0.5)
	sprite.rotation = PI / 2.0
	weapon_pivot.hide()
	velocity = Vector2.ZERO
	Events.player_died.emit()
