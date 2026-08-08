extends Node2D


@export var dude: Dude

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if dude == null:
        return
    var mapPosition := GameData.layerHelpers.mapPositionFromScreenPosition(dude.global_position, dude.currentZ)
    var layer = GameData.layerHelpers.layerFromZ(dude.currentZ)
    while layer > 0:
        var tileMap = GameData.layerHelpers.getTileMapForLayer(layer)
        if GameData.layerHelpers.isSolidTile(tileMap, mapPosition.mapCoords):
            break
        layer -= 1
    
    var screenPosition := GameData.layerHelpers.screenPositionFromMapPosition(mapPosition.mapCoords, mapPosition.offsetWithinTile, layer * GameData.layerHelpers.layerHeight)
    z_index = layer + 1
    global_position = screenPosition
