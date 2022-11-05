; A simple interface for drawing elements on-screen.

include "defines.inc"
include "draw_menu.inc"
include "hardware.inc"

section "Menu Renderer", rom0
; @param hl: Menu to draw. This should exist in the current bank, which will
; be preserved.
DrawMenu::
	ld a, low(vScratchSpace)
	ld [wVramSlack], a
	ld a, high(vScratchSpace)
	ld [wVramSlack + 1], a
.readByte
	ld a, [hli]
	add a, a
	assert MENUDRAW_END == 0
	ret z ; a value of 0 will immediately exit.
	add a, low(.jumpTable - 2)
	ld e, a
	adc a, high(.jumpTable - 2)
	sub a, e
	ld d, a
	ld a, [de]
	ld b, a
	inc de
	ld a, [de]
	ld d, a
	ld e, b
	push de
	ret
	; The function jumped to will recieve the data pointer in `hl`.
	; It must preserve this value, skipping over any parameter bytes.

.jumpTable
	dw MenuSetBackground
	dw MenuLoadTiles
	dw MenuPrint
	dw MenuSetSlack
	dw MenuEndDMG
	dw MenuEndCGB
	assert MENUDRAW_MAX == 7

section "Menu Set Region", rom0
MenuSetBackground:
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	call FillRegion
	pop hl
	inc hl
	jp DrawMenu.readByte

section "Menu Load Tiles", rom0
MenuLoadTiles:
	ldh a, [hCurrentBank]
	push af

	ld a, [hli]
	ld d, a

	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ld a, d
	rst SwapBank
	ld a, [wVramSlack]
	ld e, a
	ld a, [wVramSlack + 1]
	ld d, a
	call VramCopy
	ld a, e
	ld [wVramSlack], a
	ld a, d
	ld [wVramSlack + 1], a
	pop hl
	inc hl

	pop af
	rst SwapBank
	jp DrawMenu.readByte

MenuPrint:
	ldh a, [hCurrentBank]
	push af

	push hl
		; Prepare text
		ld b, a
		inc hl
		inc hl
		inc hl
		inc hl ; The string is placed after width, height, and address.
		ld a, $80
		ld [wTextLineLength], a
		ld a, 1
		call PrintVWFText

	pop hl
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	push hl
		xor a, a
		ld [wTextLetterDelay], a

		; This function only needs to be called once.
		; TODO: move this to its own bytecode.
		; TODO hard-coding 0x80 might be problematic...
		ld a, $80
		ld e, a
		ld d, SCRN_Y_B
		ld a, SCRN_X
		call TextInit
	pop hl
	pop af
	push af
	rst SwapBank
	ld a, [hli]
	push hl
		lb de, SCRN_X_B, SCRN_Y_B
		ld h, [hl]
		ld l, a
		call TextDefineBox
		call PrintVWFChar
		call DrawVWFChars

	pop hl
	pop af
	push af
	rst SwapBank
	; Skip string. This is a consequence of inlining it, and should be
	; changed when inline fragments are added.
	xor a, a
:	inc hl
	cp a, [hl]
	jr nz, :-
	inc hl


	pop af
	rst SwapBank
	jp DrawMenu.readByte

section "Menu Set Slack", rom0
MenuSetSlack:
	ld a, [hli]
	ld [wVramSlack], a
	ld a, [hli]
	ld [wVramSlack + 1], a
	jp DrawMenu.readByte

section "Menu End DMG", rom0
MenuEndDMG:
	ldh a, [hSystem]
	and a, a
	ret z
	ld a, 1
	ldh [rVBK], a
	jp DrawMenu.readByte

section "Menu End CGB", rom0
MenuEndCGB:
	xor a, a
	ldh [rVBK], a
	ret

section "Cursor Renderer", rom0

; Draws a cursor without a target position
DrawCursorStatic::
	ld a, [hli]
	ld c, a
	jr DrawCursor.finishedY

; Draws a cursor and moves it towards a target.
; @param b: Target Y position
; @param c: Target X position
; @param hl: Cursor struct
DrawCursor::
	ld a, c
	cp a, [hl]
	jr z, .finishedX
	jr c, .moveLeft
.moveRight
	inc [hl]
	inc [hl]
	inc [hl]
	inc [hl]
	jr .finishedX
.moveLeft
	dec [hl]
	dec [hl]
	dec [hl]
	dec [hl]
.finishedX
	ld a, [hli]
	ld c, a

	ld a, b
	cp a, [hl]
	jr z, .finishedY
	jr c, .moveDown
.moveUp
	inc [hl]
	inc [hl]
	inc [hl]
	inc [hl]
	jr .finishedY
.moveDown
	dec [hl]
	dec [hl]
	dec [hl]
	dec [hl]
.finishedY
	ld a, [hli]
	ld b, a

	ld a, [hli]
	ld d, a
	ld e, [hl]

	push bc
	call RenderSimpleSprite
	pop bc
	inc d
	inc d
	ld a, c
	add a, 8
	ld c, a
	jp RenderSimpleSprite

section "Map Region", rom0
; @param b: Width
; @param c: Height
; @param de: VRAM destination
; @param hl: Source map
MapRegion::
	ld a, b
	push af
.copy
.waitVram
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .waitVram
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy
	pop af
	dec c
	ret z
	push af
	ld b, a
	ld a, SCRN_VX_B
	sub a, b
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	jr .copy

section "Fill Region", rom0
; @param b: Width
; @param c: Height
; @param d: Value
; @param hl: VRAM destination
FillRegion::
	ld a, b
	push af
.copy
.waitVram
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .waitVram
	ld a, d
	ld [hli], a
	dec b
	jr nz, .copy
	pop af
	dec c
	ret z
	push af
	ld b, a
	ld a, SCRN_VX_B
	sub a, b
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	jr .copy

section "Draw Menu vars", wram0
wVramSlack: dw
