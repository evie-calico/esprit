include "defines.inc"
include "dungeon.inc"

; name, tileset, type, floors, completion flag, music, tick function
; item0, item1, item2, item3, items per floor,
; (entity ptr, entity level) * DUNGEON_ENTITY_COUNT
macro dungeon
	redef NAME equs "\1"
	redef TILESET equs "\2"
	redef TYPE equs "\3"
	redef FLOORS equs "\4"
	redef FLAG equs "\5"
	redef MUSIC equs "\6"
	redef TICK_FUNCTION equs "\7"
	section "{NAME} Dungeon", romx
	{NAME}:: dw .tileset, .palette

	shift 7
	farptr \1
	farptr \2
	farptr \3
	farptr \4
	db DUNGEON_TYPE_{TYPE}, (FLOORS) + 1, (\5)

	shift 5 - 2
	rept DUNGEON_ENTITY_COUNT
		shift 2
		db \2
		farptr \1
	endr

	db {FLAG}

	dw {MUSIC}
	db bank({MUSIC})

	dw {TICK_FUNCTION}

	assert sizeof_Dungeon == 57
	.tileset incbin {TILESET}
endm

macro dungeon_palette
.palette
	redef BACKGROUND_RED equ \1
	redef BACKGROUND_GREEN equ \2
	redef BACKGROUND_BLUE equ \3
	rept 3
		rgb BACKGROUND_RED, BACKGROUND_GREEN, BACKGROUND_BLUE
		shift 3
		rgb \1, \2, \3
		shift 3
		rgb \1, \2, \3
		shift 3
		rgb \1, \2, \3
	endr
endm

	dungeon xForestDungeon, "res/dungeons/tree_tiles.2bpp", HALLS, 5, FLAG_FOREST_COMPLETE, xForestMusic, null, \
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

	dungeon xFieldDungeon, "res/dungeons/field_tiles.2bpp", HALLS, 5, FLAG_FIELDS_COMPLETE, xTownMusic, null, \
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

	dungeon xLakeDungeon, "res/dungeons/lake_tiles.2bpp", HALLS, 5, FLAG_LAKE_COMPLETE, xLakeMusic, xLakeAnimationFunction, \
	        xRedApple, xGreenApple, xGrapes, xPepper, 2, \
	        xFieldRat,  2, \
	        xForestRat, 3, \
	        xForestRat, 3, \
	        xFieldRat,  3, \
	        xFieldRat,  4, \
	        xFieldRat,  5, \
	        xFieldRat,  6, \
	        xFieldRat,  6
	dungeon_palette $7b, $82, $a6, \ ; Blank
	                80, 96, 152, \
	                $3e, $4a, $83, \
	                $30, $38, $72, \
	                216, 136, 88, \
	                $3e, $4a, $83, \
	                $30, $38, $72, \
	                $63, $7f, $b7, \
	                64, 80, 160, \
	                $30, $38, $72, \

xLakeAnimationFunction:
	ldh a, [hFrameCounter]
	and a, 7
	ret nz
	ld a, [wLakeAnimationCounter]
	inc a
	cp a, 8
	jr nz, :+
	xor a, a
:
	ld [wLakeAnimationCounter], a

	add a, a ; a * 2 (18)
	add a, a ; a * 4 (36)
	add a, a ; a * 8 (72)
	add a, a ; a * 16 (144)
	add a, low(xLakeAnimationFrames / 4)
	ld l, a
	adc a, high(xLakeAnimationFrames / 4)
	sub a, l
	ld h, a
	add hl, hl
	add hl, hl

	ld de, $88C0 ; Address of full-wall tile
	ld c, 16 * 4
	jp VRAMCopySmall

ALIGN 2
xLakeAnimationFrames: incbin "res/dungeons/lake_animation.2bpp"

section FRAGMENT "dungeon BSS", wram0
wLakeAnimationCounter: db

	dungeon xPlainsDungeon, "res/dungeons/field_tiles.2bpp", HALLS, 5, FLAG_PLAINS_COMPLETE, xLakeMusic, null, \
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

	dungeon xCavesDungeon, "res/dungeons/tree_tiles.2bpp", HALLS, 5, FLAG_CAVES_COMPLETE, xLakeMusic, null, \
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

	dungeon xGemstoneWoodsDungeon, "res/dungeons/gemtree_tiles.2bpp", HALLS, 5, FLAG_GEMTREE_COMPLETE, xLakeMusic, null, \
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
