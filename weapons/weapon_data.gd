class_name WeaponData
extends Resource
## 武器数据。新增一把枪只需要在文件系统里新建一个 WeaponData 资源（.tres），不用写代码。

@export var display_name := "武器"
@export var texture: Texture2D
## 枪口相对于握把（贴图左侧中点）的位置
@export var muzzle_offset := Vector2(10, 0)
## 开火 / 挥砍时的音效
@export var sound: AudioStream

@export_group("射击")
@export var damage := 3
## 两次射击之间的最短间隔（秒）
@export var fire_interval := 0.3
## 每次射击消耗的能量，0 表示不耗能
@export var energy_cost := 0
@export var bullets_per_shot := 1
## 散射的总角度（度）
@export var spread_degrees := 6.0
@export var bullet_speed := 320.0
## 子弹最远飞行距离（像素）
@export var bullet_range := 320.0
## 子弹是否穿透敌人
@export var piercing := false

@export_group("子弹特效")
## 子弹贴图，留空用默认的黄色子弹
@export var bullet_texture: Texture2D
## 大于 0 时子弹命中（或飞到尽头）会爆炸，对半径内的所有敌人造成伤害
@export var explosion_radius := 0.0
## 子弹撞墙后可以反弹的次数
@export var bounces := 0
## 命中后让敌人减速的时间（秒）
@export var slow_duration := 0.0
## 大于 0 时子弹会追踪附近的敌人，数值是转向速度（弧度/秒）
@export var homing := 0.0

@export_group("近战")
## 勾选后变成近战武器：挥砍扇形范围内的所有敌人，并打掉范围内的敌方子弹。
## 近战武器只使用 伤害、射击间隔、能耗 这几个射击参数。
@export var is_melee := false
## 挥砍半径（像素）
@export var melee_range := 28.0
## 挥砍扇形的角度（度）
@export var melee_arc_degrees := 120.0
## 击退倍率
@export var knockback := 1.0
## 能否打掉敌人的子弹
@export var deflects_bullets := true


## 显示在 HUD 和拾取提示上的简短说明。
func describe() -> String:
	return "%s  %s" % [display_name, "近战" if is_melee else "能耗 %d" % energy_cost]
