extends RigidBody2D
class_name Trash

@onready var image: Sprite2D = $Leaf4Container/Leaf4
@onready var imageContainer: Node2D = $Leaf4Container

var myLayer: int = 0

var imageContainerBasePosition: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.
    var parentName = get_parent().name
    assert(parentName.substr(0, "TileMapLayer".length()) == "TileMapLayer", "Invalid spawn parent name")
    var idxStr = parentName.substr("TileMapLayer".length())
    var layer = int(idxStr)
    z_index = layer
    set_collision_mask_value(17 + layer, true)

    imageContainerBasePosition = imageContainer.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
    imageContainer.global_position = global_position + imageContainerBasePosition
    imageContainer.global_rotation_degrees = 0
    image.rotation = self.rotation
