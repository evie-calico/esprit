if !def(SCENE_INC)
def SCENE_INC equ 1

include "structs.inc"

rsreset
def DRAWSCENE_END         rb ; End drawing.
def DRAWSCENE_VRAMCOPY    rb ; Copy data to VRAM
def DRAWSCENE_BKG         rb ; Fill in an area of the map with three ground tiles.
def DRAWSCENE_PLACEDETAIL rb ; Place a small tilemap somewhere on the map.
def DRAWSCENE_SPAWNNPC    rb ; Allocate space for an NPC and assign it a position.
def DRAWSCENE_FILL        rb ; Fill an area of the scene
def DRAWSCENE_SETDOOR     rb ; Define a door pointing to another scene.
def DRAWSCENE_MEMCOPY     rb ; Copy data
def DRAWSCENE_SETCOLOR    rb ; Assign an attribute to a tile id
def DRAWSCENE_ENDDMG      rb ; End drawing if on DMG

rsreset
def SCENETILE_CLEAR      rb
def SCENETILE_WALL       rb
def SCENETILE_EXIT_DOWN  rb
def SCENETILE_EXIT_LEFT  rb
def SCENETILE_EXIT_UP    rb
def SCENETILE_EXIT_RIGHT rb
def SCENETILE_DOOR0      rb
def SCENETILE_DOOR1      rb
def SCENETILE_DOOR2      rb
def SCENETILE_DOOR3      rb
def SCENETILE_DOOR4      rb
def SCENETILE_DOOR5      rb
def SCENETILE_DOOR6      rb
def SCENETILE_DOOR7      rb

def SCENE_WIDTH equ 64
def SCENE_HEIGHT equ 32

	struct Scene
		words 8, Entrances
		bytes 1, Width
		bytes 1, Height
		longs 1, Seed
		bytes 3, IntroScript
		alias DrawInfo
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
macro def_background
	def \1_BACKGROUND equ 1
	def \1_SIZE equ 4
	PUSHS
	section "\1 tiledata", romx
	\1_data:
		incbin \2
	.end
	POPS
endm

; A detail is like a small tilemap which can be stamped anywhere in the scene.
macro def_detail
	def \1_DETAIL equ 1
	def \1_SIZE equs "(\1_data.end - \1_data) / 16"
	def \1_WIDTH equ \4
	def \1_HEIGHT equ \5
	def \1_COLLISION equ \6
	PUSHS
	section "\1 tiledata", romx
	\1_map:
		incbin \3
	\1_data:
		incbin \2
	.end
	POPS
endm

; Define a new scene, including certain configurations.
macro scene ; (entrance x/y) * 4, width, height, seed, initial script
	def TILE_ID = $80
	def BG_COLOR_ID = 0
	def OB_COLOR_ID = 0
	def ENTITY_ID = 2

	def SCENE_BOUNDARY_X = SCRN_X
	def SCENE_BOUNDARY_Y = SCRN_Y - 32
	def SCENE_TOP_ENTRANCE_X = SCENE_BOUNDARY_X / 8 / 2
	def SCENE_TOP_ENTRANCE_Y = 0
	def SCENE_RIGHT_ENTRANCE_X = SCENE_BOUNDARY_X / 8 - 2
	def SCENE_RIGHT_ENTRANCE_Y = SCENE_BOUNDARY_Y / 8 / 2
	def SCENE_LEFT_ENTRANCE_X = 0
	def SCENE_LEFT_ENTRANCE_Y = SCENE_BOUNDARY_Y / 8 / 2
	def SCENE_BOTTOM_ENTRANCE_X = SCENE_BOUNDARY_X / 8 / 2
	def SCENE_BOTTOM_ENTRANCE_Y = SCENE_BOUNDARY_Y / 8 - 3
	redef SCENE_ENTRANCE_SCRIPT equs "null"
endm

