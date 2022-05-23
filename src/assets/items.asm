INCLUDE "defines.inc"
INCLUDE "item.inc"

MACRO item ; Name, Description, Graphics
SECTION "\1 Item", ROMX
x\1::
	dw .palette
	dw .gfx
	dw .name
	dw .description
	db ITEM_NULL
	ASSERT sizeof_Item == 9
.name:: db "\1", 0
.description:: db \2, 0
.gfx:: INCBIN \3
ENDM

MACRO heal ; name, description, graphics, strength
SECTION "\1 Item", ROMX
x\1::
	dw .palette
	dw .gfx
	dw .name
	dw .description
	db ITEM_HEAL
	ASSERT sizeof_Item == 9
	db \4
	ASSERT sizeof_HealItem == 10
.name:: db "\1", 0
.description:: db \2, 0
.gfx:: INCBIN \3
ENDM

	heal Apple, "A small red fruit. Eat it to restore your health.", "res/items/apple.2bpp", 10
	.palette 
		rgb 255,   0,   0
		rgb 128,   0,   0
		rgb  64,   0,   0

	heal Grapes, "A bunch of sweet, ripened grapes. Eat them to restore health.", "res/items/grapes.2bpp", 20
	.palette
		rgb 255,   0, 255
		rgb 128,   0, 128
		rgb  64,   0,  64

	item Pepper, "A spicy little pepper!", "res/items/pepper.2bpp"
	.palette
		rgb 250, 173,  36
		rgb 128,  64,  64
		rgb  64,  32,  32

	item Scarf, "A fasionable scarf. You can wear it around your neck!", "res/items/scarf.2bpp"
	.palette
		rgb 120, 120, 255
		rgb  64,  64, 196
		rgb   0,   0,  80
