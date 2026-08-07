extends CharacterBody2D

const DEADZONE = 0.1
const ACCELERATION_FACTOR = 700
const DECELERATION_FACTOR = 2*ACCELERATION_FACTOR
const WORLD_ASPECT_FACTOR = 0.5

@export var speed = 300
@export var character = "Fox"
@export var controller = 0
@export var jumpButton = JOY_BUTTON_A
@export var isBerek = false

var direction = Vector2.ZERO
var currentAngle = 8
var currentState = "None"

@onready var animation: AnimatedSprite2D = $Kunek
@onready var outline: AnimatedSprite2D = $Outline
@onready var berek: AnimatedSprite2D = $Berek
@onready var timer: Timer = $Timer

func _ready() -> void:
    setBerek(isBerek)

func setBerek(state: bool):
    isBerek = state
    if isBerek:
        add_to_group("Berek")
    else:
        remove_from_group("Berek")
    berek.visible = isBerek

func calculateInputDirection() -> Vector2:
    var x = Input.get_joy_axis(controller, JOY_AXIS_LEFT_X)
    var y = Input.get_joy_axis(controller, JOY_AXIS_LEFT_Y)
    var dir = Vector2(x, y)
    if dir.length() < DEADZONE:
        dir = Vector2.ZERO
    dir.y *= WORLD_ASPECT_FACTOR
    return dir

func isJumpButtonPressed() -> bool:
    return Input.is_joy_button_pressed(controller, jumpButton)

func calculateState(direction: Vector2, isJump: bool) -> String:
    if currentState=="Die":
        return "Die"
    elif isJump:
        return "Jump"
    elif currentState=="Jump":
        return "Jump"
    elif direction == Vector2.ZERO:
        return "Idle"
    else:
        return "Dir"

func resetState():
    currentState="None"

func calculateAngle(direction: Vector2) -> int:
    var angle = roundi((rad_to_deg(atan2(direction.y, direction.x))+270.0)/45.0)
    if angle<1:
        angle += 8
    if angle>8:
        angle -= 8
    return angle

func syncAnimations():
    outline.animation="Outline"+animation.animation
    outline.frame=animation.frame

func _physics_process(delta):
    var direction = calculateInputDirection()

    var isJump = isJumpButtonPressed()

    var changeAnimation = false

    var state = calculateState(direction, isJump)

    if state != currentState:
        currentState = state
        if state == "Jump": # this is temporary solution for canceling jump
            timer.wait_time = 0.5;
            timer.start()
        changeAnimation = true

    if direction != Vector2.ZERO:

        var angle = calculateAngle(direction)
        if angle != currentAngle:
            currentAngle = angle
            changeAnimation = true

    if changeAnimation:
        animation.play(character+currentState+str(currentAngle))

    syncAnimations()

    # Ustawienie prędkości
    if direction == Vector2.ZERO:
        velocity = velocity.move_toward(Vector2.ZERO, delta*DECELERATION_FACTOR)
    else:
        velocity = velocity.move_toward(direction * speed, delta*ACCELERATION_FACTOR)

    # Ruch z obsługą kolizji
    move_and_slide()


func _on_area_2d_body_entered(body: Node2D) -> void:
    if !is_in_group("Berek") && body.is_in_group("Berek"):
        print("Die sucker!")
        currentState="Die"
        animation.play(character+currentState+str(currentAngle))
        syncAnimations()
        timer.wait_time = 2.0;
        timer.start()
