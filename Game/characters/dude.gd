extends CharacterBody2D

@export var speed = 300
var direction = Vector2.ZERO
var currentAngle = 8;
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta):
    # Pobranie inputu z padka (d-pad lub lewego stick)
    direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

    if direction != Vector2.ZERO:
        # kąt animacji
        var angle = roundi((rad_to_deg(atan2(direction.y, direction.x))+270.0)/45.0)
        if angle<1:
            angle += 8
        if angle>8:
            angle -= 8

        if angle != currentAngle:
            currentAngle = angle
            animation.play("dir" + str(currentAngle))

    # Ustawienie prędkości
    velocity = direction * speed

    # Ruch z obsługą kolizji
    move_and_slide()
