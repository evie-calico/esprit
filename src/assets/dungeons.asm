include "defines.inc"
include "dungeon.inc"
include "entity.inc"

macro def_equs
	redef \1 equs "\2"
endm

macro try_purge
	rept _NARG
		if def(\1)
			purge \1
		endc
		shift 1
	endr
endm

macro _new_dungeon
	redef NAME equs "\1"
	redef TICK_FUNCTION equs "null"

	for i, DUNGEON_ITEM_COUNT
		try_purge ITEM{d:i}
	endr
	for i, DUNGEON_ENTITY_COUNT
		try_purge ENEMY{d:i}_LEVEL
		try_purge ENEMY{d:i}
	endr
endm

macro dungeon
	try_purge TILESET, TYPE, FLOORS, COMPLETION_TYPE, COMPLETION_ARG, MUSIC, TICK_FUNCTION

	_new_dungeon \1
endm

macro get_next_name
	if strin("{NAME}", "_part")
		def part equs strsub("{NAME}", strlen("{NAME}"))
		def part_value = part + 1
		redef NEXT_NAME equs strcat(strsub("{NAME}", 1, strlen("{NAME}") - 1), "{d:part_value}")
		purge part, part_value
	else
		redef NEXT_NAME equs strcat("{NAME}", "_part2")
	endc
endm

macro next_part
	get_next_name
	_new_dungeon {NEXT_NAME}

endm
macro tileset ; path
	def_equs TILESET, \1
endm

macro shape ; dungeon generation type
	def_equs TYPE, \1
endm

macro after_floor ; number, action, [arg]
	def_equs FLOORS, \1
	redef COMPLETION_TYPE equs strupr("\2")
	if !strcmp(strupr("\2"), "SWITCH")
		get_next_name
		def_equs COMPLETION_ARG, {NEXT_NAME}
	else
		def_equs COMPLETION_ARG, \3
	endc
endm

macro on_tick
	def_equs TICK_FUNCTION, \1
endm

macro music
	def_equs MUSIC, \1
endm

macro item
	for i, DUNGEON_ITEM_COUNT
		if !def(ITEM{d:i})
			def_equs ITEM{d:i}, \1
			break
		endc
	endr
	if i == DUNGEON_ITEM_COUNT
		fail "Each dungeon is limited to {d:DUNGEON_ITEM_COUNT} items"
	endc
endm

macro items_per_floor
	def_equs ITEM_COUNT, \1
endm

macro enemy ; name, level
	for i, DUNGEON_ENTITY_COUNT
		if !def(ENEMY{d:i})
			def_equs ENEMY{d:i}, \1
			def_equs ENEMY{d:i}_LEVEL, \2
			break
		endc
	endr
	if i == DUNGEON_ENTITY_COUNT
		fail "Each dungeon is limited to {d:DUNGEON_ENTITY_COUNT} enemies"
	endc
endm

macro end
	section "{NAME} Dungeon", romx
	{NAME}:: dw .tileset, .palette

	for i, DUNGEON_ITEM_COUNT
		farptr ITEM{d:i}
	endr

	db DUNGEON_TYPE_{TYPE}, (FLOORS) + 1, (ITEM_COUNT)

	for i, DUNGEON_ENTITY_COUNT
		db ENEMY{d:i}_LEVEL
		farptr ENEMY{d:i}
	endr

	if DUNGEON_COMPLETION_{COMPLETION_TYPE} == DUNGEON_COMPLETION_EXIT
		db DUNGEON_COMPLETION_{COMPLETION_TYPE}
		db {COMPLETION_ARG}
		; Padding for exit type
		db 0, 0
	else
		db DUNGEON_COMPLETION_{COMPLETION_TYPE}
		db bank({COMPLETION_ARG})
		db low({COMPLETION_ARG})
		db high({COMPLETION_ARG})
	endc


	dw {MUSIC}
	db bank({MUSIC})

	dw {TICK_FUNCTION}

	assert sizeof_Dungeon == 60
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

macro dungeon_hex
.palette
	redef BACKGROUND equs "\1"
	shift 1
	rept 3
		hex {BACKGROUND}, \1, \2, \3
		shift 3
	endr
