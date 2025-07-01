# 海盗有限状态机的巡逻状态。构建一个圆角菱形路径，
# 让海盗在小行星集群或指定空间点周围巡逻。
# 
# 小队长将使用路径跟随转向行为，而小队成员将使用聚合和分离跟随领队。
# State for the pirate's finite state machine. Builds a rounded diamond shaped
# path for them to patrol around a cluster of asteroids or given point in space.
# 
# The squad leader will use the path following steering behavior, while the
# squaddies will follow the leader using cohesion and separation.
extends PirateState

const PATROL_TIME_MIN := 15.0  # 最小巡逻时间
const PATROL_TIME_MAX := 30.0  # 最大巡逻时间

@export var patrol_radius := 500.0  # 巡逻半径

var patrol_point := Vector2.ZERO  # 巡逻点
var acceleration := GSAITargetAcceleration.new()  # 加速度
var follow_path: GSAIFollowPath  # 路径跟随行为
var pursue: GSAIPursue  # 追击行为
var initialized := false  # 是否已初始化
var _timer: Timer  # 计时器

@onready var path: GSAIPath  # 路径
@onready var priority: GSAIPriority  # 优先级行为


func _ready() -> void:
	super()
	set_behaviors()
	ship.squad_leader_changed.connect(_on_Leader_changed)


func enter(msg := {}) -> void:
	if ship.is_squad_leader:
		# 小队长：创建巡逻路径
		patrol_point = msg.patrol_point
		# 创建菱形巡逻路径的四个角点
		var patrol_corners := [
			Vector3(patrol_point.x, patrol_point.y - patrol_radius, 0),
			Vector3(patrol_point.x + patrol_radius, patrol_point.y, 0),
			Vector3(patrol_point.x, patrol_point.y + patrol_radius, 0),
			Vector3(patrol_point.x - patrol_radius, patrol_point.y, 0)
		]

		# 在角点之间添加过渡点形成圆角菱形
		var patrol_points := [
			patrol_corners[0] + Vector3(-patrol_radius / 4, 0, 0),
			patrol_corners[0] + Vector3(patrol_radius / 4, 0, 0),
			patrol_corners[1] + Vector3(0, -patrol_radius / 4, 0),
			patrol_corners[1] + Vector3(0, patrol_radius / 4, 0),
			patrol_corners[2] + Vector3(patrol_radius / 4, 0, 0),
			patrol_corners[2] + Vector3(-patrol_radius / 4, 0, 0),
			patrol_corners[3] + Vector3(0, patrol_radius / 4, 0),
			patrol_corners[3] + Vector3(0, -patrol_radius / 4, 0)
		]

		# 随机决定巡逻方向
		if ship.rng.randf() > 0.5:
			patrol_points.reverse()

		if not path:
			path = GSAIPath.new(patrol_points, false)
			follow_path.path = path
		else:
			path.create_path(patrol_points)

		# 设置巡逻计时器
		_timer.timeout.connect(_on_Timer_timeout)
		_timer.start(ship.rng.randf_range(PATROL_TIME_MIN, PATROL_TIME_MAX))
	else:
		# 小队成员：跟随领队
		Events.end_patrol.connect(_on_SquadLeader_end_patrol)


func exit() -> void:
	# 退出巡逻状态
	if ship.is_squad_leader:
		if _timer:
			_timer.timeout.disconnect(_on_Timer_timeout)
	else:
		Events.end_patrol.disconnect(_on_SquadLeader_end_patrol)


func physics_process(_delta: float) -> void:
	# 物理处理：计算并应用优先级行为
	priority.calculate_steering(acceleration)
	ship.agent._apply_steering(acceleration, _delta)


func set_behaviors() -> void:
	# 设置AI行为
	priority = GSAIPriority.new(ship.agent)
	var avoid_collisions := GSAIAvoidCollisions.new(ship.agent, ship.world_proximity)
	priority.add(avoid_collisions)

	var faction_avoid := GSAIAvoidCollisions.new(ship.agent, ship.faction_proximity)
	priority.add(faction_avoid)

	var look := GSAILookWhereYouGo.new(ship.agent)
	look.alignment_tolerance = ship.ALIGNMENT_TOLERANCE
	look.deceleration_radius = ship.DECELERATION_RADIUS

	if ship.is_squad_leader:
		# 小队长行为：路径跟随
		follow_path = GSAIFollowPath.new(ship.agent, path, 100, 0.3)

		var path_blend := GSAIBlend.new(ship.agent)

		path_blend.add(follow_path, 1)
		path_blend.add(look, 1)

		priority.add(path_blend)
		_timer = Timer.new()
		add_child(_timer)
	else:
		# 小队成员行为：跟随、分离、聚合
		var separation := GSAISeparation.new(ship.agent, ship.squad_proximity)
		separation.decay_coefficient = 2000

		var cohesion := GSAICohesion.new(ship.agent, ship.squad_proximity)

		pursue = GSAIPursue.new(ship.agent, ship.squad_leader.agent)

		var group_blend := GSAIBlend.new(ship.agent)
		group_blend.add(pursue, 0.65)  # 追随领队
		group_blend.add(separation, 4.5)  # 分离
		group_blend.add(cohesion, 0.3)  # 聚合
		group_blend.add(look, 1)  # 朝向移动方向

		priority.add(group_blend)


func _on_Timer_timeout() -> void:
	# 巡逻时间结束
	Events.end_patrol.emit(ship)
	_state_machine.transition_to("Rest")


func _on_SquadLeader_end_patrol(leader: Node) -> void:
	# 小队长结束巡逻时
	if ship.squad_leader == leader:
		_state_machine.transition_to("Rest")


func _on_Leader_changed(current_patrol_point: Vector2) -> void:
	# 领队改变时重新设置行为
	set_behaviors()
	if _state_machine.state == self:
		_state_machine.transition_to("Patrol", {patrol_point = current_patrol_point})
