IF !DEF(DRAW_MENU_INC)
DEF DRAW_MENU_INC EQU 1

INCLUDE "structs.inc"
INCLUDE "vdef.inc"

	struct Cursor
		bytes 1, X
		bytes 1, Y
		bytes 1, Tile
		bytes 1, Attribute
	end_struct

RSRESET
DEF MENUDRAW_END RB 1
DEF MENUDRAW_SET_BACKGROUND RB 1
DEF MENUDRAW_LOAD_TILES RB 1
DEF MENUDRAW_PRINT_TEXT RB 1
DEF MENUDRAW_SET_SLACK RB 1
DEF MENUDRAW_END_DMG RB 1
DEF MENUDRAW_END_CGB RB 1

DEF MENUDRAW_MAX RB 0

	dtile_section $8800
	; Scratch space, used for allocating additional graphics
	dtile_union vScratchSpace

DEF end_menu EQUS "db MENUDRAW_END"
DEF end_dmg  EQUS "db MENUDRAW_END_DMG"
DEF end_cgb  EQUS "db MENUDRAW_END_CGB"

MACRO set_region ; tile id
	db MENUDRAW_SET_BACKGROUND
	db \3, \4, \5
	IF _NARG > 5
		dw (\6) + (\1) + (\2) * 32
	ELSE
		dw $9800 + (\1) + (\2) * 32
	ENDC
ENDM

MACRO set_tile; tile id
	set_region \1, \2, 1, 1, \3
ENDM

MACRO set_frame ; region, frame
	set_tile \1_X, \1_Y, \2 ; Top left
	set_region \1_X + 1, \1_Y, \1_Width - 2, 1, \2 + 1 ; Top
	set_tile \1_X + \1_Width - 1, \1_Y, \2 + 2 ; Top right
	set_region \1_X, \1_Y + 1, 1, \1_Height - 2, \2 + 3 ; Left
	set_region \1_X + \1_Width - 1, \1_Y + 1, 1, \1_Height - 2, \2 + 5 ; Right
	set_tile \1_X, \1_Y + \1_Height - 1, \2 + 6; Bottom left
	set_region \1_X + 1, \1_Y + \1_Height - 1, \1_Width - 2, 1, \2 + 7 ; Bottom
	set_tile \1_X + \1_Width - 1, \1_Y + \1_Height - 1, \2 + 8 ; Bottom right
ENDM

MACRO load_tiles ; tile ptr, tile count, name
	dtile \3, (\2)
	db MENUDRAW_LOAD_TILES
	db BANK(\1)
	dw (\2) * 16
	dw (\1)
ENDM

MACRO print_text ; X, Y, string, [length hint]
	db MENUDRAW_PRINT_TEXT
	; Ask vdef for the current tile ID and place it first.
	get_id CUR_ID
	db CUR_ID

	; This macro can loosely guess at the length of a string if the user can't
	; be bothered to figure it out.
	IF _NARG == 3
		db CUR_ID + STRLEN(\3) * 2 / 3
		dtile_anon STRLEN(\3) * 2 / 3
	ELSE
		db CUR_ID + \4
		dtile_anon \4
	ENDC

	PURGE CUR_ID

	; Now place the tilemap address
	dw $9800 + \1 + \2 * 32

	; And inline the string
	db \3
	db 0
ENDM

; Set the VRAM slack to a given address. This is intended for creating overlayed
; menus without once menu overwriting the other.
MACRO set_slack ; address
	db MENUDRAW_SET_SLACK
	dw \1
ENDM

ENDC
