# Base script that represents the physics body of a pirate ship. Manages the 
# pirate's squad, squad leader, and movement speeds of the ship.
# 代表海盗船物理体的基础脚本。管理海盗的小队、队长和船只的移动速度。
class_name PirateShip
extends CharacterBody2D

signal died  # 死亡信号
signal squad_leader_changed(current_patrol_point)  # 队长变更信号

const DECELERATION_RADIUS := deg_to_rad(45)  # 减速半径
const ALIGNMENT_TOLERANCE := deg_to_rad(5)  # 对齐容差

# Represents the ship on the minimap. Use a MapIcon resource.
# 在小地图上代表船只。使用MapIcon资源。
@export var map_icon: Resource  # 地图图标

@export var health_max := 100  # 最大生命值

@export var linear_speed_max := 200.0  # 最大线性速度
@export var acceleration_max := 15.0  # 最大加速度
@export var drag_factor := 0.04  # 阻力系数
@export var angular_speed_max := 270  # 最大角速度
@export var angular_acceleration_max := 15  # 最大角加速度
@export var angular_drag_factor := 0.1  # 角阻力系数
@export var distance_from_target_min := 200.0  # 与目标的最小距离
@export var distance_from_obstacles_min := 200.0  # 与障碍物的最小距离
@export var projectile_mask := 0 # (int, LAYERS_2D_PHYSICS)  # 抛射物碰撞掩码
@export var explosion_effect: PackedScene  # 爆炸特效场景

var current_target: Node  # 当前目标
var target_agent: GSAISteeringAgent  # 目标转向代理
var squaddies: Array  # 队员数组

var is_squad_leader := false  # 是否为队长
var patrol_point := Vector2.ZERO  # 巡逻点
var squad_leader: CharacterBody2D  # 队长

var agent := await GSAICharacterBody2DAgent.new(self)  # 转向代理
var squad_proximity := GSAIInfiniteProximity.new(agent, [])  # 小队邻近代理
var target_proximity := GSAIRadiusProximity.new(agent, [], distance_from_target_min)  # 目标邻近代理
var world_proximity := GSAIRadiusProximity.new(agent, [], distance_from_obstacles_min)  # 世界邻近代理
var faction_proximity := GSAIRadiusProximity.new(agent, [], 500)  # 阵营邻近代理
var rng := RandomNumberGenerator.new()  # 随机数生成器

var _acceleration := GSAITargetAcceleration.new()  # 目标加速度
var _velocity := Vector2.ZERO  # 速度
var _angular_velocity := 0.0  # 角速度
var _arrive_home_blend: GSAIBlend  # 到达基地混合行为
var _pursue_face_blend: GSAIBlend  # 追击面向混合行为
var _health := health_max  # 当前生命值

@onready var gun := $Gun  # 武器
@onready var state_machine := $StateMachine


func _ready() -> void:
	rng.randomize()
	# ----- Agent config -----
	agent.linear_acceleration_max = acceleration_max
	agent.linear_speed_max = linear_speed_max

	agent.angular_acceleration_max = deg_to_rad(angular_acceleration_max)
	agent.angular_speed_max = deg_to_rad(angular_speed_max)

	agent.bounding_radius = (MathUtils.get_triangle_circumcircle_radius($CollisionShape3D.polygon))

	agent.linear_drag_percentage = drag_factor
	agent.angular_drag_percentage = angular_drag_factor

	Events.damaged.connect(_on_self_damaged)
	Events.target_aggroed.connect(_on_Target_Aggroed)
	
	$AggroArea.body_entered.connect(_on_Body_entered_aggro_radius)


func setup_world_objects(world_objects: Array) -> void:
	world_proximity.agents.clear()
	for wo_ref in world_objects:
		var wo: Node2D = wo_ref.get_ref()
		if not wo:
			continue
		var object_agent: GSAIAgentLocation = wo.agent_location
		world_proximity.agents.append(object_agent)


func setup_squad(
	_is_squad_leader: bool,
	_squad_leader: CharacterBody2D,
	_patrol_point: Vector2,
	_squaddies: Array
) -> void:
	is_squad_leader = _is_squad_leader
	squad_leader = _squad_leader
	patrol_point = _patrol_point
	var squaddies_ref := []
	for s in _squaddies:
		squad_proximity.agents.append(s.agent)
		squaddies_ref.append(weakref(s))
	squaddies = squaddies_ref
	if not is_squad_leader:
		Events.squad_leader_changed.connect(_on_Leader_changed)


func setup_faction(pirates: Array) -> void:
	for p in pirates:
		faction_proximity.agents.append(p.agent)


func _die() -> void:
	# 用于处理死亡逻辑
	# 生成爆炸特效
	var effect: Node2D = explosion_effect.instantiate()
	ObjectRegistry.register_effect(effect)
	effect.global_position = global_position
	died.emit()
	var new_leader: CharacterBody2D
	for squaddie_ref in squaddies:
		var squaddie: CharacterBody2D = squaddie_ref.get_ref()
		if not squaddie:
			continue
		# FIXME: I had an error because a Projectile was in the squaddies array
		# We should ensure this cannot happen, and squaddies are all from the faction
		if not squaddie.is_in_group("Enemies"):
			continue
		if squaddie._health > 0:
			new_leader = squaddie
			break
	Events.squad_leader_changed.emit(self, new_leader, patrol_point)

	queue_free()


func _on_self_damaged(target: Node, amount: int, _origin: Node) -> void:
	# 用来处理受伤逻辑
	# 如果不是自己受伤，则返回
	if not target == self:
		return

	_health -= amount

	if _origin:
		Events.target_aggroed.emit(squad_leader, _origin)

	if _health <= 0:
		_die()


func _on_Leader_changed(
	old_leader: CharacterBody2D, new_leader: CharacterBody2D, current_patrol_point: Vector2
) -> void:
	if old_leader == squad_leader:
		squaddies.erase(old_leader)
		squad_proximity.agents.erase(old_leader.agent)
		squad_leader = new_leader
		if new_leader == self:
			is_squad_leader = true
			patrol_point = current_patrol_point
		squad_leader_changed.emit(current_patrol_point)


func _on_Body_entered_aggro_radius(collider: PhysicsBody2D) -> void:
	# 用于处理进入仇恨半径的逻辑
	Events.target_aggroed.emit(squad_leader, collider)


func _on_Target_Aggroed(leader: Node, target: PhysicsBody2D) -> void:
	# 用于处理目标被仇恨时的逻辑
	if squad_leader == leader:
		state_machine.transition_to("Attack", {target = target})
