include "assets/levels/level.inc"

section "Lake Dungeon", romx
	dungeon xLakeDungeon
		tileset "res/dungeons/lake_tiles.2bpp"
		after_floor 5, exit, FLAG_LAKE_COMPLETE
		shape HALLS
		music xLakeMusic
		on_tick xLakeAnimationFunction

		items_per_floor 1
		item xApple
		item xPear
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
