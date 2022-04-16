INCLUDE "defines.inc"

SECTION "Theme List", ROM0
ThemeList::
	dw PinkMenuTheme
	dw 0

SECTION "Pink Theme", ROM0
PinkMenuTheme::
	rgb_lim 31, 20, 31
	rgb_lim 31, 3, 31
	rgb_lim 16, 0, 16
	rgb 0, 0, 0
	dw 0
	db "Pink", 0

SECTION "Active Theme", WRAM0
wActiveTheme:: dw
