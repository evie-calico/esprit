include "defines.inc"
include "item.inc"

macro item ; label, name, description, graphics
section "\2 Item", romx
\2::
	dw .palette
	dw .gfx
	dw .name
	dw .description
	db ITEM_\1
	assert sizeof_Item == 9
	for i, 6, _NARG + 1
		db \<i>
	endr
.name:: db \3, 0
.description:: db \4, 0
.gfx:: incbin \5
endm

	item HEAL, xRedApple, "Apple", "A small red fruit. Eat it to restore 20 health.", "res/items/apple.2bpp", 20
	.palette 
		rgb 255,   0,   0
		rgb 128,   0,   0
		rgb  64,   0,   0

	item HEAL, xGreenApple, "Apple", "A small green fruit. Eat it to restore 24 health.", "res/items/apple.2bpp", 24
	.palette 
		rgb  80, 255,   0
		rgb  40, 128,   0
		rgb   0,  64,   0

	item HEAL, xGrapes, "Grapes", "A bunch of ripened grapes. Eat them to restore 40 health.", "res/items/grapes.2bpp", 40
	.palette
		rgb 255,   0, 255
		rgb 128,   0, 128
		rgb  64,   0,  64

	item FATIGUE_HEAL, xPepper, "Pepper", "A spicy little pepper! Makes you feel less tired and heals 20 HP.", "res/items/pepper.2bpp", 20
	.palette
		rgb 250, 173,  36
		rgb 128,  64,  64
		rgb  64,  32,  32

	item NULL, xScarf, "Scarf", "A fasionable scarf. You can wear it around your neck!", "res/items/scarf.2bpp"
	.palette
		rgb 120, 120, 255
		rgb  64,  64, 196
		rgb   0,   0,  80

	item REVIVE, xReviverSeed, "Reviver Seed", "Eating it will heal you fully the next time you are fatally wounded.", "res/items/reviver_seed.2bpp"
	.palette incbin "res/items/reviver_seed.pal8", 3
