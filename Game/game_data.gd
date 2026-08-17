extends Node

# It is auto load, so no name here - autoload has a name already.
#class_name GameData

var game: Game
var hud: Hud
var layerHelpers: LayerHelpers

const TRANSLATION_PL = preload("res://translations/game.pl.translation")
const TRANSLATION_EN = preload("res://translations/game.en.translation")
const TRANSLATION_DE = preload("res://translations/game.de.translation")

enum Language {
    PL,
    EN,
    DE,
}

var currentLanguage: Language = Language.PL

# Rejestruje pliki tlumaczen w TranslationServer, jawnie wymuszajac ich locale.
# Robimy to w kodzie (zamiast polegac na automatycznym wczytaniu z ustawien projektu),
# bo import CSV w edytorze Godota potrafi zapisac plik .translation z pustym/brakujacym
# polem locale (zaobserwowane dla "en") - wymuszenie locale tutaj naprawia ten problem.
func registerTranslations() -> void:
    TranslationServer.add_translation(TRANSLATION_PL)
    TranslationServer.add_translation(TRANSLATION_EN)
    TranslationServer.add_translation(TRANSLATION_DE)

# Switches the game's UI language. Call this instead of TranslationServer.set_locale()
# directly, so currentLanguage always stays in sync with the actual locale.
func setLanguage(lang: Language) -> void:
    currentLanguage = lang
    match lang:
        Language.PL:
            TranslationServer.set_locale("pl")
        Language.EN:
            TranslationServer.set_locale("en")
        Language.DE:
            TranslationServer.set_locale("de")

