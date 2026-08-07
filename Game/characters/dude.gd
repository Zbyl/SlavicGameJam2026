extends CharacterBody2D

const DEADZONE = 0.1

@export var speed = 300
@export var character = "Snow"
@export var controller = 0

var direction = Vector2.ZERO
var currentAngle = 8
var currentState = "None"

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
    var x = Input.get_joy_axis(controller, JOY_AXIS_LEFT_X)
    var y = Input.get_joy_axis(controller, JOY_AXIS_LEFT_Y)
    var direction = Vector2(x, y)
    if direction.length() < DEADZONE:
        direction = Vector2.ZERO

    var changeAnimation = false

    var state: String

    if direction == Vector2.ZERO:
        state = "Idle"
    else:
        state = "Dir"

    if state != currentState:
        currentState = state
        changeAnimation = true

    if direction != Vector2.ZERO:
        # kąt animacji
        var angle = roundi((rad_to_deg(atan2(direction.y, direction.x))+270.0)/45.0)
        if angle<1:
            angle += 8
        if angle>8:
            angle -= 8

        if angle != currentAngle:
            currentAngle = angle
            changeAnimation = true

    if changeAnimation:
        animation.play(character+currentState+str(currentAngle))

    # Ustawienie prędkości
    velocity = direction * speed

    # Ruch z obsługą kolizji
    move_and_slide()
