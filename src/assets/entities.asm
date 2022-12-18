include "defines.inc"
include "entity.inc"

macro entity ; label, name, graphic
	section "\1 entity", romx
	\1:: dw .gfx, .palette, .name, .moves
	.gfx incbin \3
	.name db \2, 0
endm

macro level
	db \1, bank(\2)
	dw \2
endm

	entity xLuvui, "Luvui", "res/sprites/luvui.2bpp"
	.palette
		rgb 255, 255, 160
		rgb 144, 32, 48
		rgb 32, 0, 0
	.moves
		level 1, xScratch
		level 6, xBite
		level 7, xPounce
		level 10, xHeal
		db 0

	entity xAris, "Aris", "res/sprites/aris.2bpp"
	.palette
		rgb 255, 255, 128
		rgb 32, 32, 176
		rgb 0, 0, 32
	.moves
		level 1, xScratch
		level 5, xBite
		level 7, xPounce
		db 0

	entity xForestRat, "Forest Rat", "res/sprites/rat.2bpp"
	.palette
		rgb 144, 200, 112
		rgb 48, 80, 16
		rgb 16, 24, 0
	.moves
		level 1, xNibble
		level 5, xScratch
		db 0

	entity xFieldRat, "Field Rat", "res/sprites/rat.2bpp"
	.palette
		rgb 120, 120, 80
		rgb 64, 64, 16
		rgb 16, 24, 0
	.moves
		level 1, xScratch
		level 5, xPounce
		db 0

	entity xPlatypus, "Platypus", "res/sprites/platypus.2bpp"
	.palette
		rgb 88, 216, 152
		rgb 96, 48, 16
		rgb 0, 16, 16
	.moves
		level 1, xNibble
		db 0

	entity xSnake, "Snake", "res/sprites/snake.2bpp"
	.palette
		hex ff8e00
		hex ac2c44
		hex 000000
	.moves
		level 1, xPoisonFangs
		db 0

	entity xFirefly, "Lampyr", "res/sprites/firefly.2bpp"
	.palette
		hex f58a9b
		hex fcef00
		hex 01133e
	.moves
		level 1, xHeal
		db 0
