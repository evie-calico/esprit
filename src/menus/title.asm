INCLUDE "draw_menu.inc"
INCLUDE "hardware.inc"

SECTION "Title screen", ROMX
xTitleScreen::
	db BANK(@)
	dw xTitleScreenInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_START
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw null, null, null, null, null, null, null, null
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	db 0
	; Redraw
	dw null
	; Private Items Pointer
	dw null
	; Close Function
	dw xTitleScreenClose

xDrawTitleScreen:
	set_region 0, 0, SCRN_X_B, SCRN_Y_B, idof_vBlankTile
	load_tiles .frame, 9, vFrame
	DEF idof_vBlankTile EQU idof_vFrame + 4
	dregion vTopMenu, 0, 0, SCRN_X_B, SCRN_Y_B
	set_frame vTopMenu, idof_vFrame
	print_text 1, 1, "Vuiiger"
	end_dmg
	set_region 0, 0, SCRN_X_B, SCRN_Y_B, 0
	end_cgb

.frame INCBIN "res/ui/hud_frame.2bpp"

xTitleScreenInit:
	ld hl, xDrawTitleScreen
	call DrawMenu
	ld a, 20
	ld [wFadeSteps], a
	ld a, $80 + 20 * 4
	ld [wFadeAmount], a
	ld a, -4
	ld [wFadeDelta], a
	jp LoadPalettes

xTitleScreenClose:
	; Set palettes
	ld a, %11111111
	ld [wBGPaletteMask], a
	ld a, %11111111
	ld [wOBJPaletteMask], a
	ld a, 20
	ld [wFadeSteps], a
	ld a, $80
	ld [wFadeAmount], a
	ld a, 4
	ld [wFadeDelta], a
	ld hl, wFadeCallback
	ld a, LOW(InitDungeon)
	ld [hli], a
	ld [hl], HIGH(InitDungeon)
	ret
