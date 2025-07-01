# 一次性粒子发射器，使用后自动回收
# One-shot particle emitter that recycles itself after use.
extends GPUParticles2D

@onready var timer := $Timer  # 计时器
var is_dying := false  # 是否正在消失


func _ready() -> void:
	# 设置为一次性发射并开始发射粒子
	one_shot = true
	emitting = true


func _process(_delta: float) -> void:
	# 如果不再发射且未在消失过程中，开始消失
	if not emitting and not is_dying:
		die()


func die() -> void:
	# 开始消失过程
	is_dying = true
	timer.start(lifetime)
	await timer.timeout
	queue_free()  # 删除自身
