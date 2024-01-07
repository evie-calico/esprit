include "assets/levels/level.inc"

; TODO: unkillable dragon enemies that force you to move quickly through the dungeon.
; TODO: gold & gems that can be traded for hp & xp. only a certain amount of each per save file. rare and protected by the dragons 

section "Plains Dungeon", romx
	dungeon xPlainsDungeon
		tileset "res/dungeons/plains_tiles.2bpp"
		after_floor 5, exit, FLAG_PLAINS_COMPLETE
		use_floor_color_for_standalones
		on_tick xPlainsAnimationFunction
		shape HALLS
		music xFieldAltMusic

		items_per_floor 1
		item xApple
		item xPear
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
	dungeon_palette $ff, $d6, $87, \ ; Blank
	                $dd, $67, $19, \ ; Ground
	                $da, $23, $23, \
	                $24, $12, $08, \
	                $b4, $69, $37, \ ; Wall
	                $5e, $37, $27, \
	                  0,   8,   0, \
	                 96,  80,   0, \ ; Exit
	                 64,  48,   0, \
	                 32,  24,   0, \

xPlainsAnimationFunction:
	ldh a, [hFrameCounter]
	and a, 7
	ret nz
	ld a, [wPlainsAnimationCounter]
	inc a
	cp a, 4
	jr nz, :+
	xor a, a
:
	ld [wPlainsAnimationCounter], a

	add a, a ; a * 2 (8)
	add a, a ; a * 4 (16)
	add a, a ; a * 8 (32)
	add a, a ; a * 16 (64)
	add a, a ; a * 32 (128)
	add a, low(xPlainsAnimationFrames / 2)
	ld l, a
	adc a, high(xPlainsAnimationFrames / 2)
	sub a, l
	ld h, a
	add hl, hl

	ld de, $8840 ; Address of standalone tile
	ld c, 16 * 4
	jp VramCopySmall

ALIGN 1
xPlainsAnimationFrames: incbin "res/dungeons/fire_animation.2bpp"

section FRAGMENT "dungeon BSS", wram0
wPlainsAnimationCounter: db