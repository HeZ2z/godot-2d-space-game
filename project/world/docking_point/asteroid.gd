# Represents an extended dockable that holds a random amount of mineable
# resources.
# 代表一个扩展的可对接对象，包含随机数量的可开采资源。
class_name Asteroid
extends DockingPoint

signal mined(amount)  # 开采信号
signal depleted  # 耗尽信号

@export var min_iron_amount := 5.0  # 最少铁矿量
@export var max_iron_amount := 100.0  # 最多铁矿量
@export var min_scale := 0.2  # 最小缩放比例

@onready var anim_player: AnimationPlayer = $AnimationPlayer  # 动画播放器
@onready var fx_anim_player: AnimationPlayer = $FXAnimationPlayer  # 特效动画播放器
@onready var sprite: Sprite2D = $Sprite2D  # 精灵

var iron_amount := 0.0  # 当前铁矿量


func _ready() -> void:
	# 初始化小行星
	super()
	anim_player.speed_scale = randf_range(0.5, 2.0)  # 随机动画速度


func setup(rng: RandomNumberGenerator) -> void:
	# 设置小行星属性
	iron_amount = rng.randf_range(min_iron_amount, max_iron_amount)
	scale *= max(iron_amount / max_iron_amount, min_scale)  # 根据铁矿量调整大小


func mine_amount(value: float) -> float:
	# 开采指定数量的矿物
	var mined_amount: float = min(iron_amount, value)
	iron_amount -= mined_amount
	mined.emit(mined_amount)

	if is_equal_approx(iron_amount, 0.0):
		# 如果开采完毕，脱离对接并收缩
		undock()
		shrink()
	elif not anim_player.is_playing():
		# 播放脉冲特效
		fx_anim_player.play("pulse")

	return mined_amount


# Animates the asteroid shrinking down and frees it.
# 播放小行星收缩动画并释放它
func shrink() -> void:
	var fx_tween = create_tween()
	if fx_anim_player.is_playing():
		fx_anim_player.stop(false)
	fx_tween.tween_property(
		sprite, "scale", Vector2.ZERO, 0.25
	).from_current().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	fx_tween.tween_property(
		dock_aura, "scale", Vector2.ZERO, 0.5
	).from_current().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	fx_tween.play()
	await fx_tween.finished
	queue_free()


func _on_DockingArea_body_entered(body: Node) -> void:
	# 进入对接区域时停止动画
	super._on_DockingArea_body_entered(body)
	anim_player.stop(false)


func _on_DockingArea_body_exited(body: Node) -> void:
	# 离开对接区域时重新播放动画
	super._on_DockingArea_body_exited(body)
	anim_player.play()