macro begin_draw
	; Begin with an array of 4 positions, corresponding to each direction
	dw SCENE_BOTTOM_ENTRANCE_Y * 8.0, SCENE_BOTTOM_ENTRANCE_X * 8.0
	dw SCENE_LEFT_ENTRANCE_Y * 8.0, (SCENE_LEFT_ENTRANCE_X * 8.0 + 1.0)
	dw (SCENE_TOP_ENTRANCE_Y * 8.0 + 1.0), SCENE_TOP_ENTRANCE_X * 8.0
	dw SCENE_RIGHT_ENTRANCE_Y * 8.0, SCENE_RIGHT_ENTRANCE_X * 8.0
	assert SCENE_BOUNDARY_X <= 512 && SCENE_BOUNDARY_Y <= 256, "Scenes are limited to a 512x256 area"
	db (SCENE_BOUNDARY_X - SCRN_X) / 16, (SCENE_BOUNDARY_Y - SCRN_Y + 32) / 16 ; width/height divided by 16
	; The seed ensures maps always appear the same.
	; You can generate 4 bytes for a seed here:
	; https://www.random.org/bytes/
	dl random
	db bank(SCENE_ENTRANCE_SCRIPT)
	dw SCENE_ENTRANCE_SCRIPT
.drawInfo
	; The drawing information imediately follows.
		fill_collision SCENETILE_CLEAR, 0, 0, SCENE_BOUNDARY_X / 8, SCENE_BOUNDARY_Y / 8
		register_exits
endm

def end_scene equs "db DRAWSCENE_END"

; PRNG for generating natrual-looking maps at buildtime.
; Thanks Rangi
macro next_random ; xorshift32
  def random ^= random << 13
  def random ^= random >> 17
  def random ^= random << 5
endm

macro load_tiles
	db DRAWSCENE_VRAMCOPY
	dw $8000 + TILE_ID * 16 ; Destination
	dw \1_SIZE * 16 ; length
	db bank(\1_data) ; bank
	dw \1_data ; source

	db DRAWSCENE_SETCOLOR
	db TILE_ID
	db \2_PAL_ID
	db \1_SIZE

	def \1_ID = TILE_ID
	def TILE_ID += \1_SIZE
endm

macro load_objects
	; Make sure that objects' tiles are properly aligned.
	if TILE_ID % 2
		def TILE_ID += 1
	endc

	db DRAWSCENE_VRAMCOPY
	dw $8000 + TILE_ID * 16
	dw \1_SIZE * 16 ; length
	db bank(\1_data) ; bank
	dw \1_data ; source

	assert \1_SIZE % 2 == 0, "Objects must be a multiple of 2 tiles in 8x16 mode."
	def \1_ID = TILE_ID
	def TILE_ID += \1_SIZE
endm

macro load_bgp
	db DRAWSCENE_MEMCOPY
	dw wBGPaletteBuffer + BG_COLOR_ID * 3 * 4
	dw 3 * 4
	if strsub("\2", 1, 1) == "\""
		PUSHS
		section "\1 data", romx
		incbin \2
		POPS
		db bank("\1 data")
		dw STARTOF("\1 data")
	else
		db bank(\2)
		dw \2
	endc
	def \1_PAL_ID = BG_COLOR_ID

	def BG_COLOR_ID += 1
	if BG_COLOR_ID > 8
		warn "Ran out of background color palettes for \1"
	endc
endm

macro load_obp
	db DRAWSCENE_MEMCOPY
	dw wOBJPaletteBuffer + OBJ_COLOR_ID * 3 * 4
	if strsub("\2", 0, 1) == "\""
		PUSHS
		section "\1 data", romx
		incbin \2
		POPS
		dw STARTOF("\1 data")
	else
		dw \2
	endc
	def \1_PAL_ID = OBJ_COLOR_ID

	def OBJ_COLOR_ID += 1
	if OBJ_COLOR_ID > 8
		warn "Ran out of object color palettes for \1"
	endc
endm

