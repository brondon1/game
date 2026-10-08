class_name MerchantShop
extends CanvasLayer
## 大厅商人的商店：可升级的小道具（永久生效）、下一局带上的武器、下一局生效的增益。
## 每次回大厅进货一次（武器和增益随机）。打开时暂停游戏，Esc 或"离开"关闭。

signal closed

const COIN_TEXTURE := preload("res://assets/ui/coin.png")
const BUFF_ICON := preload("res://assets/sprites/buff_star.png")
const GOLD := Color(0.98, 0.796, 0.243)

var _weapons: Array[WeaponData] = []
var _buffs: Array = []
var _coin_icon: AtlasTexture

@onready var coins_label: Label = %Coins
@onready var list: VBoxContainer = %List
@onready var note: Label = %Note
@onready var close_button: Button = %CloseButton


func _ready() -> void:
	hide()
	_coin_icon = AtlasTexture.new()
	_coin_icon.atlas = COIN_TEXTURE
	_coin_icon.region = Rect2(0, 0, 8, 8)
	%CoinIcon.texture = _coin_icon
	close_button.pressed.connect(close)


## 进货：每次回大厅调用一次
func restock() -> void:
	_weapons = GameState.merchant_weapons(3)
	_buffs = GameState.merchant_buffs(3)


func open() -> void:
	_rebuild()
	show()
	get_tree().paused = true


func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


func _rebuild() -> void:
	coins_label.text = str(GameState.coins)
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	_section("小道具 · 升级后永久生效（所有角色）")
	for id: String in GameState.TRINKETS:
		var t: Dictionary = GameState.TRINKETS[id]
		var level := GameState.trinket_level(id)
		var price := GameState.trinket_price(id)
		var desc := "每级%s" % t.desc
		if level > 0:
			desc += "（现在 %d 级）" % level
		var label := "满级" if price < 0 else ("购买" if level == 0 else "升级")
		_row(t.icon, "%s  Lv.%d/%d" % [t.name, level, t.max], desc, label, price, _buy_trinket.bind(id))
	_section("武器 · 下一局开局带上")
	for weapon in _weapons:
		var stats := "近战" if weapon.is_melee else "能耗 %d" % weapon.energy_cost
		var owned := GameState.next_weapon == weapon
		_row(weapon.texture, weapon.display_name, "伤害 %d · %s" % [weapon.damage, stats],
			"已预定" if owned else "购买", -1 if owned else GameState.NEXT_WEAPON_PRICE, _buy_weapon.bind(weapon))
	_section("增益 · 只在下一局生效")
	for buff: Dictionary in _buffs:
		var owned := GameState.next_buffs.has(buff.id)
		_row(BUFF_ICON, buff.name, String(buff.desc).replace("\n", "，"),
			"已买" if owned else "购买", -1 if owned else GameState.NEXT_BUFF_PRICE, _buy_buff.bind(buff.id))
	_refresh_note()
	var first := list.find_children("*", "Button", true, false).filter(func(b: Button) -> bool: return not b.disabled)
	(func() -> void:
		var target: Control = first[0] if not first.is_empty() else close_button
		if is_instance_valid(target) and target.is_inside_tree():
			target.grab_focus()).call_deferred()


func _section(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", GOLD)
	list.add_child(label)


## 一行商品：图标、名字、说明、价格按钮。price < 0 表示不能买（满级 / 已经买了），按钮变灰。
func _row(icon: Texture2D, title: String, desc: String, action: String, price: int, on_buy: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var pic := TextureRect.new()
	pic.texture = icon
	pic.custom_minimum_size = Vector2(32, 16)
	pic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	pic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pic)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label := Label.new()
	name_label.text = title
	text.add_child(name_label)
	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.modulate.a = 0.7
	text.add_child(desc_label)
	row.add_child(text)
	var button := Button.new()
	button.custom_minimum_size = Vector2(72, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if price < 0:
		button.text = action
		button.disabled = true
	else:
		button.text = "%s %d" % [action, price]
		button.icon = _coin_icon
		button.disabled = GameState.coins < price
		button.pressed.connect(on_buy)
	row.add_child(button)
	list.add_child(row)


func _refresh_note() -> void:
	var parts: Array[String] = []
	if GameState.next_weapon:
		parts.append(GameState.next_weapon.display_name)
	for id in GameState.next_buffs:
		parts.append(GameState.buff_name(id))
	note.text = "下一局带上：" + ("、".join(parts) if not parts.is_empty() else "无")


func _buy_trinket(id: String) -> void:
	_after_buy(GameState.buy_trinket(id))


func _buy_weapon(weapon: WeaponData) -> void:
	_after_buy(GameState.buy_next_weapon(weapon))


func _buy_buff(id: String) -> void:
	_after_buy(GameState.buy_next_buff(id))


func _after_buy(ok: bool) -> void:
	Sound.play(Sound.BUY if ok else Sound.DENIED, 0.0, 0.0)
	_rebuild.call_deferred() # 等按钮的信号处理完再重建列表
