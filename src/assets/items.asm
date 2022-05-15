INCLUDE "item.inc"

MACRO item ; Name, Graphics, Type
SECTION "\1 Item", ROMX
x\1::
	dw .name
	dw .gfx
	db ITEM_NULL
.name db "\1", 0
.gfx INCBIN \2
ENDM

MACRO heal
SECTION "\1 Item", ROMX
x\1::
	dw .name
	dw .gfx
	db ITEM_HEAL
	db \3
.name db "\1", 0
.gfx INCBIN \2
ENDM

	heal Apple, "res/items/apple.2bpp", 10
	heal Grapes, "res/items/grapes.2bpp", 20
	item Pepper, "res/items/pepper.2bpp"
	item Scarf, "res/items/scarf.2bpp"
