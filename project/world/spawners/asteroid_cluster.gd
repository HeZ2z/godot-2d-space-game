# Cluster of Asteroid nodes in the world.
# Spawns asteroids and keeps track of the available resources in the cluster.
# 世界中小行星节点的集群。
# 生成小行星并跟踪集群中可用的资源。
class_name AsteroidCluster
extends Node2D

signal cluster_depleted  # 集群耗尽信号

const AsteroidScene := preload("res://world/docking_point/asteroid.tscn")  # 小行星场景

# Ore left in the cluster.
# 集群中剩余的矿物
var iron_amount := 0.0: set = set_iron_amount
# If `true`, the cluster is occupied, e.g. by a pirate squad.
# 如果为 `true`，集群被占用，例如被海盗小队占用
var is_occupied := false


func _init() -> void:
	# 设置为顶级节点
	set_as_top_level(true)


# Spawns a new random count of asteroids and adds them as children.
# 生成随机数量的新小行星并将它们添加为子节点
func spawn_asteroids(
	rng: RandomNumberGenerator,
	count_min := 1,
	count_max := 5,
	spawn_radius := 150.0,
	asteroid_radius := 75.0
) -> void:
	var count = rng.randi_range(count_min, count_max)  # 随机数量
	var min_distance_squared := pow(asteroid_radius, 2)  # 最小距离的平方

	for _i in range(count):
		var angle := rng.randf() * 2 * PI  # 随机角度
		var radius := spawn_radius * sqrt(rng.randf())  # 随机半径
		var spawn_position := Vector2(radius * cos(angle), radius * sin(angle))
		for asteroid in get_children():
			# 检查是否与现有小行星重叠
			if spawn_position.distance_squared_to(asteroid.position) < min_distance_squared:
				continue

		var asteroid = _create_asteroid(rng, spawn_position)
		add_child(asteroid)
		asteroid.mined.connect(_on_Asteroid_mined)
		asteroid.depleted.connect(_on_Asteroid_depleted)
		iron_amount += asteroid.iron_amount
		Events.asteroid_spawned.emit(asteroid)


func set_iron_amount(value: float) -> void:
	# 设置铁矿量
	iron_amount = max(value, 0.0)
	if is_equal_approx(iron_amount, 0.0):
		# 如果铁矿耗尽，发出信号并销毁集群
		cluster_depleted.emit()
		queue_free()


# Creates, initializes, and returns a new Asteroid.
# 创建、初始化并返回一个新的小行星
func _create_asteroid(rng: RandomNumberGenerator, location: Vector2) -> Asteroid:
	var asteroid: Asteroid = AsteroidScene.instantiate()
	asteroid.setup(rng)
	asteroid.global_position = location
	asteroid.rotation = rng.randf_range(0, PI * 2)  # 随机旋转
	return asteroid


func _on_Asteroid_mined(amount: float) -> void:
	# 小行星被开采时减少铁矿量
	self.iron_amount -= amount


func _on_Asteroid_depleted() -> void:
	# 小行星耗尽时，如果是最后一个，发出集群耗尽信号
	if get_child_count() == 1:
		cluster_depleted.emit()
