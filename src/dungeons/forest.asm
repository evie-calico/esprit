INCLUDE "defines.inc"

SECTION "Forest Dungeon", ROMX
xForestDungeon::
	dw .tileset
	dw .palette
.tileset INCBIN "res/tree_tiles.2bpp"
.palette
	rgb_lim $10, $1F, $12
	;rgb_lim $18, $12, $0E
	;rgb_lim $00, $15, $06
	;rgb_lim $00, $04, $00
	;rgb $50, $C0, $60
	rgb_lim $12, $0D, $09
	rgb $00, $58, $18
	rgb $00, $20, $00
