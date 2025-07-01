# 海盗有限状态机的生成状态。小队长使用抵达转向行为从生成点
# 前往小队将要巡逻的空间点。小队成员使用聚合和分离跟随领队。
# A state for the pirates' finite state machine. The squad leader will use the
# arrive steering behavior to go from the spawning point to the point in space
# that the squad will patrol. The squaddies, meanwhile, follow the leader using
# cohesion and separation.
extends PirateState

const ARRIVAL_TOLERANCE := 350 * 350  # 抵达容忍距离

var _initialized := false  # 是否已初始化

@onready var priority := GSAIPriority.new(owner.agent)  # 优先级行为
@onready var patrol_target := GSAIAgentLocation.new()  # 巡逻目标位置
@onready var acceleration := GSAITargetAcceleration.new()  # 加速度


func _ready() -> void:
	super()
	await owner.ready
	ship.squad_leader_changed.connect(_on_Leader_changed)
	set_behaviors()

	if not ship.is_squad_leader:
		# 小队成员：等待领队到达集群
		Events.reached_cluster.connect(_on_Leader_reached_cluster)
	else:
		# 小队长：设置超时计时器防止卡住
		var timer := Timer.new()
		add_child(timer)
		timer.timeout.connect(_on_Timer_timeout)
		timer.start(30)


func exit() -> void:
	# 退出状态时清理
	queue_free()


func physics_process(delta: float) -> void:
	if ship.is_squad_leader:
		# 小队长：检查是否到达巡逻点
		var distance_to := patrol_target.position.distance_squared_to(
			GSAIUtils.to_vector3(ship.global_position)
		)
		if distance_to <= ARRIVAL_TOLERANCE:
			Events.reached_cluster.emit(ship)
			_state_machine.transition_to("Rest")

	# 计算并应用AI行为
	priority.calculate_steering(acceleration)
	ship.agent._apply_steering(acceleration, delta)


func set_behaviors() -> void:
	# 设置AI行为
	var avoid_collisions := GSAIAvoidCollisions.new(ship.agent, ship.world_proximity)
	priority.add(avoid_collisions)

	var faction_avoid := GSAIAvoidCollisions.new(ship.agent, ship.faction_proximity)
	priority.add(faction_avoid)

	var look := GSAILookWhereYouGo.new(ship.agent)
	look.alignment_tolerance = ship.ALIGNMENT_TOLERANCE
	look.deceleration_radius = ship.DECELERATION_RADIUS

	if ship.is_squad_leader:
		# 小队长行为：抵达巡逻点
		var arrive := GSAIArrive.new(ship.agent, patrol_target)
		arrive.deceleration_radius = 200
		arrive.arrival_tolerance = 50
		patrol_target.position = GSAIUtils.to_vector3(ship.patrol_point)

		var arrive_blend := GSAIBlend.new(ship.agent)

		arrive_blend.add(arrive, 1)
		arrive_blend.add(look, 1)

		priority.add(arrive_blend)
	else:
		# 小队成员行为：跟随、分离、聚合
		var separation = GSAISeparation.new(ship.agent, ship.squad_proximity)
		separation.decay_coefficient = 2000

		var cohesion = GSAICohesion.new(ship.agent, ship.squad_proximity)

		var pursue = GSAIPursue.new(ship.agent, ship.squad_leader.agent)

		var group_blend = GSAIBlend.new(ship.agent)
		group_blend.add(pursue, 0.65)  # 追随领队
		group_blend.add(separation, 4.5)  # 分离
		group_blend.add(cohesion, 0.3)  # 聚合
		group_blend.add(look, 1)  # 朝向移动方向

		priority.add(group_blend)


func _on_Leader_reached_cluster(leader: Node) -> void:
	# 领队到达集群时
	if not leader == ship.squad_leader:
		return

	_state_machine.transition_to("Rest")


func _on_Timer_timeout() -> void:
	# 超时时强制到达集群
	Events.reached_cluster.emit( ship)
	_state_machine.transition_to("Rest")


func _on_Leader_changed(
	_old_leader: CharacterBody2D, _new_leader: CharacterBody2D, _current_patrol_point: Vector2
) -> void:
	# 领队改变时重新设置行为
	set_behaviors()
	_state_machine.transition_to("Spawn")
