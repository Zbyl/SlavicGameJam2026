extends Node

# It is auto load, so not name here - autoload has a name already.
#class_name GameData

var game: Game
var hud: Hud
var layerHelpers: LayerHelpers

##############################################
# THOSE SHOULD BE USED ONLY AT LEVEL START!
# Later used values derived from them: berekTeams, characterToTeam, nonEmptyTeamToCharacters, getCharactersInTeam()...

var kunekTeam: int = 0
var fretkaTeam: int = 1
var lasicaTeam: int = 2
var gronostajTeam: int = 3

var numBereks: int = 1  # How many berek teams there should be.
                        # - if a team is a berek all members of that team are bereks
                        # - bereks can catch only non-bereks
                        # - 0 bereks make sense for single player or football
                        # - bereks more or equal to non-empty team count doesn't make sense

##############################################

var countPointsForTime: bool = true # Count points for time of not being berek,
                                    # and bonus points for catching and penalty points for being catched.
var countPointsForGoals: bool = true # Count points for scoring goals.

enum Character {
    Fox,
    Ferret,
    Weasel,
    Snow,
}

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
var characterToTeam: Dictionary[Character, int] = {}
var nonEmptyTeamToCharacters: Dictionary[int, Array] = {} # int -> Array[Character], contains only non-empty teams

# Initializing game data for the level.
func levelPreInit() -> void:
    berekTeams = []
    characterToTeam = {}
    nonEmptyTeamToCharacters = {}
    var teamToCharacters := {0: [], 1: [], 2: [], 3: []}

    characterToTeam[Character.Fox] = kunekTeam
    characterToTeam[Character.Ferret] = fretkaTeam
    characterToTeam[Character.Weasel] = lasicaTeam
    characterToTeam[Character.Snow] = gronostajTeam
    
    for character in characterToTeam:
        var team := characterToTeam[character]
        teamToCharacters[team].append(character)

    for team in teamToCharacters:
        var chars: Array[Character] = Array(teamToCharacters[team], TYPE_INT, "", null) # Copying array, while casting to a typed array.
        if chars.size() > 0:
            nonEmptyTeamToCharacters[team] = chars
        
    var currentBerekCount: int = min(numBereks, nonEmptyTeamToCharacters.size() - 1)
    berekTeams = Array(range(nonEmptyTeamToCharacters.size()), TYPE_INT, "", null) # Copying array, while casting to a typed array.
    berekTeams.shuffle()
    berekTeams.resize(currentBerekCount)

# Returns characters in given team (even if team is empty)
func getCharactersInTeam(team: int) -> Array[Character]:
    if team in nonEmptyTeamToCharacters:
        return nonEmptyTeamToCharacters[team]
    return []
    
func isCharacterBerek(character: Character) -> bool:
    var team = characterToTeam[character]
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
        var ch := characterStrToEnum(dude.character)
        if ch == character:
            return dude
            
    return null

# Called when the node enters the scene tree for the first time.
func _ready():
    layerHelpers = LayerHelpers.new()
    hud = get_tree().get_first_node_in_group('Hud')
    game = get_tree().get_first_node_in_group('Game')
