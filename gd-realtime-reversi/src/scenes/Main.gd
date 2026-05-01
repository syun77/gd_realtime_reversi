extends Node2D
# ================================================
# メインシーン.
# ================================================
@onready var _board := $Board # 盤面.
@onready var _disc_layer := $DiscLayer # コマの描画用レイヤー.

var _turn := Disc.eType.BLACK # 現在のターン.

# 開始.
func _ready() -> void:
	Common.register_layers({
		"disc": _disc_layer
	})
	# 盤面の登録.
	Common.register_board(_board)
	
	# 盤面の初期化.
	_board.init_board()

# 更新.
func _process(_delta: float) -> void:
	# マウス位置の更新.
	var mouse_pos = get_viewport().get_mouse_position()
	_board.set_mouse_pos(mouse_pos) # 盤面にマウス位置を渡す.

	# クリックした場所に石を配置.
	if Input.is_action_just_pressed("click"):
		_turn = _board.click(_turn) # 盤面のクリック処理.
