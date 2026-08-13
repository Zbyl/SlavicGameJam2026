extends Area2D

const BALL = preload("uid://bwa6ix1tgbsct")
const DUST = preload("res://dust.tscn")


@onready var goal_sound: AudioStreamPlayer2D = $GoalSound
@onready var dust_sound: AudioStreamPlayer2D = $DustSound
@onready var respawn_timer: Timer = $RespawnTimer

@export var team: int = -1  # Which team this goal belongs to. -1 if points should be awarded to whoever kicked it.


func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("Ball"):
        var ball: Ball = body as Ball
        call_deferred("_do_respawn_ball", ball)  # Altering physics state in physics callback is not allowed.
  
var ballSpawnPosition: Vector2 = Vector2.ZERO
var ballParent: Node2D = null
          
func _do_respawn_ball(ball: Ball) -> void:
    goal_sound.play()

    var scoringTeam = team
    if (scoringTeam == -1) and (ball.lastKicker != null):
        scoringTeam = GameData.getCharacterTeam(ball.lastKicker.character)
    if (scoringTeam != -1):
        GameData.hud.countPointsForGoal(scoringTeam)
    
    # Moving a RigidBody doesn't seem to work.
    # See: https://www.chrismccole.com/blog/how-to-teleport-an-object-with-physics-in-godot
    # So we are destroying it and recreating a new one.

    ballSpawnPosition = ball.spawnPosition
    ballParent = ball.get_parent()

    var oldDust: Node2D = DUST.instantiate()
    oldDust.global_position = ball.global_position
    ballParent.add_child(oldDust)

    ball.queue_free()
    dust_sound.play()
    respawn_timer.start()


func _on_respawn_timer_timeout() -> void:
    dust_sound.play()

    var newBall: Ball = BALL.instantiate()
    newBall.global_position = ballSpawnPosition
    ballParent.add_child(newBall)

    var newDust: Node2D = DUST.instantiate()
    newDust.global_position = ballSpawnPosition
    ballParent.add_child(newDust)
    
    ballParent = null