const KEYBOARD_PLAYER_ARROWS_WIDE = {"type": "keyboard", "up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "jump": KEY_SPACE, "duck": KEY_CTRL}
const KEYBOARD_PLAYER_ARROWS_TIGHT = {"type": "keyboard", "up": KEY_UP, "down": KEY_DOWN, "left": KEY_LEFT, "right": KEY_RIGHT, "jump": KEY_CTRL, "duck": KEY_ENTER}
const KEYBOARD_PLAYER_WSAD = {"type": "keyboard", "up": KEY_W, "down": KEY_S, "left": KEY_A, "right": KEY_D, "jump": KEY_SHIFT, "duck": KEY_E}
const KEYBOARD_PLAYER_IKJL = {"type": "keyboard", "up": KEY_I, "down": KEY_K, "left": KEY_J, "right": KEY_L, "jump": KEY_ALT, "duck": KEY_O}
const KEYBOARD_PLAYER_NUMPAD = {"type": "keyboard", "up": KEY_KP_8, "down": KEY_KP_5, "left": KEY_KP_4, "right": KEY_KP_6, "jump": KEY_KP_ENTER, "duck": KEY_KP_0}
const PAD_PLAYER_0 = {"type": "pad", "pad": 0}

##############################################
# THOSE SHOULD BE USED ONLY AT LEVEL START!
# Later used values derived from them: berekTeams, activeCharacterToTeam, nonEmptyTeamToCharacters, getCharactersInTeam()...

var initialCharacterToTeam: Dictionary[Character, int] = {Character.Fox: 0, Character.Ferret: 1, Character.Weasel: 2, Character.Snow: 3} # Characters to their team.

var numBereks: int = 1  # How many berek teams there should be.
                        # - if a team is a berek all members of that team are bereks
                        # - bereks can catch only non-bereks
                        # - 0 bereks make sense for single player or football
                        # - bereks more or equal to non-empty team count doesn't make sense

var tightControls: Dictionary[Character, bool] = {Character.Fox: false, Character.Ferret: false, Character.Weasel: false, Character.Snow: false}  # Tweaks to improve handling.

##############################################

var countBerekPoints: bool = true    # Count points for time of not being berek,
                                     # and bonus points for catching and penalty points for being catched.
var countGoalsPoints: bool = true # Count points for scoring goals.

var berek_boost: float = 1.3

enum Character {
    Fox,
    Ferret,
    Weasel,
    Snow,
}

const ALL_CHARACTERS: Array[Character] = [Character.Fox, Character.Ferret, Character.Weasel, Character.Snow]

func characterStrToEnum(character: String) -> Character:
    if character == "Fox":
        return Character.Fox
    if character == "Ferret":
        return Character.Ferret
    if character == "Weasel":
        return Character.Weasel
    if character == "Snow":
        return Character.Snow
    assert(false)
    return Character.Fox

func characterEnumToStr(character: Character) -> String:
    return Character.find_key(character)

var berekTeams: Array[int] = [] # Teams that are berek now. Initialized from numBereks at the start of the level.
var activeCharacterToTeam: Dictionary[Character, int] = {} # Active characters to their team.
var nonEmptyTeamToCharacters: Dictionary[int, Array] = {} # int -> Array[Character], contains only non-empty teams (only active characters are considered)
var activeCharacters: Array[Character] = [] # List of currently playing characters.
var berekCooldownActive: Dictionary[int, bool] = {}   # If true this team was just berek'd, but should not be berking yet as we are in a cooldown before they start berking.
var deathCooldownActive: Dictionary[Character, int] = {} # Characters that are dead.
                                                         # If true berekCooldownActive for his team must also be true.
                                                         # @todo This is not really used now. We could remove it.

# Initializing game data for the level.
# activeCharacters - characters that are going to play
func levelPreInit(_activeCharacters: Array[Character]) -> void:
    berekCooldownActive = {0: false, 1: false, 2: false, 3: false}
    deathCooldownActive = {}
    for character in _activeCharacters:
        deathCooldownActive[character] = false

    activeCharacters = _activeCharacters
    print("Active characters: {activeCharacters}".format({ "activeCharacters": activeCharacters }))

    berekTeams = []
    activeCharacterToTeam = {}
    nonEmptyTeamToCharacters = {}
    var teamToCharacters := {0: [], 1: [], 2: [], 3: []}

    for character in activeCharacters:
        activeCharacterToTeam[character] = initialCharacterToTeam[character]

    for character in activeCharacterToTeam:
        var team := activeCharacterToTeam[character]
        teamToCharacters[team].append(character)

    for team in teamToCharacters:
        var chars: Array[Character] = Array(teamToCharacters[team], TYPE_INT, "", null) # Copying array, while casting to a typed array.
        if chars.size() > 0:
            nonEmptyTeamToCharacters[team] = chars

    var currentBerekCount: int = min(numBereks, nonEmptyTeamToCharacters.size() - 1)
    berekTeams = Array(nonEmptyTeamToCharacters.keys(), TYPE_INT, "", null) # Copying array, while casting to a typed array.
    berekTeams.shuffle()
    berekTeams.resize(currentBerekCount)

    printTeamsAndBereks()

func printTeamsAndBereks() -> void:
    for team in range(4):
        var chars := getCharactersInTeam(team)
        print("Team {team}: {chars}".format({ "team": team, "chars": chars}))

    print("Berek teams: {berekTeams}".format({ "berekTeams": berekTeams }))
    if Character.Fox in activeCharacters:
        print("Fox berek: {berek}".format({ "berek": isActiveCharacterBerek(Character.Fox) }))
    if Character.Ferret in activeCharacters:
        print("Feret berek: {berek}".format({ "berek": isActiveCharacterBerek(Character.Ferret) }))
    if Character.Weasel in activeCharacters:
        print("Weasel berek: {berek}".format({ "berek": isActiveCharacterBerek(Character.Weasel) }))
    if Character.Snow in activeCharacters:
        print("Snow berek: {berek}".format({ "berek": isActiveCharacterBerek(Character.Snow) }))


# Returns characters in given team (even if team is empty)
func getCharactersInTeam(team: int) -> Array[Character]:
    if team in nonEmptyTeamToCharacters:
        return nonEmptyTeamToCharacters[team]
    return []

func isCharacterActive(character: Character) -> bool:
    return character in activeCharacterToTeam

# Returns true if team has any active character.
func isTeamActive(team: int) -> bool:
    return team in nonEmptyTeamToCharacters

func getActiveCharacterTeam(character: Character) -> int:
    if not isCharacterActive(character):
        push_error("character={character} is not active. activeCharacterToTeam={activeCharacterToTeam}".format({"character": character, "activeCharacterToTeam": activeCharacterToTeam}))
        return initialCharacterToTeam[character] # Returning some invalid value here.
    return activeCharacterToTeam[character]

func isTeamBerek(team: int) -> bool:
    return team in berekTeams

func isActiveCharacterBerek(character: Character) -> bool:
    var team = getActiveCharacterTeam(character)
    return team in berekTeams

func getAllBereks() -> Array[Character]:
    var result: Array[Character] = []
    for team in berekTeams:
        var chars := getCharactersInTeam(team)
        result += chars
    return result

# Returns Dude for given character. Returns null if character doesn't exist in current level.
func getCharacterDude(character: Character) -> Dude:
    assert(game.level)
    var dudes = get_tree().get_nodes_in_group("Dude")
    for dude in dudes:
        if dude.character == character:
            return dude

    return null

# Returns true if given berek can zberkować other player.
# False if this character cannot berek the other one.
func canZberkowac(berekCharacter: Character, caughtCharacter: Character) -> bool:
    if not isActiveCharacterBerek(berekCharacter):
        print("Not a berek {berek} cannot catch another player {caught}.".format({
            "berek": berekCharacter,
            "caught": caughtCharacter,
        }))
        return false

    if isActiveCharacterBerek(caughtCharacter):
        print("Berek {berek} cannot catch another berek {caught}.".format({
            "berek": berekCharacter,
            "caught": caughtCharacter,
        }))
        return false

    var berekTeam = getActiveCharacterTeam(berekCharacter)
    var caughtTeam = getActiveCharacterTeam(caughtCharacter)

    if berekTeam == caughtTeam:
        print("Berek {berek} cannot catch player from his team {caught}.".format({
            "berek": berekCharacter,
            "caught": caughtCharacter,
        }))
        return false

    if GameData.berekCooldownActive[berekTeam]:
        print("Berek {berek} under berek cooldown cannot catch player {caught}.".format({
            "berek": berekCharacter,
            "caught": caughtCharacter,
        }))
        return false

    if GameData.berekCooldownActive[caughtTeam]:
        print("Berek {berek} cannot catch player under berek cooldown {caught}.".format({
            "berek": berekCharacter,
            "caught": caughtCharacter,
        }))
        return false

    if GameData.deathCooldownActive[caughtCharacter]:
        print("Berek {berek} cannot catch player under death cooldown {caught}.".format({
            "berek": berekCharacter,
            "caught": caughtCharacter,
        }))
        return false

    return true

# Zberkuj.
# After a while need to call doWakeUpAfterZberkowany().
func doZberkuj(berekCharacter: Character, caughtCharacter: Character) -> void:
    assert(canZberkowac(berekCharacter, caughtCharacter))
    # Replace berekTeam with caughtTeam in berekTeams.
    var berekTeam = getActiveCharacterTeam(berekCharacter)
    var caughtTeam = getActiveCharacterTeam(caughtCharacter)
    var foundIdx = berekTeams.find(berekTeam)
    assert(foundIdx != -1)
    berekTeams[foundIdx] = caughtTeam

    berekCooldownActive[caughtTeam] = true
    deathCooldownActive[caughtCharacter] = true

    printTeamsAndBereks()

# See doZberkuj()
func doWakeUpAfterZberkowany(character: Character) -> void:
    var team := GameData.getActiveCharacterTeam(character)
    berekCooldownActive[team] = false
    deathCooldownActive[character] = false

# Called when the node enters the scene tree for the first time.
func _ready():
    registerTranslations()
    setLanguage(Language.PL)  # Polski jest domyslnym jezykiem gry.
    layerHelpers = LayerHelpers.new()
    hud = get_tree().get_first_node_in_group('Hud')
    game = get_tree().get_first_node_in_group('Game')
