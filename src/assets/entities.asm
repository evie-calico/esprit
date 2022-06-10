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
