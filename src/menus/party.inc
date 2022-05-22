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
	db 4
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
