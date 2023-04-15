include "defines.inc"
include "scene.inc"

	image xForestSceneBackground, "res/scenes/forest_scene_map"
	image xForestSceneBackground2, "res/scenes/forest_final_scene_map"
	image xVillageSceneBackground, "res/scenes/village_scene_map"
	image xBarrelSceneBackground, "res/scenes/barrel_scene_map"
	image xTreeSceneBackground, "res/scenes/tree_scene_map"
	image xFieldSceneBackground, "res/scenes/field_scene_map1"
	
	def random = $0

section "Forest Scene", romx
xForestScene::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitForestScene"
	begin_draw
	end_scene

section "Forest Scene 2", romx
xForestScene2::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitForestScene2"
	begin_draw
	end_scene

section "Field Scene 1", romx
xFieldScene1::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitFieldScene1"
	begin_draw
	end_scene
