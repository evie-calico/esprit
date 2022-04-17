IF !DEF(DRAW_MENU_INC)
DEF DRAW_MENU_INC EQU 1

INCLUDE "vdef.inc"

RSRESET
DEF MENUDRAW_END RB 1
DEF MENUDRAW_SET_BACKGROUND RB 1
DEF MENUDRAW_LOAD_TILES RB 1
DEF MENUDRAW_PRINT_TEXT RB 1

DEF MENUDRAW_MAX RB 0

	dtile_section $8800
	; Scratch space, used for allocating additional graphics
	dtile_union vScratchSpace

DEF menu_end EQUS "db MENUDRAW_END"

MACRO set_background ; tile id
	db MENUDRAW_SET_BACKGROUND
	db \1
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

ENDC
