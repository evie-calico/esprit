INCLUDE "defines.inc"
INCLUDE "dungeon.inc"

; name, tileset, type, floors, completion flag, music
; item0, item1, item2, item3, items per floor,
; (entity ptr, entity level) * DUNGEON_ENTITY_COUNT
MACRO dungeon
	REDEF NAME EQUS "\1"
	REDEF TILESET EQUS "\2"
	REDEF TYPE EQUS "\3"
	REDEF FLOORS EQUS "\4"
	REDEF FLAG EQUS "\5"
	REDEF MUSIC EQUS "\6"
	SECTION "{NAME} Dungeon", ROMX
	{NAME}:: dw .tileset, .palette

	SHIFT 6
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

	db {FLAG}

	dw {MUSIC}
	db BANK({MUSIC})

	ASSERT sizeof_Dungeon == 55
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

	dungeon xForestDungeon, "res/dungeons/tree_tiles.2bpp", HALLS, 5, FLAG_FOREST_COMPLETE, xForestMusic, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xForestRat, 1, \
	        xForestRat, 1, \
	        xForestRat, 2, \
	        xForestRat, 2, \
	        xForestRat, 3, \
	        xFieldRat,  3, \
	        xForestRat, 4, \
	        xForestRat, 5
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

	dungeon xFieldDungeon, "res/dungeons/field_tiles.2bpp", HALLS, 5, FLAG_FIELDS_COMPLETE, xLakeMusic, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xFieldRat,  2, \
	        xForestRat, 3, \
	        xForestRat, 3, \
	        xFieldRat,  3, \
	        xFieldRat,  4, \
	        xFieldRat,  5, \
	        xFieldRat,  6, \
	        xFieldRat,  6
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

	dungeon xLakeDungeon, "res/dungeons/lake_tiles.2bpp", HALLS, 5, FLAG_LAKE_COMPLETE, xLakeMusic, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xFieldRat,  2, \
	        xForestRat, 3, \
	        xForestRat, 3, \
	        xFieldRat,  3, \
	        xFieldRat,  4, \
	        xFieldRat,  5, \
	        xFieldRat,  6, \
	        xFieldRat,  6
	dungeon_palette 255, 255,  128, \ ; Blank
	                160, 160,  80, \ ; Ground
	                 48,  48, 176, \
	                 16,  16, 128, \
	                 48,  48, 176, \ ; Wall
	                 16,  16, 128, \
	                  0,   8,   0, \
	                255,   0,   0, \ ; Exit
	                128,   0,   0, \
	                 64,   0,   0, \

	dungeon xPlainsDungeon, "res/dungeons/field_tiles.2bpp", HALLS, 5, FLAG_PLAINS_COMPLETE, xLakeMusic, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xFieldRat,  2, \
	        xForestRat, 3, \
	        xForestRat, 3, \
	        xFieldRat,  3, \
	        xFieldRat,  4, \
	        xFieldRat,  5, \
	        xFieldRat,  6, \
	        xFieldRat,  6
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

	dungeon xCavesDungeon, "res/dungeons/tree_tiles.2bpp", HALLS, 5, FLAG_CAVES_COMPLETE, xLakeMusic, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xForestRat, 1, \
	        xForestRat, 1, \
	        xForestRat, 2, \
	        xForestRat, 2, \
	        xForestRat, 3, \
	        xFieldRat,  3, \
	        xForestRat, 4, \
	        xForestRat, 5
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

	dungeon xGemstoneWoodsDungeon, "res/dungeons/gemtree_tiles.2bpp", HALLS, 5, FLAG_GEMTREE_COMPLETE, xLakeMusic, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xForestRat, 1, \
	        xForestRat, 1, \
	        xForestRat, 2, \
	        xForestRat, 2, \
	        xForestRat, 3, \
	        xFieldRat,  3, \
	        xForestRat, 4, \
	        xForestRat, 5
	dungeon_palette 248, 136, 112, \ ; Blank
	                176,  32,  64,  \ ; Ground
	                  0, 120,   0, \ 
	                  0,  32,   0, \
	                192,  72, 112, \ ; Wall
	                128,   0,  64, \
	                 32,   0,  32, \
	                  0,   0, 255, \ ; Exit
	                  0,   0, 128, \
	                  0,   0,  64, \
