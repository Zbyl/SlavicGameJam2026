extends Control
const OPTION_CONTROLLER = 0
const OPTION_KEYBOARD = 1
const PICK_CONTROLLER = 4
const DEFAULT_KEYBOARD_KEY_MAP = {"type":"keyboard","up":KEY_UP,"down":KEY_DOWN,"left":KEY_LEFT,"right":KEY_RIGHT,"jump":KEY_SPACE}
const DEFAULT_PAD_KEY_MAP = {"type":"pad","pad":0}

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

@onready var buttons = {
    "up": up,
    "down": down,
    "left": left,
    "right": right,
    "jump": jump,
    "duck": duck,
}

var originalLabels = {
    "up": "▲",
    "down": "▼",
    "left": "◄",
    "right": "►",
    "jump": "Skok",
    "duck": "Szczekaj"
}

var waitForKey = false
var buttonWaiting: String

func _ready() -> void:
    reset()

func initiateWithdata(keyMap):
    press_something.visible = false

    if keyMap["type"] == "pad":
        selected_controller.selected= keyMap["pad"]
        optionChanged.call_deferred(OPTION_CONTROLLER)
    elif keyMap["type"] == "keyboard":
        var upCode = keyMap.get("up", -1)
        var downCode = keyMap.get("down", -1)
        var leftCode = keyMap.get("left", -1)
        var rightCode = keyMap.get("right", -1)
        var jumpCode = keyMap.get("jump", -1)
        var duckCode = keyMap.get("duck", -1)
        if upCode!=-1:
            up.text = OS.get_keycode_string(upCode)
        if downCode!=-1:
            down.text = OS.get_keycode_string(downCode)
        if leftCode!=-1:
            left.text = OS.get_keycode_string(leftCode)
        if rightCode!=-1:
            right.text = OS.get_keycode_string(rightCode)
        if jumpCode!=-1:
            jump.text = OS.get_keycode_string(jumpCode)
        if duckCode!=-1:
            duck.text = OS.get_keycode_string(duckCode)
        optionChanged.call_deferred(OPTION_KEYBOARD)

func reset():
    press_something.grab_focus.call_deferred()
    enableGroup("ControllerCtrl", false)
    enableGroup("KeyboardCtrl", false)

func optionChanged(index: int):
    enableGroup("ControllerCtrl", index==OPTION_CONTROLLER)
    enableGroup("KeyboardCtrl", index==OPTION_KEYBOARD)
    controller_type.selected = index

    press_something.visible = false
    if index==OPTION_KEYBOARD:
        selected_controller.selected = -1
        player_picker.keyMap = DEFAULT_KEYBOARD_KEY_MAP.duplicate()
        up.grab_focus.call_deferred()
    else:
        resetKeyboardMapping()
        player_picker.keyMap = DEFAULT_PAD_KEY_MAP.duplicate()
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


func waitFor(key: String):
    waitForKey = true
    buttonWaiting = key
    buttons[key].text = "-?-"
    buttons[key].disabled = true

func resetKeyboardMapping():
    up.text = originalLabels["up"]
    down.text = originalLabels["down"]
    left.text = originalLabels["left"]
    right.text = originalLabels["right"]
    jump.text = originalLabels["jump"]
    duck.text = originalLabels["duck"]


func _on_keyboard_input(event: InputEvent) -> void:
    if waitForKey && event is InputEventKey:
        waitForKey = false
        for key in player_picker.keyMap.keys():
            if typeof(player_picker.keyMap[key])==TYPE_INT && player_picker.keyMap[key] == event.keycode:
                player_picker.keyMap.erase(key)
                buttons[key].text = originalLabels[key]
        buttons[buttonWaiting].text = event.as_text_key_label()
        player_picker.keyMap.set(buttonWaiting, event.keycode)
        buttons[buttonWaiting].disabled = false
        buttonWaiting = ""
        get_viewport().set_input_as_handled()

func _on_selected_controller_item_selected(index: int) -> void:
    if index>=0 && index<=3:
        player_picker.keyMap.set("pad", index)


func _on_up_pressed() -> void:
    waitFor("up")

func _on_left_pressed() -> void:
    waitFor("left")

func _on_right_pressed() -> void:
    waitFor("right")

func _on_down_pressed() -> void:
    waitFor("down")

func _on_jump_pressed() -> void:
    waitFor("jump")

func _on_duck_pressed() -> void:
    waitFor("duck")


func _on_ok_button_pressed() -> void:
    if player_picker:
        queue_free()
    else:
        get_tree().quit()
