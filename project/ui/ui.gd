# 处理调出小地图或退出菜单的输入
# Handles the input that brings up the minimap or the quit menu.
extends CanvasLayer

@onready var screen_fader: TextureRect = $ScreenFader  # 屏幕淡入淡出效果
@onready var map: TextureRect = $MapDisplay  # 小地图显示
@onready var upgrade_menu := $UpgradeUI  # 升级菜单
@onready var quit_menu := $QuitMenu  # 退出菜单


func _ready() -> void:
	# 连接玩家死亡事件，触发重置
	Events.player_died.connect(reset.bind(true))
	# 连接退出请求事件
	Events.quit_requested.connect(quit)
	# 连接升级解锁事件，打开升级菜单
	Events.upgrade_unlocked.connect(upgrade_menu.open)
	# 开始时淡入屏幕
	screen_fader.fade_in()


func _unhandled_input(event: InputEvent) -> void:
	# 如果游戏暂停则不处理输入
	if get_tree().paused:
		return

	# 按下取消键时打开退出菜单
	if event.is_action_pressed("ui_cancel"):
		quit_menu.open()
	# 按下切换地图键且地图未在动画中时切换地图显示
	if event.is_action_pressed("toggle_map") and not map.is_animating():
		map.toggle()


func quit() -> void:
	# 退出游戏
	get_tree().quit()


func reset(with_delay: bool) -> void:
	# 重置游戏，可选择是否延迟
	screen_fader.fade_out(with_delay)
	await screen_fader.animation_finished
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
