INCLUDE "defines.inc"
INCLUDE "dungeon.inc"

; name, tileset, type, floors, completion flag
; item0, item1, item2, item3, items per floor,
; (entity ptr, entity level) * DUNGEON_ENTITY_COUNT
MACRO dungeon
	REDEF NAME EQUS "\1"
	REDEF TILESET EQUS "\2"
	REDEF TYPE EQUS "\3"
	REDEF FLOORS EQUS "\4"
	REDEF FLAG EQUS "\5"
	SECTION "{NAME} Dungeon", ROMX
	x{NAME}:: dw .tileset, .palette

	SHIFT 5
	farptr \1
	farptr \2
	farptr \3
	farptr \4
	db DUNGEON_TYPE_{TYPE}, (FLOORS) + 1, (\5)

	SHIFT 5 - 2
	REPT DUNGEON_ENTITY_COUNT
		SHIFT 2
		db \2
		farptr \1
	ENDR

	db FLAG_{FLAG}

	ASSERT sizeof_Dungeon == 52
	.tileset INCBIN {TILESET}
ENDM

MACRO dungeon_palette
.palette
	REDEF BACKGROUND_RED EQU \1
	REDEF BACKGROUND_GREEN EQU \2
	REDEF BACKGROUND_BLUE EQU \3
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

	dungeon Forest, "res/tree_tiles.2bpp", HALLS, 5, FOREST_COMPLETE, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xRat, 1, \
	        xRat, 1, \
	        xRat, 2, \
	        xRat, 2, \
	        xRat, 3, \
	        xRat, 3, \
	        xRat, 4, \
	        xRat, 5
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

	dungeon Field, "res/field_tiles.2bpp", HALLS, 5, FOREST_COMPLETE, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xRat, 1, \
	        xRat, 1, \
	        xRat, 2, \
	        xRat, 2, \
	        xRat, 3, \
	        xRat, 3, \
	        xRat, 4, \
	        xRat, 5
	dungeon_palette 120, 192,  96, \ ; Blank
	                 32, 120,   0, \ ; Ground
	                 24,  64,  24, \
	                  0,  32,   0, \
	                 64, 120,   0, \ ; Wall
	                  0,  64,   0, \
	                  0,   8,   0, \
	                 96,  80,   0, \ ; Exit
	                 64,  48,   0, \
	                 32,  24,   0, \
