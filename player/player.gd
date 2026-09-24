class_name Player
extends CharacterBody2D
## 玩家：移动、自动瞄准、射击、拾取和切换武器、释放角色技能，受伤时先扣护盾再扣生命。
## 外观、速度和技能由 GameState.character（主菜单选的角色）决定。

## 自动瞄准视线内最近的敌人（类似元气骑士手机版）。没有敌人时朝鼠标方向瞄准。
@export var auto_aim := true
@export var aim_range := 220.0
@export var invincible_time := 0.8
## 多久没受伤后开始回复护盾（秒）
@export var shield_regen_delay := 3.0
@export var shield_regen_interval := 1.0

var aim_direction := Vector2.RIGHT
var base_speed := 100.0
var skill: Skill

var _invincible := 0.0
var _since_hit := 0.0
var _regen_timer := 0.0
var _nearby_interactables: Array = []
var _aim_target: Enemy
var _dead := false
var _offhand_on := false
var _dash_velocity := Vector2.ZERO
var _dash_time := 0.0
var _afterimage_timer := 0.0
var _anim_time := 0.0
var _dust_timer := 0.0
var _sprite_base_y := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon: Weapon = $WeaponPivot/Weapon
## 副手武器，只在骑士的“双持”技能期间出现
@onready var offhand: Weapon = $WeaponPivot/Offhand


func _ready() -> void:
	add_to_group("player")
	var character := GameState.character
	sprite.texture = character.texture
	sprite.hframes = character.hframes
	# 让脚踩在节点原点上：不同角色的贴图高度不一样
	sprite.position.y = -character.texture.get_height() / 2.0 + 1.0
	_sprite_base_y = sprite.position.y
	BlobShadow.add_to(self)
	base_speed = character.speed
	skill = character.skill_scene.instantiate()
	skill.player = self
	add_child(skill)
	offhand.hide()
	GameState.weapons_changed.connect(_on_weapons_changed)
	_on_weapons_changed()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _dash_time > 0.0:
		_update_dash(delta)
	else:
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input * base_speed * GameState.speed_mult
	move_and_slide()

	_update_aim()
	_animate(delta)
	if Input.is_action_pressed("shoot") or _wants_auto_fire():
		shoot()
	_update_timers(delta)


## 逐帧动画：站着时播放 4 帧待机，跑动时播放 4 帧跑步，并扬起一点灰尘。
## 只有一帧的贴图（比如自己换的素材）退回到代码颠动。
func _animate(delta: float) -> void:
	if _dash_time > 0.0:
		return
	_anim_time += delta
	var moving := velocity.length() > 5.0
	if sprite.hframes >= CharacterData.IDLE_FRAMES + CharacterData.WALK_FRAMES:
		if moving:
			sprite.frame = CharacterData.IDLE_FRAMES + int(_anim_time * 10.0) % CharacterData.WALK_FRAMES
		else:
			sprite.frame = int(_anim_time * 6.0) % CharacterData.IDLE_FRAMES
	elif moving:
		sprite.position.y = _sprite_base_y - absf(sin(_anim_time * 14.0)) * 1.5
	else:
		sprite.position.y = _sprite_base_y
	sprite.rotation = 0.0
	if moving:
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.22
			HitEffect.spawn(get_parent(), global_position, Color(0.85, 0.8, 0.75, 0.5), 2, 0.3, true)


func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	if event.is_action_pressed("switch_weapon"):
		GameState.switch_weapon()
	elif event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("skill"):
		skill.try_activate()


func is_dead() -> bool:
	return _dead


func shoot() -> void:
	_fire(weapon)
	if _offhand_on:
		_fire(offhand)


func _fire(w: Weapon) -> void:
	if not w.is_ready_to_fire():
		return
	if not GameState.use_energy(w.data.energy_cost):
		return # 能量不足
	w.fire(Bullet.Team.PLAYER, GameState.damage_mult, GameState.fire_rate_mult)


