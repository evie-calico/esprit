; A simple interface for drawing elements on-screen.

INCLUDE "defines.inc"
INCLUDE "draw_menu.inc"
INCLUDE "hardware.inc"

SECTION "Menu Renderer", ROM0
; @param hl: Menu to draw. This should exist in the current bank, which will
; be preserved.
DrawMenu::
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
.readByte
	ld a, [hli]
	add a, a
	ASSERT MENUDRAW_END == 0
	ret z ; a value of 0 will immediately exit.
	add a, LOW(.jumpTable - 2)
	ld e, a
	adc a, HIGH(.jumpTable - 2)
	sub a, e
	ld d, a
	push de
	ret
	; The function jumped to will recieve the data pointer in `hl`.
	; It must preserve this value, skipping over any parameter bytes.

.jumpTable
	dw MenuLoadFrameset
	dw MenuSetBackground

SECTION "Menu Load Frameset", ROM0
MenuLoadFrameset:
	ldh a, [hCurrentBank]
	push af

	; Read farpointer to frame tiles.
	ld a, [hli]
	ld b, a ; Save bank.
	ld a, [hli]
	; We only read one byte after the `push`; this must be skipped later.
	push hl
		ld h, [hl]
		ld l, a
		ld a, b
		rst SwapBank
		ld de, vFrameTopLeft
		ld c, 16 * 9
		call VRAMCopySmall
	pop hl
	inc hl

	pop af
	rst SwapBank
	ret

SECTION "Menu Set Region", ROM0
MenuSetBackground:
; Used to set a full map of 20*14 regular tiles. LCD-Safe
; @ hl: Pointer to upper-left tile
; @ b : Tile ID
; @ c : Number of rows to copy
ScreenSet::
	ld a, [hli]
	push hl

	ld b, a
	ld hl, $9800
	ld e, SCRN_Y_B
.nextRow
	ld d, SCRN_X_B
.rowLoop
		ldh a, [rSTAT]
		and STATF_BUSY
		jr nz, .rowLoop
	ld a, b
	ld [hli], a
	dec d
	jr nz, .rowLoop
	dec e
	jr z, .exit
	ld a, SCRN_VX_B - SCRN_X_B
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	jr .nextRow

.exit
	pop hl
	ret


