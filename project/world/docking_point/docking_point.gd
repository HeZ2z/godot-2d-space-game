# A class that represents a dockable object in space that the player can attach
# to. Synchronizes with the docking ship, taking control of it with a remote
# transform, as well as indicating docking range being achieved or lost by
# animating a docking range circle.
# 代表空间中可对接对象的类，玩家可以连接到该对象。
# 与对接船只同步，通过远程变换控制它，
# 并通过动画对接范围圆圈来指示对接范围的获得或丢失。
class_name DockingPoint
extends Node2D

signal died  # 死亡信号

@export var map_icon := MapIcon.new()  # 地图图标
@export var docking_distance := 200.0: set = _set_docking_distance  # 对接距离

var angle_proportion := 1.0  # 角度比例
var is_player_inside := false  # 玩家是否在范围内
var radius := 0.0  # 半径
var docking_point_edge := Vector2.ZERO  # 对接点边缘

@onready var docking_shape: CollisionShape2D = $DockingArea/CollisionShape2D  # 对接形状
@onready var docking_area: Area2D = $DockingArea  # 对接区域
@onready var collision_shape: CollisionShape2D = $CharacterBody2D/CollisionShape2D  # 碰撞形状
@onready var agent_location := GSAISteeringAgent.new()  # 代理位置
@onready var ref_to = weakref(self)  # 弱引用
@onready var tween_aura := TweenAura.new()  # 补间光环
@onready var tween : Tween  # 补间动画
@onready var dock_aura := $DockingAura  # 对接光环
@onready var player_rotation_transform = $Sprite2D/PlayerRotationRig/PlayerRotationRemoteTransform  # 玩家旋转变换
@onready var player_rotation_transform_rig = $Sprite2D/PlayerRotationRig  # 玩家旋转变换装置


func _ready() -> void:
	# 初始化对接点
	player_rotation_transform_rig.scale = Vector2.ONE / $Sprite2D.scale
	radius = collision_shape.shape.radius
	agent_location.position.x = global_position.x
	agent_location.position.y = global_position.y
	agent_location.orientation = rotation
	agent_location.bounding_radius = radius
	docking_point_edge = Vector2.UP * radius

	docking_area.connect("body_entered", _on_DockingArea_body_entered)
	docking_area.connect("body_exited", _on_DockingArea_body_exited)

	var docking_diameter := docking_distance * 2
	tween_aura.scale_final = Vector2.ONE * (docking_diameter / dock_aura.texture.get_width())


func set_docking_remote(node: Node2D, docker_distance: float) -> void:
	player_rotation_transform_rig.global_rotation = GSAIUtils.vector2_to_angle(node.global_position - global_position)
	player_rotation_transform.position = docking_point_edge + Vector2.UP * (docker_distance / scale.x)
	player_rotation_transform.remote_path = node.get_path()

func undock() -> void:
	player_rotation_transform.remote_path = ""


func _set_docking_distance(value: float) -> void:
	docking_distance = value
	if not is_inside_tree():
		await self.ready

	docking_shape.shape.radius = value


func _on_DockingArea_body_entered(body: Node) -> void:
	is_player_inside = true
	body.dockables.append(ref_to)
	
	if dock_aura.visible:
		return
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(
		dock_aura,
		"scale",
		tween_aura.scale_final,
		tween_aura.duration_appear
	).from_current().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	dock_aura.visible = true
	tween.play()


func _on_DockingArea_body_exited(body: Node) -> void:
	is_player_inside = false
	var index: int = body.dockables.find(ref_to)
	if index > -1:
		body.dockables.remove_at(index)

	if not dock_aura.visible:
		return
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(
		dock_aura,
		"scale",
		tween_aura.scale_hidden,
		tween_aura.duration_disappear
	).from_current().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.play()
	await tween.finished
	dock_aura.visible = false
