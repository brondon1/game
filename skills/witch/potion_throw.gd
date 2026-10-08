extends MageSkill
## 女巫【魔药投掷】：往敌人扎堆的地方扔一瓶随机魔药（扔出去才知道是哪种）：
## 爆炸（范围伤害）/ 冰冻（冻住一片）/ 剧毒（留一摊毒液）/ 治疗（在自己脚下洒一片回血区）

enum Kind { BOOM, FREEZE, POISON, HEAL }

const COLORS := {Kind.BOOM: Color(1.6, 0.6, 0.4), Kind.FREEZE: Color(0.6, 1.0, 1.8),
	Kind.POISON: Color(0.6, 1.5, 0.5), Kind.HEAL: Color(1.0, 1.0, 1.0)}
const FLIGHT := 0.45


func _init() -> void:
	display_name = "魔药投掷"
	description = "扔一瓶随机魔药：爆炸 / 冰冻 / 剧毒 / 治疗"
	cooldown = 6.0


func _activate() -> void:
	var kind: Kind = Kind.values().pick_random()
	if kind == Kind.HEAL and GameState.hp >= GameState.max_hp:
		kind = Kind.BOOM # 满血时治疗药水没用，换成爆炸
	var spot := player.global_position if kind == Kind.HEAL else target_spot()
	var bottle := sprite_fx("../potion.png", world(), center())
	bottle.modulate = COLORS[kind]
	bottle.z_index = 10
	var from := center()
	var tween := bottle.create_tween()
	tween.tween_method(func(t: float) -> void: # 抛物线飞过去，边飞边转
		bottle.global_position = from.lerp(spot, t) + Vector2(0, -sin(t * PI) * 30.0)
		bottle.rotation = t * TAU * 1.5, 0.0, 1.0, FLIGHT)
	tween.tween_callback(func() -> void:
		bottle.queue_free()
		_splash(kind, spot))
	Sound.play(Sound.THROW, -2.0)


func _splash(kind: Kind, spot: Vector2) -> void:
	if not is_instance_valid(player):
		return
	Sound.play(Sound.CRATE_BREAK, -4.0)
	match kind:
		Kind.BOOM:
			Explosion.spawn(world(), spot, 38.0, dmg(12), Bullet.Team.PLAYER)
		Kind.FREEZE:
			for enemy in enemies_near(spot, 40.0):
				enemy.apply_stun(2.0, Color(0.55, 0.85, 1.6), true)
			HitEffect.spawn(world(), spot, Color("cae6f5"), 16, 1.3)
		Kind.POISON:
			zone(spot, 36.0, 5.0, SkillZone.Kind.POISON, dmg(2))
		Kind.HEAL:
			zone(spot, 30.0, 4.5, SkillZone.Kind.HEAL, 1)
