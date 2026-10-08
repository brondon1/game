extends Node2D
## 大厅（游戏启动后的第一个场景）：所有角色和商人都站在这里。
## - 走近角色按 E（手机上点手形按钮）对话：聊天、花经验升级、选这个角色
## - 走近商人按 E 交易：用金币买可升级的小道具、下一局带上的武器和增益
## - 最左边的门：走近时门打开、露出传送门，走进去选择开始游戏 / 退出游戏

const TILE_SIZE := 16
## 大厅的地板范围（瓦片坐标）
const ROOM := Rect2i(0, 0, 22, 11)
## 去地牢的门在最左边的墙上（像素坐标）。传送门的旋涡画在门上、盖住门；走进去的触发范围在门口的地板上。
## 玩家走到这么近，门才打开、传送门才出现
const DOOR_POS := Vector2(24, -18)
const PORTAL_POS := Vector2(24, 14)
const PORTAL_REVEAL_DISTANCE := 44.0
## 玩家出生点（瓦片坐标）
const MERCHANT_CELL := Vector2i(3, 9)
const MERCHANT_TEXTURE := preload("res://assets/sprites/merchant_idle.png")
const START_CELL := Vector2i(11, 9)
## 大厅不大，用一个固定的镜头一次看全（包括上方三格高的墙）
const CAMERA_CENTER := Vector2(176, 72)
const NPC_SCENE := preload("res://lobby/lobby_npc.tscn")
const PLAYER_SCENE := preload("res://player/player.tscn")
const PORTAL_SCENE := preload("res://dungeon/portal.tscn")
const TORCH_SCENE := preload("res://props/torch.tscn")
## 角色站的位置（瓦片坐标），地毯左边 3 个、右边 3 个
const NPC_CELLS: Array[Vector2i] = [
	Vector2i(3, 4), Vector2i(5, 6), Vector2i(7, 4),
	Vector2i(15, 4), Vector2i(17, 6), Vector2i(19, 4),
]

# ---------- 家具 ----------
# 大厅是"家"：木地板、贴墙纸的墙（比地牢多两格高：墙纸 + 顶上的线脚），再摆上家具。
const HOME := "res://assets/sprites/home/"
## 墙纸和墙顶线脚（home_tiles.png 第二行最后两格，地牢的瓦片里没有）
const UPPER_WALL_TILE := Vector2i(11, 1)
const CROWN_TILE := Vector2i(12, 1)
## 挂在墙上的东西：[贴图, 中心位置（像素）, 左右翻转]
const WALL_DECOR := [
	["window.png", Vector2(118, -28), false],
	["window.png", Vector2(250, -28), false],
	["painting.png", Vector2(284, -26), true],
]
## 立在地上的家具：[贴图, 底边中点（像素）, 挡路的碰撞框大小（为 0 就不挡路）]
const FURNITURE := [
	["bookshelf.png", Vector2(326, 6), Vector2(28, 10)],
	["plant.png", Vector2(100, 6), Vector2(12, 6)],
	["plant.png", Vector2(298, 6), Vector2(12, 6)],
	["plant.png", Vector2(10, 174), Vector2(12, 6)],
	["bed.png", Vector2(338, 176), Vector2(22, 30)],
	["table.png", Vector2(272, 160), Vector2(30, 10)],
	["chair_left.png", Vector2(250, 160), Vector2.ZERO],
	["chair_right.png", Vector2(294, 160), Vector2.ZERO],
	["barrel.png", Vector2(22, 146), Vector2(12, 6)],
	["barrel.png", Vector2(30, 160), Vector2(12, 6)],
]
const FIREPLACE_POS := Vector2(68, 8)
const RUG_CENTER := Vector2(184, 100)
## 炉火和烛光是暖色，窗户透进来的是冷色的天光
const FIRE_LIGHT := Color(1, 0.62, 0.32)
const CANDLE_LIGHT := Color(1, 0.8, 0.5)
const WINDOW_LIGHT := Color(0.62, 0.78, 1)

