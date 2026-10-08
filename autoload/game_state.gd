extends Node
## 一局游戏的全部状态（跨楼层保留），以及最高纪录的存档。

signal stats_changed
signal weapons_changed

const SAVE_PATH := "user://save.cfg"
const FINAL_FLOOR := 6
## 每两层是一个章节，换一种环境色调。[章节名, 环境光颜色]
const CHAPTERS := [
	["地牢入口", Color(0.7, 0.66, 0.68)],
	["冰封墓穴", Color(0.5, 0.6, 0.88)],
	["熔岩深渊", Color(0.82, 0.56, 0.52)],
]
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

## 消耗品（药水）：商店卖、宝箱里掉。新增道具：在这里加一条，再在 use_item() 里写效果。
const ITEMS := {
	"potion": {"name": "生命药水", "desc": "+2 生命", "price": 10, "icon": preload("res://assets/sprites/potion.png")},
	"big_potion": {"name": "大生命药水", "desc": "生命回满", "price": 20, "icon": preload("res://assets/sprites/big_potion.png")},
	"energy": {"name": "能量瓶", "desc": "+100 能量", "price": 6, "icon": preload("res://assets/sprites/energy.png")},
	"big_energy": {"name": "大能量瓶", "desc": "能量回满", "price": 12, "icon": preload("res://assets/sprites/big_energy.png")},
	"strength": {"name": "力量药剂", "desc": "30 秒内伤害 +50%", "price": 15, "icon": preload("res://assets/sprites/strength_potion.png")},
	"swift": {"name": "疾风药剂", "desc": "30 秒内移速、射速 +30%", "price": 12, "icon": preload("res://assets/sprites/swift_potion.png")},
}
## 限时药剂的持续时间（秒）
const BOOST_TIME := 30.0

## 角色等级：每个角色单独升级，经验存档。每通过一层获得经验（越深越多），
## 升级依次提升护盾、生命、能量上限。LEVEL_REWARDS 的第 i 项是升到第 i + 2 级时的奖励。
const MAX_LEVEL := 10
const LEVEL_REWARDS := [
	["shield", 1], ["hp", 1], ["energy", 30],
	["shield", 1], ["hp", 1], ["energy", 30],
	["shield", 1], ["hp", 1], ["shield", 1],
]
const REWARD_NAMES := {"shield": "护盾上限", "hp": "生命上限", "energy": "能量上限"}

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
	preload("res://weapons/data/sniper.tres"),
	preload("res://weapons/data/tesla.tres"),
	preload("res://weapons/data/fire_staff.tres"),
	preload("res://weapons/data/poison_staff.tres"),
	preload("res://weapons/data/katana.tres"),
	preload("res://weapons/data/axe.tres"),
	preload("res://weapons/data/mace.tres"),
	preload("res://weapons/data/golden_sword.tres"),
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
## 每个角色的累计经验（角色 id → 经验），角色 id 是资源文件名（knight、ranger……）
var character_xp := {}
## 本局获得的经验（结算界面显示）
var run_xp := 0
## 正在生效的限时药剂：道具 id → 剩余秒数
var boosts := {}

## 设置：门关上（在打怪）时自动开火（保存在 settings.cfg，由 Sound 读写）
var auto_fire := true
## 当前是否在锁门的战斗房里（房间锁门时设为 true，清空后设为 false）
var in_combat := false


func _ready() -> void:
	for path in CHARACTER_PATHS:
		characters.append(load(path))
	character = characters[0]
	_load_record()
	new_run()


func new_run() -> void:
	current_floor = 1
	in_combat = false
	coins = 0
	kills = 0
	var bonus := level_bonus(character)
	max_hp = character.max_hp + bonus.hp
	hp = max_hp
	max_shield = character.max_shield + bonus.shield
	shield = max_shield
	max_energy = character.max_energy + bonus.energy
	energy = max_energy
	run_xp = 0
	damage_mult = 1.0
	fire_rate_mult = 1.0
	speed_mult = 1.0
	boosts.clear()
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


## 当前楼层属于第几章（从 0 开始）
@warning_ignore("integer_division")
func chapter() -> int:
	return clampi((current_floor - 1) * CHAPTERS.size() / FINAL_FLOOR, 0, CHAPTERS.size() - 1)


func chapter_name() -> String:
	return CHAPTERS[chapter()][0]