endm

	dungeon xForestDungeon
		tileset "res/dungeons/tree_tiles.2bpp"
		after_floor 2, switch
		shape HALLS
		music xForestMusic

		items_per_floor 2
		item xRedApple
		item xGreenApple
		item xTwig
		item xGrapes

		enemy xForestRat, 1
		enemy xForestRat, 1
		enemy xForestRat, 2
		enemy xForestRat, 2
		enemy xForestRat, 2
		enemy xForestRat, 3
		enemy xMudCrab,   1
		enemy xFieldRat,  1
	end
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

	next_part
		after_floor 3, scene, xForestScene
		shape LATTICE

		items_per_floor 5
		item xAloe
		item xGreenApple
		item xGrapes
		item xReviverSeed

		; In the deep forest, dangerous enemies are slightly more common
		enemy xForestRat, 2
		enemy xForestRat, 2
		enemy xForestRat, 2
		enemy xForestRat, 3
		enemy xMudCrab,   1
		enemy xMudCrab,   1
		enemy xFieldRat,  1
		enemy xFieldRat,  2
	end
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

	next_part
		after_floor 4, switch
		shape LATTICE
		music xForestNightMusic

		items_per_floor 5
		item xRedApple
		item xAloe
		item xGrapes
		item xReviverSeed

		; In the deep forest, dangerous enemies are slightly more common
		enemy xForestRat, 2
		enemy xForestRat, 2
		enemy xForestRat, 2
		enemy xForestRat, 3
		enemy xMudCrab,   1
		enemy xMudCrab,   1
		enemy xFieldRat,  1
		enemy xFieldRat,  2
	end
	dungeon_palette 120, 192,  96, \ ; Blank
	                 32, 120,   0, \ ; Ground
	                 24,  64,  24, \
	                  0,  32,   0, \
	                 64, 120,   0, \ ; Wall
	                  0,  64,   0, \
	                  0,   8,   0, \
	                  0,   0, 255, \ ; Exit
	                  0,   0, 128, \
	                  0,   0,  64, \

	; Transition back to the original forest before finally reaching the fields.
	next_part
		after_floor 5, switch
		shape HALLS

		items_per_floor 2
		item xRedApple
		item xGreenApple
		item xGrapes
		item xTwig

		enemy xForestRat, 1
		enemy xForestRat, 1
		enemy xForestRat, 1
		enemy xForestRat, 2
		enemy xForestRat, 2
		enemy xForestRat, 2
		enemy xForestRat, 3
		enemy xFieldRat,  1
	end
	dungeon_palette 120, 192,  96, \ ; Blank
	                 32, 120,   0, \ ; Ground
	                 24,  64,  24, \
	                  0,  32,   0, \
	                 64, 120,   0, \ ; Wall
	                  0,  64,   0, \
	                  0,   8,   0, \
	                  0,   0, 255, \ ; Exit
	                  0,   0, 128, \
	                  0,   0,  64, \

	; Give the player a preview of the fields :)
	next_part
		tileset "res/dungeons/field_tiles.2bpp"
		after_floor 6, scene, xForestScene2
		on_tick xForestNightForceTired

		items_per_floor 3
		item xAloe
		item xPepper
		item xGrapes
		item xTwig

		enemy xForestRat, 3
		enemy xForestRat, 3
		enemy xForestRat, 4
		enemy xSnake,     3
		enemy xSnake,     4
		enemy xFieldRat,  2
		enemy xFieldRat,  3
		enemy xFieldRat,  4
	end
	dungeon_palette  94, 144, 175, \ ; Blank
	                  9, 109, 102, \ ; Ground
	                 11,  76,  43, \
	                  4,  40,  26, \
	                  9, 109, 102, \ ; Ground
	                 11,  76,  43, \
	                  4,  40,  26, \
	                  9, 109, 102, \ ; Ground
	                 11,  76,  43, \
	                  4,  40,  26,

; Placing this after the dungeon ensures it's in the same bank.
; Forcefully cap the players' fatigue so they always display "Tired".
xForestNightForceTired:
	ld a, [wFadeSteps]
	and a, a
	jr nz, :+
	ld a, [wShownNightMessage]
	and a, a
	jr nz, :+
	ld b, bank(.message)
	ld hl, .message
	call PrintHUD
	ld a, 1
	ld [wShownNightMessage], a
:
	ld a, [wEntity0_Fatigue]
	cp a, TIRED_THRESHOLD - 1
	jr c, :+
	ld a, TIRED_THRESHOLD - 2
	ld [wEntity0_Fatigue], a
:
	ld a, [wEntity1_Fatigue]
	cp a, TIRED_THRESHOLD - 1
	ret c
	ld a, TIRED_THRESHOLD - 2
	ld [wEntity1_Fatigue], a
	ret

.message
	db "Being out so late is making you feel tired. "
	db "Your maximum energy is capped.", 0