var _npcs: Array[LobbyNpc] = []
## 正在对话的角色，和这个角色已经说到第几句
var _talking: LobbyNpc
var _line_index := 0
var _portal: Portal
var _door: Sprite2D
## 传送门现在是否露出来（门是否开着）
var _portal_open := false

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var decor_root: Node2D = $Decor
@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player
@onready var dialog: LobbyDialog = $LobbyDialog
@onready var shop: MerchantShop = $MerchantShop
@onready var info: Label = %Info
@onready var hint: Label = %Hint
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	get_tree().paused = false
	GameState.new_run() # 大厅里也拿着当前角色的初始武器，可以试枪
	_build_room()
	for i in GameState.characters.size():
		var npc: LobbyNpc = NPC_SCENE.instantiate()
		npc.character = GameState.characters[i]
		npc.position = _cell_center(NPC_CELLS[i % NPC_CELLS.size()])
		npc.talked.connect(_on_npc_talked)
		entities.add_child(npc)
		_npcs.append(npc)
	var merchant: LobbyNpc = NPC_SCENE.instantiate()
	merchant.display_name = "商人"
	merchant.texture = MERCHANT_TEXTURE
	merchant.hframes = 4
	merchant.action = "交易"
	merchant.position = _cell_center(MERCHANT_CELL)
	merchant.talked.connect(func(_npc: LobbyNpc) -> void: shop.open())
	entities.add_child(merchant)
	shop.restock()
	shop.closed.connect(_refresh)
	_door = Sprite2D.new()
	_door.texture = load(HOME + "door.png")
	_door.hframes = 2
	_door.position = DOOR_POS
	decor_root.add_child(_door)
	_portal = PORTAL_SCENE.instantiate()
	_portal.position = PORTAL_POS
	_portal.player_entered.connect(_on_portal_entered)
	entities.add_child(_portal)
	for visual: Node2D in [_portal.sprite, _portal.get_node("PointLight2D")]:
		visual.position = DOOR_POS - PORTAL_POS + Vector2(0, 2) # 旋涡挪到门上
	_portal.hide() # 平时只看到门
	_portal.monitoring = false
	player.global_position = _cell_center(START_CELL)
	player.get_node("Camera2D").enabled = false
	camera.position = CAMERA_CENTER
	camera.make_current()
	_refresh()
	hint.text = ("左边拖动移动 · 手形按钮和角色对话、找商人交易 · 走到最左边的门出发" if TouchControls.active
		else "WASD 移动 · E 和角色对话、找商人交易 · 走到最左边的门出发")
	Sound.play_music(Sound.MUSIC_DUNGEON)


func _process(_delta: float) -> void:
	var near := is_instance_valid(player) and player.global_position.distance_to(PORTAL_POS) < PORTAL_REVEAL_DISTANCE
	if near != _portal_open:
		_set_portal_open(near)


