include "defines.inc"
include "item.inc"

macro item ; Type, Label, name, description, graphics, [dstructs]
section "\2 Item", romx
	def ENUM_TYPE equs "ItemType_\1"
\2::
	dw .palette
	dw .gfx
	dw .name
	dw .description
	db {ENUM_TYPE}
	assert sizeof_Item == 9
	SHIFT 5
	dstruct {ENUM_TYPE}, .type, \#
	SHIFT -5
.name:: db \3, 0
.description:: db \4, 0
.gfx:: incbin \5
	purge ENUM_TYPE
endm

	item Null, xDummyItem, "Dummy", "You should not be reading this.", "res/items/dummy.2bpp"
	.palette incbin "res/items/dummy.pal8", 3

	item Null, xFabricShred, "Fabric Shred", "You could probably make something with this.", "res/items/fabric_shred.2bpp"
	.palette incbin "res/items/fabric_shred.pal8", 3

	item Heal, xApple, "Apple", "A small round fruit. Eat it to restore 20 HP.", "res/items/apple.2bpp", \
		.Health=20
	.palette 
		rgb 255,   0,   0
		rgb 128,   0,   0
		rgb  64,   0,   0

	item Heal, xPear, "Pear", "An oddly shaped fruit. Eat it to restore 24 HP.", "res/items/pear.2bpp", \
		.Health=24
	.palette incbin "res/items/pear.pal8", 3

	item Heal, xPearOnAStick, "Pear on a stick", "Somehow this makes eating it more fun. Eat it to restore 30 HP.", "res/items/pear_on_a_stick.2bpp", \
		.Health=30
	.palette incbin "res/items/pear_on_a_stick.pal8", 3

	item Heal, xGrapes, "Grapes", "A bunch of ripened grapes. Eat them to restore 40 HP.", "res/items/grapes.2bpp", \
		.Health=40
	.palette
		rgb 255,   0, 255
		rgb 128,   0, 128
		rgb  64,   0,  64

	item FatigueHeal, xPepper, "Pepper", "A spicy little pepper! Makes you feel less tired and heals 16 HP.", "res/items/pepper.2bpp", \
		.Fatigue=50, \
		.Health=16
	.palette
		rgb 250, 173,  36
		rgb 128,  64,  64
		rgb  64,  32,  32

	item Null, xScarf, "Scarf", "A fasionable scarf. You can wear it around your neck!", "res/items/scarf.2bpp"
	.palette
		rgb 120, 120, 255
		rgb  64,  64, 196
		rgb   0,   0,  80

	item Null, xTwig, "Twig", "Just a flimsy, broken tree branch. You can't use this...", "res/items/twig.2bpp"
	.palette incbin "res/items/twig.pal8", 3

	item Revive, xReviverSeed, "Reviver Seed", "Eating it will fully heal you the next time you are fatally wounded.", "res/items/reviver_seed.2bpp"
	.palette incbin "res/items/reviver_seed.pal8", 3

	item PoisonCure, xAloe, "Aloe", "It's slimy... Eating it cures Poison.", "res/items/aloe.2bpp", \
		.Health=0
	.palette incbin "res/items/aloe.pal8", 3

	item PoisonCure, xSlimyApple, "Slimy Apple", "Someone smushed Aloe all over this. Cures Poison and restores 20 HP.", "res/items/slimy_apple.2bpp", \
		.Health=20
	.palette incbin "res/items/slimy_apple.pal8", 3

	item BlinkTeam, xBlinkfruit, "Blinkfruit", "Eating it will randomly warp your party after a few turns.", "res/items/blinkfruit.2bpp", \
		.Delay=2
	.palette incbin "res/items/blinkfruit.pal8", 3

	item PureBlinkTeam, xPurefruit, "Purefruit", "Eating it will warp your party to the exit after a few turns.", "res/items/purefruit.2bpp", \
		.Delay=2
	.palette incbin "res/items/purefruit.pal8", 3

	item HealHeatstroke, xWaterMelon, "Water Melon", "It's literally filled with water. Heals 26 HP and cools you down.", "res/items/watermelon.2bpp", \
		.Health=26
	.palette incbin "res/items/watermelon.pal8", 3

	item HealHeatstroke, xIceCream, "Ice Cream", "Strawberry and Vanilla~ Heals 50 HP and cools you down.", "res/items/ice_cream.2bpp", \
		.Health=50
	.palette incbin "res/items/ice_cream.pal8", 3

	item Heal, xWaterChestnut, "Water Nut", "They're all wet and crunchy. Eating them restores 85 HP", "res/items/water_chestnut.2bpp", \
		.Health=85
	.palette incbin "res/items/water_chestnut.pal8", 3

	item PoisonCure, xLily, "Lily", "Smells like fox. Cures poison and restores 60 HP.", "res/items/lily.2bpp", \
		.Health=60
	.palette incbin "res/items/lily.pal8", 3

	item FatigueHeal, xSuperPepper, "Super Pepper", "Even spicier! Makes you feel less tired and heals 60 HP.", "res/items/super_pepper.2bpp", \
		.Fatigue=75, \
		.Health=60
	.palette incbin "res/items/super_pepper.pal8", 3
