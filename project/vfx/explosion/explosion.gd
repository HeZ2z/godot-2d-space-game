# 爆炸视觉效果，包含音效和冲击波
extends Node2D

# 爆炸音效样本数组
var _audio_samples := [
	preload("explosion_01.wav"),
	preload("explosion_02.wav"),
	preload("explosion_03.wav"),
	preload("explosion_04.wav"),
]

@export var Shockwave: PackedScene  # 冲击波场景

@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D  # 音频播放器
@onready var anim: AnimationPlayer = $AnimationPlayer  # 动画播放器

func _ready() -> void:
	# 发出爆炸发生事件
	Events.explosion_occurred.emit()
	
	# 随机选择一个爆炸音效并播放
	audio.stream = _audio_samples[randi() % _audio_samples.size()]
	audio.play()
	# 创建冲击波效果
	var shockwave := Shockwave.instantiate()
	ObjectRegistry.register_distortion_effect(shockwave)
	shockwave.global_position = global_position
	shockwave.emitting = true
	shockwave.get_node("LifeSpan").autostart = true
	
	# 播放爆炸动画
	anim.play(&"Explode")
