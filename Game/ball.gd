extends Trash

var spawnPosition: Vector2

func _ready() -> void:
    super._ready()
    spawnPosition = global_position
    rotation_degrees = 0
    
func resetPosition():
    global_position = spawnPosition
    global_rotation = 0
