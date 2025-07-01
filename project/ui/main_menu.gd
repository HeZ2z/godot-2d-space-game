# 在按下任意键后淡出屏幕并切换场景
extends Control

const FADE_IN_TIME := 0.5  # 淡入时间
const FADE_OUT_TIME := 2.5  # 淡出时间

@onready var screen_fader: TextureRect = $FadeLayer/ScreenFader  # 屏幕淡入淡出控制器

@onready var menu_sounds: MenuSoundPlayer = $MenuSoundPlayer  # 菜单音效播放器

func _ready() -> void:
	# 准备完成时淡入屏幕
	screen_fader.fade_in()


func _unhandled_input(event: InputEvent) -> void:
	if screen_fader.is_playing:
		return
	if event is InputEventKey:
		# 如果是键盘事件，开始切换场景
		menu_sounds.play_confirm()
		screen_fader.fade_out()
		await screen_fader.animation_finished
		get_tree().change_scene_to_file("res://main/game.tscn")
