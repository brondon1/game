class_name SkillBarrier
extends Node2D
## 立在玩家面前的一道墙（冰墙、风墙），垂直于瞄准方向，持续 lifetime 秒。
## 飞到墙上的敌方子弹：冰墙直接挡掉，风墙反弹回去变成自己的子弹。

var length := 56.0
var lifetime := 4.0
var reflect := false
var reflect_damage := 3
var texture: Texture2D
## 墙的朝向（瞄准方向），墙沿着它的垂直方向排开
var facing := Vector2.RIGHT

const THICKNESS := 8.0


func _ready() -> void:
	var count := maxi(1, int(length / 12.0))
	var along := facing.orthogonal()
	for i in count:
		var block := Sprite2D.new()
		block.texture = texture
		block.position = along * (i - (count - 1) / 2.0) * 12.0 + Vector2(0, -8)
		add_child(block)
	scale = Vector2(1, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		set_physics_process(false)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
		return
	if lifetime < 0.8:
		modulate.a = 0.5 + 0.5 * float(int(lifetime * 10.0) % 2)
	var along := facing.orthogonal()
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		var bullet := node as Bullet
		if bullet == null or bullet.is_queued_for_deletion():
			continue
		var offset := bullet.global_position - global_position
		if absf(offset.dot(facing)) <= THICKNESS and absf(offset.dot(along)) <= length / 2.0 + 4.0:
			if reflect:
				bullet.reflect(reflect_damage)
				bullet.global_position += facing * (THICKNESS + 2.0)
				HitEffect.spawn(get_parent(), bullet.global_position, Color("cae6f5"), 3, 0.5)
			else:
				HitEffect.spawn(get_parent(), bullet.global_position, Color("cae6f5"), 4, 0.6)
				bullet.destroy()
