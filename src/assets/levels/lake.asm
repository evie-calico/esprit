include "assets/levels/level.inc"

section "Lake Dungeon", romx
	dungeon xLakeDungeon
		tileset "res/dungeons/lake_tiles.2bpp"
		after_floor 2, switch
		shape HALLS
		music xLakeMusic
		on_tick xLakeAnimationFunction.noStars

		items_per_floor 2
		item xWaterChestnut
		item xBlinkfruit
		item xLily
		item xPurefruit

		enemy xFieldRat,  5
		enemy xFieldRat,  5
		enemy xFieldRat,  6
		enemy xPlatypus,  4
		enemy xPlatypus,  4
		enemy xPlatypus,  5
		enemy xAlligator, 6
		enemy xAlligator, 6
	end
	; maybe the first two floors could be brighter (sunset)
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

	next_part
		after_floor 4, switch ; scene??
		shape HALLS ; A new dungeon type would be cool. Maybe a big long river walk.
		on_tick xLakeAnimationFunction.stars

		items_per_floor 2
		item xPurefruit
		item xLily
		item xSuperPepper
		item xBlinkfruit

		enemy xFieldRat,  6
		enemy xFirefly,   4
		enemy xFirefly,   5
		enemy xPlatypus,  4
		enemy xPlatypus,  5
		enemy xAlligator, 6
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

	next_part
		after_floor 7, exit, FLAG_LAKE_COMPLETE
		shape HALLS ; river but in the other direction?
		on_tick xLakeAnimationFunction.stars

		items_per_floor 2
		item xBlinkfruit
		item xWaterChestnut
		item xLily
		item xFabricShred

		enemy xFirefly,   5
		enemy xFirefly,   6
		enemy xPlatypus,  5
		enemy xPlatypus,  6
		enemy xPlatypus,  7
		enemy xAlligator, 6
		enemy xAlligator, 7
		enemy xAlligator, 7
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