func room_count() -> int:
	return 6 + current_floor


func enemy_hp_mult() -> float:
	return 1.0 + 0.25 * (current_floor - 1)


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


# ---------- 道具 ----------

func use_item(id: String) -> void:
	match id:
		"potion":
			heal(2)
		"big_potion":
			heal(max_hp)
		"energy":
			add_energy(100)
		"big_energy":
			add_energy(max_energy)
		"strength", "swift":
			if not boosts.has(id):
				_set_boost(id, true)
			boosts[id] = BOOST_TIME # 再喝一瓶只刷新时间，不叠加
	stats_changed.emit()


## 随机一种道具（商店、宝箱用）
func random_item() -> String:
	return ITEMS.keys().pick_random()


func _set_boost(id: String, on: bool) -> void:
	var factor := 1.0 if on else -1.0
	match id:
		"strength":
			damage_mult += 0.5 * factor
		"swift":
			speed_mult += 0.3 * factor
			fire_rate_mult += 0.3 * factor


func _process(delta: float) -> void:
	for id: String in boosts.keys():
		boosts[id] -= delta
		if boosts[id] <= 0.0:
			boosts.erase(id)
			_set_boost(id, false)
			stats_changed.emit()


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


# ---------- 角色等级 ----------

static func character_id(ch: CharacterData) -> String:
	return ch.resource_path.get_file().get_basename()


func xp_of(ch: CharacterData) -> int:
	return character_xp.get(character_id(ch), 0)


## 升到 level 级一共需要多少经验（1 级是 0）。每升一级比上一级多要 20 点。
static func xp_for_level(level: int) -> int:
	var total := 0
	for l in range(1, level):
		total += 40 + 20 * (l - 1)
	return total


func level_of(ch: CharacterData) -> int:
	var xp := xp_of(ch)
	var level := 1
	while level < MAX_LEVEL and xp >= xp_for_level(level + 1):
		level += 1
	return level


## 这个角色因为等级获得的属性加成：{"shield": .., "hp": .., "energy": ..}
func level_bonus(ch: CharacterData) -> Dictionary:
	var bonus := {"shield": 0, "hp": 0, "energy": 0}
	for i in level_of(ch) - 1:
		bonus[LEVEL_REWARDS[i][0]] += LEVEL_REWARDS[i][1]
	return bonus


## 通过一层获得的经验：越深越多
func floor_xp(floor_number: int) -> int:
	return 15 + 10 * floor_number


## 通过当前这一层：给当前角色加经验并存档。升级的奖励立即生效（本局也能用上）。
## 返回 {"xp": 获得的经验, "level": 现在的等级, "rewards": 这次升级获得的奖励说明}
func grant_floor_xp() -> Dictionary:
	var old_level := level_of(character)
	var gained := floor_xp(current_floor)
	character_xp[character_id(character)] = xp_of(character) + gained
	run_xp += gained
	var new_level := level_of(character)
	var rewards: Array[String] = []
	for i in range(old_level - 1, new_level - 1):
		var stat: String = LEVEL_REWARDS[i][0]
		var amount: int = LEVEL_REWARDS[i][1]
		rewards.append("%s +%d" % [REWARD_NAMES[stat], amount])
		match stat:
			"shield":
				max_shield += amount
				shield += amount
			"hp":
				max_hp += amount
				hp += amount
			"energy":
				max_energy += amount
				energy += amount
	stats_changed.emit()
	_save()
	return {"xp": gained, "level": new_level, "rewards": rewards}


# ---------- 存档 ----------

func record_run(won: bool) -> void:
	best_floor = maxi(best_floor, current_floor)
	if won:
		wins += 1
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("record", "best_floor", best_floor)
	cfg.set_value("record", "wins", wins)
	cfg.set_value("record", "character", characters.find(character))
	for id: String in character_xp:
		cfg.set_value("xp", id, character_xp[id])
	cfg.save(SAVE_PATH)


func _load_record() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		best_floor = cfg.get_value("record", "best_floor", 0)
		wins = cfg.get_value("record", "wins", 0)
		var index: int = cfg.get_value("record", "character", 0)
		if cfg.has_section("xp"):
			for id in cfg.get_section_keys("xp"):
				character_xp[id] = cfg.get_value("xp", id, 0)
		character = characters[clampi(index, 0, characters.size() - 1)]
