extends Camera2D
class_name GameCamera

var dudes: Array[Dude] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var minPosOfKuns := Vector2(1e10, 1e10)
    var maxPosOfKuns := Vector2(-1e10, -1e10)

    for dude in dudes:
        var posOfKun = dude.positionOfKunek()
        minPosOfKuns = minPosOfKuns.min(posOfKun)
        maxPosOfKuns = maxPosOfKuns.max(posOfKun)

    var zoomIncreaseMaxRelVelocity =  0.08
    var screen_size = get_viewport().get_visible_rect().size
    var viewWidthAtZoom0 = screen_size.x
    var viewHeightAtZoom0 = screen_size.y

    if dudes.size() > 0:
        position.x = (maxPosOfKuns.x + minPosOfKuns.x) * 0.5
        position.y = (maxPosOfKuns.y + minPosOfKuns.y) * 0.5
        var neededZoomX = viewWidthAtZoom0 / (maxPosOfKuns.x - minPosOfKuns.x + 0.55 * viewWidthAtZoom0)
        var neededZoomY = viewHeightAtZoom0 / (maxPosOfKuns.y - minPosOfKuns.y + 0.55 * viewHeightAtZoom0)
        var neededZoom = min(1.0, neededZoomX, neededZoomY)
        var oldZoom = zoom.x
        var zoomVelocity = (neededZoom - oldZoom) / delta

        #zoom.x = neededZoom
        zoom.x = min(zoomVelocity / oldZoom, zoomIncreaseMaxRelVelocity) * oldZoom * delta + oldZoom
        zoom.y = zoom.x
