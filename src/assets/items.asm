INCLUDE "defines.inc"
INCLUDE "item.inc"

MACRO item ; label, name, description, graphics
SECTION "\1 Item", ROMX
\1::
	dw .palette
	dw .gfx
	dw .name
	dw .description
	db ITEM_NULL
	ASSERT sizeof_Item == 9
.name:: db \2, 0
.description:: db \3, 0
.gfx:: INCBIN \4
ENDM

MACRO heal ; label, name, description, graphics, strength
SECTION "\1 Item", ROMX
\1::
	dw .palette
	dw .gfx
	dw .name
	dw .description
	db ITEM_HEAL
	ASSERT sizeof_Item == 9
	db \5
	ASSERT sizeof_HealItem == 10
.name:: db \2, 0
.description:: db \3, 0
.gfx:: INCBIN \4
ENDM

	heal xRedApple, "Apple", "A small red fruit. Eat it to restore 20 health.", "res/items/apple.2bpp", 20
	.palette 
		rgb 255,   0,   0
		rgb 128,   0,   0
		rgb  64,   0,   0

	heal xGreenApple, "Apple", "A small green fruit. Eat it to restore 24 health.", "res/items/apple.2bpp", 24
	.palette 
		rgb  80, 255,   0
		rgb  40, 128,   0
		rgb   0,  64,   0

	heal xGrapes, "Grapes", "A bunch of ripened grapes. Eat them to restore 40 health.", "res/items/grapes.2bpp", 40
	.palette
		rgb 255,   0, 255
		rgb 128,   0, 128
		rgb  64,   0,  64

	item xPepper, "Pepper", "A spicy little pepper! It doesn't seem to do anything.", "res/items/pepper.2bpp"
	.palette
		rgb 250, 173,  36
		rgb 128,  64,  64
		rgb  64,  32,  32

	item xScarf, "Scarf", "A fasionable scarf. You can wear it around your neck!", "res/items/scarf.2bpp"
	.palette
		rgb 120, 120, 255
		rgb  64,  64, 196
		rgb   0,   0,  80
