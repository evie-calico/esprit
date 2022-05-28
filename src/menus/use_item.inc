INCLUDE "entity.inc"

DEF PLAYER_SPACING EQU 24

xUseItemMenu::
	db BANK(@)
	dw xUseItemMenuInit
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
	db 3
	; Redraw
	dw xUseItemMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xUseItemMenuClose

xUseItemMenuInit:
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	ld a, 12 * 8
	ld [wScrollInterp.y], a

	ld hl, wUseItemCurrentPalette
	ld a, LOW(wOBJPaletteBuffer + 3 * 3 * 2)
	ld [hli], a
	ld [hl], HIGH(wOBJPaletteBuffer + 3 * 3 * 2)
	FOR I, 3
		ld h, HIGH(wEntity{d:I})
		ld de, vPlayer{d:I}
		call UseItemLoadEntity
	ENDR
	ret

xUseItemMenuRedraw:
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	dec hl
	dec hl ; Size
	dec hl ; Selection
	ld b, [hl]
	inc b
	ld a, SCRN_Y + 4 - PLAYER_SPACING
:
	add a, PLAYER_SPACING
	dec b
	jr nz, :-
	ld b, a
	ld c, SCRN_VX - SCRN_X + 4
	ld hl, wUseItemMenuCursor
	call DrawCursor
	ld hl, wSubMenuCursor
	ld a, [hli]
	ld c, a
	ld a, [hld]
	ld b, a
	call DrawCursor

	lb bc, SCRN_Y + 4, SCRN_VX - SCRN_X + 24
	lb de, idof_vPlayer0, 2
	call xUseItemDrawPlayer
	lb bc, SCRN_Y + 4 + PLAYER_SPACING, SCRN_VX - SCRN_X + 24
	lb de, idof_vPlayer1, 3
	call xUseItemDrawPlayer
	lb bc, SCRN_Y + 4 + PLAYER_SPACING * 2, SCRN_VX - SCRN_X + 24
	lb de, idof_vPlayer2, 4
	call xUseItemDrawPlayer

	jp xScrollInterp

xUseItemMenuClose:
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	xor a, a
	ld [wScrollInterp.y], a
	ret

; @param b: Y
; @param c: X
; @param d: Tile
; @param e: Color
xUseItemDrawPlayer:
	ldh a, [hFrameCounter]
	and a, %00010000
	rra
	rra
	add a, d
	ld d, a
	push bc
	call RenderSimpleSprite
	pop bc
	ld a, c
	add a, 8
	ld c, a
	inc d
	inc d
	call RenderSimpleSprite

PUSHS
SECTION "Use item Menu ROM0", ROM0
UseItemLoadEntity:
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .clear
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ASSERT EntityData_Graphics == 0
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	; Now get the facing forward idle frames
	ASSERT SPRITE_DIRECTION_SIZE * DOWN >> 8 == 3
	inc h
	inc h
	inc h
	; Copy both
	ld c, 128
	call VRAMCopySmall
	pop hl
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ASSERT EntityData_Palette == 2
	ld de, wUseItemCurrentPalette
	ld a, [de]
	inc de
	ld b, a
	ld a, [de]
	ld d, a
	ld e, b
	ld c, 3 * 3
	call MemCopySmall
	ld hl, wUseItemCurrentPalette
	ld a, e
	ld [hli], a
	ld [hl], d
	ld a, BANK("Pause Menu")
	rst SwapBank
	jp ReloadColor
.clear
	ld h, d
	ld l, e
	lb bc, 0, 128
	jp VRAMSetSmall

SECTION "Use Item vars", WRAM0
wUseItemCurrentPalette: dw

POPS
