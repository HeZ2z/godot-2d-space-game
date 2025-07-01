class_name LoopingAudioStreamPlayer2D  # 循环音频流播放器2D类
extends AudioStreamPlayer2D

@export var sound_start: AudioStream  # 开始播放的音频流
@export var sound_loop: AudioStream  # 循环播放的音频流
@export var sound_tail: AudioStream  # 结束播放的音频流

var ending := false  # 是否正在结束播放


func _ready() -> void:
	# 连接播放完成信号
	finished.connect(_on_finished)


func start() -> void:
	# 开始播放音频
	stream = sound_start
	ending = false
	play()


func end() -> void:
	# 结束播放音频
	stream = sound_tail
	ending = true


func _on_finished() -> void:
	# 播放完成时的回调
	if stream == sound_start:
		# 如果刚播放完开始音频，切换到循环音频
		stream = sound_loop
		play()
