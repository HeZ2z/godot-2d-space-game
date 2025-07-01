# 海盗有限状态机的攻击状态。初始化并控制海盗飞船追击玩家、
# 保持与玩家的距离、何时停止追击返回巡逻、何时开火等行为。
# State for the pirates' finite state machine. Initializes and controls the way
# the pirate ships will chase and maintain a certain distance from the player,
# or when to break off pursuit and return to patrol, and when to fire the gun.
extends PirateState

@export var distance_from_player_min := 200.0  # 与玩家的最小距离
@export var firing_alignment_tolerance_percentage := 0.15  # 开火对准容忍度百分比
@export var pursuit_distance_max := 800.0  # 最大追击距离

var target: GSAISteeringAgent  # 目标代理
var pursue: GSAIPursue  # 追击行为
var blend: GSAIBlend  # 混合行为
var face: GSAIFace  # 面向行为
var accel := GSAITargetAcceleration.new()  # 目标加速度
var starting_position: Vector2  # 起始位置
var target_separate: GSAIRadiusProximity  # 目标分离接近度


func _ready() -> void:
	super()
	await owner.ready
	# 初始化AI行为
	pursue = GSAIPursue.new(ship.agent, target)
	var avoid := GSAIAvoidCollisions.new(ship.agent, ship.world_proximity)
	var squad_avoid := GSAIAvoidCollisions.new(ship.agent, ship.squad_proximity)
	face = GSAIFace.new(ship.agent, target)

	target_separate = GSAIRadiusProximity.new(ship.agent, [], distance_from_player_min)

	var separate := GSAISeparation.new(ship.agent, target_separate)
	separate.decay_coefficient = 20000

	# 混合所有AI行为
	blend = GSAIBlend.new(ship.agent)
	blend.add(avoid, 2)  # 避免碰撞
	blend.add(squad_avoid, 1)  # 小队避免碰撞
	blend.add(pursue, 1)  # 追击
	blend.add(face, 1)  # 面向目标
	blend.add(separate, 8)  # 分离


func enter(msg := {}) -> void:
	# 进入攻击状态
	target = msg.target.agent
	pursue.target = target
	face.target = target
	if not target_separate.agents.has(target):
		target_separate.agents.append(target)

	if ship.is_squad_leader:
		starting_position = ship.global_position
	else:
		Events.call_off_pursuit.connect(_on_Leader_call_off_pursuit)


func exit() -> void:
	# 退出攻击状态
	if not ship.is_squad_leader:
		Events.call_off_pursuit.disconnect(_on_Leader_call_off_pursuit)


func physics_process(delta: float) -> void:
	# 物理处理：计算AI行为并应用转向
	blend.calculate_steering(accel)
	ship.agent._apply_steering(accel, delta)
	var facing_direction := GSAIUtils.angle_to_vector2(ship.agent.orientation)
	var to_player := GSAIUtils.to_vector2(ship.agent.position - target.position).normalized()
	var player_dot_facing := facing_direction.dot(to_player)

	# 如果面向玩家则开火
	if player_dot_facing > 1 - firing_alignment_tolerance_percentage:
		ship.gun.fire(ship.gun.global_position, ship.agent.orientation, ship.projectile_mask)
	# 如果是小队长，检查是否需要停止追击
	if ship.is_squad_leader:
		var distance_to := starting_position.distance_squared_to(ship.global_position)
		if distance_to > pursuit_distance_max * pursuit_distance_max:
			Events.call_off_pursuit.emit(ship)
			_state_machine.transition_to("Patrol", {patrol_point = ship.patrol_point})


func _on_Leader_call_off_pursuit(leader: Node) -> void:
	# 当领队呼叫停止追击时
	if leader == ship.squad_leader:
		_state_machine.transition_to("Patrol", {patrol_point = ship.patrol_point})
