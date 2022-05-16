INCLUDE "defines.inc"

DEF BLANK EQUS "rgb_lim $10, $1F, $12"

SECTION "Forest Dungeon", ROMX
xForestDungeon::
	dw .tileset
	dw .palette
	farptr xApple
	farptr xGrapes
	farptr xPepper
	farptr xScarf
.tileset INCBIN "res/tree_tiles.2bpp"
.palette
	; Ground
	BLANK
	rgb   0, 120,   0
	rgb   0, $58, $18
	rgb   0, $20,   0
	; Walls
	BLANK
	rgb_lim $12, $0D, $09
	rgb   0, $58, $18
	rgb   0, $20,  0
	; Exit
	BLANK
	rgb_lim $12, $0D, $09
	rgb   0, $58, $18
	rgb   0, $20,   0
	; Item0
	rgb 255,   0,   0
	rgb 128,   0,   0
	rgb  64,   0,   0
	; Item1
	rgb 255,   0, 255
	rgb 128,   0, 128
	rgb  64,   0,  64
	; Item2
	rgb 250, 173,  36
	rgb 128,  64,  64
	rgb  64,  32,  32
	; Item3
	rgb 255, 255, 120
	rgb   0,   0, 128
	rgb   0,   0,  64
