INCLUDE "config.inc"
INCLUDE "defines.inc"
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
	end_dmg
	set_region 0, 0, SCRN_X_B, SCRN_Y_B, 0
	end_cgb
	dtile vVersionText

.frame INCBIN "res/ui/hud_frame.2bpp"

xTitleScreenInit:
	xor a, a
	ld [wTextLetterDelay], a
	ld hl, xDrawTitleScreen
	call DrawMenu

	ld a, $80
	ld e, a
	ld d, SCRN_Y_B
	ld a, SCRN_X - 16
	ld b, idof_vVersionText
	ld c, $FF
	call TextInit
	lb de, 10, 10
	ld hl, $9800 + 1 + 1 * 32
	call TextDefineBox
	ld a, 1
	ld b, BANK(@)
	ld hl, Version
	call PrintVWFText
	call PrintVWFChar
	call DrawVWFChars

	call Rand

	xor a, a
	ld [wFadeDelta], a ; Initialize this value to fade in from white
	call FadeIn
	jp LoadPalettes

xTitleScreenClose:
	; Set palettes
	ld a, %11111111
	ld [wBGPaletteMask], a
	ld a, %11111111
	ld [wOBJPaletteMask], a
	call FadeToBlack

	ld hl, wActiveDungeon
	ld a, BANK(FIRST_DUNGEON)
	ld [hli], a
	ld a, LOW(FIRST_DUNGEON)
	ld [hli], a
	ld a, HIGH(FIRST_DUNGEON)
	ld [hli], a

	ld hl, wActiveMapNode
	ld a, BANK(FIRST_NODE)
	ld [hli], a
	ld a, LOW(FIRST_NODE)
	ld [hli], a
	ld a, HIGH(FIRST_NODE)
	ld [hli], a

	ld hl, wFadeCallback
	ld a, LOW(InitDungeon)
	ld [hli], a
	ld [hl], HIGH(InitDungeon)
	ret
