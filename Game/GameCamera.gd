extends Camera2D
class_name GameCamera

var dudes: Array[Dude] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    var averagePosition := Vector2.ZERO
    for dude in dudes:
        averagePosition += dude.positionOfKunek()
    if dudes.size() > 0:
        averagePosition /= dudes.size()
        position = averagePosition
