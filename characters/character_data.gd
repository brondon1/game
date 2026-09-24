class_name CharacterData
extends Resource
## 可选角色：外观、初始属性、初始武器和技能。新增角色：新建一个 CharacterData 资源并加到 GameState.characters。

@export var display_name := "角色"
@export var texture: Texture2D
@export var max_hp := 6
@export var max_shield := 4
@export var max_energy := 180
@export var speed := 100.0
@export var starting_weapon: WeaponData
## 技能场景：根节点挂一个继承 Skill 的脚本
@export var skill_scene: PackedScene
