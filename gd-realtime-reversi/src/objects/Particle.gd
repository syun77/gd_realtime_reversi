extends Sprite2D
# ================================================
# パーティクルクラス.
# ================================================
class_name Particle

const IMG_RING = preload("res://assets/images/ring.png") # リングのテクスチャ.
const IMG_CIRCLE = preload("res://assets/images/circle.png") # 円のテクスチャ.

enum eType {
	RING, # リング.
	CIRCLE, # 円.
}

var _type := eType.RING # パーティクルの種類.
var _timer := 0.0 # タイマー.
var _duration := 1.0 # パーティクルの持続時間.
var _velocity := Vector2.ZERO # 速度.
var _acceleration := Vector2.ZERO # 加速度.
var _decay := 0.97 # 速度減衰率.
var _base_scale := 1.0 # 基本スケール値.
var _max_scale := 1.0 # 最大拡大スケール値.

# 速度設定.
func set_velocity(deg: float, speed: float, decay: float) -> void:
	var rad := deg_to_rad(deg)
	_velocity = Vector2(cos(rad), -sin(rad)) * speed
	_decay = decay

# 加速度の設定
func set_acceleration(deg: float, power: float) -> void:
	var rad := deg_to_rad(deg)
	_acceleration = Vector2(cos(rad), -sin(rad)) * power

# 最大拡大スケール値の設定.
func set_max_scale(max_scale: float) -> void:
	_max_scale = max_scale

# セットアップ.
func setup(type: eType, duration: float, pos: Vector2, sc: float, color: Color) -> void:
	_type = type
	position = pos
	modulate = color
	_duration = duration
	_timer = 0.0
	_base_scale = sc
	scale = Vector2.ONE * _base_scale

func _ready() -> void:
	# 初期化処理.
	match _type:
		eType.RING:
			texture = IMG_RING # リングのテクスチャ.
		eType.CIRCLE:
			texture = IMG_CIRCLE # 円のテクスチャ.

func _get_rate() -> float:
	return _timer / _duration

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= _duration:
		queue_free() # パーティクルの寿命が尽きたら削除
		return
	
	# 位置の更新.
	_velocity += _acceleration # 加速度の加算.
	_velocity *= _decay # 速度の減衰.
	position += _velocity * delta
	
	match _type:
		eType.RING:
			var d = _max_scale - _base_scale
			scale = Vector2.ONE * (_base_scale + Easing.expo_out(d * _get_rate())) # 拡大.
			modulate.a = 1.0 - _get_rate() # 徐々に透明に.
		eType.CIRCLE:
			var d = _max_scale - _base_scale
			scale = Vector2.ONE * (_base_scale + d * Easing.expo_out(_get_rate())) # 拡大.
			modulate.a = 1.0 - _get_rate() # 徐々に透明に.
			pass

# ------------------------------------------------
# static functions.
# ------------------------------------------------
# パーティクルの生成.
static func spawn(type: eType, duration: float, pos: Vector2, sc: float, color: Color) -> Particle:
	var particle = Particle.new()
	particle.setup(type, duration, pos, sc, color)
	var layer := Common.get_layer("particle") # パーティクル用のレイヤーを取得.
	layer.add_child(particle) # パーティクルをレイヤーに追加.
	return particle

# ボールパーティクルの生成.
static func spawn_ball(pos: Vector2, deg: float, speed: float, duration:float, sc: float, color: Color) -> Particle:
	var particle = Particle.new()
	particle.setup(eType.CIRCLE, duration, pos, sc, color)
	particle.set_velocity(deg, speed, 0.98)
	var layer := Common.get_layer("particle") # パーティクル用のレイヤーを取得.
	layer.add_child(particle) # パーティクルをレイヤーに追加.
	return particle

static func spawn_balls(center:Vector2, count: int, color: Color) -> void:
	# ランダムな方向を決める.
	var deg = randf() * 360.0
	for i in range(count):
		# 速度.
		var speed = 250.0 + randf() * 50.0
		var sc = 0.5 + randf() * 0.2
		var time = 0.5 + randf() * 0.5
		var p = spawn_ball(center, deg, speed, time, sc, color)
		p.set_max_scale(0) # 小さくなる.
		p.set_acceleration(270, 10.0) # 重力のように下方向に加速.
		deg += 30.0 + randf() * 30.0 # 次のボールの方向を決める.