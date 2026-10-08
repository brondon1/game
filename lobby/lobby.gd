extends Node2D
## 大厅（游戏启动后的第一个场景）：所有角色和商人都站在这里。
## - 走近角色按 E（手机上点手形按钮）对话：聊天、花经验升级、选这个角色
## - 走近商人按 E 交易：用金币买可升级的小道具、下一局带上的武器和增益
## - 走进上方的传送门：开始游戏 / 退出游戏

const TILE_SIZE := 16
## 大厅的地板范围（瓦片坐标）
const ROOM := Rect2i(0, 0, 22, 12)
## 传送门和玩家出生点（瓦片坐标）
const PORTAL_CELL := Vector2i(11, 2)
const MERCHANT_CELL := Vector2i(3, 10)
const MERCHANT_TEXTURE := preload("res://assets/sprites/merchant_idle.png")
const START_CELL := Vector2i(11, 10)
## 大厅不大，用一个固定的镜头一次看全（屏幕上方留出左上角信息栏的位置）
const CAMERA_CENTER := Vector2(176, 78)
const NPC_SCENE := preload("res://lobby/lobby_npc.tscn")
const PLAYER_SCENE := preload("res://player/player.tscn")
const PORTAL_SCENE := preload("res://dungeon/portal.tscn")
const TORCH_SCENE := preload("res://props/torch.tscn")
## 角色站的位置（瓦片坐标），左边 3 个、右边 3 个
const NPC_CELLS: Array[Vector2i] = [
	Vector2i(3, 5), Vector2i(5, 7), Vector2i(7, 5),
	Vector2i(14, 5), Vector2i(16, 7), Vector2i(18, 5),
]

var _npcs: Array[LobbyNpc] = []
## 正在对话的角色，和这个角色已经说到第几句
var _talking: LobbyNpc
var _line_index := 0
var _portal: Portal

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
	_portal = PORTAL_SCENE.instantiate()
	_portal.position = _cell_center(PORTAL_CELL)
	_portal.player_entered.connect(_on_portal_entered)
	entities.add_child(_portal)
	player.global_position = _cell_center(START_CELL)
	player.get_node("Camera2D").enabled = false
	camera.position = CAMERA_CENTER
	camera.make_current()
	_refresh()
	hint.text = ("左边拖动移动 · 手形按钮和角色对话、找商人交易 · 走进传送门出发" if TouchControls.active
		else "WASD 移动 · E 和角色对话、找商人交易 · 走进传送门出发")
	Sound.play_music(Sound.MUSIC_DUNGEON)


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * TILE_SIZE) + Vector2.ONE * TILE_SIZE * 0.5


## 铺地板和墙，上方墙面挂火把（传送门正上方空出来）
func _build_room() -> void:
	var floor_cells := {}
	for x in range(ROOM.position.x, ROOM.end.x):
		for y in range(ROOM.position.y, ROOM.end.y):
			floor_cells[Vector2i(x, y)] = true
	TilePainter.paint(tile_map, floor_cells, TilePainter.walls_around(floor_cells))
	for x in range(ROOM.position.x + 2, ROOM.end.x - 1, 4):
		if absi(x - PORTAL_CELL.x) <= 2:
			continue
		var torch: Torch = TORCH_SCENE.instantiate()
		torch.position = Vector2(Vector2i(x, ROOM.position.y - 1) * TILE_SIZE) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.6)
		decor_root.add_child(torch)


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
