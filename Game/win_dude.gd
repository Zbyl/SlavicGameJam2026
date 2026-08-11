extends Node2D
const ANIM_DIE = {"name":"Die", "frame":0, "speed":1.0, "sound": -1}
const ANIM_TWITCH = {"name":"Die", "frame":6, "speed":1.0, "sound": -1}
const ANIM_JUMP = {"name":"Jump", "frame":4, "speed":0.5, "sound": 0}
const ANIM_REST = {"name":"Die", "frame":0, "speed":1.0, "sound": 1}

@onready var crown_animation_player: AnimationPlayer = $CrownAnimationPlayer

@export var win: bool = false
@export var character: GameData.Character = GameData.Character.Fox
@export var dir: int = 1
@onready var animation: AnimatedSprite2D = $Animation
@onready var player: AudioStreamPlayer = $Player
@onready var crown: Sprite2D = $Crown
@onready var streams = [
    load("res://Sounds/Kunek/yeah.wav"),
    load("res://Sounds/Kunek/ufff.wav")
]

@onready var queue = [ANIM_DIE]
@onready var queuePos = 0

func _ready() -> void:
    if win:
        queue = [ANIM_JUMP,ANIM_JUMP,ANIM_JUMP,ANIM_JUMP,ANIM_REST]

    crown.visible = win

    animation.animation = GameData.characterEnumToStr(character) + queue[queuePos].name + str(dir)
    animation.frame = queue[queuePos].frame
    animation.speed_scale = queue[queuePos].speed
    animation.animation_finished.connect(_on_animation_finished)
    animation.animation_looped.connect(_on_animation_finished)
    animation.play()
    if queue[queuePos].sound!=-1:
        player.stream = streams[queue[queuePos].sound]
        player.play()
    queuePos += 1

func istwitchButtonPressed() -> bool:
    var pressed := false
    var playerIndex = GameData.ALL_CHARACTERS.find(character)
    var controllerData = GameData.hud.playerData[playerIndex]
    if controllerData["type"]=="pad":
        var controller = controllerData["pad"]
        var x = Input.get_joy_axis(controller, JOY_AXIS_LEFT_X)
        var y = Input.get_joy_axis(controller, JOY_AXIS_LEFT_Y)
        pressed = Vector2(x, y).length()>0.1
    elif controllerData["type"]=="keyboard":
        pressed = Input.is_key_pressed(controllerData["up"]) || Input.is_key_pressed(controllerData["down"]) || Input.is_key_pressed(controllerData["left"]) || Input.is_key_pressed(controllerData["right"])
    return pressed


func _process(_delta: float) -> void:
    if istwitchButtonPressed():
        if not animation.is_playing():
            queue = [ANIM_TWITCH]
            queuePos = 0
            animation.animation = GameData.characterEnumToStr(character) + queue[queuePos].name + str(dir)
            animation.frame = 12
            animation.speed_scale = queue[queuePos].speed
            queuePos += 1
            animation.play()

func _on_animation_finished():
    if queuePos >= queue.size():
        if animation.is_playing():
            animation.stop()
    else:
        animation.animation = GameData.characterEnumToStr(character) + queue[queuePos].name + str(dir)
        animation.frame = queue[queuePos].frame
        animation.speed_scale = queue[queuePos].speed
        animation.play()
        if queue[queuePos].sound!=-1:
            player.stream = streams[queue[queuePos].sound]
            player.play()
        queuePos += 1
        if (queuePos == queue.size()):
            crown_animation_player.play("CrownFly0")
