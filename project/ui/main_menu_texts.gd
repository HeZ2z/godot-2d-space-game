extends Control

const EXPOSE_DURATION := 2.0
const FADE_DURATION := 0.5

@onready var container := $HBoxContainer/CenterContainer
@onready var tween := create_tween()
@onready var keyboard := container.get_node("AnyKey")

func _ready() -> void:
	var total_time := 0.0
	tween.set_loops()
	tween.play()
