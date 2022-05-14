INCLUDE "defines.inc"
INCLUDE "menu.inc"

SECTION "Paw Theme", ROM0
PawprintMenuTheme::
	dw ExplorerMenuTheme
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

SECTION "Explorer Theme", ROM0
ExplorerMenuTheme:
	dw HeartMenuTheme
	INCBIN "res/ui/explorer_cursor.2bpp"
	dw .end - .emblem
	dw .emblem
	dw .map
	db "Explorer", 0
.emblem
	INCBIN "res/ui/explorer_emblem.2bpp"
.end
.map
	INCBIN "res/ui/explorer_emblem.map"

SECTION "Heart Theme", ROM0
HeartMenuTheme:
	dw PawprintMenuTheme
	INCBIN "res/ui/heart_cursor.2bpp"
	dw .end - .emblem
	dw .emblem
	dw .map
	db "Hearts", 0
.emblem
	INCBIN "res/ui/heart_emblem.2bpp"
.end
.map
	INCBIN "res/ui/heart_emblem.map"

SECTION "Pink Theme", ROM0
PinkMenuPalette::
	dw RedMenuPalette
	rgb_lim 31, 20, 31
	rgb_lim 31, 3, 31
	rgb_lim 16, 0, 16
	rgb 0, 0, 0
	db "Pink", 0

SECTION "Red Theme", ROM0
RedMenuPalette:
	dw OrangeMenuPalette
	rgb_lim 31, 20, 20
	rgb_lim 31, 3, 3
	rgb_lim 16, 0, 0
	rgb 0, 0, 0
	db "Red", 0

SECTION "Orange Theme", ROM0
OrangeMenuPalette:
	dw YellowMenuPalette
	rgb 255, 238, 204
	rgb 230, 153, 16
	rgb 150, 102, 0
	rgb 0, 0, 0
	db "Orange", 0

SECTION "Yellow Theme", ROM0
YellowMenuPalette::
	dw GreenMenuPalette
	rgb_lim 31, 31, 20
	rgb_lim 31, 31, 3
	rgb_lim 16, 16, 0
	rgb 0, 0, 0
	db "Yellow", 0

SECTION "Green Theme", ROM0
GreenMenuPalette:
	dw BlueMenuPalette
	rgb_lim 20, 31, 20
	rgb_lim 3, 31, 3
	rgb_lim 0, 16, 0
	rgb 0, 0, 0
	db "Green", 0

SECTION "Blue Theme", ROM0
BlueMenuPalette:
	dw BlackMenuPalette
	rgb_lim 20, 20, 31
	rgb_lim 3, 3, 31
	rgb_lim 0, 0, 16
	rgb 0, 0, 0
	db "Blue", 0

SECTION "Black Theme", ROM0
BlackMenuPalette:
	dw PinkMenuPalette
	rgb 0, 0, 0
	rgb_lim 8, 8, 8
	rgb_lim 16, 16, 16
	rgb_lim 31, 31, 31
	db "Black", 0

SECTION "Active Theme", WRAM0
wActiveMenuPalette:: dw
wActiveMenuTheme:: dw
