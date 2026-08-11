extends RigidBody2D
class_name Trash

@onready var image: Sprite2D = $ImageContainer/Image
@onready var imageContainer: Node2D = $ImageContainer

var myLayer: int = 0

var imageContainerBasePosition: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var parentName = get_parent().name
    assert(parentName.substr(0, "TileMapLayer".length()) == "TileMapLayer", "Invalid spawn parent name")
    var idxStr = parentName.substr("TileMapLayer".length())
    var layer = int(idxStr)
    z_index = layer
    set_collision_mask_value(17 + layer, true)

    imageContainerBasePosition = imageContainer.position

    # Start with random rotation.
    rotation_degrees = randf_range(0.0, 360.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
    imageContainer.global_position = global_position + imageContainerBasePosition
    imageContainer.global_rotation_degrees = 0
    image.rotation = self.rotation
