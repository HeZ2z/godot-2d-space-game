# 控制小地图视口，以及在小地图上添加和移除代理对象
# Controls the minimap viewport, and adding and removing proxy objects on the minimap.
class_name MapView
extends SubViewport

@export var map_sprite: PackedScene = preload("res://ui/minimap/map_sprite.tscn")  # 地图精灵场景

@onready var sprites: Node2D = $Sprites  # 精灵容器


func _ready() -> void:
	# 连接节点生成事件
	Events.node_spawned.connect(_on_Spawner_node_spawned)


func register_camera(camera: Camera2D) -> void:
	# 注册摄像机
	add_child(camera)


func register_map_object(remote_transform: RemoteTransform2D, icon: MapIcon) -> MapSprite:
	# 注册地图对象，创建对应的地图精灵
	var map_sprite: MapSprite = map_sprite.instantiate()
	map_sprite.global_position = remote_transform.global_position
	sprites.add_child(map_sprite)
	map_sprite.setup(remote_transform, icon)
	return map_sprite


func _on_Spawner_node_spawned(node: Node) -> void:
	# 当生成器生成节点时，如果节点属于mini-map组则在地图上显示
	if not node.is_in_group("mini-map"):
		return
	assert(node.has_node("MapTransform"))
	assert(node.get("map_icon") != null)
	var map_sprite := register_map_object(node.get_node("MapTransform"), node.map_icon)
	node.tree_exiting.connect(map_sprite.queue_free)
