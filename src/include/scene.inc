IF !DEF(SCENE_INC)
DEF SCENE_INC EQU 1

INCLUDE "structs.inc"

RSRESET
DEF DRAWSCENE_END RB         ; End drawing.
DEF DRAWSCENE_VRAMCOPY RB    ; Copy data to VRAM
DEF DRAWSCENE_BKG RB         ; Fill in an area of the map with three ground tiles.
DEF DRAWSCENE_PLACEDETAIL RB ; Place a small tilemap somewhere on the map.
DEF DRAWSCENE_SPAWNEFFECT RB ; Allocate space for a script-controlled effect and assign it a position.
DEF DRAWSCENE_FILL RB        ; Fill an area of the scene
DEF DRAWSCENE_SETDOOR RB     ; Define a door pointing to another scene.
DEF DRAWSCENE_MEMCOPY RB     ; Copy data
DEF DRAWSCENE_SETCOLOR RB    ; Assign an attribute to a tile id

RSRESET
DEF SCENETILE_CLEAR RB
DEF SCENETILE_WALL RB
DEF SCENETILE_EXIT_DOWN RB
DEF SCENETILE_EXIT_LEFT RB
DEF SCENETILE_EXIT_UP RB
DEF SCENETILE_EXIT_RIGHT RB
DEF SCENETILE_DOOR0 RB
DEF SCENETILE_DOOR1 RB
DEF SCENETILE_DOOR2 RB
DEF SCENETILE_DOOR3 RB
DEF SCENETILE_DOOR4 RB
DEF SCENETILE_DOOR5 RB
DEF SCENETILE_DOOR6 RB
DEF SCENETILE_DOOR7 RB

DEF SCENE_WIDTH EQU 64
DEF SCENE_HEIGHT EQU 32

	struct Scene
		words 8, Entrances
		bytes 1, Width
		bytes 1, Height
		longs 1, Seed
		bytes 3, IntroScript
		bytes 0, DrawInfo
	end_struct

; A scene is map up of two maps; one for collision and one for tiles.
; In addition, a table of attributes is used to provide colors for tiles as they
; are loaded. This means that a single ID may only have one attribute, which
; prevents flipping, the second VRAM bank, or re-using a tile with multiple colors.
; This system is used to simplify map design by circumventing the need for
; metatiles.

; Objects are collections of constants used in drawing a map. This allows tiles
; to be seamlessly loaded and passed around without any definitions needed from
; the user. Each object flags itself using a type, and then defines various
; constants describing how they behave.

; A background object consists of 4 tiles which are used to fill in a region of
; the map.
MACRO scene_background
	DEF \1_BACKGROUND EQU 1
	DEF \1_SIZE EQU 4
	PUSHS
	SECTION "\1 tiledata", ROMX
	\1_data:
		INCBIN \2
	.end
	POPS
ENDM

; A detail is like a small tilemap which can be stamped anywhere in the scene.
MACRO scene_detail
	DEF \1_DETAIL EQU 1
	DEF \1_SIZE EQU \4 * \5
	DEF \1_WIDTH EQU \4
	DEF \1_HEIGHT EQU \5
	DEF \1_COLLISION EQU \6
	PUSHS
	SECTION "\1 tiledata", ROMX
	\1_map:
		INCBIN \3
	\1_data:
		INCBIN \2
	.end
	POPS
ENDM

; Define a new scene, including certain configurations.
MACRO scene ; (entrance x/y) * 4, width, height, seed, initial script
	DEF TILE_ID = $80
	DEF BG_COLOR_ID = 0
	DEF OB_COLOR_ID = 0
	; Begin with an array of 4 positions, corresponding to each direction
	REPT 4
		dw (\2) * 8 << 4, (\1) * 8 << 4
		SHIFT 2
	ENDR
	ASSERT \1 <= 512 && \2 <= 256, "Scenes are limited to a 512x256 area"
	db ((\1) - SCRN_X) / 16, ((\2) - SCRN_Y + 32) / 16 ; width/height divided by 16
	SHIFT 2
	; The seed ensures maps always appear the same.
	; You can generate 4 bytes for a seed here:
	; https://www.random.org/bytes/
	dl \1
	DEF random = \1 ; Also use this for the buildtime PRNG.
	SHIFT 1
	db BANK(\1)
	dw \1
.drawInfo
	; The drawing information imediately follows.
ENDM

DEF end_scene EQUS "db DRAWSCENE_END"

; PRNG for generating natrual-looking maps at buildtime.
; Thanks Rangi
MACRO next_random ; xorshift32
  DEF random ^= random << 13
  DEF random ^= random >> 17
  DEF random ^= random << 5
ENDM

MACRO load_tiles
	db DRAWSCENE_VRAMCOPY
	dw $8000 + TILE_ID * 16 ; Destination
	dw \1_SIZE * 16 ; length
	db BANK(\1_data) ; bank
	dw \1_data ; source

	db DRAWSCENE_SETCOLOR
	db TILE_ID
	db \2_PAL_ID
	db \1_SIZE

	DEF \1_ID = TILE_ID
	DEF TILE_ID += \1_SIZE
ENDM

MACRO load_objects
	; Make sure that objects' tiles are properly aligned.
	IF TILE_ID % 2
		DEF TILE_ID += 1
	ENDC

	db DRAWSCENE_VRAMCOPY
	dw $8000 + TILE_ID * 16
	dw \1_SIZE * 16 ; length
	db BANK(\1_data) ; bank
	dw \1_data ; source

	ASSERT \1_SIZE % 2 == 0, "Objects must be a multiple of 2 tiles in 8x16 mode."
	DEF \1_ID = TILE_ID
	DEF TILE_ID += \1_SIZE
