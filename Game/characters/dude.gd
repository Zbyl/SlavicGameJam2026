extends CharacterBody2D

const DEADZONE = 0.1
const ACCELERATION_FACTOR = 400
const DECELERATION_FACTOR = 2*ACCELERATION_FACTOR
const WORLD_ASPECT_FACTOR = 0.5

@export var speed = 300
@export var character = "Fox"
@export var controller = 0
@export var isBerek = false

var direction = Vector2.ZERO
var currentAngle = 8
var currentState = "None"

@onready var animation: AnimatedSprite2D = $Kunek
@onready var berek: AnimatedSprite2D = $Berek

func _ready() -> void:
    setBerek(isBerek)

func setBerek(state: bool):
    isBerek = state
    berek.visible = isBerek

func calculateInputDirection() -> Vector2:
    var x = Input.get_joy_axis(controller, JOY_AXIS_LEFT_X)
    var y = Input.get_joy_axis(controller, JOY_AXIS_LEFT_Y)
    var dir = Vector2(x, y)
    if dir.length() < DEADZONE:
        dir = Vector2.ZERO
    dir.y *= WORLD_ASPECT_FACTOR
    return dir

func calculateState(direction: Vector2) -> String:
    if direction == Vector2.ZERO:
        return "Idle"
    else:
        return "Dir"

func calculateAngle(direction: Vector2) -> int:
    var angle = roundi((rad_to_deg(atan2(direction.y, direction.x))+270.0)/45.0)
    if angle<1:
        angle += 8
    if angle>8:
        angle -= 8
    return angle


func _physics_process(delta):
    var direction = calculateInputDirection()
    var changeAnimation = false

    var state = calculateState(direction)


    if state != currentState:
        currentState = state
        changeAnimation = true

    if direction != Vector2.ZERO:

        var angle = calculateAngle(direction)
        if angle != currentAngle:
            currentAngle = angle
            changeAnimation = true

    if changeAnimation:
        animation.play(character+currentState+str(currentAngle))

    # Ustawienie prędkości
    if direction == Vector2.ZERO:
        velocity = velocity.move_toward(Vector2.ZERO, delta*DECELERATION_FACTOR)
    else:
        velocity = velocity.move_toward(direction * speed, delta*ACCELERATION_FACTOR)

    # Ruch z obsługą kolizji
    move_and_slide()
