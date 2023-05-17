def OPTIONS_CURSOR_X equ SCRN_VX - SCRN_X + 69
def OPTIONS_CURSOR_Y equ 20

xOptionsMenu::
	db bank(@)
	dw xOptionsMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw xOptionsMenuAPress, null, null, null, null, null, null, null
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	db 2
	; Redraw
	dw xOptionsMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xOptionsMenuClose

xDrawOptionsMenu::
	set_region 20, 0, SCRN_VX_B - 20, SCRN_VY_B, idof_vBlankTile
	dtile_section vScratchRegion
	dregion vOptionsMenu, 20, 0, 12, 10
	set_frame vOptionsMenu, idof_vFrame
	print_text 24, 1, "Options"
	print_text 23, 3, "Theme:"
	print_text 23, 6, "Color:"
	end_menu
	dtile vSelectionsText

xOptionsMenuInit:
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	xor a, a
	ld [wScrollInterp.y], a
	ld hl, wSubMenuCursor
	ld a, OPTIONS_CURSOR_X
	ld [hli], a
	ld a, OPTIONS_CURSOR_Y
	ld [hli], a
	ld a, idof_vCursor
	ld [hli], a
	ld [hl], OAMF_PAL1
	ld hl, xDrawOptionsMenu
	call DrawMenu
	call xOptionsMenuDrawSelections
	ret

xOptionsMenuRedraw:
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
	ld b, a
	add a, a ; a * 16
	add a, b
	add a, OPTIONS_CURSOR_Y
	ld b, a
	ld c, OPTIONS_CURSOR_X
	ld hl, wSubMenuCursor
	call DrawCursor
	ld hl, wPauseMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor
	jp xScrollInterp

xOptionsMenuAPress:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	and a, a
	jr z, .changeTheme
	dec a
	jr z, .changeColor
	jr .toggleSticky

.toggleSticky
	xor a, a
	ld [wMenuAction], a
	ld hl, wWindowSticky
	ld a, 1
	xor a, [hl]
	ld [hl], a
	jr xOptionsMenuDrawSelections

.changeColor
	ld hl, wActiveMenuPalette
	ldh a, [hCurrentBank]
	call ChangeColorROM0
PUSHS
section "Change Color rom0", rom0
ChangeColorROM0:
	push af
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli]
	ld [wActiveMenuPalette], a
	ld a, [hli]
	ld [wActiveMenuPalette + 1], a
	ld a, [hl]
	ld [wActiveMenuPalette + 2], a
	jp BankReturn
POPS
	xor a, a
	ld [wMenuAction], a

	; Reload the palette.
	ldh a, [hSystem]
	and a, a
	jr z, xOptionsMenuDrawSelections
	call LoadPalettes
	call ReloadPalettes
	jr xOptionsMenuDrawSelections

.changeTheme
	ld hl, wActiveMenuTheme
	ldh a, [hCurrentBank]
	call ChangeThemeROM0
PUSHS
section "Change Theme rom0", rom0
ChangeThemeROM0:
	push af
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hli]
	ld [wActiveMenuTheme], a
	ld a, [hli]
	ld [wActiveMenuTheme + 1], a
	ld a, [hl]
	ld [wActiveMenuTheme + 2], a
	jp BankReturn
POPS
	xor a, a
	ld [wMenuAction], a
	call LoadTheme
	jr xOptionsMenuDrawSelections

xOptionsMenuDrawSelections:
	; Clear the tiles of text where we will draw.
	ld hl, $9800 + 23 + 4 * 32
	lb bc, idof_vBlankTile, 8
	call VramSetSmall
	ld hl, $9800 + 23 + 7 * 32
	lb bc, idof_vBlankTile, 8
	call VramSetSmall
	ld hl, $9800 + 23 + 10 * 32
	lb bc, idof_vBlankTile, 8
	call VramSetSmall

	; Print palette name.
	ld hl, wActiveMenuPalette
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	add a, MenuPal_Name
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, 1
	call PrintVWFText

	; Text is already mostly initialized by the menu renderer.
	xor a, a
	ld [wTextLetterDelay], a
	ld a, idof_vSelectionsText
	ld [wTextCurTile], a
	ld [wWrapTileID], a
	ld a, $FF
	ld [wLastTextTile], a
	lb de, 8, 1
	ld hl, $9800 + 23 + 7 * 32
	call TextDefineBox

	call PrintVWFChar
	call DrawVWFChars

	; Print theme name.
	ld hl, wActiveMenuTheme
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	add a, MenuTheme_Name
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, 1
	call PrintVWFText

	; Text is already mostly initialized by the menu renderer.
	lb de, 8, 1
	ld hl, $9800 + 23 + 4 * 32
	call TextDefineBox

	call PrintVWFChar
	call DrawVWFChars

	ret

.loose db "Loose", 0
.sticky db "Sticky", 0

xOptionsMenuClose:
	xor a, a
	ld [wScrollInterp.x], a
	ld [wScrollInterp.y], a
	ret
