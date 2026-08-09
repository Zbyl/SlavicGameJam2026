extends RigidBody2D

@onready var ball: Sprite2D = $BallContainer/Ball
@onready var leaf4: Sprite2D = $Leaf4Container/Leaf4
@onready var ballContainer: Node2D = $BallContainer
@onready var leaf4Container: Node2D = $Leaf4Container

@export var isBall: bool = false
var myLayer: int = 0

var ballBasePosition: Vector2
var leaf4BasePosition: Vector2
var ballContainerBasePosition: Vector2
var leaf4ContainerBasePosition: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.
    var parentName = get_parent().name
    assert(parentName.substr(0, "TileMapLayer".length()) == "TileMapLayer", "Invalid spawn parent name")
    var idxStr = parentName.substr("TileMapLayer".length())
    var layer = int(idxStr)
    z_index = layer
    set_collision_mask_value(17 + layer, true)

    if isBall:
        ball.visible = true
        leaf4.visible = false
        linear_damp = 1.0
        angular_damp = 0.05
    else:
        physics_material_override = null
        ball.visible = false
        leaf4.visible = true

    ballBasePosition = ball.position
    leaf4BasePosition = leaf4.position
    ballContainerBasePosition = ballContainer.position
    leaf4ContainerBasePosition = leaf4Container.position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
    ballContainer.global_position = global_position + ballContainerBasePosition
    ballContainer.global_rotation_degrees = 0
    ball.rotation = self.rotation

    leaf4Container.global_position = global_position + leaf4ContainerBasePosition
    leaf4Container.global_rotation_degrees = 0
    leaf4.rotation = self.rotation
