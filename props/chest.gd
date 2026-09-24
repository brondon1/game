class_name Chest
extends StaticBody2D
## 宝箱：走近按 E 打开，奖励会从箱子里弹出来。
## 金宝箱（宝箱房）给一把武器和药水；补给箱（清完战斗房后可能出现）给金币和能量。

enum Kind { WEAPON, SUPPLY }

const PICKUP_SCENE := preload("res://pickups/pickup.tscn")
const WEAPON_PICKUP_SCENE := preload("res://pickups/weapon_pickup.tscn")
const TEXTURES := {
	Kind.WEAPON: [preload("res://assets/sprites/chest_gold_closed.png"), preload("res://assets/sprites/chest_gold_open.png")],
	Kind.SUPPLY: [preload("res://assets/sprites/chest_closed.png"), preload("res://assets/sprites/chest_open.png")],
}

@export var kind := Kind.SUPPLY

var opened := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $InteractArea
@onready var label: Label = $Label


func _ready() -> void:
	sprite.texture = TEXTURES[kind][0]
	BlobShadow.add_to(self, 1.2, Vector2(0, 0))
	label.hide()
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	# 出现时弹一下
	sprite.scale = Vector2(0.2, 0.2)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func interact(player: Player) -> void:
	if opened:
		return
	opened = true
	player.remove_interactable(self)
	label.hide()
	sprite.texture = TEXTURES[kind][1]
	Sound.play(Sound.CHEST_OPEN, 0.0, 0.0)
	sprite.scale = Vector2(1.2, 0.8)
	create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	_spawn_loot.call_deferred()


func _spawn_loot() -> void:
	match kind:
		Kind.WEAPON:
			var weapon: WeaponPickup = WEAPON_PICKUP_SCENE.instantiate()
			weapon.data = GameState.random_new_weapon()
			weapon.position = position + Vector2(-10, 18)
			get_parent().add_child(weapon)
			_drop(Pickup.Kind.HEALTH, 2, Vector2(12, 18))
		Kind.SUPPLY:
			for i in randi_range(3, 6):
				_drop(Pickup.Kind.COIN, 1, Vector2(randf_range(-14, 14), randf_range(10, 20)))
			for i in 2:
				_drop(Pickup.Kind.ENERGY, 8, Vector2(randf_range(-14, 14), randf_range(10, 20)))


func _drop(pickup_kind: Pickup.Kind, amount: int, offset: Vector2) -> void:
	var pickup: Pickup = PICKUP_SCENE.instantiate()
	pickup.kind = pickup_kind
	pickup.amount = amount
	pickup.position = position + offset
	get_parent().add_child(pickup)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not opened:
		body.add_interactable(self)
		label.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_interactable(self)
		label.hide()
