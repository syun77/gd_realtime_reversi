extends Node2D
# ================================================
# 石クラス.
# ================================================
class_name Stone

enum eType {
	EMPTY = 0,
	BLACK = 1,
	WHITE = 2,
}

var _type := eType.EMPTY
var _center := Vector2.ZERO
var _radius := 0.0

func set_draw_info(center: Vector2, radius: float, type: eType) -> void:
	_center = center
	_radius = radius
	_type = type

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var stone_border := Color(0, 0, 0, 0.6)
	# 外枠で立体感
	draw_circle(_center + Vector2(1, 1), _radius, Color(0, 0, 0, 0.12))
	# 石本体
	var fill := Color(0, 0, 0)
	if _type == eType.WHITE:
		fill = Color(1, 1, 1)
	draw_circle(_center, _radius, fill)
	# 輪郭
	draw_circle(_center, _radius, stone_border, false)
