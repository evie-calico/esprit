IF !DEF(DRAW_MENU_INC)
DEF DRAW_MENU_INC EQU 1

INCLUDE "vdef.inc"

RSRESET
DEF MENUDRAW_END RB 1
DEF MENUDRAW_SET_FRAME RB 1
DEF MENUDRAW_SET_BACKGROUND RB 1

	dtile_section $9000
	dtile vFrameTopLeft
	dtile vFrameTop
	dtile vFrameTopRight
	dtile vFrameLeft
	dtile vFrameCenter
	dtile vFrameRight
	dtile vFrameBottomLeft
	dtile vFrameBottom
	dtile vFrameBottomRight

DEF menu_end EQUS "db MENUDRAW_END"

MACRO set_frame ; frame
	db MENUDRAW_SET_FRAME, BANK(\1)
	dw \1
ENDM

MACRO set_background ; tile id
	db MENUDRAW_SET_BACKGROUND, \1
ENDM

ENDC
