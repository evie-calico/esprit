IF !DEF(DUNGEON_INC)
DEF DUNGEON_INC EQU 1

INCLUDE "structs.inc"

DEF DUNGEON_WIDTH EQU 64
DEF DUNGEON_HEIGHT EQU 64
DEF DUNGEON_ITEM_COUNT EQU 4
DEF DUNGEON_ENTITY_COUNT EQU 8

RSRESET
DEF TILE_CLEAR RB 1
DEF TILE_WALL RB 1
DEF TILE_EXIT RB 1
DEF TILE_ITEMS RB 0
DEF TILE_ITEM0 RB 1
DEF TILE_ITEM1 RB 1
DEF TILE_ITEM2 RB 1
DEF TILE_ITEM3 RB 1

; The dungeon renderer is hard-coded to use these 4 metatiles to draw floors and
; walls. Additional tiles should follow these metatiles.
; For example, stairs, which use an ID of 2, should be placed at $90.
RSSET $80
DEF BLANK_METATILE_ID RB 4
DEF STANDALONE_METATILE_ID RB 4
DEF TERMINAL_METATILE_ID RB 4
DEF FULL_METATILE_ID RB 4
DEF EXIT_METATILE_ID RB 4
DEF ITEM_METATILE_ID RB 4 * 4

RSRESET
DEF DUNGEON_TYPE_SCRAPER RB 1
DEF DUNGEON_TYPE_HALLS RB 1

RSRESET
DEF WINDOW_HIDE RB 1
DEF WINDOW_SHOW_MOVES RB 1
DEF WINDOW_TURNING RB 1

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

ENDC
