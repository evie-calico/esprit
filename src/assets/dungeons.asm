INCLUDE "defines.inc"
INCLUDE "dungeon.inc"

; name, tileset, type, floors,
; item0, item1, item2, item3, items per floor,
; (entity ptr, entity level) * DUNGEON_ENTITY_COUNT
MACRO dungeon
	SECTION "\1 Dungeon", ROMX
	x\1:: dw .tileset, .palette
	farptr \5
	farptr \6
	farptr \7
	farptr \8
	db DUNGEON_TYPE_\3, (\4) + 1, (\9)
	DEF DUNGEON_TILESET EQUS "\2"
	SHIFT 7
	REPT DUNGEON_ENTITY_COUNT
		SHIFT 2
		db \2
		farptr \1
	ENDR
	ASSERT sizeof_Dungeon == 51
	.tileset INCBIN {DUNGEON_TILESET}
	PURGE DUNGEON_TILESET
ENDM

MACRO dungeon_palette
.palette
	DEF BACKGROUND_RED EQU \1
	DEF BACKGROUND_GREEN EQU \2
	DEF BACKGROUND_BLUE EQU \3
	REPT 3
		rgb BACKGROUND_RED, BACKGROUND_GREEN, BACKGROUND_BLUE
		SHIFT 3
		rgb \1, \2, \3
		SHIFT 3
		rgb \1, \2, \3
		SHIFT 3
		rgb \1, \2, \3
	ENDR
ENDM

	dungeon Forest, "res/tree_tiles.2bpp", HALLS, 3, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 4, \
	        xRat, 1, \
	        xRat, 1, \
	        xAris, 1, \
	        xLuvui, 1, \
	        xRat, 2, \
	        xRat, 2, \
	        xRat, 3, \
	        xRat, 3
	dungeon_palette 128, 255, 144, \ ; Blank
	                  0, 120,   0, \ ; Ground
	                  0,  88,  24, \
	                  0,  32,   0, \
	                144, 104,  72, \ ; Wall
	                  0,  88,  24, \
	                  0,  32,   0, \
	                  0,   0, 255, \ ; Exit
	                  0,   0, 128, \
	                  0,   0,  64, \