; Fill in a flat area, adding random variation.
macro draw_bkg ; bkg detail, x, y, width, height
	if _NARG == 1
		def _draw_bkg_X = 0
		def _draw_bkg_Y = 0
		def _draw_bkg_W = SCENE_WIDTH
		def _draw_bkg_H = SCENE_HEIGHT
	else
		def _draw_bkg_X = \2
		def _draw_bkg_Y = \3
		def _draw_bkg_W = \4
		def _draw_bkg_H = \5
	endc

	assert def(\1_BACKGROUND), "\1 is not marked as a background object"
	db DRAWSCENE_BKG
	dw wSceneMap + _draw_bkg_X + _draw_bkg_Y * SCENE_WIDTH
	db _draw_bkg_W, _draw_bkg_H
	db \1_ID ; starting id
endm

; place a small tilemap on the map.
def pd equs "place_detail"
macro place_detail ; detail, x, y
	assert def(\1_DETAIL), "\1 is not marked as a detail object"
	db DRAWSCENE_PLACEDETAIL
	db \1_WIDTH, \1_HEIGHT
	db \1_ID
	db bank(\1_map)
	dw wSceneMap + \2 + \3 * SCENE_WIDTH ; Offset for both tiles and collision.
	dw \1_map
	if \1_COLLISION != SCENETILE_CLEAR
		fill_collision \1_COLLISION, \2, \3, \1_WIDTH, \1_HEIGHT
	endc
endm

; Scatters details around a given area.
macro scatter_details_row ; x, y, x boundry, y boundry, x spacing min, x spacing max, [List of details]
	def X = \1
	def SOURCE_Y = \2
	def BOUNDRY_X = \3
	def BOUNDRY_Y = \4 - \2
	def X_SPACING_MIN = \5
	def X_SPACING_MAX = \6 - \5 + 1
	next_random
	def X += random % X_SPACING_MAX
	next_random
	rept $FFFF
		def Y = SOURCE_Y + random % BOUNDRY_Y
		place_detail \7, X, Y
		next_random
		def X += X_SPACING_MIN + random % X_SPACING_MAX
		if X >= BOUNDRY_X
			break
		endc
	endr
endm

; Spawn an NPC in a given position.
macro npc
	db DRAWSCENE_SPAWNNPC
	if ENTITY_ID >= 8
		fail "Out of NPCs, only 6 NPCs may exist in a single scene."
	endc
	db high(wEntity0) + ENTITY_ID
	def ENTITY_ID += 1
	db bank(\1)
	dw \1 ; NPC's entity base (source of graphics)
	dw \3, \2 ; x/y fixed-point positions
	db \4
	db bank(\5) ; Idle Script
	dw \5
	db bank(\6) ; Interation Script
	dw \6
endm

; Register an area with exit tiles. There are 4 tiles for each potentential exit,
; which determines where you will end up if the scene is re-rentered. This is
; seperate from a door, which is direct a link between scenes.
macro register_exits
	fill_collision SCENETILE_EXIT_LEFT, 0, 0, 1, SCENE_BOUNDARY_Y / 8
	fill_collision SCENETILE_EXIT_RIGHT, SCENE_BOUNDARY_X / 8 - 1, 0, 1, SCENE_BOUNDARY_Y / 8
	fill_collision SCENETILE_EXIT_UP, 0, 0, SCENE_BOUNDARY_X / 8, 1
	fill_collision SCENETILE_EXIT_DOWN, 0, SCENE_BOUNDARY_Y / 8 - 1, SCENE_BOUNDARY_X / 8, 1
endm

macro register_door
	db DRAWSCENE_FILL
	dw wSceneCollision + (\2) + (\3) * SCENE_WIDTH
	db 2, 2
	db SCENETILE_DOOR\1
	db DRAWSCENE_SETDOOR
	db \1 ; Which door slot to fill.
	db bank(\4)
	dw \4 ; next scene pointer
	dw \5, \6 ; exit x/y
endm

macro fill_tiles
	db DRAWSCENE_FILL
	dw wSceneMap + (\2) + (\3) * SCENE_WIDTH
	db \4, \5
	db \1_ID
endm

macro fill_collision
	db DRAWSCENE_FILL
	dw wSceneCollision + (\2) + (\3) * SCENE_WIDTH
	db \4, \5
	db \1
endm

endc
