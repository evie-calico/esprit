INCLUDE "defines.inc"
INCLUDE "dungeon.inc"

MACRO dungeon ; name, tileset, type, floors, item0, item1, item2, item3
	SECTION "\1 Dungeon", ROMX
	x\1:: dw .tileset, .palette
	farptr \5
	farptr \6
	farptr \7
	farptr \8
	db \3, \4
	.tileset INCBIN \2
ENDM

MACRO dungeon_palette
.palette
	DEF BRED EQU \1
	DEF BGRN EQU \2
	DEF BBLU EQU \3
	REPT 3
		rgb BRED, BGRN, BBLU
		SHIFT 3
		rgb \1, \2, \3
		SHIFT 3
		rgb \1, \2, \3
		SHIFT 3
		rgb \1, \2, \3
	ENDR
ENDM

	dungeon Forest, "res/tree_tiles.2bpp", DUNGEON_TYPE_SCRAPER, 6, \
	        xApple, xGrapes, xPepper, xScarf
	dungeon_palette 128, 255, 144, \ ; Blank
	                  0, 120,   0, \ ; Ground
	                  0,  88,  24, \
	                  0,  32,   0, \
	                144, 104,  72, \ ; Wall
	                  0,  88,  24, \
	                  0,  32,   0, \
	                  0, 120,   0, \ ; Exit
	                  0,  88,  24, \
	                  0,  32,   0, \
