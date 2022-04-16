INCLUDE "draw_menu.inc"
INCLUDE "hardware.inc"
INCLUDE "menu.inc"
INCLUDE "structs.inc"
INCLUDE "theme.inc"

SECTION "Pause Menu", ROMX
PauseMenu::
	db BANK(@)
	dw xPauseMenuInit
	; Used Buttons
	db PADF_UP | PADF_DOWN
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	;dw HandleAPress, HandleBPress, HandleStartPress, HandleStartPress, \
	;   MoveRight, MoveLeft, MoveUp, MoveDown
	dw null, null, null, null, null, null, null, null
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	db 6
	; Redraw
	dw xPauseMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xPauseMenuClose

xPauseMenuInit:
	ld hl, xDrawPauseMenu
	call DrawMenu

	; Load theme
	ld hl, wActiveTheme
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	; The first member of a theme is a palette.
	ASSERT MenuTheme_Palette == 0
	ld de, wBGPaletteBuffer
	ld c, 12
	call MemCopySmall
	pop hl
	inc hl
	inc hl
	inc hl
	ld de, wOBJPaletteBuffer
	ld c, 12
	call MemCopySmall

	; Set palettes
	ld a, %10000000
	ld [wBGPaletteMask], a
	ld a, %10000000
	ld [wOBJPaletteMask], a
	ld a, 20
	ld [wFadeSteps], a
	ld a, -4
	ld [wFadeDelta], a

	; Initialize cursor
	ld hl, wCursor
	ld a, 8
	ld [hli], a
	ld a, 8
	ld [hli], a
	ld a, $00
	ld [hli], a
	ld [hl], 0
	ret

xPauseMenuRedraw:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	dec hl
	dec hl ; Size
	dec hl ; Selection
	ld a, [hl]
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, a ; a * 16
	add a, 8
	ld b, a
	ld c, 8
	call DrawCursor
	ret

xPauseMenuClose:
	ret

xSimpleFrame:
	INCBIN "res/ui/hud_frame.2bpp"

xDrawPauseMenu::
	set_frame xSimpleFrame
	set_background idof_vFrameCenter
	load_tiles xSimpleFrame, 1, vDebug0
	load_tiles xSimpleFrame, 1, vDebug1
	load_tiles xSimpleFrame, 1, vDebug2
	print_text 3, 1, "Return"
	print_text 3, 3, "Items"
	print_text 3, 5, "Party"
	print_text 3, 7, "Save", 3
	print_text 3, 9, "Options"
	print_text 3, 11, "Escape!"
	menu_end
