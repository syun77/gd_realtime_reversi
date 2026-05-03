extends Node2D
# ================================================
# メインシーン.
# ================================================
const TYPE_ENEMY := Disc.eType.BLACK # 敵の石の種類.

# 状態.
enum eState {
	READY, # 開始演出.
	MAIN, # メイン.
	ENEMY_TURN, # 敵のターン.
	GAME_END, # ゲーム終了.
}

@onready var _board := $Board # 盤面.
@onready var _disc_layer := $DiscLayer # コマの描画用レイヤー.
# UI.
@onready var _ui_layer := $UILayer # UIのレイヤー.
@onready var _player_hp_bar := %PlayerHPBar # プレイヤーのHPバー (ユニークIDアクセスなのでこの記述で問題ない).
@onready var _enemy_hp_bar := %EnemyHPBar # 敵のHPバー (ユニークIDアクセスなのでこの記述で問題ない).
@onready var _enemy_atb_bar := %EnemyATBBar # 敵のATBバー (ユニークIDアクセスなのでこの記述で問題ない).

var _state := StateObj.new() # 状態オブジェクト.
var _turn := Disc.eType.WHITE # 現在のターン.
var _enemy_place_pos := Vector2i.ZERO

# 開始.
func _ready() -> void:
	# ゲームの初期化.
	Common.init_game()

	# 各種CanvasLayerを登録.
	Common.register_layers({
		"disc": _disc_layer,
		"ui": _ui_layer,
	})
	# 盤面の登録.
	Common.register_board(_board)
	
	# 盤面の初期化.
	_board.init_board(_turn)

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
	_update_enemy_atb(_delta) # 敵のATBゲージの更新.
	if Common.is_enemy_atb_full():
		_state.change(eState.ENEMY_TURN) # 敵のATBゲージが満タンになったら敵のターンに移行.
		return

	# マウス位置の更新.
	var mouse_pos = get_viewport().get_mouse_position()
	_board.set_mouse_pos(mouse_pos) # 盤面にマウス位置を渡す.

	# クリックした場所に石を配置.
	if Input.is_action_just_pressed("click"):
		_board.click(_turn) # 盤面のクリック処理.

# 更新 > 敵のターン.
func _update_enemy_turn(_delta:float) -> void:
	if _state.is_first():
		_board.update_board_hint(TYPE_ENEMY) # 敵のヒントを更新.
		var hint:Array2D = _board.board_hint # ヒントを取得.
		var ret := hint.find_if(func(_x, _y, value):
			if value > 0:
				return true # 置ける場所が対象.
			return false
		)
		if ret.is_empty():
			# 置ける場所がない場合はプレイヤーのターンに戻る.
			_state.change(eState.MAIN)
			Common.reset_enemy_atb() # 敵のATBゲージをリセット.
			return

		ret.shuffle() # 置ける場所をランダムにシャッフル.
		var pos := ret[0] # 最初の場所を選択.
		_board.place_disc(pos.x, pos.y, TYPE_ENEMY) # 石を配置.
		_enemy_place_pos = pos # 敵が石を置いた場所を保存.
		return

	if _state.get_timer() > 0.5: # 石を置いてから0.5秒後にひっくり返す.
		var pos = _enemy_place_pos
		var list = _board.calc_flip_positions(pos.x, pos.y, TYPE_ENEMY) # 置いた石を基準に盤面の石をひっくり返す.
		for pos2 in list:
			_board.place_disc(pos2.x, pos2.y, TYPE_ENEMY) # 石を配置（ひっくり返す）
		
		Common.reset_enemy_atb() # 敵のATBゲージをリセット.
		_state.change(eState.MAIN) # プレイヤーのターンに移行
	

# 更新 > ゲーム終了.
func _update_game_end(_delta:float) -> void:
	pass

# 敵のATBゲージの更新.
func _update_enemy_atb(delta:float) -> void:
	Common.charge_enemy_atb(delta * 100)

# UIの更新.
func _update_ui() -> void:
	# HPバーの更新.
	_player_hp_bar.value = Common.get_player_hp()
	_enemy_hp_bar.value = Common.get_enemy_hp()
	_enemy_atb_bar.value = Common.get_enemy_atb()
