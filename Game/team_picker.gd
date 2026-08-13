extends Control

@onready var kunek_panel: Panel = %KunekPanel
@onready var fretka_panel: Panel = %FretkaPanel
@onready var lasica_panel: Panel = %ŁasicaPanel
@onready var gronostaj_panel: Panel = %GronostajPanel
@onready var ok_button: Button = %OkButton
@onready var num_bereks_button: OptionButton = %NumBereksButton
@onready var count_berek_points: CheckBox = %CountBerekPoints
@onready var count_goals: CheckBox = %CountGoals
@onready var tight_controls: CheckBox = %TightControls
@onready var team_background0: ColorRect = %TeamSelector/Team0/TeamBackground
@onready var team_background1: ColorRect = %TeamSelector/Team1/TeamBackground
@onready var team_background2: ColorRect = %TeamSelector/Team2/TeamBackground
@onready var team_background3: ColorRect = %TeamSelector/Team3/TeamBackground

var teamBackgrounds: Array[ColorRect] = []

var kunki: Array[Node] = []
var fretki: Array[Node] = []
var lasice: Array[Node] = []
var gronostaje: Array[Node] = []

var selectedRow: int = 0 # We have 4 rows for characters and 4 columns for teams.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    teamBackgrounds = [team_background0, team_background1, team_background2, team_background3]
    
    kunki = get_tree().get_nodes_in_group("Fox")
    fretki = get_tree().get_nodes_in_group("Ferret")
    lasice = get_tree().get_nodes_in_group("Weasel")
    gronostaje = get_tree().get_nodes_in_group("Snow")

    assert(kunki.size() == 4)
    assert(fretki.size() == 4)
    assert(lasice.size() == 4)
    assert(gronostaje.size() == 4)
    
    selectRow(0)
    updateKunki()
    num_bereks_button.select(GameData.numBereks)
    count_berek_points.button_pressed = GameData.countBerekPoints
    count_goals.button_pressed = GameData.countGoalsPoints
    tight_controls.button_pressed = GameData.tightControls
    
    ok_button.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_up"):
        selectRow(selectedRow - 1)
    if Input.is_action_just_pressed("ui_down"):
        selectRow(selectedRow + 1)

    var character: GameData.Character = {0: GameData.Character.Fox, 1: GameData.Character.Ferret, 2: GameData.Character.Weasel, 3: GameData.Character.Snow}[selectedRow]
        
    if Input.is_action_just_pressed("ui_left"):
        GameData.initialCharacterToTeam[character] = (GameData.initialCharacterToTeam[character] + 4 - 1) % 4
        updateKunki()
    
    if Input.is_action_just_pressed("ui_right"):
        GameData.initialCharacterToTeam[character] = (GameData.initialCharacterToTeam[character] + 1) % 4
        updateKunki()
    
# Updates visibility of characters according to chosen teams.
func updateKunki() -> void:
    for team in range(4):
        kunki[team].visible = (team == GameData.initialCharacterToTeam[GameData.Character.Fox])
        fretki[team].visible = (team == GameData.initialCharacterToTeam[GameData.Character.Ferret])
        lasice[team].visible = (team == GameData.initialCharacterToTeam[GameData.Character.Weasel])
        gronostaje[team].visible = (team == GameData.initialCharacterToTeam[GameData.Character.Snow])

func selectRow(rowIdx: int) -> void:
    while rowIdx < 0:
        rowIdx += 4
    while rowIdx >= 4:
        rowIdx -= 4
    selectedRow = rowIdx
    kunek_panel.visible = rowIdx == 0
    fretka_panel.visible = rowIdx == 1
    lasica_panel.visible = rowIdx == 2
    gronostaj_panel.visible = rowIdx == 3

func _on_ok_button_pressed() -> void:
    queue_free()


func _on_num_bereks_button_item_selected(index: int) -> void:
    GameData.numBereks = index


func _on_count_berek_points_pressed() -> void:
    GameData.countBerekPoints = count_berek_points.button_pressed


func _on_count_goals_pressed() -> void:
    GameData.countGoalsPoints = count_goals.button_pressed


func _on_tight_controls_pressed() -> void:
    GameData.tightControls = tight_controls.button_pressed

#########################################################
## Code for dragging kunek's into teams.

var dragging := false
var drag_start_position: Vector2
var drag_item_base_position: Vector2
var drag_item : KunekPicture

func cancelDrag() -> void:
    if not dragging:
        return
    
    dragging = false
    drag_item.global_position = drag_item_base_position

func startDrag(pos: Vector2, kunek: KunekPicture) -> void:
    if dragging:
        cancelDrag()
    
    dragging = true;
    drag_item = kunek
    drag_item_base_position = kunek.global_position
    drag_start_position = pos

# Returns kunek under mouse, but not the dragged one.
func kunekUnderMouse(pos: Vector2) -> KunekPicture:
    for node in kunki + fretki + lasice + gronostaje:
        var tex := node as KunekPicture
        if dragging and (tex == drag_item):
            return
        if tex.get_global_rect().has_point(pos):
            return tex
    return null

# Returns team under mouse, or -1.
func teamUnderMouse(pos: Vector2) -> int:
    for team in range(4):
        var bg := teamBackgrounds[team]
        if bg.get_global_rect().has_point(pos):
            return team
    return -1

func _gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                cancelDrag()
                var kunek := kunekUnderMouse(event.global_position)
                if kunek != null:
                    startDrag(event.global_position, kunek)
            else:
                if dragging:
                    var dropOnTeam := teamUnderMouse(event.global_position)
                    if dropOnTeam != -1:
                        GameData.initialCharacterToTeam[drag_item.character] = dropOnTeam
                        updateKunki()
                cancelDrag()
    elif event is InputEventMouseMotion:
        if dragging:
            drag_item.global_position = drag_item_base_position + (event.global_position - drag_start_position)

#########################################################
