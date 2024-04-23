include "defines.inc"
include "scene.inc"

	image xForestSceneBackground, "res/scenes/forest_scene_map"
	image xForestSceneBackground2, "res/scenes/forest_final_scene_map"
	image xVillageSceneBackground, "res/scenes/village_scene_map"
	image xBarrelSceneBackground, "res/scenes/barrel_scene_map"
	image xTreeSceneBackground, "res/scenes/tree_scene_map"
	image xFieldSceneBackground, "res/scenes/field_scene_map1"
	image xFieldSceneBackground2, "res/scenes/field_scene_map2"
	image xRemoteHouseSceneBackground, "res/scenes/remote_house_scene_map"
	image xLakeSceneBeachBackground, "res/scenes/lake_scene_beachside"
	image xLakeSceneBridgeBackground, "res/scenes/lake_scene_bridge"
	image xLakeSceneLookoutBackground, "res/scenes/lake_scene_lookout"
	
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

section "Field Scene 2", romx
xFieldScene2::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitFieldScene2"
	begin_draw
	end_scene

section "Field Scene 3", romx
xFieldScene3::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitFieldScene3"
	begin_draw
	end_scene

section "Lake Scene 1", romx
xLakeScene1::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitLakeScene1"
	begin_draw
	end_scene

section "Lake Scene 2", romx
xLakeScene2::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitLakeScene2"
	begin_draw
	end_scene

section "Lake Scene 3", romx
xLakeScene3::
	scene
		redef SCENE_ENTRANCE_SCRIPT equs "xInitLakeScene3"
	begin_draw
	end_scene
