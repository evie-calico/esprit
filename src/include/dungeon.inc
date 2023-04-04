if !def(DUNGEON_INC)
def DUNGEON_INC equ 1

include "structs.inc"

def DUNGEON_WIDTH equ 64
def DUNGEON_HEIGHT equ 64
def DUNGEON_ITEM_COUNT equ 4
def DUNGEON_ENTITY_COUNT equ 8

rsreset
def TILE_CLEAR rb
def TILE_WALL rb
def TILE_EXIT rb
def TILE_ITEMS rb 0
def TILE_ITEM0 rb
def TILE_ITEM1 rb
def TILE_ITEM2 rb
def TILE_ITEM3 rb

; The dungeon renderer is hard-coded to use these 4 metatiles to draw floors and
; walls. Additional tiles should follow these metatiles.
; For example, stairs, which use an ID of 2, should be placed at $90.
rsset $80
def BLANK_METATILE_ID rb 4
def STANDALONE_METATILE_ID rb 4
def TERMINAL_METATILE_ID rb 4
def FULL_METATILE_ID rb 4
def EXIT_METATILE_ID rb 4
def ITEM_METATILE_ID rb 4 * 4

rsreset
def DUNGEON_TYPE_SCRAPER rb
def DUNGEON_TYPE_HALLS rb
def DUNGEON_TYPE_LATTICE rb
def DUNGEON_TYPE_GROTTO rb
def DUNGEON_TYPE_DEBUG rb

rsreset
def WINDOW_HIDE rb
def WINDOW_SHOW_MOVES rb
def WINDOW_TURNING rb

rsreset
def DUNGEON_COMPLETION_EXIT rb
; TODO: make SWITCH change the current music if it differs from the old dungeon.
def DUNGEON_COMPLETION_SWITCH rb
def DUNGEON_COMPLETION_SCENE rb

	struct SpawnEntityInfo
		bytes 1, Level
		bytes 1, Bank
		words 1, Pointer
	end_struct

	struct Dungeon
		words 1, Tileset
		words 1, Palette
		bytes DUNGEON_ITEM_COUNT * 3, Items
		bytes 1, GenerationType
		bytes 1, FloorCount
		bytes 1, ItemsPerFloor
		bytes sizeof_SpawnEntityInfo * DUNGEON_ENTITY_COUNT, Entities
		; TODO: this could potentially be moved to the "end" script.
		; No reason to do this here when the script can already take care of it.
		bytes 1, CompletionType
		alias CompletionFlag
		alias NextScenePointer
		bytes 3, NextDungeonPointer
		bytes 3, Music
		words 1, TickFunction
	end_struct

endc
