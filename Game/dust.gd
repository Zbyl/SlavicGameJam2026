extends Node2D

@onready var dust: AnimatedSprite2D = $Dust

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    dust.play("dirt")


func _dust_dispersed():
    queue_free()
