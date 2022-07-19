INCLUDE "scene.inc"

	scene_background Grass, "res/scenes/grass_bkg.2bpp"
	scene_detail Bush, "res/scenes/bush_detail.2bpp", "res/scenes/bush_detail.map", 3, 2, SCENETILE_WALL

SECTION "Village Scene", ROMX
xVillageScene::
	scene
		DEF random = $EA751B27
	begin_draw
		load_background_palette GrassGreen, "res/scenes/grass_bkg.pal8"
		load_tiles Grass, GrassGreen
		load_tiles Bush, GrassGreen

		draw_bkg Grass
		scatter_details_row 0, 3, SCENE_WIDTH - 3, 6, 4, 8, Bush
		scatter_details_row 0, 10, SCENE_WIDTH - 3, 13, 4, 8, Bush
	end_scene
