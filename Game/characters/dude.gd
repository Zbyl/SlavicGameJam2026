extends CharacterBody2D

@export var speed = 300
@export var character = "Fox"
var direction = Vector2.ZERO
var currentAngle = 8
var currentState = "Idle"
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
    # Pobranie inputu z padka (d-pad lub lewego stick)
    direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

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
