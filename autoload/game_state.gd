extends Node
## 一局游戏的全部状态（跨楼层保留），以及最高纪录的存档。

signal stats_changed
signal weapons_changed

const SAVE_PATH := "user://save.cfg"
const FINAL_FLOOR := 12
## 每三层是一个章节，换一种环境色调，Boss 也升一阶（会更多技能、弹幕更密）。[章节名, 环境光颜色]
const CHAPTERS := [
	["地牢入口", Color(0.7, 0.66, 0.68)],
	["冰封墓穴", Color(0.5, 0.6, 0.88)],
	["熔岩深渊", Color(0.82, 0.56, 0.52)],
	["虚空王座", Color(0.66, 0.56, 0.86)],
]
const MAX_WEAPONS := 2

## 每层通关后三选一的强化。新增 Buff：在这里加一条，再在 apply_buff() 里写效果。
const BUFFS := [
	{"id": "max_hp", "name": "强健体魄", "desc": "生命上限 +2\n并回满生命"},
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

## 大厅商人卖的可升级小道具：买下是 1 级，之后可以继续升级，每级永久提升所有角色的属性（下一局生效）。
## 升到下一级的价格 = price × 下一级的等级。新增小道具：在这里加一条，再在 new_run() 里写效果。
const TRINKETS := {
	"amulet": {"name": "生命护符", "desc": "初始生命 +1", "max": 5, "price": 40, "icon": preload("res://assets/sprites/trinket_amulet.png")},
	"crystal": {"name": "能量水晶", "desc": "初始能量 +20", "max": 5, "price": 30, "icon": preload("res://assets/sprites/trinket_crystal.png")},
	"ring": {"name": "力量戒指", "desc": "伤害 +6%", "max": 5, "price": 50, "icon": preload("res://assets/sprites/trinket_ring.png")},
	"boots": {"name": "疾风之靴", "desc": "移速 +5%", "max": 5, "price": 35, "icon": preload("res://assets/sprites/trinket_boots.png")},
	"lucky_coin": {"name": "幸运金币", "desc": "过关金币 +20%", "max": 5, "price": 45, "icon": preload("res://assets/sprites/trinket_lucky_coin.png")},
}
## 大厅商人卖的"下一局带上"的武器和增益的价格
const NEXT_WEAPON_PRICE := 50
const NEXT_BUFF_PRICE := 30

## 角色等级：每个角色单独升级。在地牢里每通过一层获得经验（越深越多），回到大厅和角色对话、花经验升级，
## 永久提升角色的初始属性（只对新开的一局生效）。LEVEL_REWARDS 的第 i 项是升到第 i + 2 级时的奖励。
## 只有骑士有护盾，其他角色的"初始护盾 +1"换成"初始生命 +1"（见 reward_stat()）。
const MAX_LEVEL := 10
const LEVEL_REWARDS := [
	["shield", 1], ["hp", 1], ["energy", 30],
	["shield", 1], ["hp", 1], ["energy", 30],
	["shield", 1], ["hp", 1], ["shield", 1],
]
const REWARD_NAMES := {"shield": "初始护盾", "hp": "初始生命", "energy": "初始能量"}

## 可选的角色（都站在大厅里）。新增角色：新建一个 CharacterData 资源，把路径加进来。
## （角色 → 技能脚本 → 又会用到 GameState，所以这里不能 preload，在 _ready 里再加载）
const CHARACTER_PATHS: Array[String] = [
	"res://characters/knight.tres",
	"res://characters/ranger.tres",
	"res://characters/mage.tres",
	"res://characters/assassin.tres",
	"res://characters/engineer.tres",
	"res://characters/berserker.tres",
	"res://characters/mechanic.tres",
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
## 上一层打的是哪个 Boss（Room.BOSS_SCENES 的下标），下一层不会再抽到它
var last_boss := -1
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
## 每个角色还没花掉的经验、当前等级（角色 id → 数值），角色 id 是资源文件名（knight、ranger……）
var character_xp := {}
var character_level := {}
## 本局获得的经验（结算界面显示）
var run_xp := 0
## 正在生效的限时药剂：道具 id → 剩余秒数
var boosts := {}
## 小道具的等级（道具 id → 等级，没买过的不在里面）
var trinket_levels := {}
## 在大厅商人那里买的、下一局开局时生效的武器和增益（开局后清空）
var next_weapon: WeaponData
var next_buffs: Array[String] = []

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


## 重置一局的状态（金币不清零，会一直带着）。属性 = 角色基础 + 角色等级加成 + 小道具加成。
func new_run() -> void:
	current_floor = 1
	last_boss = -1
	in_combat = false
	kills = 0
	var bonus := level_bonus(character)
	max_hp = character.max_hp + bonus.hp + trinket_level("amulet")
	hp = max_hp
	max_shield = character.max_shield + bonus.shield
	shield = max_shield
	max_energy = character.max_energy + bonus.energy + 20 * trinket_level("crystal")
	energy = max_energy
	run_xp = 0
	damage_mult = 1.0 + 0.06 * trinket_level("ring")
	fire_rate_mult = 1.0
	speed_mult = 1.0 + 0.05 * trinket_level("boots")
	boosts.clear()
	weapons = [character.starting_weapon]
	weapon_index = 0
	stats_changed.emit()
	weapons_changed.emit()


## 从大厅出发：重置一局，再加上在商人那里买的"下一局"武器和增益（用掉就没了）。
func start_run() -> void:
	new_run()
	if next_weapon and not weapons.has(next_weapon):
		weapons.append(next_weapon)
		weapons_changed.emit()
	for id in next_buffs:
		apply_buff(id)
	next_weapon = null
	next_buffs.clear()
	save_progress()


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


## 每层的房间数：第 1 层 7 间，每两层多一间，第 12 层 12 间
@warning_ignore("integer_division")
func room_count() -> int:
	return 7 + (current_floor - 1) / 2


## 难度每层都往上调一点：敌人（包括 Boss）的血量、子弹速度、每波数量、每间房的波数
func enemy_hp_mult() -> float:
	return 1.0 + 0.2 * (current_floor - 1)


func enemy_bullet_speed_mult() -> float:
	return 1.0 + 0.04 * (current_floor - 1)


@warning_ignore("integer_division")
func wave_size() -> int:
	return mini(3 + (current_floor - 1) / 2, 8)


func waves_per_room() -> int:
	if current_floor == 1:
		return 2
	return 3 if current_floor < 7 else 4


## 随机挑这一层的 Boss（不和上一层重复），返回下标
func pick_boss(count: int) -> int:
	var choices: Array = range(count).filter(func(i: int) -> bool: return i != last_boss)
	last_boss = choices.pick_random()
	return last_boss


## Boss 的阶数（0～3）：跟着章节走，阶数越高 Boss 的技能越多、弹幕越密
func boss_tier() -> int:
	return chapter()


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


# ---------- 角色 ----------

## 选择要用的角色（在大厅里和角色对话时选），会存档，下次打开游戏还是它。
func select_character(ch: CharacterData) -> void:
	character = ch
	new_run()
	save_progress()


# ---------- 角色等级 ----------

static func character_id(ch: CharacterData) -> String:
	return ch.resource_path.get_file().get_basename()


## 这个角色还没花掉的经验
func xp_of(ch: CharacterData) -> int:
	return character_xp.get(character_id(ch), 0)


func level_of(ch: CharacterData) -> int:
	return character_level.get(character_id(ch), 1)


## 从 level 级升到下一级要花多少经验：40 起，每级多 20
static func upgrade_cost(level: int) -> int:
	return 40 + 20 * (level - 1)


func can_upgrade(ch: CharacterData) -> bool:
	var level := level_of(ch)
	return level < MAX_LEVEL and xp_of(ch) >= upgrade_cost(level)


## 下一级的奖励说明，比如"初始护盾 +1"；满级返回空字符串
func next_reward_text(ch: CharacterData) -> String:
	var level := level_of(ch)
	if level >= MAX_LEVEL:
		return ""
	return "%s +%d · 技能冷却 -%d%%" % [REWARD_NAMES[reward_stat(ch, level - 1)], LEVEL_REWARDS[level - 1][1],
		roundi(SKILL_COOLDOWN_PER_LEVEL * 100)]


# ---------- 法师流派 ----------

## 法师当前的流派和每个流派带的技能（流派 id → 技能下标），存档
var mage_branch := "arcane"
var mage_skills := {}
## 其他有多个可选技能的角色：角色 id → 带的技能下标
var skill_choices := {}


func is_mage(ch: CharacterData) -> bool:
	return ch != null and character_id(ch) == "mage"


## 角色的外观（法师按流派换外观）
func character_texture(ch: CharacterData) -> Texture2D:
	return MageBranches.texture(mage_branch) if is_mage(ch) else ch.texture


## 生成角色的技能（法师用当前流派带的那个技能）
func create_skill(ch: CharacterData) -> Skill:
	if is_mage(ch):
		return MageBranches.create_skill(mage_branch, mage_skill_index())
	if not ch.skill_options.is_empty():
		var path := ch.skill_options[clampi(skill_choice(ch), 0, ch.skill_options.size() - 1)]
		var skill: Skill = load(path).new()
		skill.name = path.get_file().get_basename().to_pascal_case()
		return skill
	return ch.skill_scene.instantiate()


## 有多个可选技能的角色（女巫、机械师……）现在带的是第几个
func skill_choice(ch: CharacterData) -> int:
	return skill_choices.get(character_id(ch), 0)


func set_skill_choice(ch: CharacterData, index: int) -> void:
	skill_choices[character_id(ch)] = index
	save_progress()


## 能不能换技能（法师换流派里的技能，其他角色在 skill_options 里选）
func has_skill_options(ch: CharacterData) -> bool:
	return is_mage(ch) or not ch.skill_options.is_empty()


func mage_skill_index(branch := "") -> int:
	return mage_skills.get(branch if branch != "" else mage_branch, 0)


func set_mage_branch(id: String) -> void:
	mage_branch = id
	save_progress()


func set_mage_skill(index: int) -> void:
	mage_skills[mage_branch] = index
	save_progress()


## 每升一级技能冷却缩短多少（Lv.10 一共 -36%）
const SKILL_COOLDOWN_PER_LEVEL := 0.04


## 技能冷却倍率：等级越高冷却越短
func skill_cooldown_mult(ch: CharacterData = null) -> float:
	return 1.0 - SKILL_COOLDOWN_PER_LEVEL * (level_of(ch if ch else character) - 1)


## 在大厅花经验升一级（只改初始属性，下一局开始生效）。经验不够或满级时返回 false。
func upgrade(ch: CharacterData) -> bool:
	if not can_upgrade(ch):
		return false
	var id := character_id(ch)
	character_xp[id] = xp_of(ch) - upgrade_cost(level_of(ch))
	character_level[id] = level_of(ch) + 1
	save_progress()
	return true


## 这个角色因为等级获得的属性加成：{"shield": .., "hp": .., "energy": ..}
func level_bonus(ch: CharacterData) -> Dictionary:
	var bonus := {"shield": 0, "hp": 0, "energy": 0}
	for i in level_of(ch) - 1:
		bonus[reward_stat(ch, i)] += LEVEL_REWARDS[i][1]
	return bonus


## 第 i 项升级奖励对这个角色加的是什么属性。只有骑士有护盾，其他角色的"护盾 +1"换成"生命 +1"。
static func reward_stat(ch: CharacterData, i: int) -> String:
	var stat: String = LEVEL_REWARDS[i][0]
	return "hp" if stat == "shield" and not has_shield(ch) else stat


## 这个角色有没有护盾（只有骑士有）
static func has_shield(ch: CharacterData) -> bool:
	return ch.max_shield > 0


## 通过一层获得的经验：越深越多
func floor_xp(floor_number: int) -> int:
	return 15 + 10 * floor_number


## 通过一层奖励的金币：越深越多，幸运金币每级再多 20%
func floor_coins(floor_number: int) -> int:
	return roundi((10 + 5 * floor_number) * (1.0 + 0.2 * trinket_level("lucky_coin")))


## 通过当前这一层：奖励金币并存档，返回奖励了多少
func grant_floor_coins() -> int:
	var gained := floor_coins(current_floor)
	add_coins(gained)
	save_progress()
	return gained


## 通过当前这一层：给当前角色加经验并存档（回大厅再花经验升级），返回获得的经验。
func grant_floor_xp() -> int:
	var gained := floor_xp(current_floor)
	character_xp[character_id(character)] = xp_of(character) + gained
	run_xp += gained
	save_progress()
	return gained


# ---------- 大厅商人 ----------

func trinket_level(id: String) -> int:
	return trinket_levels.get(id, 0)


## 买下（0 级 → 1 级）或升一级的价格；满级返回 -1
func trinket_price(id: String) -> int:
	var level := trinket_level(id)
	if level >= TRINKETS[id].max:
		return -1
	return TRINKETS[id].price * (level + 1)


func buy_trinket(id: String) -> bool:
	var price := trinket_price(id)
	if price < 0 or not spend_coins(price):
		return false
	trinket_levels[id] = trinket_level(id) + 1
	save_progress()
	return true


## 下一局开局带上这把武器（只能预定一把，再买会换掉之前的）
func buy_next_weapon(weapon: WeaponData) -> bool:
	if not spend_coins(NEXT_WEAPON_PRICE):
		return false
	next_weapon = weapon
	save_progress()
	return true


## 下一局开局获得这个强化（每种只能买一次）
func buy_next_buff(id: String) -> bool:
	if next_buffs.has(id) or not spend_coins(NEXT_BUFF_PRICE):
		return false
	next_buffs.append(id)
	save_progress()
	return true


## 商人今天进的货：几把随机武器（不含当前角色的初始武器）和几个随机增益（不含"急救包"，开局用不上）
func merchant_weapons(count: int) -> Array[WeaponData]:
	var pool := weapon_pool.filter(func(w: WeaponData) -> bool: return w != character.starting_weapon)
	pool.shuffle()
	var result: Array[WeaponData] = []
	result.assign(pool.slice(0, count))
	return result


func merchant_buffs(count: int) -> Array:
	var pool := BUFFS.filter(func(b: Dictionary) -> bool: return b.id != "heal")
	pool.shuffle()
	return pool.slice(0, count)


func buff_name(id: String) -> String:
	for b: Dictionary in BUFFS:
		if b.id == id:
			return b.name
	return id


# ---------- 存档 ----------

func record_run(won: bool) -> void:
	best_floor = maxi(best_floor, current_floor)
	if won:
		wins += 1
	save_progress()


## 存档：纪录、角色经验和等级、金币、小道具、下一局的预定
func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("record", "best_floor", best_floor)
	cfg.set_value("record", "wins", wins)
	cfg.set_value("record", "character", characters.find(character))
	for id: String in character_xp:
		cfg.set_value("xp", id, character_xp[id])
	for id: String in character_level:
		cfg.set_value("level", id, character_level[id])
	cfg.set_value("record", "coins", coins)
	for id: String in trinket_levels:
		cfg.set_value("trinkets", id, trinket_levels[id])
	cfg.set_value("next_run", "weapon", next_weapon.resource_path if next_weapon else "")
	cfg.set_value("next_run", "buffs", next_buffs)
	cfg.set_value("mage", "branch", mage_branch)
	cfg.set_value("mage", "skills", mage_skills)
	cfg.set_value("skills", "choices", skill_choices)
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
		if cfg.has_section("level"):
			for id in cfg.get_section_keys("level"):
				character_level[id] = cfg.get_value("level", id, 1)
		character = characters[clampi(index, 0, characters.size() - 1)]
		coins = cfg.get_value("record", "coins", 0)
		if cfg.has_section("trinkets"):
			for id in cfg.get_section_keys("trinkets"):
				if TRINKETS.has(id):
					trinket_levels[id] = cfg.get_value("trinkets", id, 0)
		var weapon_path: String = cfg.get_value("next_run", "weapon", "")
		next_weapon = load(weapon_path) as WeaponData if weapon_path != "" and ResourceLoader.exists(weapon_path) else null
		next_buffs.assign(cfg.get_value("next_run", "buffs", []))
		mage_branch = cfg.get_value("mage", "branch", "arcane")
		mage_skills = cfg.get_value("mage", "skills", {})
		skill_choices = cfg.get_value("skills", "choices", {})
