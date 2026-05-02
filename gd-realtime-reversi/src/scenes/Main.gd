extends Node2D
# ================================================
# メインシーン.
# ================================================
@onready var _board := $Board # 盤面.
@onready var _disc_layer := $DiscLayer # コマの描画用レイヤー.
@onready var _ui_layer := $UILayer # UIのレイヤー.
@onready var _player_hp_bar := %PlayerHPBar # プレイヤーのHPバー (ユニークIDアクセスなのでこの記述で問題ない).
@onready var _enemy_hp_bar := %EnemyHPBar # 敵のHPバー (ユニークIDアクセスなのでこの記述で問題ない).
@onready var _enemy_atb_bar := %EnemyATBBar # 敵のATBバー (ユニークIDアクセスなのでこの記述で問題ない).

var _turn := Disc.eType.WHITE # 現在のターン.

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
func _process(_delta: float) -> void:
	_update_enemy_atb(_delta) # 敵のATBゲージの更新.

	# マウス位置の更新.
	var mouse_pos = get_viewport().get_mouse_position()
	_board.set_mouse_pos(mouse_pos) # 盤面にマウス位置を渡す.

	# クリックした場所に石を配置.
	if Input.is_action_just_pressed("click"):
		_turn = _board.click(_turn) # 盤面のクリック処理.

	_update_ui() # UIの更新.

# 敵のATBゲージの更新.
func _update_enemy_atb(delta:float) -> void:
	Common.charge_enemy_atb(delta * 100)

# UIの更新.
func _update_ui() -> void:
	# HPバーの更新.
	_player_hp_bar.value = Common.get_player_hp()
	_enemy_hp_bar.value = Common.get_enemy_hp()
	_enemy_atb_bar.value = Common.get_enemy_atb()