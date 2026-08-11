extends Trash
class_name Ball

const BALL = preload("uid://bwa6ix1tgbsct")
const DUST = preload("res://dust.tscn")

var spawnPosition: Vector2
var lastKicker: Dude = null

func _ready() -> void:
    super._ready()
    spawnPosition = global_position
    rotation_degrees = 0
    
func respawn():
    # We cannot destroy object from a collision query.
    # But we can defer.
    call_deferred("_do_respawn")

func _do_respawn():
    # Moving a RigidBody doesn't seem to work.
    # See: https://www.chrismccole.com/blog/how-to-teleport-an-object-with-physics-in-godot
    # So we are destroying it and recreating a new one.

    var newBall: Ball = BALL.instantiate()
    newBall.global_position = spawnPosition
    get_parent().add_child(newBall)

    var newDust: Node2D = DUST.instantiate()
    newDust.global_position = spawnPosition
    get_parent().add_child(newDust)

    var oldDust: Node2D = DUST.instantiate()
    oldDust.global_position = global_position
    get_parent().add_child(oldDust)

    queue_free()


func _on_body_entered(body: Node) -> void:
    # @note contact_monitor and max_contacts_reported need to be set for this function to be called.
    if body.is_in_group("Dude"):
        lastKicker = body as Dude
        print("Kicked by " + GameData.characterEnumToStr(lastKicker.character))
