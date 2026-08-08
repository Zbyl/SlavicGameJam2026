extends Camera2D
class_name GameCamera

var dudes: Array[Dude] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var averagePosition := Vector2.ZERO
    var averagePosition2 := Vector2.ZERO
    
    for dude in dudes:
        var posOfKun = dude.positionOfKunek()
        averagePosition += posOfKun
        averagePosition2.x += posOfKun.x ** 2
        averagePosition2.y += posOfKun.y ** 2
        
    var stdOfPosition = Vector2.ZERO
    var zoomIncreaseMaxRelVelocity =  0.05
    var viewWidthAtZoom0 = 1280.0
    var viewHeightAtZoom0 = 640.0
    
    if dudes.size() > 0:
        averagePosition /= dudes.size()
        averagePosition2 /= dudes.size()
        stdOfPosition.x = sqrt(averagePosition2.x - averagePosition.x ** 2) 
        stdOfPosition.y = sqrt(averagePosition2.y - averagePosition.y ** 2) 
        var neededZoomX = viewWidthAtZoom0 / (3 * stdOfPosition.x)
        var neededZoomY = viewHeightAtZoom0 / (3 * stdOfPosition.y)
        var neededZoom = min(1.0, neededZoomX, neededZoomY)
        position = averagePosition
        var oldZoom = zoom.x
        var zoomVelocity = (neededZoom - oldZoom) / delta
        
        zoom.x = min(zoomVelocity / oldZoom, zoomIncreaseMaxRelVelocity) * oldZoom * delta + oldZoom
        zoom.y = zoom.x
        
