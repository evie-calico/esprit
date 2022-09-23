INCLUDE "defines.inc"
INCLUDE "draw_menu.inc"
INCLUDE "hardware.inc"
INCLUDE "menu.inc"
INCLUDE "structs.inc"

DEF MAIN_CURSOR_X EQU 5
DEF MAIN_CURSOR_Y EQU 4

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
	dw xPauseMenuAPress, null, null, null, null, null, null, null
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
	set_region 0, 0, SCRN_VX_B, SCRN_VY_B, idof_vBlankTile
	load_tiles .frame, 9, vFrame
	DEF idof_vBlankTile EQU idof_vFrame + 4
	dregion vTopMenu, 0, 0, 9, 14
	set_frame vTopMenu, idof_vFrame
	print_text 3, 1, "Return"
	print_text 3, 3, "Items"
	print_text 3, 5, "Party"
	print_text 3, 7, "Save"
	print_text 3, 9, "Options"
	print_text 3, 11, "Escape!"
	end_dmg
	set_region 0, 0, SCRN_VX_B, SCRN_VY_B, 0
	end_cgb

	; Custom vallocs must happen after the menu has been defined.
	; Unused tiles reserved for submenus to draw text on.
	dtile vScratchRegion
	; Define sprites up here for convienience :)
	dtile_section $8000
	dtile vCursor, 4
	dtile vItemCursor, 4
	dtile vPlayer0, 8
	dtile vPlayer1, 8
	dtile vPlayer2, 8

.frame INCBIN "res/ui/hud_frame.2bpp"

xPauseMenuInit:
	; Set scroll
	xor a, a
	ldh [hShadowSCX], a
	ldh [hShadowSCY], a
	ld [wScrollInterp.x], a
	ld [wScrollInterp.y], a

	ld hl, xDrawPauseMenu
	call DrawMenu
	call LoadTheme
	; Load palette
	ldh a, [hSystem]
	and a, a
	call nz, LoadPalettes

	; Set palettes
	call FadeIn

	; Initialize cursors
	ld hl, wPauseMenuCursor
	ld a, MAIN_CURSOR_X
	ld [hli], a
	ld a, MAIN_CURSOR_Y
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
	add a, MAIN_CURSOR_Y
	ld b, a
	ld c, MAIN_CURSOR_X
	ld hl, wPauseMenuCursor
	call DrawCursor
	ld hl, wSubMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor

	jp xScrollInterp

xPauseMenuAPress:
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
	call FadeToWhite
	ld hl, wFadeCallback
	ld a, LOW(SwitchToDungeonState)
	ld [hli], a
	ld [hl], HIGH(SwitchToDungeonState)
	ret

INCLUDE "menus/inventory.inc"
INCLUDE "menus/use_item.inc"
INCLUDE "menus/party.inc"
INCLUDE "menus/options.inc"

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

SECTION "Pause Menu Load Palettes", ROM0
LoadPalettes::
	ldh a, [hCurrentBank]
	push af
	ld hl, wActiveMenuPalette
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	; Skip over next pointer.
	ASSERT MenuPal_Colors == 3
	inc hl
	inc hl
	inc hl
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
	ld c, 9
	call MemCopySmall

	ld a, %10000000
	ld [wBGPaletteMask], a
	ld a, %10000000
	ld [wOBJPaletteMask], a
	jp BankReturn

LoadTheme::
	ldh a, [hCurrentBank]
	push af
	; Load theme
	ld hl, wActiveMenuTheme
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	; Skip next pointer.
	ASSERT MenuTheme_Cursor == 3
	inc hl
	inc hl
	inc hl
	; First is the cursor. We can seek over it by loading!
	ld de, vCursor
	ld c, 16 * 4
	call VRAMCopySmall
	; After this is the emblem tiles
	; First read the length
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	; THen deref the tiles
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ld de, $9000
	call VRAMCopy
	pop hl
	inc hl

	ld a, [hli]
	ld h, [hl]
	ld l, a
	; And finally, the tilemap.
	lb bc, 11, 10
	ld de, $9909
	call MapRegion
	pop af
	rst SwapBank
	ret

SECTION "Scroll interp vars", WRAM0
wScrollInterp:
.x db
.y db

SECTION "Pause menu cursor", WRAM0
	dstruct Cursor, wPauseMenuCursor
	dstruct Cursor, wSubMenuCursor
	dstruct Cursor, wUseItemMenuCursor
