if !def(DUNGEON_INC)
def DUNGEON_INC equ 1

include "structs.inc"

def DUNGEON_WIDTH equ 64
def DUNGEON_HEIGHT equ 64
def DUNGEON_ITEM_COUNT equ 4
def DUNGEON_ENTITY_COUNT equ 8

rsreset
def TILE_CLEAR rb 1
def TILE_WALL rb 1
def TILE_EXIT rb 1
def TILE_ITEMS rb 0
def TILE_ITEM0 rb 1
def TILE_ITEM1 rb 1
def TILE_ITEM2 rb 1
def TILE_ITEM3 rb 1

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
def DUNGEON_TYPE_SCRAPER rb 1
def DUNGEON_TYPE_HALLS rb 1

rsreset
def WINDOW_HIDE rb 1
def WINDOW_SHOW_MOVES rb 1
def WINDOW_TURNING rb 1

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
		bytes 1, CompletionFlag
		bytes 3, Music
		words 1, TickFunction
	end_struct

endc
