extends Node2D
# ================================================
# 盤面クラス.
# ================================================
class_name Board

const BOARD_SIZE := 8

# ■preload(s).
const DISC_OBJ = preload("res://src/objects/Disc.tscn")
const LABEL_SETTINGS = preload("res://assets/fonts/label_settings.tres")

class DamageInfo:
	var turn_cnt: int = 0 # ひっくり返した石の数.
	var dir_cnt: int = 0 # ひっくり返した方向の数.
	# 初期化.
	func clear() -> void:
		turn_cnt = 0
		dir_cnt = 0
	# ダメージ計算.
	func calc_damage() -> int:
		# ダメージ計算式（ひっくり返した駒の数:t ひっくり返した方向:d)
		# (1 + t^1.5) * d
		var t := turn_cnt
		var d := dir_cnt
		return int((1 + pow(t, 1.5)) * d)


var board := Array2D.new(BOARD_SIZE, BOARD_SIZE, Stone.eType.EMPTY) # 盤面データ.
var board_hint_black := Array2D.new(BOARD_SIZE, BOARD_SIZE, 0) # 黒石を置いたときにひっくり返すことができる石のヒント.
var board_hint_white := Array2D.new(BOARD_SIZE, BOARD_SIZE, 0) # 白石を置いたときにひっくり返すことができる石のヒント.
var disc_map:Dictionary[int, Disc] = {} # 石のインスタンス管理用マップ.
var mouse_pos := Vector2.ZERO # マウス位置.
var grid_pos := Vector2i.ZERO # マウス位置のグリッド座標.
var _last_damage_info := DamageInfo.new() # 最後のダメージ情報.

# 盤面の初期化.
func init_board() -> void:
	# 初期化.
	board.fill(Disc.eType.EMPTY)

	# 初期配置（中央に4つ）
	var mid := int(BOARD_SIZE / 2.0)
	place_disc(Vector2i(mid - 1, mid - 1), Disc.eType.WHITE)
	place_disc(Vector2i(mid,     mid    ), Disc.eType.WHITE)
	place_disc(Vector2i(mid - 1, mid    ), Disc.eType.BLACK)
	place_disc(Vector2i(mid,     mid - 1), Disc.eType.BLACK)
	update_board_hint_all() # 盤面のヒントをすべて更新.

# clac_flip_positions()でひっくり返した情報をもとに計算されるダメージ量.
func get_last_damage() -> int:
	return _last_damage_info.calc_damage()

func set_mouse_pos(pos: Vector2) -> void:
	mouse_pos = pos
	var cell_size := _get_cell_size()
	var start := _get_board_start()
	grid_pos = Vector2i((mouse_pos - start) / cell_size)

# 盤面をクリックした.
func click(type: Disc.eType) -> Disc.eType:
	if board.is_valid_pos(grid_pos):
		place_disc(grid_pos, type) # 石を配置.

		# 置いた石から盤面の石をひっくり返す.
		flip_disc(grid_pos.x, grid_pos.y, type)
		
		update_board_hint(type) # 盤面のヒントを更新.

		return Disc.reverse(type)
	return type

# 指定の位置が有効な座標かどうか.
func is_valid(x: int, y: int) -> bool:
	return board.is_valid(x, y)

# 指定の位置に石が置けるかどうか.
func can_place_disc(type: Disc.eType) -> bool:
	if type == Disc.eType.WHITE:
		if board_hint_white.getv_pos(grid_pos) > 0:
			return true
	else:
		if board_hint_black.getv_pos(grid_pos) > 0:
			return true
	return false

func count_total() -> int:
	var count = [0] # gdscriptのLambdaは外部変数を直接変更できないため、配列にして参照渡しする.
	board.foreach(func(_x, _y, value):
		if value != Disc.eType.EMPTY:
			count[0] += 1
	)
	return count[0]
