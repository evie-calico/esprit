INCLUDE "entity.inc"

SECTION "Luvui data", ROMX
xLuvui::
	dw .graphics
	dw .palette
	dw .name
.graphics INCBIN "res/sprites/luvui.2bpp"
.palette
	db $FF, $FF, $A0
	db $20, $90, $30
	db $00, $20, $00
.name db "Luvui", 0
