extends Node2D
# ================================================
# メインシーン.
# ================================================
const BOARD_SIZE := 8

const STONE_OBJ = preload("res://src/objects/Stone.tscn")
const LABEL_SETTINGS = preload("res://assets/fonts/label_settings.tres")

@onready var stone_layer := $StoneLayer # 石の描画用レイヤー.

var board := Array2D.new(BOARD_SIZE, BOARD_SIZE, Stone.eType.EMPTY) # 盤面データ.
var mouse_pos := Vector2.ZERO # マウス位置.
var stone_map:Dictionary[int, Stone] = {} # 石のインスタンス管理用マップ.

# 開始.
func _ready() -> void:
	# 盤面の初期化.
	_init_board()

# 盤面の初期化.
func _init_board() -> void:
	# 初期化.
	board.fill(Stone.eType.EMPTY)

	# 初期配置（中央に4つ）
	var mid := int(BOARD_SIZE / 2.0)
	place_stone(mid - 1, mid - 1, Stone.eType.WHITE)
	place_stone(mid, mid, Stone.eType.WHITE)
	place_stone(mid - 1, mid, Stone.eType.BLACK)
	place_stone(mid, mid - 1, Stone.eType.BLACK)

# 石を置く.
func place_stone(x: int, y: int, type: Stone.eType) -> void:
	if not board.is_valid(x, y):
		return # 範囲外は無視.
	
	var index := board.pos_to_index(Vector2i(x, y))
	var stone: Stone = stone_map.get(index)
	if stone == null:
		# 新規に石を作成して配置.
		stone = STONE_OBJ.instantiate() as Stone
		stone_layer.add_child(stone)
		stone_map[index] = stone
	board.setv(x, y, type)

	var cell_size = _get_cell_size() # セルサイズを更新.
	var start := _get_board_start()
	var center := start + Vector2(x * cell_size + cell_size / 2.0, y * cell_size + cell_size / 2.0)
	var radius: float = cell_size * 0.42
	stone.set_draw_info(center, radius, type) # 描画情報を更新.

# 更新.
func _process(_delta: float) -> void:
	# マウス位置の更新
	mouse_pos = get_viewport().get_mouse_position()

	# クリックした場所に石を配置.
	if Input.is_action_just_pressed("click"):
		var cell_size := _get_cell_size()
		var start := _get_board_start()
		var grid_pos := (mouse_pos - start) / cell_size
		var x := int(grid_pos.x)
		var y := int(grid_pos.y)
		if board.is_valid(x, y):
			place_stone(x, y, Stone.eType.BLACK) # 黒石を配置.

	# 描画更新.
	queue_redraw()

func _get_cell_size() -> float:
	var vp_size := get_viewport_rect().size
	var margin := 20.0 # 盤面周りの余白
	return min((vp_size.x - margin * 2) / BOARD_SIZE, (vp_size.y - margin * 2) / BOARD_SIZE)

func _get_board_start() -> Vector2:
	var vp_size := get_viewport_rect().size
	var cell_size := _get_cell_size()
	var board_pixel := cell_size * BOARD_SIZE
	return (vp_size - Vector2(board_pixel, board_pixel)) / 2.0

func _draw() -> void:
	# 盤面のセルサイズを計算
	var cell_size: float = _get_cell_size()
	# 盤面全体のサイズ.
	var board_pixel := cell_size * BOARD_SIZE
	var start := _get_board_start()

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

	# マウス位置にグリッド線を描画.
	_draw_mouse_cursor_grid(start, cell_size)
	
	# 石の情報をフォントでデバッグ描画.
	var label_settings := LABEL_SETTINGS as LabelSettings
	var font: Font = label_settings.font if label_settings != null else null
	if font != null:
		for y in range(BOARD_SIZE):
			for x in range(BOARD_SIZE):
				var value := board.getv(x, y)
				var text := str(value)
				var pos := start + Vector2(x * cell_size + 5, y * cell_size + 20)
				var font_color := Color(1, 1, 1)
				var font_size := 16
				# Godot 4.6 の draw_string シグネチャに合わせて全引数を指定
				# (font, pos, text, alignment, width, font_size, modulate, justification_flags, direction, orientation, oversampling)
				draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, font_color, 0, 0, 0, 0.0)
	

# マウス位置にグリッド線を描画.
func _draw_mouse_cursor_grid(start: Vector2, cell_size: float) -> void:
	var mouse_grid := (mouse_pos - start) / cell_size
	if mouse_grid.x >= 0 and mouse_grid.x < BOARD_SIZE and mouse_grid.y >= 0 and mouse_grid.y < BOARD_SIZE:
		var grid_pos := Vector2(int(mouse_grid.x), int(mouse_grid.y))
		var line_color := Color(1, 1, 0, 0.8)
		# 四角形で描画.
		var rect := Rect2(start + grid_pos * cell_size, Vector2(cell_size, cell_size))
		draw_rect(rect, line_color, false, 2.0)
