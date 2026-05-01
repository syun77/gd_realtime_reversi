extends Node
# ================================================
# 2次元配列のユーティリティ関数.
# ================================================
class_name Array2D

var width := 0 # 幅.
var height := 0 # 高さ.
var data:Array[int] = [] # データ配列 (1次元で管理).
var default_value := 0 # デフォルト値 (空).
var invalid_value := -1 # 無効値 (範囲外).

# 生成.
func _init(w:int, h:int, value:int = 0) -> void:
	width = w
	height = h
	default_value = value # デフォルト値.
	data.clear()
	for i in range(width * height):
		data.append(default_value)

# 範囲の有効チェック.
func is_valid(x:int, y:int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

# 値の取得.
func getv(x:int, y:int) -> int:
	if not is_valid(x, y):
		return invalid_value
	return data[y * width + x]

func getv_pos(pos:Vector2i) -> int:
	return getv(pos.x, pos.y)

# 値の設定.
func setv(x:int, y:int, value:int) -> void:
	if not is_valid(x, y):
		return
	data[y * width + x] = value

func setv_pos(pos:Vector2i, value:int) -> void:
	setv(pos.x, pos.y, value)

func foreach(function:Callable) -> void:
	for y in range(height):
		for x in range(width):
			function.call(x, y, getv(x, y))

# 指定の位置が空かどうか.
func is_empty(x:int, y:int) -> bool:
	return getv(x, y) == default_value
func is_empty_pos(pos:Vector2i) -> bool:
	return is_empty(pos.x, pos.y)

# 指定の値で埋める.
func fill(value:int) -> void:
	for i in range(width * height):
		data[i] = value

# クリアする.
func clear() -> void:
	fill(default_value)

# 指定の値の座標リストを返す.
func find(value:int) -> Array[Vector2i]:
	var result := []
	foreach(func(x, y, v):
		if v == value:
			result.append(Vector2i(x, y))
	)
	return result

# デバッグ出力.
func debug_print() -> void:
	print("[Array2D]: width=%d, height=%d" % [width, height])
	foreach(func(x, y, v):
		print("  (%d, %d) = %d" % [x, y, v])
	)
