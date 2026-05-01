extends Node
# ================================================
# 共通ユーティリティクラス.
# ================================================
class_name Common

static var _layers:Dictionary[String, CanvasLayer] = {} # レイヤー管理用マップ.
static var _board:Board = null # 盤面クラスの参照.

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
