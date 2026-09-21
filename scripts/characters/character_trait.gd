class_name CharacterTrait
extends Node
## A rule a character owns. RunSession instances one as a child of the penguin
## at spawn and calls setup(); from there it may read and adjust that penguin's
## stats, listen to its signals, add nodes, or wrap its behaviour.
##
## This is how a character changes rules without Player.gd knowing that any
## character exists. Nothing anywhere asks "is this the Caveman" — a character
## is a CharacterDefinition plus the traits it carries.
##
## A trait belongs to exactly one penguin. For anything party-wide, put the
## rule on a system and let the trait talk to it, rather than reaching across
## to other players.

var player: PenguinPlayer

## Called once, after the penguin is in the tree and its own @onready nodes
## exist, and after starting stats have been applied.
func setup(owner_player: PenguinPlayer) -> void:
	player = owner_player
