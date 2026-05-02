extends Node
# ================================================
# 共通ユーティリティクラス.
# ================================================
class_name Common

const DEFAULT_PLAYER_HP := 100 # プレイヤーの初期HP.
const DEFAULT_ENEMY_HP := 100 # 敵の初期HP.
const MAX_ATB := 100 # ATBゲージの最大値.

static var _layers:Dictionary[String, CanvasLayer] = {} # レイヤー管理用マップ.
static var _board:Board = null # 盤面クラスの参照.
static var _player_hp:int = DEFAULT_PLAYER_HP # プレイヤーのHP.
static var _enemy_hp:int = DEFAULT_ENEMY_HP	 # 敵のHP.
static var _enemy_atb:float = 0 # 敵のATBゲージ.

# ゲームの初期化.
static func init_game() -> void:
	_player_hp = DEFAULT_PLAYER_HP
	_enemy_hp = DEFAULT_ENEMY_HP
	_enemy_atb = 0

static func get_player_hp() -> int:
	return _player_hp
static func get_enemy_hp() -> int:
	return _enemy_hp
static func get_enemy_atb() -> float:
	return _enemy_atb
static func is_enemy_atb_full() -> bool:
	return _enemy_atb >= MAX_ATB
static func charge_enemy_atb(amount:float) -> void:
	_enemy_atb = min(MAX_ATB, _enemy_atb + amount)

static func damage(type:Disc.eType, amount:int) -> void:
	if type == Disc.eType.WHITE:
		_player_hp = max(0, _player_hp - amount)
	elif type == Disc.eType.BLACK:
		_enemy_hp = max(0, _enemy_hp - amount)

# レイヤーの取得
static func get_layer(layer_name:String) -> CanvasLayer:
	if _layers.has(layer_name):
		return _layers[layer_name]
	return null

# レイヤーの登録.
static func register_layers(layers:Dictionary[String, CanvasLayer]) -> void:
	_layers = layers

# 盤面クラスの参照を登録.
static func register_board(board:Board) -> void:
	_board = board

# 盤面クラスの参照を取得.
static func get_board() -> Board:
	return _board
