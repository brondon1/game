extends Skill
## 骑士技能【双持】：一段时间内副手拿起另一把武器，两把一起开火。只有一把武器时双持同一把。


func _activate() -> void:
	player.set_offhand(true)


func _end() -> void:
	player.set_offhand(false)
