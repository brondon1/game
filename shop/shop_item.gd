class_name ShopItem
extends Area2D
## 商店里的一件商品：下方显示价格，玩家靠近时显示名字，按 E 花金币购买。

enum Kind { WEAPON, ITEM, BUFF }

const WEAPON_PICKUP_SCENE := preload("res://pickups/weapon_pickup.tscn")
const BUFF_ICON := preload("res://assets/sprites/buff_star.png")

@export var kind := Kind.ITEM
@export var price := 10
## 只有 kind 为 WEAPON 时使用
@export var weapon: WeaponData
## 只有 kind 为 ITEM 时使用：GameState.ITEMS 里的道具 id
@export var item_id := "potion"

@onready var sprite: Sprite2D = $Sprite2D
@onready var price_label: Label = $Price/PriceLabel
@onready var name_label: Label = $NameLabel


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	match kind:
		Kind.WEAPON:
			sprite.texture = weapon.texture
		Kind.ITEM:
			sprite.texture = GameState.ITEMS[item_id].icon
		Kind.BUFF:
			sprite.texture = BUFF_ICON
	price_label.text = str(price)
	name_label.text = "[E] 购买 " + _item_name()
	name_label.hide()
	var tween := create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -2.0, 0.7).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE)


func interact(_player: Player) -> void:
	if not GameState.spend_coins(price):
		Sound.play(Sound.DENIED, 0.0, 0.0)
		Events.message.emit("金币不足")
		price_label.modulate = Color("da4e38")
		create_tween().tween_property(price_label, "modulate", Color.WHITE, 0.5)
		return
	Sound.play(Sound.BUY, 0.0, 0.0)
	match kind:
		Kind.WEAPON:
			var dropped := GameState.pick_up_weapon(weapon)
			if dropped:
				# 背包满了：换下来的武器放在地上，想换回来可以再捡
				var pickup: WeaponPickup = WEAPON_PICKUP_SCENE.instantiate()
				pickup.data = dropped
				pickup.position = position + Vector2(0, 20)
				get_parent().add_child.call_deferred(pickup)
		Kind.ITEM:
			GameState.use_item(item_id)
		Kind.BUFF:
			var buff: Dictionary = GameState.random_buffs(1)[0]
			GameState.apply_buff(buff.id)
			Events.message.emit("获得强化：" + buff.name)
	queue_free()


func _item_name() -> String:
	match kind:
		Kind.WEAPON:
			return weapon.describe()
		Kind.ITEM:
			var item: Dictionary = GameState.ITEMS[item_id]
			return "%s（%s）" % [item.name, item.desc]
	return "神秘强化（随机一个）"


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.add_interactable(self)
		name_label.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.remove_interactable(self)
		name_label.hide()
