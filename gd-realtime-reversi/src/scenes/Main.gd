extends Node2D
# ================================================
# メインシーン.
# ================================================
const TYPE_PLAYER := Disc.eType.BLACK # プレイヤーの石の種類.
const TYPE_ENEMY := Disc.eType.WHITE # 敵の石の種類.
const ENERGY_BALL_OBJ = preload("res://src/objects/EnergyBall.tscn") # エネルギーボールのシーン.

# 状態.
enum eState {
	READY, # 開始演出.
	MAIN, # メイン.
	PLAYER_TURN, # プレイヤーのターン.
	ENEMY_TURN, # 敵のターン.
	GAME_END, # ゲーム終了.
}

@onready var _board := $Board # 盤面.
@onready var _disc_layer := $DiscLayer # コマの描画用レイヤー.
@onready var _energy_layer := $EnergyLayer # エネルギーボールの描画用レイヤー.
@onready var _particle_layer := $ParticleLayer # パーティクルの描画用レイヤー.
# UI.
@onready var _ui_layer := $UILayer # UIのレイヤー.
@onready var _player_hp_bar := %PlayerHPBar # プレイヤーのHPバー (ユニークIDアクセスなのでこの記述で問題ない).
@onready var _enemy_hp_bar := %EnemyHPBar # 敵のHPバー (ユニークIDアクセスなのでこの記述で問題ない).
@onready var _enemy_atb_bar := %EnemyATBBar # 敵のATBバー (ユニークIDアクセスなのでこの記述で問題ない).
@onready var _player_marker := %PlayerMarker # プレイヤーのHPマーカー (ユニークIDアクセスなのでこの記述で問題ない).
@onready var _enemy_marker := %EnemyMarker # 敵のHPマーカー (ユニークIDアクセスなのでこの記述で問題ない).

var _state := StateObj.new() # 状態オブジェクト.
var _enemy_place_pos := Vector2i.ZERO

# 開始.
func _ready() -> void:
	# ゲームの初期化.
	Common.init_game()

	# 各種CanvasLayerを登録.
	Common.register_layers({
		"disc": _disc_layer,
		"ui": _ui_layer,
		"particle": _particle_layer,
		"energy": _energy_layer,
	})
	# 盤面の登録.
	Common.register_board(_board)
	
	# 盤面の初期化.
	_board.init_board()

	# UIの初期化.
	_init_ui()

# UIの初期化.
func _init_ui() -> void:
	_update_ui()

# 更新.
func _process(delta: float) -> void:
	_state.update(delta) # 状態の更新.
	match _state.get_state():
		eState.READY:
			# 開始演出の処理.
			_update_ready(delta)
		eState.MAIN:
			_update_main(delta)
		eState.PLAYER_TURN:
			# プレイヤーのターンの処理.
			_update_player_turn(delta)
		eState.ENEMY_TURN:
			# 敵のターンの処理.
			_update_enemy_turn(delta)
		eState.GAME_END:
			# ゲーム終了の処理.
			_update_game_end(delta)

	_update_ui() # UIの更新.

# 更新 > 開始演出.
func _update_ready(_delta:float) -> void:
	# TODO: 開始演出.
	# 演出が終了したらメイン状態に移行.
	_state.change_state(eState.MAIN)

# 更新 > メイン.
func _update_main(_delta:float) -> void:
	# マウス位置の更新.
	var mouse_pos = get_viewport().get_mouse_position()
	_board.set_mouse_pos(mouse_pos) # 盤面にマウス位置を渡す.

	# クリックした場所に石を配置.
	if Input.is_action_just_pressed("click"):
		# 指定した位置に石が置けるかをチェック.
		if not _board.can_place_disc(TYPE_PLAYER):
			return # クリックが有効でない場合は無視.
		_state.change(eState.PLAYER_TURN) # プレイヤーのターンに移行.
		return
	
	# 敵のATBゲージの更新.
	_update_enemy_atb(_delta)
	if Common.is_enemy_atb_full():
		if _board.count_hint_total(TYPE_ENEMY) > 0: # 敵が置ける場所がある場合のみ敵のターンに移行.
			_board.set_hint_draw_fg(false) # 敵のターン中はヒントの前景を非表示にする.
			_state.change(eState.ENEMY_TURN) # 敵のATBゲージが満タンになったら敵のターンに移行.
			return

