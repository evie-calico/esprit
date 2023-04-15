include "assets/levels/level.inc"

section "Field Dungeon", romx
	; this dungeon should range from levels 3-6 with 7 floors

	dungeon xFieldDungeon
		tileset "res/dungeons/field_tiles.2bpp"
		after_floor 2, scene, xFieldScene1
		shape HALLS
		music xFieldMusic

		items_per_floor 4
		item xGrapes
		item xPepper
		item xAloe
		item xWaterMelon

		enemy xForestRat, 4
		enemy xForestRat, 5
		enemy xForestRat, 6
		enemy xSnake,     3
		enemy xSnake,     4
		enemy xFieldRat,  3
		enemy xFieldRat,  4
		enemy xFieldRat,  5
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

	next_part
		after_floor 4, switch
		; Start giving heatstroke now
		on_tick xFieldsGiveHeatstroke
		shape HALLS_OR_CLEARING

		items_per_floor 3
		item xWaterMelon
		item xPepper
		item xAloe
		item xGrapes

		enemy xAlligator, 3
		enemy xForestRat, 5
		enemy xForestRat, 6
		enemy xSnake,     3
		enemy xSnake,     4
		enemy xFieldRat,  3
		enemy xFieldRat,  4
		enemy xFieldRat,  5
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

	next_part
		after_floor 7, exit, FLAG_FIELDS_COMPLETE
		; Continue giving heatstroke
		on_tick xFieldsGiveHeatstroke.harsh

		items_per_floor 2
		item xWaterMelon
		item xPepper
		item xGrapes
		item xAloe

		; These enemies are the toughest in the dungeon :)
		enemy xAlligator, 4
		enemy xAlligator, 6
		enemy xSnake,     3
		enemy xSnake,     4
		enemy xSnake,     5
		enemy xFieldRat,  4
		enemy xFieldRat,  5
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

xFieldsGiveHeatstroke:
	ld a, [wFadeSteps]
	and a, a
	jr nz, :+
	ld a, [wShownFieldsMessage]
	and a, a
	jr nz, :+
	ld b, bank(.message)
	ld hl, .message
	call PrintHUD
	ld a, 1
	ld [wShownFieldsMessage], a
:
	ld a, [wLastTurnNumber]
	ld b, a
	ld a, [wTurnCounter]
	cp a, b
	ret z
	ld [wLastTurnNumber], a	

	call Rand
.hook
	res 7, a ; make heatstroke more likely
	res 7, e
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

.message
	db "The sun is beating down. It's starting to get hot.", 0

.harsh:
	ld a, [wLastTurnNumber]
	ld b, a
	ld a, [wTurnCounter]
	cp a, b
	ret z
	ld [wLastTurnNumber], a	

	call Rand
	res 6, a ; make heatstroke even more likely
	res 6, e
	jr .hook


section fragment "dungeon BSS", wram0
wLastTurnNumber: db
wShownFieldsMessage: db
