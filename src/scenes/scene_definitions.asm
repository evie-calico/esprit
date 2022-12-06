include "defines.inc"
include "scene.inc"

	scene_background Grass, "res/scenes/grass_bkg.2bpp"
	scene_detail Bush, "res/scenes/bush_detail.2bpp", "res/scenes/bush_detail.map", 3, 2, SCENETILE_WALL
	scene_detail RedTent, "res/scenes/tent.2bpp", "res/scenes/tent.map", 3, 2, SCENETILE_WALL
	scene_detail BlueTent, "res/scenes/tent2.2bpp", "res/scenes/tent2.map", 3, 2, SCENETILE_WALL

section "Village Scene", romx
xVillageScene::
	scene
		def random = $e0c8a0b6
	begin_draw
		load_background_palette GrassGreen, "res/scenes/bush_detail.pal8"
		load_background_palette RedTentPal, "res/scenes/tent.pal8"
		load_background_palette BlueTentPal, "res/scenes/tent2.pal8"
		load_tiles Grass, GrassGreen
		load_tiles Bush, GrassGreen
		load_tiles RedTent, RedTentPal
		load_tiles BlueTent, BlueTentPal

		draw_bkg Grass
		scatter_details_row 0, 0, SCENE_WIDTH - 3, 2, 3, 3, Bush
		scatter_details_row 0, 11, SCENE_WIDTH - 3, 13, 3, 3, Bush
		place_detail RedTent, 13, 9
		place_detail BlueTent, 9, 7

		npc xPlatypus, 64.0, 64.0, RIGHT, null, xWalkAround
	end_scene
