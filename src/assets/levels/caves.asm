include "assets/levels/level.inc"

section "Caves Dungeon", romx
	dungeon xCavesDungeon
		tileset "res/dungeons/cave_tiles.2bpp"
		after_floor 5, exit, FLAG_CAVES_COMPLETE
		shape HALLS
		music xCaveMusic

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
	dungeon_hex 9191a9, \ ; Blank
	            555571, \ ; Ground
	            3d455a, \
	            07152f, \
	            555571, \ ; Ground
	            3d455a, \
	            07152f, \
	            555571, \ ; Wall
	            3d455a, \
	            07152f, \
	            555571, \ ; Exit
	            3d455a, \
	            07152f, \