## 走近：门打开，传送门弹出来；走远：传送门收起来，门关上
func _set_portal_open(opened: bool) -> void:
	_portal_open = opened
	_door.frame = 1 if opened else 0
	_portal.set_deferred("monitoring", opened)
	if opened:
		_portal.show()
		_portal.sprite.scale = Vector2.ZERO
		_portal.create_tween().tween_property(_portal.sprite, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sound.play(Sound.DOOR, -4.0)
	else:
		_portal.hide()
		_portal.reset()


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5


## 铺地板和墙：TilePainter 铺好一圈墙后，把上方的墙加高成"护墙板 + 墙纸 + 线脚"三层，
## 左右两边的侧墙也跟着加高，最后摆家具。
func _build_room() -> void:
	var floor_cells := {}
	for x in range(ROOM.position.x, ROOM.end.x):
		for y in range(ROOM.position.y, ROOM.end.y):
			floor_cells[Vector2i(x, y)] = true
	TilePainter.paint(tile_map, floor_cells, TilePainter.walls_around(floor_cells))
	var top := ROOM.position.y
	for x in range(ROOM.position.x, ROOM.end.x):
		tile_map.set_cell(Vector2i(x, top - 2), 0, UPPER_WALL_TILE)
		tile_map.set_cell(Vector2i(x, top - 3), 0, CROWN_TILE)
	for y in range(top - 3, ROOM.end.y):
		tile_map.set_cell(Vector2i(ROOM.position.x - 1, y), 0, TilePainter.WALL_SIDE_LEFT_TILE)
		tile_map.set_cell(Vector2i(ROOM.end.x, y), 0, TilePainter.WALL_SIDE_RIGHT_TILE)
	for x in range(ROOM.position.x - 1, ROOM.end.x + 1):
		tile_map.set_cell(Vector2i(x, top - 4), 0, TilePainter.WALL_TOP_TILE)
		tile_map.set_cell(Vector2i(x, ROOM.end.y), 0, TilePainter.WALL_TOP_TILE)
	_furnish()


func _furnish() -> void:
	var rug := Sprite2D.new()
	rug.texture = load(HOME + "rug.png")
	rug.position = RUG_CENTER
	decor_root.add_child(rug)
	for item: Array in WALL_DECOR:
		var sprite := Sprite2D.new()
		sprite.texture = load(HOME + item[0])
		sprite.position = item[1]
		sprite.flip_h = item[2]
		decor_root.add_child(sprite)
		if item[0] == "window.png":
			_add_light(decor_root, item[1] + Vector2(0, 34), WINDOW_LIGHT, 0.25, 1.1)
	for item: Array in FURNITURE:
		_add_furniture(item[0], item[1], item[2])
	# 壁炉：炉膛里是会跳动的火（借用火把的闪烁逻辑），照亮左上角
	var fireplace := _add_furniture("fireplace.png", FIREPLACE_POS, Vector2(34, 10))
	var fire: Torch = TORCH_SCENE.instantiate()
	fire.base_energy = 1.2
	fire.base_scale = 2.4
	fire.position = Vector2(0, -8)
	fireplace.add_child(fire)
	var fire_sprite: Sprite2D = fire.get_node("Sprite2D")
	fire_sprite.texture = load(HOME + "fire.png")
	fire.get_node("PointLight2D").color = FIRE_LIGHT
	# 桌上的蜡烛
	var table := entities.get_children().filter(func(n: Node) -> bool: return n.name == "Table").front() as Node2D
	var candle := Sprite2D.new()
	candle.texture = load(HOME + "candle.png")
	candle.material = preload("res://common/unshaded.tres")
	candle.position = Vector2(4, -22)
	table.add_child(candle)
	_add_light(candle, Vector2(0, -3), CANDLE_LIGHT, 0.8, 0.9)


## 立在地上的家具：贴图的底边对齐 base（参与 Y 排序，角色能走到它前面或后面），
## 底部有一块挡路的碰撞框。
func _add_furniture(file: String, base: Vector2, solid: Vector2) -> Node2D:
	var body := StaticBody2D.new()
	body.name = file.get_basename().to_pascal_case()
	body.position = base
	body.collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = load(HOME + file)
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5)
	body.add_child(sprite)
	if solid != Vector2.ZERO:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = solid
		shape.shape = rect
		shape.position = Vector2(0, -solid.y * 0.5)
		body.add_child(shape)
	entities.add_child(body)
	return body


func _add_light(parent: Node, pos: Vector2, color: Color, energy: float, scale: float) -> void:
	var light := PointLight2D.new()
	light.texture = preload("res://common/light_texture.tres")
	light.position = pos
	light.color = color
	light.energy = energy
	light.texture_scale = scale
	parent.add_child(light)


