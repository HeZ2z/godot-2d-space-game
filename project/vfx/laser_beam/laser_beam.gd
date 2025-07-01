# 激光束视觉效果，具有动态长度和粒子效果
extends RayCast2D

@export var cast_speed := 7000.0  # 发射速度
@export var max_length := 1400  # 最大长度
@export var growth_time := 0.1  # 生长时间

@onready var casting_particles := $CastingParticles2D  # 发射粒子
@onready var collision_particles := $CollisionParticles2D  # 碰撞粒子
@onready var beam_particles := $BeamParticles2D  # 光束粒子
@onready var fill := $FillLine2D  # 填充线条
@onready var tween : Tween  # 补间动画
@onready var line_width: float = fill.width  # 线条宽度

var is_casting := false: set = set_is_casting  # 是否正在发射


func _ready() -> void:
	set_physics_process(false)
	fill.points[1] = Vector2.ZERO


func _physics_process(delta: float) -> void:
	# 更新激光目标位置
	target_position = (target_position + Vector2.RIGHT * cast_speed * delta).limit_length(max_length)
	cast_beam()


func set_is_casting(cast: bool) -> void:
	# 设置发射状态
	is_casting = cast

	if is_casting:
		target_position = Vector2.ZERO
		fill.points[1] = target_position
		appear()  # 显示激光
	else:
		collision_particles.emitting = false
		disappear()  # 隐藏激光

	set_physics_process(is_casting)
	beam_particles.emitting = is_casting
	casting_particles.emitting = is_casting


func cast_beam() -> void:
	# 发射激光束
	var cast_point := target_position

	# 必需的，射线投射的碰撞在移动后一帧才更新，否则激光会超越碰撞点
	# Required, the raycast's collisions update one frame after moving otherwise, making the laser
	# overshoot the collision point.
	force_raycast_update()
	if is_colliding():
		cast_point = to_local(get_collision_point())
		# 设置碰撞粒子方向
		collision_particles.process_material.direction = Vector3(
			get_collision_normal().x, get_collision_normal().y, 0
		)

	collision_particles.emitting = is_colliding()

	# 更新激光束视觉效果
	fill.points[1] = cast_point
	collision_particles.position = cast_point
	beam_particles.position = cast_point * 0.5
	beam_particles.process_material.emission_box_extents.x = cast_point.length() * 0.5


func appear() -> void:
	# 激光出现动画
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(fill, "width", line_width, growth_time * 2).from(0.0)
	tween.play()


func disappear() -> void:
	# 激光消失动画
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(fill, "width", 0, growth_time).from(fill.width)
	tween.play()