# 更新 > プレイヤーのターン.
func _update_player_turn(_delta:float) -> void:
	if _state.is_first():
		# 石を置く.
		_board.place_disc_player(TYPE_PLAYER, true) # プレイヤーの石を配置.
		return
	
	if _state.get_timer() > 0.5: # 石を置いてから0.5秒後にひっくり返す.
		var pos = _board.grid_pos
		var list = _board.calc_flip_positions(pos.x, pos.y, TYPE_PLAYER) # 置いた石を基準に盤面の石をひっくり返す.
		for pos2 in list:
			_board.place_disc(pos2, TYPE_PLAYER, true) # 石を配置（ひっくり返す）
		var damage = _board.get_last_damage() # ひっくり返した石の数からダメージを計算.
		add_energy_ball(pos, TYPE_PLAYER, damage) # エネルギーボールを追加.
		
		_update_hint() # ヒントの更新.
		_state.change(eState.MAIN) # メイン状態に移行.


# 更新 > 敵のターン.
func _update_enemy_turn(_delta:float) -> void:
	if _state.is_first():
		var hint:Array2D = _board.get_board_hint(TYPE_ENEMY) # ヒントを取得.
		var ret := hint.find_if(func(_x, _y, value):
			if value > 0:
				return true # 置ける場所が対象.
			return false
		)
		if ret.is_empty():
			# 置ける場所がない場合はプレイヤーのターンに戻る.
			_update_hint() # ヒントの更新.
			_state.change(eState.MAIN)
			Common.reset_enemy_atb() # 敵のATBゲージをリセット.
			return

		ret.shuffle() # 置ける場所をランダムにシャッフル.
		var pos := ret[0] # 最初の場所を選択.
		_board.place_disc(pos, TYPE_ENEMY, true) # 石を配置.
		_enemy_place_pos = pos # 敵が石を置いた場所を保存.
		return

	if _state.get_timer() > 0.5: # 石を置いてから0.5秒後にひっくり返す.
		var pos = _enemy_place_pos
		var list = _board.calc_flip_positions(pos.x, pos.y, TYPE_ENEMY) # 置いた石を基準に盤面の石をひっくり返す.
		for pos2 in list:
			_board.place_disc(pos2, TYPE_ENEMY, true) # 石を配置（ひっくり返す）
		var damage = _board.get_last_damage() # ひっくり返した石の数からダメージを計算.
		add_energy_ball(pos, TYPE_ENEMY, damage) # エネルギーボールを追加.

		Common.reset_enemy_atb() # 敵のATBゲージをリセット.
		_update_hint() # ヒントの更新.
		_board.set_hint_draw_fg(true) # ヒントを再表示.
		_state.change(eState.MAIN) # プレイヤーのターンに移行.

# エネルギーボールを追加.
func add_energy_ball(pos:Vector2i, type:Disc.eType, damage:int) -> void:
	var ball = ENERGY_BALL_OBJ.instantiate() as EnergyBall
	var p = _board.pos_to_world(pos) # 盤面の座標をワールド座標に変換.
	var target = _get_target_pos(type) # ターゲット座標を取得.
	Common.get_layer("energy").add_child(ball)
	ball.setup(type, damage, p, target, 300.0)

# 更新 > ゲーム終了.
func _update_game_end(_delta:float) -> void:
	pass

# 敵のATBゲージの更新.
func _update_enemy_atb(delta:float) -> void:
	var total = _board.count_total()
	var white = _board.count_if(TYPE_ENEMY)
	var black = _board.count_if(TYPE_PLAYER)
	var rate = 30
	if black == 1:
		rate = 30 # 最後の一枚の場合は長く待ちます.
	elif white == 1:
		rate = 500 # 自分が最後の一枚の場合は高速.
	elif total < 8:
		rate = 100 - total # 8枚までは早指し.
	else:
		# それ以降は枚数の応じて遅くなる.
		rate = 10 + white * 5
	if rate < 30:
		rate = 30
	Common.charge_enemy_atb(delta * rate)

# ヒントの更新.
func _update_hint() -> void:
	_board.update_board_hint_all()

# UIの更新.
func _update_ui() -> void:
	# HPバーの更新.
	_player_hp_bar.value = Common.get_player_hp()
	_enemy_hp_bar.value = Common.get_enemy_hp()
	_enemy_atb_bar.value = Common.get_enemy_atb()

# ターゲット座標の取得.
func _get_target_pos(type:Disc.eType) -> Vector2:
	if type == TYPE_PLAYER:
		return _enemy_marker.global_position
	elif type == TYPE_ENEMY:
		return _player_marker.global_position
	return Vector2.ZERO
