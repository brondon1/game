extends Enemy
## 骷髅法师：和玩家保持距离，定时停下来施法召唤蝙蝠。自己召唤的蝙蝠在场上最多几只。
## 优先干掉它，不然蝙蝠会越来越多。

const BAT_SCENE := preload("res://enemies/bat.tscn")

@export var summon_interval := 4.5
@export var summon_count := 2
@export var max_minions := 4
@export var cast_time := 0.8
@export var preferred_distance := 130.0

var _timer := 0.0
var _casting := 0.0
var _minions: Array = []


func _ready() -> void:
	super()
	_timer = randf_range(1.5, 3.0)


func _think(delta: float) -> Vector2:
	_timer -= delta
	if _casting > 0.0:
		_casting -= delta
		sprite.self_modulate = Color(1.3, 0.8, 1.6) if int(_casting * 10.0) % 2 == 0 else Color.WHITE
		if _casting <= 0.0:
			sprite.self_modulate = Color.WHITE
			_summon()
		return Vector2.ZERO
	_minions = _minions.filter(is_instance_valid)
	if _timer <= 0.0 and _minions.size() < max_minions:
		_timer = summon_interval
		_casting = cast_time
		Sound.play(Sound.SUMMON)
		return Vector2.ZERO
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if dist > preferred_distance + 40.0 or not has_line_of_sight_to_player():
		return chase_direction()
	if dist < preferred_distance - 30.0:
		return -to_player / maxf(dist, 0.001)
	return Vector2.ZERO


func _summon() -> void:
	for i in summon_count:
		var bat := spawn_minion(BAT_SCENE, global_position + Vector2.from_angle(randf() * TAU) * 12.0)
		_minions.append(bat)
	HitEffect.spawn(get_parent(), global_position + Vector2(0, -8), Color("b55088"), 12, 1.0)