func take_damage(amount: int, _direction := Vector2.ZERO) -> void:
	if _dead or _invincible > 0.0 or _dash_time > 0.0:
		return
	_invincible = invincible_time
	_since_hit = 0.0
	_regen_timer = 0.0
	GameState.apply_damage(amount)
	Events.screen_shake.emit(4.0)
	Sound.play(Sound.PLAYER_HURT)
	sprite.modulate = Color(1, 0.3, 0.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
	if GameState.hp <= 0:
		_die()


# ---------- 瞄准 ----------

func _update_aim() -> void:
	var target: Enemy = find_aim_target() if auto_aim else null
	_aim_target = target
	if target:
		# 从手上的枪瞄向敌人身体中心，和子弹实际飞的路线一致
		aim_direction = weapon_pivot.global_position.direction_to(target.global_position + Vector2(0, -4))
	elif TouchControls.active:
		# 手机上没有鼠标：没有目标时枪口朝着移动的方向
		if velocity.length() > 1.0:
			aim_direction = velocity.normalized()
	else:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 4.0:
			aim_direction = to_mouse.normalized()
	weapon_pivot.rotation = aim_direction.angle()
	# 朝左时翻转角色，并上下翻转枪，避免枪倒过来
	var facing_left := aim_direction.x < 0.0
	sprite.flip_h = facing_left
	weapon_pivot.scale.y = -1.0 if facing_left else 1.0


## 自动射击：门关着（在打怪）时，只要瞄着的敌人子弹打得到就自动开火；
## 近战武器等敌人进了攻击范围再挥。在暂停菜单里可以关掉。
func _wants_auto_fire() -> bool:
	if not GameState.auto_fire or not GameState.in_combat or not is_instance_valid(_aim_target):
		return false
	if weapon.data and weapon.data.is_melee:
		return global_position.distance_to(_aim_target.global_position) <= weapon.data.melee_range + 8.0
	return has_clear_shot(_aim_target.global_position + Vector2(0, -4))


## 瞄准范围内最近的敌人（自动瞄准和刺客技能都用它）。
## 优先选子弹真的打得到的；都打不到时退而选看得见的（比如只露出一角），被墙完全挡住的不瞄。
func find_aim_target() -> Enemy:
	var best_clear: Enemy = null
	var best_clear_dist := aim_range
	var best_visible: Enemy = null
	var best_visible_dist := aim_range
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or not enemy.is_targetable():
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist >= best_visible_dist and dist >= best_clear_dist:
			continue
		var point := enemy.global_position + Vector2(0, -4) # 敌人身体中心
		if dist < best_clear_dist and has_clear_shot(point):
			best_clear = enemy
			best_clear_dist = dist
		elif dist < best_visible_dist and _is_visible(weapon_pivot.global_position, point):
			best_visible = enemy
			best_visible_dist = dist
	return best_clear if best_clear else best_visible


## 子弹从枪口飞到 point 的这一路有没有墙：按枪口的实际位置（偏离手的中心线几个像素）
## 和子弹的粗细，检查弹道中线和两侧边缘三条线。只看中心线的话，子弹会一直蹭在石柱角上。
func has_clear_shot(point: Vector2) -> bool:
	var hand := weapon_pivot.global_position
	var dir := hand.direction_to(point)
	var side := Vector2(-dir.y, dir.x) # 武器本地坐标的 +y 方向
	var muzzle_y := weapon.position.y + weapon.muzzle.position.y
	if dir.x < 0.0:
		muzzle_y = -muzzle_y # 朝左时枪上下翻转（见 _update_aim）
	for edge in [-Bullet.RADIUS, 0.0, Bullet.RADIUS]:
		var offset: Vector2 = side * (muzzle_y + edge)
		if not _is_visible(hand + offset, point + offset):
			return false
	return true


func _is_visible(from: Vector2, to: Vector2) -> bool:
	# 只检测第 1 层：墙、门和障碍物
	var query := PhysicsRayQueryParameters2D.create(from, to, Bullet.LAYER_WORLD)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


# ---------- 交互（按 E） ----------
# 可交互物体（地上的武器、商店商品……）是带 interact(player) 方法的 Area2D，
# 玩家靠近时它们调用 add_interactable()，离开时调用 remove_interactable()。

func add_interactable(node: Node2D) -> void:
	if not _nearby_interactables.has(node):
		_nearby_interactables.append(node)


func remove_interactable(node: Node2D) -> void:
	_nearby_interactables.erase(node)


## 附近有没有能交互的东西（手机上的交互按钮只在这时显示）。
func can_interact() -> bool:
	_nearby_interactables = _nearby_interactables.filter(
		func(n: Object) -> bool: return is_instance_valid(n) and not n.is_queued_for_deletion())
	return not _nearby_interactables.is_empty()


func _interact() -> void:
	if not can_interact():
		return
	var closest: Node2D = _nearby_interactables[0]
	for n: Node2D in _nearby_interactables:
		if global_position.distance_to(n.global_position) < global_position.distance_to(closest.global_position):
			closest = n
	closest.interact(self)


func _on_weapons_changed() -> void:
	weapon.data = GameState.current_weapon()
	_refresh_offhand()


# ---------- 技能用到的能力 ----------

## 打开或关闭副手武器（双持）。
func set_offhand(enabled: bool) -> void:
	_offhand_on = enabled
	offhand.visible = enabled
	_refresh_offhand()


## 副手拿另一把武器；只有一把时拿同一把。
func _refresh_offhand() -> void:
	var weapons := GameState.weapons
	if weapons.is_empty():
		return
	offhand.data = weapons[(GameState.weapon_index + 1) % weapons.size()]


## 冲刺 / 翻滚：在 time 秒内以固定速度移动，期间无敌。
func start_dash(dash_velocity: Vector2, time: float) -> void:
	_dash_velocity = dash_velocity
	_dash_time = time
	_afterimage_timer = 0.0
	sprite.rotation = 0.0
	var spin := TAU if dash_velocity.x >= 0.0 else -TAU
	var tween := create_tween()
	tween.tween_property(sprite, "rotation", spin, time)
	tween.tween_callback(func() -> void: sprite.rotation = 0.0)


func _update_dash(delta: float) -> void:
	velocity = _dash_velocity
	_dash_time -= delta
	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0:
		_afterimage_timer = 0.04
		_spawn_afterimage()


## 残影：复制一份当前的角色贴图，慢慢淡出。
func _spawn_afterimage() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.rotation = sprite.rotation
	ghost.global_position = sprite.global_position
	ghost.modulate = Color(0.45, 0.94, 0.97, 0.6)
	get_parent().add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)


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
