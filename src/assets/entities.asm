INCLUDE "defines.inc"
INCLUDE "entity.inc"

MACRO entity ; name, graphic
	SECTION "\1 entity", ROMX
	x\1:: dw .gfx, .palette, .name, .moveTable
	.gfx INCBIN \2
	.name db "\1", 0
ENDM

MACRO level
	db \1, BANK(\2)
	dw \2
ENDM

	entity Luvui, "res/sprites/luvui.2bpp"
	.palette
		db $FF, $FF, $A0
		db $20, $90, $30
		db $00, $20, $00
	.moveTable
		level 1, xScratch
		level 6, xBite
		level 7, xPounce
		db 0

	entity Aris, "res/sprites/aris.2bpp"
	.palette
		rgb 255, 255, 128
		rgb 32, 32, 176
		rgb 0, 0, 32
	.moveTable
		level 1, xScratch
		level 5, xBite
		level 7, xPounce
		db 0

	entity Rat, "res/sprites/rat.2bpp"
	.palette
		rgb 144, 200, 112
		rgb 80, 48, 16
		rgb 16, 24, 0
	.moveTable
		level 1, xNibble
		db 0
