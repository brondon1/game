class_name WeaponData
extends Resource
## 武器数据。新增一把枪只需要在文件系统里新建一个 WeaponData 资源（.tres），不用写代码。

@export var display_name := "武器"
@export var texture: Texture2D
## 枪口相对于握把（贴图左侧中点）的位置
@export var muzzle_offset := Vector2(10, 0)

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
