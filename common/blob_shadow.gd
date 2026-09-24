class_name BlobShadow
extends Sprite2D
## 脚下的椭圆阴影，让角色和物体“站”在地上。挂成第一个子节点，保证画在本体下面。


static func add_to(node: Node2D, width_scale := 1.0, offset := Vector2(0, 1)) -> BlobShadow:
	var shadow := BlobShadow.new()
	shadow.texture = preload("res://assets/sprites/shadow.png")
	shadow.position = offset
	shadow.scale = Vector2(width_scale, width_scale)
	node.add_child(shadow)
	node.move_child(shadow, 0)
	return shadow
