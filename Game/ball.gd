extends Trash
class_name Ball

var spawnPosition: Vector2
var lastKicker: Dude = null

func _ready() -> void:
    super._ready()
    spawnPosition = global_position
    rotation_degrees = 0
    
func _on_body_entered(body: Node) -> void:
    # @note contact_monitor and max_contacts_reported need to be set for this function to be called.
    if body.is_in_group("Dude"):
        lastKicker = body as Dude
        print("Kicked by " + GameData.characterEnumToStr(lastKicker.character))
