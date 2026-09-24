class_name CharacterData
extends Resource
## 可选角色：外观、初始属性、初始武器和技能。新增角色：新建一个 CharacterData 资源并加到 GameState.characters。
## texture 是横向排列的动画帧：前 2 帧待机（呼吸），后 4 帧走路，每帧都是正方形。

const IDLE_FRAMES := 2
const WALK_FRAMES := 4

@export var display_name := "角色"
@export var texture: Texture2D
@export var max_hp := 6
@export var max_shield := 4
@export var max_energy := 180
@export var speed := 100.0
@export var starting_weapon: WeaponData
## 技能场景：根节点挂一个继承 Skill 的脚本
@export var skill_scene: PackedScene


## 动画一共几帧（按正方形帧计算，兼容只有一帧的旧贴图）
func frame_count() -> int:
	return maxi(1, texture.get_width() / texture.get_height())


## 菜单里用的头像：动画的第一帧
func icon() -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0, 0, texture.get_height(), texture.get_height())
	return atlas