func count_if(type: Disc.eType) -> int:
	var count = [0] # gdscriptのLambdaは外部変数を直接変更できないため、配列にして参照渡しする.
	board.foreach(func(_x, _y, value):
		if value == type:
			count[0] += 1
	)
	return count[0]

func count_hint_total(type: Disc.eType) -> int:
	var count = [0] # gdscriptのLambdaは外部変数を直接変更できないため、配列にして参照渡しする.
	if type == Disc.eType.WHITE:
		board_hint_white.foreach(func(_x, _y, value):
			if value > 0:
				count[0] += 1
		)
	else:
		board_hint_black.foreach(func(_x, _y, value):
			if value > 0:
				count[0] += 1
		)
	return count[0]

# 石を置いたときにひっくり返す石のある座標リストを取得する.
func calc_flip_positions(x: int, y: int, type: Disc.eType) -> Array[Vector2i]:
	var flip_positions:Array[Vector2i] = [] # ひっくり返す石の座標リスト.
	_last_damage_info.clear() # ダメージ情報を初期化.
	# 8方向をチェック.
	var directions:Array[Vector2i] = [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0),  Vector2i.ZERO,   Vector2i(1, 0),
		Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
	]
	for dir in directions:
		var to_flip:Array[Vector2i] = [] # ひっくり返す石のリスト.
		var pos := Vector2i(x, y) + dir # チェックする位置.
		while board.is_valid(pos.x, pos.y):
			var current_type := board.getv(pos.x, pos.y)
			if current_type == Disc.eType.EMPTY:
				break # 空白に当たったら終了.
			elif current_type == type:
				# 同じ色の石に当たったら、to_flipの石をひっくり返す.
				if to_flip.size() > 0:
					_last_damage_info.turn_cnt += to_flip.size() # ひっくり返す石の数をカウント.
					_last_damage_info.dir_cnt += 1 # ひっくり返す方向の数をカウント.
				flip_positions += to_flip
				break
			else:
				to_flip.append(pos) # ひっくり返す候補に追加.
			pos += dir
		
	return flip_positions

# 石を置く (プレイヤー用).
func place_disc_player(type: Disc.eType, is_play_effect:bool=false) -> void:
	place_disc(grid_pos, type, is_play_effect)

# 石を置く.
func place_disc(pos: Vector2i, type: Disc.eType, is_play_effect:bool=false) -> void:
	if not board.is_valid_pos(pos):
		return # 範囲外は無視.
	
	var index := board.pos_to_index(pos)
	var disc: Disc = disc_map.get(index)
	if disc == null:
		# 新規に石を作成して配置.
		disc = DISC_OBJ.instantiate() as Disc
		var disc_layer := Common.get_layer("disc")
		disc_layer.add_child(disc)
		disc_map[index] = disc
	board.setv_pos(pos, type)

	var cell_size = _get_cell_size() # セルサイズを更新.
	var start := _get_board_start()
	var center := start + Vector2(pos.x * cell_size + cell_size / 2.0, pos.y * cell_size + cell_size / 2.0)
	var radius: float = cell_size * 0.42
	var delay: float = 0
	var rotating_count := _count_rotateing_discs()
	if rotating_count > 0:
		# 重なりがあるようにディレイを設定する.
		delay = 0.05 * rotating_count
	disc.set_draw_info(center, radius, type, delay) # 描画情報を更新.

	if is_play_effect:
		# 石を置いたときのエフェクトを再生.
		var p = pos_to_world(pos)
		var color := Color.BLACK if type == Disc.eType.BLACK else Color.WHITE
		var particle := Particle.spawn(Particle.eType.RING, 0.5, p, 0.2, color)
		particle.set_max_scale(0.8)

	return

func pos_to_world(pos: Vector2i) -> Vector2:
	var cell_size = _get_cell_size() # セルサイズを更新.
	var start := _get_board_start()
	return start + Vector2(pos.x * cell_size + cell_size / 2.0, pos.y * cell_size + cell_size / 2.0)

