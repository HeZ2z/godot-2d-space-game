# Main class to represent the player's physics body. Controls the player's
# current health and how to operate when an upgrade choice has been made.
# 代表玩家物理体的主类。控制玩家当前生命值以及升级选择时的操作。
class_name PlayerShip
extends CharacterBody2D

signal died  # 死亡信号

@export var stats: Resource = preload("res://ships/player/player_stats.tres")  # 玩家属性
@export var projectile_mask := 0 # (int, LAYERS_2D_PHYSICS)  # 抛射物碰撞掩码
@export var ExplosionEffect: PackedScene  # 爆炸特效场景
# Represents the ship on the minimap. Use a MapIcon resource.
# 在小地图上代表船只。使用MapIcon资源。
@export var map_icon: Resource  # 地图图标

var dockables := []  # 可对接对象列表

@onready var shape := $CollisionShape3D  # 碰撞形状
@onready var agent: GSAISteeringAgent = $StateMachine/Move.agent  # 转向代理
@onready var camera_transform := $CameraTransform  # 相机变换
@onready var timer := $MapTimer  # 地图计时器
@onready var cargo := $Cargo  # 货物系统
@onready var move_state := $StateMachine/Move  # 移动状态
@onready var gun := $Gun  # 主武器
@onready var laser_gun := $LaserGun  # 激光武器
@onready var vfx := $VFX  # 视觉特效


func _ready() -> void:
	# 初始化玩家船只
	stats.initialize()
	Events.damaged.connect(_on_damaged)
	Events.upgrade_chosen.connect(_on_upgrade_chosen)
	stats.health_depleted.connect(die)
	gun.collision_mask = projectile_mask
	laser_gun.collision_mask = projectile_mask


func _toggle_map(map_up: bool, tween_time: float) -> void:
	# 切换地图显示
	if not map_up:
		timer.start(tween_time)
		await timer.timeout
	camera_transform.update_position = not map_up


func die() -> void:
	# 玩家死亡
	var effect := ExplosionEffect.instantiate()
	effect.global_position = global_position
	ObjectRegistry.register_effect(effect)

	died.emit()
	Events.player_died.emit()

	queue_free()


func grab_camera(camera: Camera2D) -> void:
	# 获取相机控制
	camera_transform.remote_path = camera.get_path()


func _on_damaged(target: Node, amount: int, _origin: Node) -> void:
	# 受伤回调
	if not target == self:
		return

	stats.health -= amount


func _on_upgrade_chosen(choice: int) -> void:
	# 升级选择回调
	match choice:
		Events.UpgradeChoices.HEALTH:
			# 生命值升级
			stats.add_modifier("max_health", 25.0)
		Events.UpgradeChoices.SPEED:
			# 速度升级
			stats.add_modifier("linear_speed_max", 125.0)
		Events.UpgradeChoices.CARGO:
			# 货物容量升级
			cargo.stats.add_modifier("max_cargo", 50.0)
		Events.UpgradeChoices.MINING:
			# 挖矿升级
			cargo.stats.add_modifier("mining_rate", 10.0)
			cargo.stats.add_modifier("unload_rate", 5.0)
		Events.UpgradeChoices.WEAPON:
			# 武器升级
			gun.stats.add_modifier("damage", 3.0)
			# That's a limitation of the stats system, modifiers only add or remove values, and they
			# don't have limits
			# 这是属性系统的限制，修饰符只能增加或减少值，没有限制
			if gun.stats.get_stat("cooldown") > 0.2:
				gun.stats.add_modifier("cooldown", -0.05)
