include "defines.inc"
include "scene.inc"

	def_background Grass, "res/scenes/grass_bkg.2bpp"
	def_detail Bush, "res/scenes/bush_detail.2bpp", "res/scenes/bush_detail.map", 3, 2, SCENETILE_WALL
	def_detail RedTent, "res/scenes/tent.2bpp", "res/scenes/tent.map", 3, 2, SCENETILE_WALL
	def_detail BlueTent, "res/scenes/tent2.2bpp", "res/scenes/tent2.map", 3, 2, SCENETILE_WALL
	def_detail Barrel, "res/scenes/barrel.2bpp", "res/scenes/barrel.map", 5, 6, SCENETILE_WALL

section "VillageGrassPalette", romx
xVillageGrassPalette: incbin "res/scenes/bush_detail.pal8"

section "Village Scene", romx
xVillageScene::
	scene
		def random = $e0c8a0b6
		redef SCENE_ENTRANCE_SCRIPT equs "xInitVillage"
	begin_draw
		load_bgp GrassGreen, xVillageGrassPalette
		load_bgp RedTentPal, "res/scenes/tent.pal8"
		load_bgp BlueTentPal, "res/scenes/tent2.pal8"
		load_bgp BarrelPal, "res/scenes/barrel.pal8"
		load_tiles Grass, GrassGreen
		load_tiles Bush, GrassGreen
		load_tiles RedTent, RedTentPal
		load_tiles BlueTent, BlueTentPal
		load_tiles Barrel, BarrelPal

		draw_bkg Grass

		; Draw a line of bushes on the top of the town.
		for i, 4
			pd Bush, i * 3, 0
		endr
		pd Bush, 5, 2
		pd Bush, 8, 2
		pd Bush, 17, 0
		; Place the barrel in the upper right corner.
		pd Barrel, 12, 0

		; Draw a line of bushes on the bottom of the town.
		pd Bush, 0, 11
		pd Bush, 0, 13
		for i, 1, 5
			pd Bush, i * 3, 12
		endr
		pd Bush, 15, 11
		pd Bush, 15, 13
		pd Bush, 18, 10
		pd Bush, 18, 12

		pd RedTent, 9, 4
		pd BlueTent, 6, 10

		; TODO: actually load the NPC palette
		npc xPlatypus, 72.0, 76.0, LEFT, null, xWalkAround
	end_scene

	def_image ForestImage, "res/scenes/forest_scene_map.2bpp", "res/scenes/forest_scene_map.map", "res/scenes/forest_scene_map.pal8", "res/scenes/forest_scene_map.pmap", 20, 12

section "Forest Scene", romx
xForestScene::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitForestScene"
	begin_draw
		load_image_bgp ForestImage
		load_tiles_no_color ForestImage

		pi ForestImage, 0, 2
	end_scene
