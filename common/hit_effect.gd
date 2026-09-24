class_name HitEffect
extends CPUParticles2D
## 一次性的像素火花粒子（白色小十字，按 color 染色），播放完自动删除。


const SPARK := preload("res://assets/sprites/spark.png")
const PUFF := preload("res://assets/sprites/puff.png")


## speed 缩放粒子飞出的速度；puff 为 true 时用圆形烟尘（脚步扬尘），否则用十字火花
static func spawn(parent: Node, pos: Vector2, color: Color, count := 6, speed := 1.0, puff := false) -> void:
	var fx := HitEffect.new()
	fx.one_shot = true
	fx.emitting = false
	fx.amount = count
	fx.lifetime = 0.25
	fx.explosiveness = 1.0
	fx.spread = 180.0
	fx.gravity = Vector2.ZERO
	fx.initial_velocity_min = 40.0 * speed
	fx.initial_velocity_max = 90.0 * speed
	fx.damping_min = 100.0
	fx.damping_max = 150.0
	fx.texture = PUFF if puff else SPARK
	fx.scale_amount_min = 1.0
	fx.scale_amount_max = 1.0
	fx.color = color
	fx.material = preload("res://common/unshaded.tres")
	fx.position = pos
	fx.finished.connect(fx.queue_free)
	parent.add_child.call_deferred(fx)
	fx.set_deferred("emitting", true)