ENDM

MACRO load_background_palette
	db DRAWSCENE_MEMCOPY
	dw wBGPaletteBuffer + BG_COLOR_ID * 3 * 4
	dw 3 * 4
	IF STRSUB("\2", 1, 1) == "\""
		PUSHS
		SECTION "\1 data", ROMX
		INCBIN \2
		POPS
		db BANK("\1 data")
		dw STARTOF("\1 data")
	ELSE
		db BANK(\2)
		dw \2
	ENDC
	DEF \1_PAL_ID = BG_COLOR_ID

	DEF BG_COLOR_ID += 1
	IF BG_COLOR_ID > 8
		WARN "Ran out of background color palettes for \1"
	ENDC
ENDM

MACRO load_object_palette
	db DRAWSCENE_MEMCOPY
	dw wOBJPaletteBuffer + OBJ_COLOR_ID * 3 * 4
	IF STRSUB("\2", 0, 1) == "\""
		PUSHS
		SECTION "\1 data", ROMX
		INCBIN \2
		POPS
		dw STARTOF("\1 data")
	ELSE
		dw \2
	ENDC
	DEF \1_PAL_ID = OBJ_COLOR_ID

	DEF OBJ_COLOR_ID += 1
	IF OBJ_COLOR_ID > 8
		WARN "Ran out of object color palettes for \1"
	ENDC
ENDM

; Fill in a flat area, adding random variation.
MACRO draw_bkg ; bkg detail, x, y, width, height
	IF _NARG == 1
		DEF _draw_bkg_X = 0
		DEF _draw_bkg_Y = 0
		DEF _draw_bkg_W = SCENE_WIDTH
		DEF _draw_bkg_H = SCENE_HEIGHT
	ELSE
		DEF _draw_bkg_X = \2
		DEF _draw_bkg_Y = \3
		DEF _draw_bkg_W = \4
		DEF _draw_bkg_H = \5
	ENDC

	ASSERT DEF(\1_BACKGROUND), "\1 is not marked as a background object"
	db DRAWSCENE_BKG
	dw wSceneMap + _draw_bkg_X + _draw_bkg_Y * SCENE_WIDTH
	db _draw_bkg_W, _draw_bkg_H
	db \1_ID ; starting id
ENDM

; place a small tilemap on the map.
MACRO place_detail ; detail, x, y
	ASSERT DEF(\1_DETAIL), "\1 is not marked as a detail object"
	db DRAWSCENE_PLACEDETAIL
	db \1_WIDTH, \1_HEIGHT
	db \1_ID
	db BANK(\1_map)
	dw wSceneMap + \2 + \3 * SCENE_WIDTH ; Offset for both tiles and collision.
	dw \1_map
	IF \1_COLLISION != SCENETILE_CLEAR
		fill_collision \1_COLLISION, \2, \3, \1_WIDTH, \1_HEIGHT
	ENDC
ENDM

; Scatters details around a given area.
MACRO scatter_details_row ; x, y, x boundry, y boundry, x spacing min, x spacing max, [List of details]
	DEF X = \1
	DEF SOURCE_Y = \2
	DEF BOUNDRY_X = \3
	DEF BOUNDRY_Y = \4 - \2
	DEF X_SPACING_MIN = \5
	DEF X_SPACING_MAX = \6 - \5 + 1
	next_random
	DEF X += random % X_SPACING_MAX
	next_random
	REPT $FFFF
		DEF Y = SOURCE_Y + random % BOUNDRY_Y
		place_detail \7, X, Y
		next_random
		DEF X += X_SPACING_MIN + random % X_SPACING_MAX
		IF X >= BOUNDRY_X
			BREAK
		ENDC
	ENDR
ENDM

; Spawn a script in a given position.
MACRO spawn_effect
	ASSERT DEF(\1_EFFECT), "\1 is not marked as an effect object"
	db DRAWSCENE_SPAWNEFFECT
	db BANK(\1_SCRIPT)
	dw \1_SCRIPT ; Script pointer
	dw \2, \3 ; x/y fixed-point positions
	db \1_ID ; starting id for tiles
ENDM

; Register an area with exit tiles. There are 4 tiles for each potentential exit,
; which determines where you will end up if the scene is re-rentered. This is
; seperate from a door, which is direct a link between scenes.
MACRO register_exit
	db DRAWSCENE_FILL
	dw wSceneCollision + (\2) + (\3) * SCENE_WIDTH
	db \4, \5
	db SCENETILE_EXIT_\1
ENDM

MACRO register_door
	db DRAWSCENE_FILL
	dw wSceneCollision + (\2) + (\3) * SCENE_WIDTH
	db 2, 2
	db SCENETILE_DOOR\1
	db DRAWSCENE_SETDOOR
	db \1 ; Which door slot to fill.
	db BANK(\4)
	dw \4 ; next scene pointer
	dw \5, \6 ; exit x/y
ENDM

MACRO fill_tiles
	db DRAWSCENE_FILL
	dw wSceneMap + (\2) + (\3) * SCENE_WIDTH
	db \4, \5
	db \1_ID
ENDM

MACRO fill_collision
	db DRAWSCENE_FILL
	dw wSceneCollision + (\2) + (\3) * SCENE_WIDTH
	db \4, \5
	db \1
ENDM

ENDC
