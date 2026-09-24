class_name Torch
extends Node2D
## 墙上的火把：两帧火苗交替，光的亮度和大小随机抖动。

@export var base_energy := 1.0

var _time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D


func _ready() -> void:
	_time = randf() * 10.0 # 每个火把的节奏错开


func _process(delta: float) -> void:
	_time += delta
	sprite.frame = int(_time * 7.0) % 2
	var flicker := sin(_time * 11.0) * 0.06 + sin(_time * 23.0) * 0.04 + randf_range(-0.03, 0.03)
	light.energy = base_energy + flicker
	light.texture_scale = 1.6 + flicker * 0.5
