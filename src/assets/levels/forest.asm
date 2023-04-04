include "assets/levels/level.inc"

section "Forest Dungeon", romx
	dungeon xForestDungeon
		tileset "res/dungeons/tree_tiles.2bpp"
		after_floor 2, switch
		shape HALLS
		music xForestMusic

		items_per_floor 2
		item xApple
		item xPear
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
		item xPear
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
		shape GROTTO
		music xForestNightMusic

		items_per_floor 1
		item xApple
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
		item xApple
		item xPear
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
