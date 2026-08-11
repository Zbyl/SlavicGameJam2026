extends Area2D

const DUST = preload("res://dust.tscn")

@onready var goal_sound: AudioStreamPlayer2D = $GoalSound

var team: int = -1  # Which team this goal belongs to. -1 if points should be awarded to whoever kicked it.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    pass



func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("Ball"):
        var ball: Ball = body as Ball
            
        ball.respawn()
        goal_sound.play()

        var scoringTeam = team
        if (scoringTeam == -1) and (ball.lastKicker != null):
            scoringTeam = GameData.getCharacterTeam(ball.lastKicker.character)
        if (scoringTeam == -1):
            return
        GameData.hud.countPointsForGoal(scoringTeam)
