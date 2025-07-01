# 在屏幕上显示MapView视口，并播放出现和消失的动画
# Displays the MapView viewport on the screen, and animates it appearing and 
# disappearing
extends TextureRect

const AUDIO_STREAMS := {
	appear = preload("ui_minimap_zoom_in.wav"),  # 出现音效
	disappear = preload("ui_minimap_zoom_out.wav"),  # 消失音效
}

@onready var _anim_player: AnimationPlayer = $AnimationPlayer  # 动画播放器
@onready var _audio_player: AudioStreamPlayer = $AudioStreamPlayer  # 音频播放器

# Godot 4中视口仍有些问题，有时路径会被设置为Game场景的顶级对象GameInitializer
# 所以在这里硬编码...
# Viewports are still sort of buggy in Godot 4, 
# sometimes the path gets set to the Game scene's top-level object; GameInitializer
# so hard-coding it here...
func _ready() -> void:
	var t = texture as ViewportTexture
	t.viewport_path = "MapView"

func toggle() -> void:
	# 切换地图显示状态
	if visible:
		_anim_player.play("disappear")
		_audio_player.stream = AUDIO_STREAMS.appear
		_audio_player.play()
	else:
		_anim_player.play("appear")
		_audio_player.stream = AUDIO_STREAMS.disappear
		_audio_player.play()
	Events.map_toggled.emit(visible, _anim_player.current_animation_length)


func is_animating() -> bool:
	# 检查是否正在播放动画
	return _anim_player.is_playing()
