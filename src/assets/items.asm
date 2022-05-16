INCLUDE "defines.inc"
INCLUDE "item.inc"

MACRO item ; Name, Graphics, Type
SECTION "\1 Item", ROMX
x\1::
	dw .palette
	dw .gfx
	dw .name
	db ITEM_NULL
	ASSERT sizeof_Item == 7
.name:: db "\1", 0
.gfx:: INCBIN \2
ENDM

MACRO heal
SECTION "\1 Item", ROMX
x\1::
	dw .palette
	dw .gfx
	dw .name
	db ITEM_HEAL
	ASSERT sizeof_Item == 7
	db \3
	ASSERT sizeof_HealItem == 8
.name:: db "\1", 0
.gfx:: INCBIN \2
ENDM

	heal Apple, "res/items/apple.2bpp", 10
	.palette 
		rgb 255,   0,   0
		rgb 128,   0,   0
		rgb  64,   0,   0

	heal Grapes, "res/items/grapes.2bpp", 20
	.palette
		rgb 255,   0, 255
		rgb 128,   0, 128
		rgb  64,   0,  64

	item Pepper, "res/items/pepper.2bpp"
	.palette
		rgb 250, 173,  36
		rgb 128,  64,  64
		rgb  64,  32,  32

	item Scarf, "res/items/scarf.2bpp"
	.palette
		rgb 255, 255, 120
		rgb   0,   0, 128
		rgb   0,   0,  64
