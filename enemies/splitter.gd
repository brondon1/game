extends Enemy
## 分裂史莱姆：死后分裂成几只小史莱姆（小史莱姆也要打完，房间才算清空）。

const MINI_SLIME_SCENE := preload("res://enemies/mini_slime.tscn")

@export var split_count := 2


func _die() -> void:
	for i in split_count:
		var offset := Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
		spawn_minion(MINI_SLIME_SCENE, global_position + offset)
	super()
