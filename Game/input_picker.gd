extends Control
const OPTION_CONTROLLER = 0
const OPTION_KEYBOARD = 1
const PICK_CONTROLLER = 4

@export var player_picker : Node
@onready var controller_type: OptionButton = $VBoxContainer/ControllerType
@onready var selected_controller: OptionButton = $VBoxContainer/SelectedController
@onready var press_something: Button = $VBoxContainer/PressSomething
@onready var ok_button: Button = $VBoxContainer/OkButton
@onready var up: Button = $VBoxContainer/GridContainer/Up
@onready var left: Button = $VBoxContainer/GridContainer/Left
@onready var right: Button = $VBoxContainer/GridContainer/Right
@onready var down: Button = $VBoxContainer/GridContainer/Down
@onready var jump: Button = $VBoxContainer/Jump
@onready var duck: Button = $VBoxContainer/Duck

var buttonMap = {}
var originalLabels = {}

var waitForKey = false
var buttonWaiting: Button

func saveOriginalLabel(button: Button):
    originalLabels[button] = button.text

func _ready() -> void:
    saveOriginalLabel(up)
    saveOriginalLabel(left)
    saveOriginalLabel(right)
    saveOriginalLabel(down)
    saveOriginalLabel(jump)
    saveOriginalLabel(duck)
    reset()

func reset():
    press_something.grab_focus.call_deferred()
    enableGroup("ControllerCtrl", false)
    enableGroup("KeyboardCtrl", false)

func optionChanged(index: int):
    enableGroup("ControllerCtrl", index==OPTION_CONTROLLER)
    enableGroup("KeyboardCtrl", index==OPTION_KEYBOARD)
    controller_type.selected = index

    press_something.visible = false
    if index!=OPTION_CONTROLLER:
        selected_controller.selected = -1
        up.grab_focus.call_deferred()
    else:
        resetKeyboardMapping()
        ok_button.grab_focus.call_deferred()


func enableGroup(groupName, enabled):
    var objects = get_tree().get_nodes_in_group(groupName)
    for obj in objects:
        obj.visible = enabled

func _on_controller_type_item_selected(index: int) -> void:
    optionChanged(index)

func _on_press_something_gui_input(event: InputEvent) -> void:
    if event is InputEventKey:
        optionChanged(OPTION_KEYBOARD)
    elif event is InputEventJoypadButton:
        optionChanged(OPTION_CONTROLLER)
        selected_controller.select(event.device)


func waitFor(button: Button):
    waitForKey = true
    button.text = "-?-"
    buttonWaiting = button
    button.disabled = true

func resetKeyboardMapping():
    for btn in buttonMap.keys():
        buttonMap.erase(btn)
        btn.text = originalLabels[btn]


func _on_keyboard_input(event: InputEvent) -> void:
    if waitForKey && event is InputEventKey:
        waitForKey = false
        for btn in buttonMap.keys():
            if buttonMap[btn] == event.keycode:
                buttonMap.erase(btn)
                btn.text = originalLabels[btn]
        buttonWaiting.text = event.as_text_key_label()
        buttonMap[buttonWaiting] = event.keycode
        buttonWaiting.disabled = false
        buttonWaiting = null
        get_viewport().set_input_as_handled()

func _on_up_pressed() -> void:
    waitFor(up)

func _on_left_pressed() -> void:
    waitFor(left)

func _on_right_pressed() -> void:
    waitFor(right)

func _on_down_pressed() -> void:
    waitFor(down)

func _on_jump_pressed() -> void:
    waitFor(jump)

func _on_duck_pressed() -> void:
    waitFor(duck)


func _on_ok_button_pressed() -> void:
    if player_picker:
        player_picker.updateControls(self)
        queue_free()
    else:
        get_tree().quit()
