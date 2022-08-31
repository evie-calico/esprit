INCLUDE "defines.inc"
INCLUDE "entity.inc"

MACRO entity ; label, name, graphic
	SECTION "\1 entity", ROMX
	\1:: dw .gfx, .palette, .name, .moveTable
	.gfx INCBIN \3
	.name db \2, 0
ENDM

MACRO level
	db \1, BANK(\2)
	dw \2
ENDM

	entity xLuvui, "Luvui", "res/sprites/luvui.2bpp"
	.palette
		rgb 255, 255, 160
		rgb 144, 32, 48
		rgb 32, 0, 0
	.moveTable
		level 1, xScratch
		level 1, xHeal
		level 6, xBite
		level 7, xPounce
		db 0

	entity xAris, "Aris", "res/sprites/aris.2bpp"
	.palette
		rgb 255, 255, 128
		rgb 32, 32, 176
		rgb 0, 0, 32
	.moveTable
		level 1, xScratch
		level 5, xBite
		level 7, xPounce
		db 0

	entity xForestRat, "Forest Rat", "res/sprites/rat.2bpp"
	.palette
		rgb 144, 200, 112
		rgb 48, 80, 16
		rgb 16, 24, 0
	.moveTable
		level 1, xNibble
		db 0

	entity xFieldRat, "Field Rat", "res/sprites/rat.2bpp"
	.palette
		rgb 120, 120, 80
		rgb 64, 64, 16
		rgb 16, 24, 0
	.moveTable
		level 1, xScratch
		level 6, xPounce
		db 0

	entity xPlatypus, "Platypus", "res/sprites/platypus.2bpp"
	.palette
		rgb 88, 216, 152
		rgb 96, 48, 16
		rgb 0, 16, 16
	.moveTable
		level 1, xNibble
		db 0
