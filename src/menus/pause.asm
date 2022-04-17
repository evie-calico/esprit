INCLUDE "defines.inc"
INCLUDE "draw_menu.inc"
INCLUDE "hardware.inc"
INCLUDE "menu.inc"
INCLUDE "structs.inc"

SECTION "Pause Menu", ROMX
PauseMenu::
	db BANK(@)
	dw xPauseMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	;dw HandleAPress, HandleBPress, HandleStartPress, HandleStartPress, \
	;   MoveRight, MoveLeft, MoveUp, MoveDown
	dw xAPress, null, null, null, null, null, null, null
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

; Place this first to define certain constants.
xDrawPauseMenu:
	load_tiles .blankTile, 1, vBlankTile
	set_background idof_vBlankTile
	print_text 3, 1, "Return"
	print_text 3, 3, "Items"
	print_text 3, 5, "Party"
	print_text 3, 7, "Save", 3
	print_text 3, 9, "Options"
	print_text 3, 11, "Escape!", 6
	menu_end
	; Custom vallocs must happen after the menu has been defined.
	dtile_section $8000
	dtile vCursor, 4

.blankTile ds 16, 0

xPauseMenuInit:
	ld hl, xDrawPauseMenu
	call DrawMenu

	; Load theme
	ld hl, wActiveMenuTheme
	ld a, [hli]
	ld h, [hl]
	ld l, a
	; First is the cursor. We can seek over it by loading!
	ld de, vCursor
	ld c, 16 * 4
	call VRAMCopySmall
	; After this is the emblem tiles
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld de, $9000
	call VRAMCopy
	; And finally, the tilemap.
	lb bc, 11, 10
	ld de, $9909
	call MapRegion

	; Load palette
	ld hl, wActiveMenuPalette
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	; The first member of a theme is a palette.
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
	ld a, 4
	ld [hli], a
	ld a, 4
	ld [hli], a
	ld a, idof_vCursor
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
	add a, 4
	ld b, a
	ld c, 4
	call DrawCursor
	ret

xAPress:
	ret

xPauseMenuClose:
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
	ld a, LOW(SwitchToDungeonState)
	ld [hli], a
	ld [hl], HIGH(SwitchToDungeonState)
	ret

xSimpleFrame:
	INCBIN "res/ui/hud_frame.2bpp"
