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

	item NULL, xDummyItem, "Dummy", "You should not be reading this.", "res/items/dummy.2bpp"
	.palette incbin "res/items/dummy.pal8", 3

	item NULL, xFabricShred, "Fabric Shred", "You could probably make something with this.", "res/items/fabric_shred.2bpp"
	.palette incbin "res/items/fabric_shred.pal8", 3

	item HEAL, xApple, "Apple", "A small round fruit. Eat it to restore 20 HP.", "res/items/apple.2bpp", 20
	.palette 
		rgb 255,   0,   0
		rgb 128,   0,   0
		rgb  64,   0,   0

	item HEAL, xPear, "Pear", "An oddly shaped fruit. Eat it to restore 24 HP.", "res/items/pear.2bpp", 24
	.palette incbin "res/items/pear.pal8", 3

	item HEAL, xPearOnAStick, "Pear on a stick", "Somehow this makes eating it more fun. Eat it to restore 30 HP.", "res/items/pear_on_a_stick.2bpp", 30
	.palette incbin "res/items/pear_on_a_stick.pal8", 3

	item HEAL, xGrapes, "Grapes", "A bunch of ripened grapes. Eat them to restore 40 HP.", "res/items/grapes.2bpp", 40
	.palette
		rgb 255,   0, 255
		rgb 128,   0, 128
		rgb  64,   0,  64

	item FATIGUE_HEAL, xPepper, "Pepper", "A spicy little pepper! Makes you feel less tired and heals 16 HP.", "res/items/pepper.2bpp", 50, 16
	.palette
		rgb 250, 173,  36
		rgb 128,  64,  64
		rgb  64,  32,  32

	item NULL, xScarf, "Scarf", "A fasionable scarf. You can wear it around your neck!", "res/items/scarf.2bpp"
	.palette
		rgb 120, 120, 255
		rgb  64,  64, 196
		rgb   0,   0,  80

	item NULL, xTwig, "Twig", "Just a flimsy, broken tree branch. You can't use this...", "res/items/twig.2bpp"
	.palette incbin "res/items/twig.pal8", 3

	item REVIVE, xReviverSeed, "Reviver Seed", "Eating it will fully heal you the next time you are fatally wounded.", "res/items/reviver_seed.2bpp"
	.palette incbin "res/items/reviver_seed.pal8", 3

	item POISON_CURE, xAloe, "Aloe", "It's slimy... Eating it cures Poison.", "res/items/aloe.2bpp", 0
	.palette incbin "res/items/aloe.pal8", 3

	item POISON_CURE, xSlimyApple, "Slimy Apple", "Someone smushed Aloe all over this. Cures Poison and restores 20 HP.", "res/items/slimy_apple.2bpp", 20
	.palette incbin "res/items/slimy_apple.pal8", 3

	item BLINK_TEAM, xBlinkfruit, "Blinkfruit", "Eating it will randomly warp your party after a few turns.", "res/items/blinkfruit.2bpp", 2
	.palette incbin "res/items/blinkfruit.pal8", 3

	item PURE_BLINK_TEAM, xPurefruit, "Purefruit", "Eating it will warp your party to the exit after a few turns.", "res/items/purefruit.2bpp", 2
	.palette incbin "res/items/purefruit.pal8", 3

	item HEAL_HEATSTROKE, xWaterMelon, "Water Melon", "It's literally filled with water. Heals 26 HP and cools you down.", "res/items/watermelon.2bpp", 26
	.palette incbin "res/items/watermelon.pal8", 3

	item HEAL_HEATSTROKE, xIceCream, "Ice Cream", "Strawberry and Vanilla~ Heals 50 HP and cools you down.", "res/items/ice_cream.2bpp", 50
	.palette incbin "res/items/ice_cream.pal8", 3

	item HEAL, xWaterChestnut, "WaterChestnut", "They're all wet and crunchy. Eating them restores 85 HP", "res/items/water_chestnut.2bpp", 85
	.palette incbin "res/items/water_chestnut.pal8", 3

	item POISON_CURE, xLily, "Lily", "Smells like fox. Cures poison and restores 60 HP.", "res/items/lily.2bpp", 60
	.palette incbin "res/items/lily.pal8", 3

	item FATIGUE_HEAL, xSuperPepper, "Super Pepper", "Even spicier! Makes you feel less tired and heals 60 HP.", "res/items/super_pepper.2bpp", 75, 60
	.palette incbin "res/items/super_pepper.pal8", 3
