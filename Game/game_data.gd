extends Node

# It is auto load, so not name here - autoload has a name already.
#class_name GameData

var game: Game
var hud: Hud
var layerHelpers: LayerHelpers

# Called when the node enters the scene tree for the first time.
func _ready():
    layerHelpers = LayerHelpers.new()
    hud = get_tree().get_first_node_in_group('Hud')
    game = get_tree().get_first_node_in_group('Game')
