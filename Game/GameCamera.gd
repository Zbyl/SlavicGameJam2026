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
    var minPosOfKuns := Vector2(1e10, 1e10)
    var maxPosOfKuns := Vector2(-1e10, -1e10)

    for dude in dudes:
        var posOfKun = dude.positionOfKunek()
        averagePosition += posOfKun
        averagePosition2.x += posOfKun.x ** 2
        averagePosition2.y += posOfKun.y ** 2
        minPosOfKuns = minPosOfKuns.min(posOfKun)
        maxPosOfKuns = maxPosOfKuns.max(posOfKun)

    var stdOfPosition = Vector2.ZERO
    var zoomIncreaseMaxRelVelocity =  0.05
    var screen_size = get_viewport().get_visible_rect().size
    var viewWidthAtZoom0 = screen_size.x
    var viewHeightAtZoom0 = screen_size.y

    if dudes.size() > 0:
        averagePosition /= dudes.size()
        averagePosition2 /= dudes.size()
        stdOfPosition.x = sqrt(averagePosition2.x - averagePosition.x ** 2) 
        stdOfPosition.y = sqrt(averagePosition2.y - averagePosition.y ** 2) 
        position.x = (maxPosOfKuns.x + minPosOfKuns.x) * 0.5
        position.y = (maxPosOfKuns.y + minPosOfKuns.y) * 0.5
        var neededZoomX = viewWidthAtZoom0 / max(maxPosOfKuns.x - minPosOfKuns.x + 0.05 * viewWidthAtZoom0, 2.7 * stdOfPosition.x)
        var neededZoomY = viewHeightAtZoom0 / max(maxPosOfKuns.y - minPosOfKuns.y + 0.05 * viewHeightAtZoom0, 2.7 * stdOfPosition.y)
        var neededZoom = min(1.0, neededZoomX, neededZoomY)
        var oldZoom = zoom.x
        var zoomVelocity = (neededZoom - oldZoom) / delta

        zoom.x = min(zoomVelocity / oldZoom, zoomIncreaseMaxRelVelocity) * oldZoom * delta + oldZoom
        zoom.y = zoom.x
