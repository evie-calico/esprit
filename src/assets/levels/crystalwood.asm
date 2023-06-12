include "assets/levels/level.inc"

section "Crystalwood Dungeon", romx
	dungeon xCrystalwoodDungeon
		tileset "res/dungeons/gemtree_tiles.2bpp"
		after_floor 5, exit, FLAG_GEMTREE_COMPLETE
		shape HALLS
		music xCrystalwoodMusic

		items_per_floor 1
		item xApple
		item xPear
		item xGrapes
		item xPepper

		enemy xFieldRat,  2
		enemy xForestRat, 3
		enemy xForestRat, 3
		enemy xFirefly,   3
		enemy xFirefly,   4
		enemy xFieldRat,  5
		enemy xFieldRat,  6
		enemy xFieldRat,  6
	end
	dungeon_palette 248, 136, 112, \ ; Blank
	                176,  32,  64,  \ ; Ground
	                  0, 120,   0, \ 
	                  0,  32,   0, \
	                192,  72, 112, \ ; Wall
	                128,   0,  64, \
	                 32,   0,  32, \
	                  0,   0, 255, \ ; Exit
	                  0,   0, 128, \
	                  0,   0,  64, \
