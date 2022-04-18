INCLUDE "defines.inc"
INCLUDE "draw_menu.inc"
INCLUDE "hardware.inc"
INCLUDE "menu.inc"
INCLUDE "structs.inc"

SECTION "Pause Menu", ROMX
xPauseMenu::
	db BANK(@)
	dw xPauseMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw xAPress, null, null, null, null, null, null, null
	db 0 ; Last selected item
	; Allow wrapping
	db 1
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
	print_text 3, 1, "Return"
	print_text 3, 3, "Items"
	print_text 3, 5, "Party"
	print_text 3, 7, "Save", 3
	print_text 3, 9, "Options"
	print_text 3, 11, "Escape!", 6
	menu_end
	; Custom vallocs must happen after the menu has been defined.
	dtile vBlankTile
	; Unused tiles reserved for submenus to draw text on.
	dtile vScratchRegion
	dtile_section $8000
	dtile vCursor, 4

.blankTile ds 16, 0

xPauseMenuInit:
	; Clear background.
	lb bc, 0, 16
	ld hl, vBlankTile
	call VRAMSetSmall
	ld d, idof_vBlankTile
	ld bc, $400
	ld hl, $9800
	call VRAMSet

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
	ldh a, [hSystem]
	and a, a
	jr z, .skipCGB
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

		ld a, %10000000
		ld [wBGPaletteMask], a
		ld a, %10000000
		ld [wOBJPaletteMask], a
.skipCGB

	; Set palettes
	ld a, 20
	ld [wFadeSteps], a
	ld a, -4
	ld [wFadeDelta], a

	; Initialize cursors
	ld hl, wPauseMenuCursor
	ld a, 4
	ld [hli], a
	ld [hli], a
	ld a, idof_vCursor
	ld [hli], a
	ld [hl], OAMF_PAL1
	; This menu is expected to maintain submenu's cursors so that they show
	; while scrolling.
	ld hl, wSubMenuCursor
	ld a, -16
	ld [hli], a
	ld [hli], a
	ld a, idof_vCursor
	ld [hli], a
	ld [hl], OAMF_PAL1

	; Set scroll
	xor a, a
	ldh [hShadowSCX], a
	ldh [hShadowSCY], a
	ld [wScrollInterp.x], a
	ld [wScrollInterp.y], a
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
	ld hl, wPauseMenuCursor
	call DrawCursor
	ld hl, wSubMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor

	jp xScrollInterp

xAPress:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	and a, a
	ret z
	dec a
	jr z, .inventory
	dec a
	jr z, .party
	dec a
	ret z
.options
	xor a, a
	ld [wMenuAction], a
	ld de, xOptionsMenu
	ld b, BANK(xOptionsMenu)
	jp AddMenu

.party
	xor a, a
	ld [wMenuAction], a
	ld de, xPartyMenu
	ld b, BANK(xPartyMenu)
	jp AddMenu

.inventory
	xor a, a
	ld [wMenuAction], a
	ld de, xInventoryMenu
	ld b, BANK(xInventoryMenu)
	jp AddMenu

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

xInventoryMenu::
	db BANK(@)
	dw xInventoryMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
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
	db 8
	; Redraw
	dw xInventoryMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xInventoryMenuClose

xInventoryMenuInit:
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	xor a, a
	ld [wScrollInterp.y], a
	ld hl, wSubMenuCursor
	ld a, SCRN_VX - SCRN_X + 64
	ld [hli], a
	ld a, 4
	ld [hli], a
	ld a, idof_vCursor
	ld [hli], a
	ld [hl], OAMF_PAL1
	ret

xInventoryMenuRedraw:
	ld hl, wSubMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor
	ld hl, wPauseMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor
	jp xScrollInterp

xInventoryMenuClose:
	xor a, a
	ld [wScrollInterp.x], a
	ld [wScrollInterp.y], a
	ret

xPartyMenu::
	db BANK(@)
	dw xPartyMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
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
	db 8
	; Redraw
	dw xPartyMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xPartyMenuClose

xPartyMenuInit:
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	xor a, a
	ld [wScrollInterp.y], a
	ld hl, wSubMenuCursor
	ld a, SCRN_VX - SCRN_X + 4
	ld [hli], a
	ld a, 4
	ld [hli], a
	ld a, idof_vCursor
	ld [hli], a
	ld [hl], OAMF_PAL1
	ret

xPartyMenuRedraw:
	ld hl, wSubMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor
	ld hl, wPauseMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor
	jp xScrollInterp

xPartyMenuClose:
	xor a, a
	ld [wScrollInterp.x], a
	ld [wScrollInterp.y], a
	ret

xOptionsMenu::
	db BANK(@)
	dw xOptionsMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
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
	db 8
	; Redraw
	dw xOptionsMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xOptionsMenuClose

xOptionsMenuInit:
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	xor a, a
	ld [wScrollInterp.y], a
	ld hl, wSubMenuCursor
	ld a, SCRN_VX - SCRN_X + 4
	ld [hli], a
	ld a, 4
	ld [hli], a
	ld a, idof_vCursor
	ld [hli], a
	ld [hl], OAMF_PAL1
	ret

xOptionsMenuRedraw:
	ld hl, wSubMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor
	ld hl, wPauseMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor
	jp xScrollInterp

xOptionsMenuClose:
	xor a, a
	ld [wScrollInterp.x], a
	ld [wScrollInterp.y], a
	ret

; Scroll towards a target position.
xScrollInterp:
	ld hl, hShadowSCX
	ld a, [wScrollInterp.x]
	cp a, [hl]
	jr z, .finishedX
	jr c, .moveLeft
.moveRight
	ld a, [hl]
	add a, 8
	ld [hl], a
	jr .finishedX
.moveLeft
	ld a, [hl]
	sub a, 8
	ld [hl], a
.finishedX
	inc l

	ld a, [wScrollInterp.y]
	cp a, [hl]
	ret z
	jr c, .moveDown
.moveUp
	ld a, [hl]
	add a, 8
	ld [hl], a
	ret
.moveDown
	ld a, [hl]
	sub a, 8
	ld [hl], a
	ret

SECTION "Scroll interp vars", WRAM0
wScrollInterp:
.x db
.y db

SECTION "Pause menu cursor", WRAM0
	dstruct Cursor, wPauseMenuCursor
	dstruct Cursor, wSubMenuCursor