section fragment "dungeon BSS", wram0
wShownNightMessage: db

	dungeon xFieldDungeon
		tileset "res/dungeons/field_tiles.2bpp"
		after_floor 5, exit, FLAG_FIELDS_COMPLETE
		on_tick xFieldsGiveHeatstroke
		shape HALLS
		music xFieldMusic

		items_per_floor 1
		item xWaterMelon
		item xPepper
		item xGrapes
		item xGrapes

		enemy xAlligator, 3
		enemy xForestRat, 3
		enemy xForestRat, 4
		enemy xSnake,     3
		enemy xSnake,     4
		enemy xFieldRat,  2
		enemy xFieldRat,  3
		enemy xFieldRat,  4
	end
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

xFieldsGiveHeatstroke:
	ld a, [wLastTurnNumber]
	ld b, a
	ld a, [wTurnCounter]
	cp a, b
	ret z
	ld [wLastTurnNumber], a	

	call Rand
	and a, a
	jr nz, :+
	ld a, 1
	ld [wEntity0_IsHeatstroked], a
	ld [wForceHudUpdate], a
	ld a, high(wEntity0)
	ld [wfmt_xGotHeatstrokeString_target], a
	ld b, bank(xGotHeatstrokeString)
	ld hl, xGotHeatstrokeString
	call PrintHUD
:
	ld a, e
	and a, a
	ret nz
	ld a, 1
	ld [wEntity1_IsHeatstroked], a
	ld [wForceHudUpdate], a
	ld a, high(wEntity1)
	ld [wfmt_xGotHeatstrokeString_target], a
	ld b, bank(xGotHeatstrokeString)
	ld hl, xGotHeatstrokeString
	call PrintHUD
	ret

section fragment "dungeon BSS", wram0
wLastTurnNumber: db

	dungeon xLakeDungeon
		tileset "res/dungeons/lake_tiles.2bpp"
		after_floor 5, exit, FLAG_LAKE_COMPLETE
		shape HALLS
		music xLakeMusic
		on_tick xLakeAnimationFunction

		items_per_floor 1
		item xRedApple
		item xGreenApple
		item xGrapes
		item xPepper

		enemy xFieldRat,  2
		enemy xFieldRat,  3
		enemy xPlatypus,  3
		enemy xFirefly,   3
		enemy xFirefly,   4
		enemy xPlatypus,  5
		enemy xAlligator, 6
		enemy xAlligator, 6
	end
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

; Placing this after the dungeon ensures it's in the same bank.
; Animates the stars in the reflection of the water
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
	jp VramCopySmall

ALIGN 2
xLakeAnimationFrames: incbin "res/dungeons/lake_animation.2bpp"

section FRAGMENT "dungeon BSS", wram0
wLakeAnimationCounter: db

	; ---------------------
	; The rest of these dungeons are incomplete placeholders.
	; ---------------------

	dungeon xPlainsDungeon
		tileset "res/dungeons/field_tiles.2bpp"
		after_floor 5, exit, FLAG_PLAINS_COMPLETE
		shape HALLS
		music xFieldAltMusic

		items_per_floor 1
		item xRedApple
		item xGreenApple
		item xGrapes
		item xPepper

		enemy xFieldRat,  2
		enemy xForestRat, 3
		enemy xForestRat, 3
		enemy xFirefly,   3
		enemy xFirefly,   4
		enemy xFieldRat,  5
		enemy xFieldRat,  6
		enemy xFieldRat,  6
	end
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

	dungeon xCavesDungeon
		tileset "res/dungeons/cave_tiles.2bpp"
		after_floor 5, exit, FLAG_CAVES_COMPLETE
		shape HALLS
		music xLakeMusic

		items_per_floor 1
		item xRedApple
		item xGreenApple
		item xGrapes
		item xPepper

		enemy xFieldRat,  2
		enemy xForestRat, 3
		enemy xForestRat, 3
		enemy xFirefly,   3
		enemy xFirefly,   4
		enemy xFieldRat,  5
		enemy xFieldRat,  6
		enemy xFieldRat,  6
	end
	dungeon_hex 9191a9, \ ; Blank
	            555571, \ ; Ground
	            3d455a, \
	            07152f, \
	            555571, \ ; Ground
	            3d455a, \
	            07152f, \
	            555571, \ ; Wall
	            3d455a, \
	            07152f, \
	            555571, \ ; Exit
	            3d455a, \
	            07152f, \

	dungeon xGemstoneWoodsDungeon
		tileset "res/dungeons/gemtree_tiles.2bpp"
		after_floor 5, exit, FLAG_GEMTREE_COMPLETE
		shape HALLS
		music xLakeMusic

		items_per_floor 1
		item xRedApple
		item xGreenApple
		item xGrapes
		item xPepper

		enemy xFieldRat,  2
		enemy xForestRat, 3
		enemy xForestRat, 3
		enemy xFirefly,   3
		enemy xFirefly,   4
		enemy xFieldRat,  5
		enemy xFieldRat,  6
		enemy xFieldRat,  6
	end
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
