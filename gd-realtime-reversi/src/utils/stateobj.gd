# Nodeは継承しない.
#extends Node
# ================================================
# 状態オブジェクト.
# @note update()を呼び出さないと状態遷移しません.
# ================================================
class_name StateObj

var _counter:int = 0 # フレームカウンター.
var _state:int = -1 # 状態を表す整数値.
var _next_state:int = 0 # 次の状態を表す整数値.
var _timer:float = 0 # 状態の経過時間.
var _is_first_frame:bool = true # 状態遷移して最初のフレームかどうか.

# 状態の更新.
func update(delta: float) -> void:
	if _state != _next_state:
		_state = _next_state
		_timer = 0
		_is_first_frame = true
	else:
		_is_first_frame = false
	_timer += delta
	_counter += 1

# 状態変更.
func change_state(new_state:int) -> void:
	if _state == new_state:
		return
	_next_state = new_state
	_timer = 0
	_counter = 0

func change(new_state:int) -> void:
	change_state(new_state)

# 状態の取得.
func get_state() -> int:
	return _state

# タイマーを取得.
func get_timer() -> float:
	return _timer

# フレームカウンターを取得.
func get_counter() -> int:
	return _counter

# 状態を遷移して最初かどうか.
func is_first() -> bool:
	return _is_first_frame

# -----------------------------------------------
# プロパティ定義.
# -----------------------------------------------
var state: int:
	get:
		return _state
	set(value):
		change_state(value)
