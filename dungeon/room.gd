class_name Room
extends Node2D
## 地牢里的一个房间。战斗房和 Boss 房：玩家走进来后关门、分波刷怪，全部清完后开门。
## 宝箱房放一把武器和药水，商店房放商人和商品。

enum Type { START, BATTLE, CHEST, BOSS, SHOP }
enum State { IDLE, FIGHTING, CLEARED }

const SLIME_SCENE := preload("res://enemies/slime.tscn")
const GUNNER_SCENE := preload("res://enemies/gunner.tscn")
const BOSS_SCENE := preload("res://enemies/boss.tscn")
const PICKUP_SCENE := preload("res://pickups/pickup.tscn")
const WEAPON_PICKUP_SCENE := preload("res://pickups/weapon_pickup.tscn")
const SHOP_ITEM_SCENE := preload("res://shop/shop_item.tscn")
const MERCHANT_TEXTURE := preload("res://assets/sprites/merchant.png")

## 玩家要走进房间多深（像素）才触发关门，保证不会被门卡住
const TRIGGER_INSET := 24.0

var type := Type.BATTLE
## 房间内部（可行走区域）的世界坐标范围
var rect := Rect2()
var doors: Array[Door] = []
## 在地牢网格里的坐标（小地图用）
var cell := Vector2i.ZERO
## 玩家是否进过这个房间（小地图用）
var visited := false

var _state := State.IDLE
var _entities: Node2D
var _waves_left := 0
var _alive := 0


func setup(p_type: Type, p_rect: Rect2, entities: Node2D) -> void:
	type = p_type
	rect = p_rect
	_entities = entities


func _ready() -> void:
	match type:
		Type.BATTLE, Type.BOSS:
			_create_trigger()
		Type.CHEST:
			_state = State.CLEARED
			_spawn_chest_loot()
		Type.SHOP:
			_state = State.CLEARED
			_spawn_shop()
		_:
			_state = State.CLEARED


func is_cleared() -> bool:
	return _state == State.CLEARED


func _create_trigger() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = Bullet.LAYER_PLAYER
	area.monitorable = false
	area.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size - Vector2.ONE * TRIGGER_INSET * 2.0
	shape.shape = rect_shape
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_trigger_body_entered)


func _on_trigger_body_entered(body: Node2D) -> void:
	if _state != State.IDLE or not body is Player:
		return
	_state = State.FIGHTING
	if type == Type.BOSS:
		_waves_left = 1
	else:
		_waves_left = 2 if GameState.current_floor == 1 else 3
	for door in doors:
		door.set_closed(true)
	Sound.play(Sound.DOOR)
	if type == Type.BOSS:
		Sound.play_music(Sound.MUSIC_BOSS)
	_spawn_wave.call_deferred()


func _spawn_wave() -> void:
	_waves_left -= 1
	var wave: Array[PackedScene] = _random_wave()
	if type == Type.BOSS:
		wave.assign([BOSS_SCENE])
	for scene in wave:
		var enemy: Enemy = scene.instantiate()
		enemy.position = rect.get_center() if type == Type.BOSS else _random_spawn_point()
		enemy.hp_multiplier = GameState.enemy_hp_mult()
		enemy.died.connect(_on_enemy_died)
		_entities.add_child(enemy)
		_alive += 1


## 一波敌人的组成：楼层越高越多，远程怪比例越高。
func _random_wave() -> Array[PackedScene]:
	var count := 2 + GameState.current_floor + randi_range(0, 1)
	var gunner_chance := 0.25 + 0.1 * GameState.current_floor
	var wave: Array[PackedScene] = []
	for i in count:
		wave.append(GUNNER_SCENE if randf() < gunner_chance else SLIME_SCENE)
	return wave


func _random_spawn_point() -> Vector2:
	var area := rect.grow(-32.0)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var point := area.get_center()
	for i in 20:
		point = Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if player == null or point.distance_to(player.global_position) > 80.0:
			break
	return point


func _on_enemy_died(_enemy: Enemy) -> void:
	_alive -= 1
	if _alive > 0:
		return
	if _waves_left > 0:
		get_tree().create_timer(0.8, false).timeout.connect(_spawn_wave)
	else:
		_clear()


func _clear() -> void:
	_state = State.CLEARED
	for door in doors:
		door.set_closed(false)
	Sound.play(Sound.DOOR, -4.0)
	if type == Type.BOSS:
		Sound.play_music(Sound.MUSIC_DUNGEON)
	Events.room_cleared.emit(self)


func _spawn_chest_loot() -> void:
	var weapon_pickup: WeaponPickup = WEAPON_PICKUP_SCENE.instantiate()
	weapon_pickup.data = GameState.random_new_weapon()
	weapon_pickup.position = rect.get_center() + Vector2(-20, 0)
	_entities.add_child(weapon_pickup)

	var potion: Pickup = PICKUP_SCENE.instantiate()
	potion.kind = Pickup.Kind.HEALTH
	potion.amount = 2
	potion.position = rect.get_center() + Vector2(20, 0)
	_entities.add_child(potion)


func _spawn_shop() -> void:
	var center := rect.get_center()
	var merchant := Sprite2D.new()
	merchant.texture = MERCHANT_TEXTURE
	merchant.position = center + Vector2(0, -30)
	merchant.offset = Vector2(0, -6)
	_entities.add_child(merchant)

	# 商品：一把随机武器、药水、能量、神秘强化。价格随楼层上涨一点。
	var floor_bonus := (GameState.current_floor - 1) * 2
	var goods := [
		[ShopItem.Kind.WEAPON, 18 + floor_bonus],
		[ShopItem.Kind.POTION, 10 + floor_bonus],
		[ShopItem.Kind.ENERGY, 6 + floor_bonus],
		[ShopItem.Kind.BUFF, 30 + floor_bonus * 2],
	]
	for i in goods.size():
		var item: ShopItem = SHOP_ITEM_SCENE.instantiate()
		item.kind = goods[i][0]
		item.price = goods[i][1]
		if item.kind == ShopItem.Kind.WEAPON:
			item.weapon = GameState.random_new_weapon()
		item.position = center + Vector2(-54 + i * 36, 10)
		_entities.add_child(item)
