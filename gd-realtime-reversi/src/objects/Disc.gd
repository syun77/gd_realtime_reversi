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
var _delay := 0.0 # 描画開始前の遅延時間.

func get_stone_color(type:eType) -> Color:
	if type == eType.BLACK:
		return Color(0, 0, 0)
	elif type == eType.WHITE:
		return Color(1, 1, 1)
	return Color(0, 0, 0, 0) # EMPTYは透明.

# 回転中かどうか.
func is_rotateing() -> bool:
	return _state == eState.ROTATING

func set_draw_info(center: Vector2, radius: float, type: eType, delay: float, rotated: bool=true) -> void:
	position = center
	_radius = radius
	_type_prev = _type # 前回のタイプ.
	_type = type
	_delay = delay
	if rotated:
		# 透明の場合は回転演出なし.
		if _type_prev != eType.EMPTY:
			if _type != _type_prev:
				# 回転する.
				_timer_rotate = TIMER_ROTATE
				_state = eState.ROTATING

func _process(delta: float) -> void:
	if _timer_rotate > 0.0:
		_update_rotate(delta)
	else:
		scale.x = 1.0 # 回転終了後はスケールを元に戻す.

	queue_redraw()

func _update_rotate(delta: float) -> void:
	if _delay > 0.0:
		_delay = max(0.0, _delay - delta)
		return # 遅延中は回転しない.

	_timer_rotate = max(0.0, _timer_rotate - delta)
	# 回転する.
	var rate = abs(0.5 - _timer_rotate / TIMER_ROTATE) * 2 # 0.0 -> 1.0 -> 0.0
	scale.x = sin((rate * PI * 0.5)) # 回転のためにX軸を変形.
	_timer_rotate = max(0.0, _timer_rotate - delta)
	if _timer_rotate == 0.0:
		_state = eState.STATIC

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

# 属性に対応する色を返す.
static func get_color(type: eType, alpha: float) -> Color:
	match type:
		eType.BLACK:
			return Color(0, 0, 0, alpha)
		eType.WHITE:
			return Color(1, 1, 1, alpha)
		_:
			return Color(0.5, 0.5, 0.5, alpha) # NONEの場合はグレーを返す.

# 属性に対応するアウトラインの色を返す.
static func get_outline_color(type: eType, alpha: float) -> Color:
	match type:
		eType.BLACK:
			return Color(1, 0, 0, alpha) # 黒のアウトラインは赤.
		eType.WHITE:
			return Color(0, 1, 1, alpha) # 白のアウトラインは青.
		_:
			return Color(0.5, 0.5, 0.5, alpha) # NONEの場合はグレーを返す.
