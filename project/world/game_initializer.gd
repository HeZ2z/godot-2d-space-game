# Primary node that takes care of sending setup instructions to some of the
# game's sub-systems; passing along the location of the map viewport for
# mappable objects, informing pirates of obstacles in the world, and 
# giving the player access to the game camera.
# 主要节点，负责向游戏的一些子系统发送设置指令；
# 为可映射对象传递地图视窗的位置，告知海盗世界中的障碍物，
# 并为玩家提供游戏相机的访问权限。
extends Node

var _spawned_positions := []  # 已生成位置列表
var _world_objects := []  # 世界对象列表

@onready var map: MapView = $MapView  # 地图视图
@onready var camera := $GameWorld/Camera  # 游戏相机
@onready var hud := $UI/HUD  # HUD界面


func _ready() -> void:
	# 连接生成器信号
	Events.station_spawned.connect(_on_Spawner_station_spawned)
	Events.asteroid_spawned.connect(_on_Spawner_asteroid_spawned)
	Events.pirate_spawned.connect(_on_Spawner_pirate_spawned)

	# 设置相机地图
	camera.setup_camera_map(map)

	# 注册扭曲效果父视窗
	ObjectRegistry.register_distortion_parent($DistortMaskView/SubViewport)
	camera.setup_distortion_camera()


func _input(event: InputEvent) -> void:
	# 处理全屏切换
	if event.is_action_pressed("toggle_fullscreen"):
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (not ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
		get_viewport().set_input_as_handled()


func _on_Spawner_pirate_spawned(pirate: PirateShip) -> void:
	# 海盗生成回调
	pirate.setup_world_objects(_world_objects)
	Events.node_spawned.emit(pirate)


func _on_Spawner_station_spawned(station: DockingPoint, player: PlayerShip) -> void:
	# 空间站生成回调
	_world_objects.append(weakref(station))

	hud.initialize(player)
	player.grab_camera(camera)
	Events.node_spawned.emit(station)
	Events.node_spawned.emit(player)


func _on_Spawner_asteroid_spawned(asteroid: DockingPoint) -> void:
	# 小行星生成回调
	_world_objects.append(weakref(asteroid))
	Events.node_spawned.emit(asteroid)
