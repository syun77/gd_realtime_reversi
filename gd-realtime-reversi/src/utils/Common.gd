extends Node
# ================================================
# 共通ユーティリティクラス.
# ================================================
class_name Common

const DEFAULT_PLAYER_HP := 100 # プレイヤーの初期HP.
const DEFAULT_ENEMY_HP := 100 # 敵の初期HP.
const MAX_ATB := 100 # ATBゲージの最大値.

static var _layers:Dictionary[String, CanvasLayer] = {} # レイヤー管理用マップ.
static var _main:MainScene = null # Mainシーンの参照.
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
static func reset_enemy_atb() -> void:
	_enemy_atb = 0

static func damage(type:Disc.eType, amount:int) -> void:
	if type == Disc.eType.WHITE:
		_player_hp = max(0, _player_hp - amount)
		MainScene.request_damage_shake(type, amount)
	elif type == Disc.eType.BLACK:
		_enemy_hp = max(0, _enemy_hp - amount)
		MainScene.request_damage_shake(type, amount)

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

# Mainシーンの参照を登録.
static func register_main(scene:MainScene) -> void:
	_main = scene

# Mainシーンの参照を取得.
static func get_main() -> MainScene:
	return _main

# ------------------------------------------------
# サウンドデータ.
# ------------------------------------------------
const MAX_SOUND = 8 # 同時に鳴らせる最大サウンド数.

# SEテーブル.
static var _snd_tbl = {
	"pi":    "res://assets/sounds/pi.wav",
	"ready": "res://assets/sounds/ready.wav",
	"place": "res://assets/sounds/place.wav",
	"break": "res://assets/sounds/break.wav",
	"build": "res://assets/sounds/build.wav",
	"destroy": "res://assets/sounds/destroy.wav",
	"hit": "res://assets/sounds/hit.wav",
	"laser": "res://assets/sounds/laser.wav",
	"start": "res://assets/sounds/start.wav",
	"upgrade": "res://assets/sounds/upgrade.wav",
}

static var _se_players:Array[AudioStreamPlayer]

static func setup_sounds(parent:Node) -> void:
	_se_players = []
	for i in range(MAX_SOUND):
		var player := AudioStreamPlayer.new()
		parent.add_child(player)
		_se_players.append(player)

# SEを再生.
static func play_se(se_name:String, id:int=0) -> void:
	if id < 0 or id >= MAX_SOUND:
		push_error("不正なサウンドID: " + str(id))
		return # 無効なIDは無視.
	
	if not se_name in _snd_tbl:
		push_error("不正なサウンド名: " + se_name)
		return # 無効なサウンド名は無視.
	
	var snd = _se_players[id]
	# サウンドファイルをロード.
	snd.stream = load(_snd_tbl[se_name])
	snd.play() # サウンドを再生.
