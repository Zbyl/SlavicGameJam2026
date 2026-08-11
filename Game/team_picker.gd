extends Control

@onready var kunek_panel: Panel = $KunekPanel
@onready var fretka_panel: Panel = $FretkaPanel
@onready var lasica_panel: Panel = $ŁasicaPanel
@onready var gronostaj_panel: Panel = $GronostajPanel
@onready var ok_button: Button = $OkButton
@onready var num_bereks_button: OptionButton = $NumBereksButton
@onready var count_berek_points: CheckBox = $CountBerekPoints
@onready var count_goals: CheckBox = $CountGoals

var kunki: Array[Node] = []
var fretki: Array[Node] = []
var lasice: Array[Node] = []
var gronostaje: Array[Node] = []

var selectedRow: int = 0 # We have 4 rows for characters and 4 columns for teams.

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
    
    ok_button.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("ui_up"):
        selectRow(selectedRow - 1)
    if Input.is_action_just_pressed("ui_down"):
        selectRow(selectedRow + 1)
        
    if Input.is_action_just_pressed("ui_left"):
        if selectedRow == 0:
            GameData.kunekTeam = (GameData.kunekTeam + 4 - 1) % 4
        if selectedRow == 1:
            GameData.fretkaTeam = (GameData.fretkaTeam + 4 - 1) % 4
        if selectedRow == 2:
            GameData.lasicaTeam = (GameData.lasicaTeam + 4 - 1) % 4
        if selectedRow == 3:
            GameData.gronostajTeam = (GameData.gronostajTeam + 4 - 1) % 4
        updateKunki()
    
    if Input.is_action_just_pressed("ui_right"):
        if selectedRow == 0:
            GameData.kunekTeam = (GameData.kunekTeam + 1) % 4
        if selectedRow == 1:
            GameData.fretkaTeam = (GameData.fretkaTeam + 1) % 4
        if selectedRow == 2:
            GameData.lasicaTeam = (GameData.lasicaTeam + 1) % 4
        if selectedRow == 3:
            GameData.gronostajTeam = (GameData.gronostajTeam + 1) % 4
        updateKunki()
    

# Updates visibility of characters according to chosen teams.
func updateKunki() -> void:
    for i in range(4):
        kunki[i].visible = GameData.kunekTeam == i
        fretki[i].visible = GameData.fretkaTeam == i
        lasice[i].visible = GameData.lasicaTeam == i
        gronostaje[i].visible = GameData.gronostajTeam == i

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
