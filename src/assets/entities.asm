INCLUDE "entity.inc"

MACRO entity ; name, graphic
	SECTION "\1 entity", ROMX
	x\1:: dw .gfx, .palette, .name
	.gfx INCBIN \2
	.name db "\1", 0
ENDM

	entity Luvui, "res/sprites/luvui.2bpp"
	.palette
		db $FF, $FF, $A0
		db $20, $90, $30
		db $00, $20, $00
