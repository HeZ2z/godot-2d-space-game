# A physics body that moves in a straight line at a constant speed until it runs
# into something that it's able to collide with, at which point it signals
# damage.
# 以恒定速度直线移动的物理体，直到撞击到可碰撞的物体，此时发出伤害信号。
class_name Projectile
extends CharacterBody2D

const _AUDIO_SAMPLES = [
	# 音频样本列表
	preload("weapons_plasma_shot_01.wav"),
	preload("weapons_plasma_shot_02.wav"),
	preload("weapons_plasma_shot_03.wav"),
	preload("weapons_plasma_shot_04.wav"),
	preload("weapons_plasma_shot_05.wav"),
	preload("weapons_plasma_shot_06.wav"),
]

@export var speed := 1650.0  # 移动速度
@export var damage := 10.0  # 伤害值
@export var distortion_emitter: PackedScene  # 扭曲效果发射器场景

var is_active := true: set = set_is_active  # 是否激活
var direction := Vector2.ZERO  # 移动方向
var shooter: Node  # 射击者

@onready var tween : Tween  # 补间动画
@onready var sprite := $Sprite2D  # 精灵
@onready var player := $AnimationPlayer  # 动画播放器
@onready var remote_transform := $DistortionTransform  # 远程变换
@onready var visibility_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D  # 可见性通知器
@onready var collider: CollisionShape2D = $CollisionShape2D  # 碰撞器
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D  # 音频播放器


func _ready() -> void:
	# 初始化抛射物
	direction = -GSAIUtils.angle_to_vector2(rotation)  # 设置移动方向
	visibility_notifier.screen_exited.connect(queue_free)  # 离开屏幕时销毁

	sprite.material = sprite.material.duplicate()  # 复制材质
	player.play("Flicker")  # 播放闪烁动画

	var emitter := distortion_emitter.instantiate()  # 创建扭曲效果发射器
	ObjectRegistry.register_distortion_effect(emitter)
	remote_transform.remote_path = emitter.get_path()

	appear()  # 播放出现动画

#E 0:01:17:0974   Projectile.gd:50 @ _physics_process(): Error calling from signal 'damaged' to callable: 'CharacterBody2D(PirateShip.gd)::_on_self_damaged': Cannot convert argument 3 from Object to Object.

func _physics_process(delta: float) -> void:
	# 物理处理：移动和碰撞检测
	var collision := move_and_collide(direction * speed * delta)
	if collision:
		Events.damaged.emit(collision.get_collider(), damage, shooter)
		die()


func appear() -> void:
	self.is_active = true
	tween = create_tween()
	tween.tween_method(_fade, 0.0, 1.0, 0.05).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(
		self, "scale", scale, 0.05
	).from(scale / 5.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.play()

	audio.stream = _AUDIO_SAMPLES[randi() % _AUDIO_SAMPLES.size()]
	audio.play()


func die() -> void:
	self.is_active = false
	tween = create_tween()
	tween.tween_method(_fade, 1.0, 0.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.play()
	await tween.finished
	queue_free()


func set_is_active(value: bool) -> void:
	is_active = value
	collider.disabled = not is_active
	set_physics_process(is_active)


func _fade(value: float) -> void:
	sprite.material.set_shader_parameter("fade_amount", value)
