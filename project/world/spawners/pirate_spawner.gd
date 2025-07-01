# Spawns a group of pirates, then updates their squad and faction. Pirates are
# spawned outside of the asteroid belt, but are asigned an asteroid cluster
# or a point in space in the belt for them to path to. This keeps pirates from
# appearing right on top of the player, or to appear jarringly out of thin air.
# 生成一组海盗，然后更新他们的小队和阵营。海盗在小行星带外生成，
# 但会被分配到小行星集群或带内的空间点供他们寻路。
# 这防止海盗直接出现在玩家身边，或突兀地凭空出现。
class_name PirateSpawner
extends Node2D

@export var pirate_scene: PackedScene = null  # 海盗场景
@export var count_min := 1  # 最少生成数量
@export var count_max := 5  # 最多生成数量
@export var spawn_radius := 150.0  # 生成半径


func spawn_pirate_group(
	rng: RandomNumberGenerator, _choice: int, world_radius: float, cluster_position: Vector2
) -> void:
	# 生成海盗小组
	var spawn_position := cluster_position.normalized() * world_radius * 1.25

	var pirates_in_cluster := []
	for _i in range(rng.randi_range(count_min, count_max)):
		var pirate := pirate_scene.instantiate()
		pirate.position = (
			spawn_position
			+ Vector2.UP.rotated(rng.randf_range(0, PI * 2)) * spawn_radius
		)
		pirates_in_cluster.append(pirate)
	for p in pirates_in_cluster:
		# 设置小队：第一个海盗为队长
		p.setup_squad(
			p == pirates_in_cluster[0], pirates_in_cluster[0], cluster_position, pirates_in_cluster
		)
		# 设置阵营
		p.setup_faction(get_tree().get_nodes_in_group("Pirates"))
		add_child(p)
		Events.pirate_spawned.emit(p)
