extends Node2D
const ANIM_DIE = {"name":"Die", "frame":0, "speed":1.0, "sound": -1}
const ANIM_TWITCH = {"name":"Die", "frame":6, "speed":1.0, "sound": -1}
const ANIM_JUMP = {"name":"Jump", "frame":4, "speed":0.5, "sound": 0}
const ANIM_REST = {"name":"Die", "frame":0, "speed":1.0, "sound": 1}

@export var win: bool = false
@export var character: String = "Fox"
@export var dir: int = 1
@onready var animation: AnimatedSprite2D = $Animation
@onready var player: AudioStreamPlayer = $Player
@onready var streams = [
    load("res://Sounds/Kunek/yeah.wav"),
    load("res://Sounds/Kunek/ufff.wav")
]

@onready var queue = [ANIM_DIE]
@onready var queuePos = 0

func _ready() -> void:
    if win:
        queue = [ANIM_JUMP,ANIM_JUMP,ANIM_JUMP,ANIM_JUMP,ANIM_REST]
    animation.animation = character+queue[queuePos].name+str(dir)
    animation.frame = queue[queuePos].frame
    animation.speed_scale = queue[queuePos].speed
    animation.animation_finished.connect(_on_animation_finished)
    animation.animation_looped.connect(_on_animation_finished)
    animation.play()
    if queue[queuePos].sound!=-1:
        player.stream = streams[queue[queuePos].sound]
        player.play()
    queuePos += 1

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("ui_text_backspace"):
        if not animation.is_playing():
            queue = [ANIM_TWITCH]
            queuePos = 0
            animation.animation = character+queue[queuePos].name+str(dir)
            animation.frame = 12
            animation.speed_scale = queue[queuePos].speed
            queuePos += 1
            animation.play()

func _on_animation_finished():
    if queuePos >= queue.size():
        if animation.is_playing():
            animation.stop()
    else:
        animation.animation = character+queue[queuePos].name+str(dir)
        animation.frame = queue[queuePos].frame
        animation.speed_scale = queue[queuePos].speed
        animation.play()
        if queue[queuePos].sound!=-1:
            player.stream = streams[queue[queuePos].sound]
            player.play()
        queuePos += 1
