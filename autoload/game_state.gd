extends Node
## 一局游戏的全部状态（跨楼层保留），以及最高纪录的存档。

signal stats_changed
signal weapons_changed

const SAVE_PATH := "user://save.cfg"
const FINAL_FLOOR := 3
const MAX_WEAPONS := 2

## 每层通关后三选一的强化。新增 Buff：在这里加一条，再在 apply_buff() 里写效果。
const BUFFS := [
	{"id": "max_hp", "name": "强健体魄", "desc": "生命上限 +2\n并回满生命"},
	{"id": "max_shield", "name": "坚固护甲", "desc": "护盾上限 +1"},
	{"id": "max_energy", "name": "能量扩容", "desc": "能量上限 +60\n并回满能量"},
	{"id": "damage", "name": "锋利子弹", "desc": "所有武器伤害 +25%"},
	{"id": "fire_rate", "name": "快速扳机", "desc": "射速 +20%"},
	{"id": "speed", "name": "轻盈步伐", "desc": "移动速度 +15%"},
	{"id": "heal", "name": "急救包", "desc": "立即回复 3 点生命"},
]

## 主菜单里可选的角色。新增角色：新建一个 CharacterData 资源，把路径加进来。
## （角色 → 技能脚本 → 又会用到 GameState，所以这里不能 preload，在 _ready 里再加载）
const CHARACTER_PATHS: Array[String] = [
	"res://characters/knight.tres",
	"res://characters/ranger.tres",
	"res://characters/mage.tres",
	"res://characters/assassin.tres",
	"res://characters/engineer.tres",
	"res://characters/berserker.tres",
]
var characters: Array[CharacterData] = []
## 本局使用的角色
var character: CharacterData
## 宝箱房会从这里随机掉落武器。新增武器：新建一个 WeaponData 资源并加进来。
var weapon_pool: Array[WeaponData] = [
	preload("res://weapons/data/shotgun.tres"),
	preload("res://weapons/data/smg.tres"),
	preload("res://weapons/data/rifle.tres"),
	preload("res://weapons/data/sword.tres"),
	preload("res://weapons/data/hammer.tres"),
	preload("res://weapons/data/rocket_launcher.tres"),
	preload("res://weapons/data/bouncer.tres"),
	preload("res://weapons/data/frost_staff.tres"),
	preload("res://weapons/data/crossbow.tres"),
	preload("res://weapons/data/minigun.tres"),
	preload("res://weapons/data/spear.tres"),
	preload("res://weapons/data/dagger.tres"),
]

var current_floor := 1
var coins := 0
var kills := 0

var max_hp := 6
var hp := 6
var max_shield := 4
var shield := 4
var max_energy := 180
var energy := 180

var damage_mult := 1.0
var fire_rate_mult := 1.0
var speed_mult := 1.0

var weapons: Array[WeaponData] = []
var weapon_index := 0

var best_floor := 0
var wins := 0


func _ready() -> void:
	for path in CHARACTER_PATHS:
		characters.append(load(path))
	character = characters[0]
	_load_record()
	new_run()


func new_run() -> void:
	current_floor = 1
	coins = 0
	kills = 0
	max_hp = character.max_hp
	hp = max_hp
	max_shield = character.max_shield
	shield = max_shield
	max_energy = character.max_energy
	energy = max_energy
	damage_mult = 1.0
	fire_rate_mult = 1.0
	speed_mult = 1.0
	weapons = [character.starting_weapon]
	weapon_index = 0
	stats_changed.emit()
	weapons_changed.emit()


# ---------- 楼层 ----------

func next_floor() -> void:
	current_floor += 1
	stats_changed.emit()


func is_final_floor() -> bool:
	return current_floor >= FINAL_FLOOR


func room_count() -> int:
	return 5 + current_floor * 2


func enemy_hp_mult() -> float:
	return 1.0 + 0.35 * (current_floor - 1)


# ---------- 数值 ----------

## 受到伤害：先扣护盾，再扣生命。
func apply_damage(amount: int) -> void:
	var absorbed := mini(shield, amount)
	shield -= absorbed
	hp = maxi(hp - (amount - absorbed), 0)
	stats_changed.emit()


func restore_shield(amount: int) -> void:
	shield = mini(shield + amount, max_shield)
	stats_changed.emit()


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	stats_changed.emit()


func use_energy(cost: int) -> bool:
	if energy < cost:
		return false
	energy -= cost
	stats_changed.emit()
	return true


func add_energy(amount: int) -> void:
	energy = mini(energy + amount, max_energy)
	stats_changed.emit()


func add_coins(amount: int) -> void:
	coins += amount
	stats_changed.emit()


## 花金币，不够就返回 false。
func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	stats_changed.emit()
	return true


# ---------- 武器 ----------

func current_weapon() -> WeaponData:
	return null if weapons.is_empty() else weapons[weapon_index]


func switch_weapon() -> void:
	if weapons.size() > 1:
		weapon_index = (weapon_index + 1) % weapons.size()
		weapons_changed.emit()


## 拾取武器。背包满了就替换当前武器，并返回被换下的武器（没有则返回 null）。
func pick_up_weapon(data: WeaponData) -> WeaponData:
	if weapons.size() < MAX_WEAPONS:
		weapons.append(data)
		weapon_index = weapons.size() - 1
		weapons_changed.emit()
		return null
	var old := weapons[weapon_index]
	weapons[weapon_index] = data
	weapons_changed.emit()
	return old


## 随机一把玩家还没有的武器。
func random_new_weapon() -> WeaponData:
	var candidates := weapon_pool.filter(func(w: WeaponData) -> bool: return not weapons.has(w))
	return weapon_pool.pick_random() if candidates.is_empty() else candidates.pick_random()


# ---------- Buff ----------

func random_buffs(count: int) -> Array:
	var pool := BUFFS.duplicate()
	pool.shuffle()
	return pool.slice(0, count)


func apply_buff(id: String) -> void:
	match id:
		"max_hp":
			max_hp += 2
			hp = max_hp
		"max_shield":
			max_shield += 1
			shield = max_shield
		"max_energy":
			max_energy += 60
			energy = max_energy
		"damage":
			damage_mult += 0.25
		"fire_rate":
			fire_rate_mult += 0.2
		"speed":
			speed_mult += 0.15
		"heal":
			hp = mini(hp + 3, max_hp)
	stats_changed.emit()


# ---------- 存档 ----------

func record_run(won: bool) -> void:
	best_floor = maxi(best_floor, current_floor)
	if won:
		wins += 1
	var cfg := ConfigFile.new()
	cfg.set_value("record", "best_floor", best_floor)
	cfg.set_value("record", "wins", wins)
	cfg.set_value("record", "character", characters.find(character))
	cfg.save(SAVE_PATH)


func _load_record() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_floor = cfg.get_value("record", "best_floor", 0)
		wins = cfg.get_value("record", "wins", 0)
		var index: int = cfg.get_value("record", "character", 0)
		character = characters[clampi(index, 0, characters.size() - 1)]
