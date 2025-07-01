# Spawns the station, asteroids, and pirates when entering the game.
# 进入游戏时生成空间站、小行星和海盗
# Keeps track of resources available in the world and which asteroid clusters holds it,
# 跟踪世界中可用的资源以及哪些小行星集群拥有这些资源，
# and spawns more when running low.
# 并在资源不足时生成更多
# It also signals the pirate spawner when an upgrade has been made.
# 当进行升级时，它还会向海盗生成器发送信号
class_name GameWorld
extends Node2D

# Radius of the world in pixels.
# 世界半径（像素）
@export var radius := 8000.0

# Minimum amount of iron that must be added when the world spawns new asteroids.
# 世界生成新小行星时必须添加的最少铁矿量
# Used in `_spawn_asteroids`.
# 在 `_spawn_asteroids` 中使用
@export var iron_amount_balance_level := 100.0
# If the amouns of iron in the world goes below this threshold, spawns new asteroids.
# 如果世界中的铁矿量低于此阈值，则生成新的小行星
@export var refresh_threshold_range := 25.0

var _spawned_positions := []  # 已生成位置列表
var _world_objects := []  # 世界对象列表
var _iron_clusters := {}  # 铁矿集群字典

@onready var rng := RandomNumberGenerator.new()  # 随机数生成器

@onready var station_spawner: StationSpawner = $StationSpawner  # 空间站生成器
@onready var asteroid_spawner: AsteroidSpawner = $AsteroidSpawner  # 小行星生成器
@onready var pirate_spawner: PirateSpawner = $PirateSpawner  # 海盗生成器


func _ready() -> void:
	await owner.ready
	setup()


func setup() -> void:
	# 设置游戏世界
	rng.randomize()

	Events.upgrade_chosen.connect(_on_Events_upgrade_chosen)
	asteroid_spawner.cluster_depleted.connect(_on_AsteroidSpawner_cluster_depleted)

	station_spawner.spawn_station(rng)
	asteroid_spawner.spawn_asteroid_clusters(rng, iron_amount_balance_level, radius)
	pirate_spawner.spawn_pirate_group(
		rng, 0, radius, _find_largest_inoccupied_asteroid_cluster().global_position
	)


# Returns the AsteroidCluster with the most iron that isn't occupied.
# 返回铁矿最多且未被占用的小行星集群
# If all clusters are occupied, returns `null`.
# 如果所有集群都被占用，返回 `null`
func _find_largest_inoccupied_asteroid_cluster() -> AsteroidCluster:
	var target_cluster: AsteroidCluster
	var target_cluster_iron_amount := -INF
	for cluster in asteroid_spawner.get_children():
		assert(cluster is AsteroidCluster)
		if cluster.is_occupied:
			continue
		if cluster.iron_amount > target_cluster_iron_amount:
			target_cluster = cluster
			target_cluster_iron_amount = cluster.iron_amount
	if target_cluster:
		target_cluster.is_occupied = true
	return target_cluster


# Spawn a new group of pirates upon getting an upgrade
# 获得升级时生成新的海盗组
func _on_Events_upgrade_chosen(_choice) -> void:
	var target_cluster := _find_largest_inoccupied_asteroid_cluster()
	if target_cluster:
		pirate_spawner.spawn_pirate_group(rng, 0, radius, target_cluster.global_position)


func _on_AsteroidSpawner_cluster_depleted(iron_left: float) -> void:
	# 当小行星集群耗尽时的回调
	if iron_left < refresh_threshold_range:
		asteroid_spawner.spawn_asteroid_clusters(rng, iron_amount_balance_level, radius)