# 置いた石を基準に盤面の石をひっくり返す
func flip_disc(x: int, y: int, type: Disc.eType) -> void:
	var flip_positions := calc_flip_positions(x, y, type)

	# 相手属性にダメージを与える.
	var type2 := Disc.reverse(type)
	Common.damage(type2, flip_positions.size()) # ひっくり返す石の数に応じてダメージ

	for p in flip_positions:
		place_disc(p, type) # 石を配置（ひっくり返す）

# 盤面のヒントをすべて更新.
func update_board_hint_all() -> void:
	update_board_hint(Disc.eType.WHITE)
	update_board_hint(Disc.eType.BLACK)

# 盤面のヒントを更新する.
func update_board_hint(type: Disc.eType) -> void:
	board.foreach(func(x, y, value):
		if value == Disc.eType.EMPTY:
			var flip_positions := calc_flip_positions(x, y, type)
			var cnt = flip_positions.size()
			if type == Disc.eType.WHITE:
				board_hint_white.setv(x, y, cnt)
			else:
				board_hint_black.setv(x, y, cnt)
		else:
			if type == Disc.eType.WHITE:
				board_hint_white.setv(x, y, 0)
			else:
				board_hint_black.setv(x, y, 0)
	)

func get_board_hint(type: Disc.eType) -> Array2D:
	if type == Disc.eType.WHITE:
		return board_hint_white
	else:
		return board_hint_black

func _get_cell_size() -> float:
	var vp_size := get_viewport_rect().size
	var margin := 20.0 # 盤面周りの余白
	return min((vp_size.x - margin * 2) / BOARD_SIZE, (vp_size.y - margin * 2) / BOARD_SIZE)

func _get_board_start() -> Vector2:
	var vp_size := get_viewport_rect().size
	var cell_size := _get_cell_size()
	var board_pixel := cell_size * BOARD_SIZE
	return (vp_size - Vector2(board_pixel, board_pixel)) / 2.0

# 盤面上の回転中のコマの数をカウントする.
func _count_rotateing_discs() -> int:
	var count := 0
	for disc in disc_map.values():
		if disc.is_rotateing():
			count += 1
	return count

# -------------------------------------------------------
# イベント関数.
# -------------------------------------------------------
func _process(_delta: float) -> void:
	queue_redraw() # 描画更新.

# -------------------------------------------------------
# 以下、描画関数.
# -------------------------------------------------------
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

	# 盤面ヒントの描画.
	board_hint_black.foreach(func(x, y, hint):
		if hint > 0:
			_draw_text_board(Vector2i(x, y), str(hint), Color(1, 1, 1))
	)
	

# マウス位置にグリッド線を描画.
func _draw_mouse_cursor_grid(start: Vector2, cell_size: float) -> void:
	var mouse_grid := (mouse_pos - start) / cell_size
	if mouse_grid.x >= 0 and mouse_grid.x < BOARD_SIZE and mouse_grid.y >= 0 and mouse_grid.y < BOARD_SIZE:
		var grid_pos := Vector2(int(mouse_grid.x), int(mouse_grid.y))
		var line_color := Color(1, 1, 0, 0.8)
		# 四角形で描画.
		var rect := Rect2(start + grid_pos * cell_size, Vector2(cell_size, cell_size))
		draw_rect(rect, line_color, false, 2.0)

# セルの中心にテキストを描画.
func _draw_text_board(cell:Vector2i, text:String, color:Color, font_size:int=32) -> void:
	var label_settings := LABEL_SETTINGS as LabelSettings
	var font: Font = label_settings.font if label_settings != null else null
	var cell_size := _get_cell_size()
	var pos := _get_board_start() + Vector2((cell.x * cell_size) + (cell_size / 2.0), (cell.y * cell_size) + (cell_size / 2.0))
	# Godot 4.6 の draw_string シグネチャに合わせて全引数を指定
	# (font, pos, text, alignment, width, font_size, modulate, justification_flags, direction, orientation, oversampling)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size, color, 0, 0, 0, 0.0)
