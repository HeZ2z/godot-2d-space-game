# Spawns the player and the resource offloading station at the center of the
# world.
# 在世界中心生成玩家和资源卸载空间站。
class_name StationSpawner
extends Node2D

@export var station_scene: PackedScene = null  # 空间站场景
@export var radius_player_near_station := 300.0  # 玩家距离空间站的半径

@onready var player_ship: PlayerShip = $PlayerShip  # 玩家船只


func spawn_station(rng: RandomNumberGenerator) -> void:
	# 生成空间站
	var station := station_scene.instantiate()
	add_child(station)
	# 在空间站附近随机位置放置玩家
	player_ship.global_position = (
		station.global_position
		+ (Vector2.UP.rotated(rng.randf_range(0, PI * 2)) * radius_player_near_station)
	)
	Events.station_spawned.emit(station, player_ship)


func get_player() -> PlayerShip:
	# 获取玩家船只引用
	return player_ship
