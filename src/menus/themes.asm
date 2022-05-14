INCLUDE "defines.inc"
INCLUDE "menu.inc"

SECTION "Paw Theme", ROM0
PawprintMenuTheme::
	dw 0
	INCBIN "res/ui/paw_cursor.2bpp"
	dw .end - .emblem
	dw .emblem
	dw .map
	db "Pawprint", 0
.emblem
	INCBIN "res/ui/paw_emblem.2bpp"
.end
.map
	INCBIN "res/ui/paw_emblem.map"

SECTION "Pink Theme", ROM0
PinkMenuPalette::
	dw BlueMenuPalette
	rgb_lim 31, 20, 31
	rgb_lim 31, 3, 31
	rgb_lim 16, 0, 16
	rgb 0, 0, 0
	db "Pink", 0

SECTION "Blue Theme", ROM0
BlueMenuPalette::
	dw PinkMenuPalette
	rgb_lim 20, 20, 31
	rgb_lim 3, 3, 31
	rgb_lim 0, 0, 16
	rgb 0, 0, 0
	db "Blue", 0

SECTION "Active Theme", WRAM0
wActiveMenuPalette:: dw
wActiveMenuTheme:: dw
