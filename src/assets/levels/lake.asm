include "assets/levels/level.inc"

section "Lake Dungeon", romx
	; this dungeon should range from levels 5-8 with 7 floors

	dungeon xLakeDungeon
		tileset "res/dungeons/lake_tiles.2bpp"
		after_floor 2, scene, xLakeScene2
		shape HALLS
		music xLakeMusic
		on_tick xLakeAnimationFunction.noStars

		items_per_floor 2
		item xWaterChestnut
		item xLily
		item xBlinkfruit
		item xPurefruit

		enemy xFieldRat,  5
		enemy xFieldRat,  5
		enemy xFieldRat,  6
		enemy xPlatypus,  5
		enemy xPlatypus,  5
		enemy xPlatypus,  5
		enemy xAlligator, 6
		enemy xAlligator, 6
	end
	; maybe the first two floors could be brighter (sunset)
	dungeon_palette $9b, $82, $96, \ ; Blank
	                112, 96, 136, \
	                $5e, $4a, $73, \
	                24, 32, $72, \
	                216, 136, 88, \
	                $3e, $4a, $83, \
	                24, 32, $72, \
	                $63, $7f, $b7, \
	                64, 160, 80, \
	                24, $72, 32, \

	next_part
		tileset "res/dungeons/bridge_lake_tiles.2bpp"
		use_floor_color_for_terminals
		after_floor 4, switch
		shape BRIDGE
		on_tick xLakeAnimationFunction.stars

		items_per_floor 2
		item xWaterChestnut
		item xSuperPepper
		item xBlinkfruit
		item xPurefruit

		enemy xFirefly,   5
		enemy xFirefly,   6
		enemy xPlatypus,  5
		enemy xPlatypus,  6
		enemy xPlatypus,  7
		enemy xAlligator, 7
		enemy xAlligator, 7
		enemy xAlligator, 8
	end
	dungeon_palette $BA, $69, $53, \ ; Blank
	                $9C, $4b, $34, \
	                $3d, $13, $19, \
	                24, 32, $72, \
	                216, 136, 88, \
	                $3e, $4a, $83, \
	                24, 32, $72, \
	                $9C, $4b, $34, \
	                $3d, $13, $19, \
	                192, 255, 255, \

	next_part
		tileset "res/dungeons/lake_tiles.2bpp"
		after_floor 7, exit, FLAG_LAKE_COMPLETE
		shape HALLS
		on_tick xLakeAnimationFunction.stars

		items_per_floor 2
		item xLily
		item xSuperPepper
		item xBlinkfruit
		item xFabricShred

		enemy xFirefly,   5
		enemy xPlatypus,  5
		enemy xPlatypus,  6
		enemy xPlatypus,  7
		enemy xAlligator, 6
		enemy xAlligator, 7
		enemy xAlligator, 7
		enemy xAlligator, 8
	end
	dungeon_palette $Bb, $82, $a6, \ ; Blank
	                144, 96, 152, \
	                $7e, $4a, $83, \
	                24, 32, $72, \
	                216, 136, 88, \
	                $3e, $4a, $83, \
	                24, 32, $72, \
	                $63, $7f, $b7, \
	                64, 160, 80, \
	                24, $72, 32, \

; Placing this after the dungeon ensures it's in the same bank.
; Animates the stars in the reflection of the water
xLakeAnimationFunction:
.stars
	ld de, xLakeAnimationFrames / 4
	jr .hook
.noStars
	ld de, xLakeAnimationFrames.noStars / 4
.hook
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
	add a, e
	ld l, a
	adc a, d
	sub a, l
	ld h, a
	add hl, hl
	add hl, hl

	ld de, $88C0 ; Address of full-wall tile
	ld c, 16 * 4
	jp VramCopySmall

ALIGN 2
xLakeAnimationFrames: incbin "res/dungeons/lake_animation.2bpp"
.noStars incbin "res/dungeons/starless_lake_animation.2bpp"

section FRAGMENT "dungeon BSS", wram0
wLakeAnimationCounter: db
