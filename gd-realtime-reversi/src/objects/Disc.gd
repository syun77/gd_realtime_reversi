extends Node2D
# ================================================
# 石クラス.
# ================================================
class_name Disc

const TIMER_ROTATE := 0.2 # 回転時間 (秒).

enum eType {
	EMPTY = 0,
	BLACK = 1,
	WHITE = 2,
}

enum eState {
	STATIC = 0, # 静止.
	ROTATING = 1, # 回転中.
}

var _state := eState.STATIC
var _type := eType.EMPTY
var _type_prev := eType.EMPTY # 前回のタイプ（描画更新の最適化用）
var _radius := 0.0
var _timer_rotate := 0.0 # 回転用タイマー.

func get_stone_color(type:eType) -> Color:
	if type == eType.BLACK:
		return Color(0, 0, 0)
	elif type == eType.WHITE:
		return Color(1, 1, 1)
	return Color(0, 0, 0, 0) # EMPTYは透明.

func set_draw_info(center: Vector2, radius: float, type: eType, rotated: bool=true) -> void:
	position = center
	_radius = radius
	_type_prev = _type # 前回のタイプ.
	_type = type
	if rotated:
		# 透明の場合は回転演出なし.
		if _type_prev != eType.EMPTY:
			if _type != _type_prev:
				# 回転する.
				_timer_rotate = TIMER_ROTATE
				_state = eState.ROTATING

func _process(delta: float) -> void:
	if _timer_rotate > 0.0:
		# 回転する.
		var rate = abs(0.5 - _timer_rotate / TIMER_ROTATE) * 2 # 0.0 -> 1.0 -> 0.0
		scale.x = sin((rate * PI * 0.5)) # 回転のためにX軸を変形.
		_timer_rotate = max(0.0, _timer_rotate - delta)
		if _timer_rotate == 0.0:
			_state = eState.STATIC
	else:
		scale.x = 1.0 # 回転終了後はスケールを元に戻す.

	queue_redraw()

func _draw() -> void:
	var stone_border := Color(0, 0, 0, 0.6)
	# 外枠で立体感
	draw_circle(Vector2.ZERO, _radius, Color(0, 0, 0, 0.12))
	# 石本体
	var fill := get_stone_color(_type)
	if _state == eState.ROTATING:
		# 回転中.
		if _timer_rotate > TIMER_ROTATE * 0.5:
			# 裏面: 前回の石を描画する.
			fill = get_stone_color(_type_prev)

	draw_circle(Vector2.ZERO, _radius, fill)
	# 輪郭
	draw_circle(Vector2.ZERO, _radius, stone_border, false)

# ------------------------------------------------
# static functions
# ------------------------------------------------
static func reverse(type:eType) -> eType:
	if type == eType.BLACK:
		return eType.WHITE
	elif type == eType.WHITE:
		return eType.BLACK
	return eType.EMPTY
