INCLUDE "defines.inc"

SECTION "Theme List", ROM0
ThemeList::
	dw PawprintMenuTheme
	dw 0
	DEF NB_MENU_THEMES EQU 1
	EXPORT NB_MENU_THEMES

SECTION "Paw Theme", ROM0
PawprintMenuTheme::
	INCBIN "res/ui/paw_cursor.2bpp"
	dw .end - .emblem
.emblem
	INCBIN "res/ui/paw_emblem.2bpp"
.end
	INCBIN "res/ui/paw_emblem.map"
	db "Pawprint", 0

SECTION "Palette List", ROM0
PaletteList::
	dw PinkMenuPalette
	dw 0
	DEF NB_MENU_PALS EQU 1
	EXPORT NB_MENU_PALS

SECTION "Pink Theme", ROM0
PinkMenuPalette::
	rgb_lim 31, 20, 31
	rgb_lim 31, 3, 31
	rgb_lim 16, 0, 16
	rgb 0, 0, 0
	db "Pink", 0

SECTION "Active Theme", WRAM0
wActiveMenuPalette:: dw
wActiveMenuTheme:: dw
