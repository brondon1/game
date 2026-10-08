class_name MageBranches
extends RefCounted
## 元素法师的流派：每个流派有自己的外观和 3 个技能，一次只能带其中一个。
## 在大厅和法师对话切换流派、换技能（GameState.mage_branch / mage_skill_index）。
## 新增流派：画一条 8 帧的外观贴图，写几个继承 MageSkill 的技能脚本，在 BRANCHES 里加一条。

const MAGE := "res://assets/sprites/mage"
const SKILLS := "res://skills/mage/"

## [id, 名字, 外观贴图, 技能列表]。技能可以是 PackedScene（奥术的元素新星沿用原来的场景）或脚本。
static var BRANCHES: Array = [
	["arcane", "奥术", MAGE + ".png", [preload("res://skills/nova.tscn"), "arcane_time", "arcane_missiles"]],
	["fire", "火焰", MAGE + "_fire.png", ["fire_meteor", "fire_nova", "fire_dash"]],
	["ice", "冰霜", MAGE + "_ice.png", ["ice_nova", "ice_blizzard", "ice_wall"]],
	["lightning", "雷电", MAGE + "_lightning.png", ["lightning_storm", "lightning_chain", "lightning_blink"]],
	["earth", "大地", MAGE + "_earth.png", ["earth_quake", "earth_spikes", "earth_shield"]],
	["wind", "疾风", MAGE + "_wind.png", ["wind_tornado", "wind_wall", "wind_step"]],
	["water", "潮汐", MAGE + "_water.png", ["water_wave", "water_spring", "water_bubble"]],
	["shadow", "暗影", MAGE + "_shadow.png", ["shadow_hole", "shadow_clone", "shadow_drain"]],
	["light", "圣光", MAGE + "_light.png", ["light_barrier", "light_judgment", "light_heal"]],
	["poison", "剧毒", MAGE + "_poison.png", ["poison_cloud", "poison_vines", "poison_mushroom"]],
]


static func index_of(id: String) -> int:
	for i in BRANCHES.size():
		if BRANCHES[i][0] == id:
			return i
	return 0


static func branch_name(id: String) -> String:
	return BRANCHES[index_of(id)][1]


static func texture(id: String) -> Texture2D:
	return load(BRANCHES[index_of(id)][2])


static func skill_count(id: String) -> int:
	return BRANCHES[index_of(id)][3].size()


## 生成这个流派的第 index 个技能
static func create_skill(id: String, index: int) -> Skill:
	var list: Array = BRANCHES[index_of(id)][3]
	var entry: Variant = list[clampi(index, 0, list.size() - 1)]
	if entry is PackedScene:
		return (entry as PackedScene).instantiate()
	var skill: Skill = load(SKILLS + str(entry) + ".gd").new()
	skill.name = str(entry).to_pascal_case()
	return skill