## 当前角色不站在人群里（玩家就是他）；左上角显示当前角色的等级、经验和金币
func _refresh() -> void:
	for npc in _npcs:
		npc.visible = npc.character != GameState.character
		npc.monitoring = npc.visible
	var ch := GameState.character
	info.text = "%s　Lv.%d · 经验 %d · 金币 %d" % [ch.display_name, GameState.level_of(ch), GameState.xp_of(ch), GameState.coins]


# ---------- 和角色对话 ----------

func _on_npc_talked(npc: LobbyNpc) -> void:
	_talking = npc
	_line_index = 0
	var ch := npc.character
	dialog.open(_dialog_title(ch), _line(ch), ch.icon(), _npc_buttons())


func _dialog_title(ch: CharacterData) -> String:
	return "%s　Lv.%d · 经验 %d" % [ch.display_name, GameState.level_of(ch), GameState.xp_of(ch)]


func _line(ch: CharacterData) -> String:
	if ch.lines.is_empty():
		return "……"
	return ch.lines[_line_index % ch.lines.size()]


func _npc_buttons() -> Array:
	var ch := _talking.character
	var buttons := [["聊天", _chat]]
	var level := GameState.level_of(ch)
	if level >= GameState.MAX_LEVEL:
		buttons.append(["已满级", func() -> void: pass, true])
	else:
		var can := GameState.can_upgrade(ch)
		buttons.append(["升级：%s（%s %d 经验）" % [GameState.next_reward_text(ch), "花费" if can else "需要",
			GameState.upgrade_cost(level)], _upgrade, not can])
	buttons.append(["选这个角色", _select])
	buttons.append(["离开", dialog.close])
	return buttons


func _chat() -> void:
	_line_index += 1
	dialog.set_body(_line(_talking.character))


func _upgrade() -> void:
	var ch := _talking.character
	if not GameState.upgrade(ch):
		return
	Sound.play(Sound.BUFF, 0.0, 0.0)
	var bonus := GameState.level_bonus(ch)
	var stats := "生命 %d" % (ch.max_hp + bonus.hp)
	if GameState.has_shield(ch):
		stats += " · 护盾 %d" % (ch.max_shield + bonus.shield)
	stats += " · 能量 %d" % (ch.max_energy + bonus.energy)
	dialog.title.text = _dialog_title(ch)
	dialog.set_body("变强了！现在的初始属性：%s" % stats)
	dialog.set_buttons(_npc_buttons())
	_refresh()


## 换成这个角色：在原地换掉玩家节点（外观、技能、初始武器都换成新角色的）
func _select() -> void:
	var ch := _talking.character
	GameState.select_character(ch)
	var old := player
	player = PLAYER_SCENE.instantiate()
	player.position = _talking.position
	entities.add_child(player)
	player.get_node("Camera2D").enabled = false
	old.queue_free()
	Sound.play(Sound.PICKUP_WEAPON, 0.0, 0.0)
	dialog.close()
	_refresh()


# ---------- 传送门 ----------

func _on_portal_entered() -> void:
	var buttons := [["开始游戏", _start]]
	if not (OS.has_feature("web") or OS.has_feature("ios")): # 网页版和 iOS 不能自己退出
		buttons.append(["退出游戏", get_tree().quit])
	buttons.append(["再逛逛", _stay])
	var ch := GameState.character
	var record := "最高纪录：第 %d 层 · 通关 %d 次" % [GameState.best_floor, GameState.wins] if GameState.best_floor > 0 else "还没进过地牢"
	dialog.open("传送门", "用%s（Lv.%d）出发去地牢？\n%s" % [ch.display_name, GameState.level_of(ch), record], null, buttons)


func _start() -> void:
	dialog.close()
	GameState.start_run() # 带上在商人那里买的武器和增益
	get_tree().change_scene_to_file("res://dungeon/dungeon.tscn")


func _stay() -> void:
	dialog.close()
	_portal.reset() # 走出去再走进来会再问一次
