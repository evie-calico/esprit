if !def(DRAW_MENU_INC)
def DRAW_MENU_INC equ 1

include "structs.inc"
include "vdef.inc"
include "res/ui/optix_glyphs.inc"

	struct Cursor
		bytes 1, X
		bytes 1, Y
		bytes 1, Tile
		bytes 1, Attribute
	end_struct

rsreset
def MENUDRAW_END rb 1
def MENUDRAW_SET_BACKGROUND rb 1
def MENUDRAW_LOAD_TILES rb 1
def MENUDRAW_PRINT_TEXT rb 1
def MENUDRAW_SET_SLACK rb 1
def MENUDRAW_END_DMG rb 1
def MENUDRAW_END_CGB rb 1

def MENUDRAW_MAX rb 0

	dtile_section $8800
	; Scratch space, used for allocating additional graphics
	dtile_union vScratchSpace

def end_menu equs "db MENUDRAW_END"
def end_dmg  equs "db MENUDRAW_END_DMG"
def end_cgb  equs "db MENUDRAW_END_CGB"

macro set_region ; tile id
	db MENUDRAW_SET_BACKGROUND
	db \3, \4, \5
	if _NARG > 5
		dw (\6) + (\1) + (\2) * 32
	else
		dw $9800 + (\1) + (\2) * 32
	endc
endm

macro set_tile; tile id
	set_region (\1), (\2), 1, 1, (\3)
endm

macro set_frame ; region, frame
	set_tile \1_X, \1_Y, \2 ; Top left
	set_region \1_X + 1, \1_Y, \1_Width - 2, 1, \2 + 1 ; Top
	set_tile \1_X + \1_Width - 1, \1_Y, \2 + 2 ; Top right
	set_region \1_X, \1_Y + 1, 1, \1_Height - 2, \2 + 3 ; Left
	set_region \1_X + \1_Width - 1, \1_Y + 1, 1, \1_Height - 2, \2 + 5 ; Right
	set_tile \1_X, \1_Y + \1_Height - 1, \2 + 6; Bottom left
	set_region \1_X + 1, \1_Y + \1_Height - 1, \1_Width - 2, 1, \2 + 7 ; Bottom
	set_tile \1_X + \1_Width - 1, \1_Y + \1_Height - 1, \2 + 8 ; Bottom right
endm

macro load_tiles ; tile ptr, tile count, name
	dtile \3, (\2)
	db MENUDRAW_LOAD_TILES
	db bank(\1)
	dw (\2) * 16
	dw (\1)
endm

macro print_text ; X, Y, string, [length hint]
	db MENUDRAW_PRINT_TEXT
	; Ask vdef for the current tile ID and place it first.
	get_id CUR_ID
	db CUR_ID

	def WIDTH = 1
	for I, 1, strlen(\3)
		def GLYPH = CHARSUB(\3, I)
		if GLYPH == "\n"
			def WIDTH += 8
		else
			def WIDTH += glyph{d:GLYPH}
		endc
	endr
	db CUR_ID + (WIDTH / 8) + 1
	dtile_anon (WIDTH / 8) + 1

	purge CUR_ID, WIDTH, GLYPH

	; Now place the tilemap address
	dw $9800 + \1 + \2 * 32

	; And inline the string
	db \3
	db 0
endm

; Set the VRAM slack to a given address. This is intended for creating overlayed
; menus without once menu overwriting the other.
macro set_slack ; address
	db MENUDRAW_SET_SLACK
	dw \1
endm

endc
