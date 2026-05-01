extends Node2D
# ================================================
# メインシーン.
# ================================================
const BOARD_SIZE := 8

# コマの種別.
enum eReversi {
	EMPTY = 0,
	BLACK = 1,
	WHITE = 2,
}

var board := Array2D.new(BOARD_SIZE, BOARD_SIZE, eReversi.EMPTY)
var mouse_pos := Vector2.ZERO

# 開始.
func _ready() -> void:
	# 盤面の初期化.
	_init_board()

# 盤面の初期化.
func _init_board() -> void:
	# 初期化.
	board.fill(eReversi.EMPTY)

	# 初期配置（中央に4つ）
	var mid := int(BOARD_SIZE / 2.0)
	board.setv(mid - 1, mid - 1, eReversi.WHITE)
	board.setv(mid, mid, eReversi.WHITE)
	board.setv(mid - 1, mid, eReversi.BLACK)
	board.setv(mid, mid - 1, eReversi.BLACK)

# 更新.
func _process(_delta: float) -> void:
	# マウス位置の更新
	mouse_pos = get_viewport().get_mouse_position()

	# 描画更新.
	queue_redraw()

func _draw() -> void:
	# ウィンドウサイズに合わせて盤面を中央に描画する
	var vp_size := get_viewport_rect().size
	var margin := 20.0 # 盤面周りの余白
	# 盤面のセルサイズを計算
	var cell_size: float = min((vp_size.x - margin * 2) / BOARD_SIZE, (vp_size.y - margin * 2) / BOARD_SIZE)
	# 盤面全体のサイズ.
	var board_pixel := cell_size * BOARD_SIZE
	var start := (vp_size - Vector2(board_pixel, board_pixel)) / 2.0

	# 背景（緑）
	var board_rect := Rect2(start, Vector2(board_pixel, board_pixel))
	draw_rect(board_rect, Color(0.08, 0.5, 0.08))

	# グリッド線
	var line_color := Color(0, 0, 0, 0.8)
	var line_width := 2.0
	for i in range(BOARD_SIZE + 1):
		var x := start.x + i * cell_size
		draw_line(Vector2(x, start.y), Vector2(x, start.y + board_pixel), line_color, line_width)
		var y := start.y + i * cell_size
		draw_line(Vector2(start.x, y), Vector2(start.x + board_pixel, y), line_color, line_width)

	# 石の描画
	var stone_border := Color(0, 0, 0, 0.6)
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			var v := board.getv(r, c)
			if v == eReversi.EMPTY:
				continue
			var center := start + Vector2(c * cell_size + cell_size / 2.0, r * cell_size + cell_size / 2.0)
			var radius := cell_size * 0.42
			# 外枠で立体感
			draw_circle(center + Vector2(1, 1), radius, Color(0, 0, 0, 0.12))
			# 石本体
			var fill := Color(0, 0, 0)
			if v == eReversi.WHITE:
				fill = Color(1, 1, 1)
			draw_circle(center, radius, fill)
			# 輪郭
			draw_circle(center, radius, stone_border, false)
	
	# マウス位置にグリッド線を描画.
	_draw_mouse_cursor_grid(start, cell_size)

# マウス位置にグリッド線を描画.
func _draw_mouse_cursor_grid(start: Vector2, cell_size: float) -> void:
	var mouse_grid := (mouse_pos - start) / cell_size
	if mouse_grid.x >= 0 and mouse_grid.x < BOARD_SIZE and mouse_grid.y >= 0 and mouse_grid.y < BOARD_SIZE:
		var grid_pos := Vector2(int(mouse_grid.x), int(mouse_grid.y))
		var line_color := Color(1, 1, 0, 0.8)
		# 四角形で描画.
		var rect := Rect2(start + grid_pos * cell_size, Vector2(cell_size, cell_size))
		draw_rect(rect, line_color, false, 2.0)
