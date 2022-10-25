INCLUDE "hardware.inc"

SECTION "Wait for VBlank", ROM0
WaitVBlank::
	xor a, a
	ld [wWaitVBlankFlag], a
:   halt
	ld a, [wWaitVBlankFlag]
	and a, a
	jr z, :-
	ret

SECTION "VBlank Interrupt", ROM0[$0040]
	push af
	push bc
	push de
	push hl
	jp VBlank

SECTION "STAT Interrupt", ROM0[$0048]
	push af
	push bc
	push de
	push hl
	jp STAT

SECTION "VBlank Handler", ROM0
VBlank:
	ld a, [hCurrentBank]
	push af

	ld a, HIGH(wShadowOAM)
	call hOAMDMA

	ldh a, [hShadowWX]
	ldh [rWX], a
	ldh a, [hShadowWY]
	ldh [rWY], a
	ldh a, [hShadowSCX]
	ldh [rSCX], a
	ldh a, [hShadowSCY]
	ldh [rSCY], a
	ldh a, [hShadowLCDC]
	ldh [rLCDC], a
	ldh a, [hBGP]
	ldh [rBGP], a
	ldh a, [hOBP0]
	ldh [rOBP0], a
	ldh a, [hOBP1]
	ldh [rOBP1], a

	ldh a, [hFrameCounter]
	inc a
	ldh [hFrameCounter], a

	ld a, 1
	ld [wWaitVBlankFlag], a

	ei

	ldh a, [hSongBank]
	rst SwapBank
	call TickMusic

	ld a, BANK("Sound Effects")
	rst SwapBank
	call audio_update

	pop af
	rst SwapBank

	pop hl
	pop de
	pop bc
	pop af
	ret

SECTION "STAT Handler", ROM0
STAT:
	ld hl, wSTATTarget
	ld a, [hli]
	ld h, [hl]
	ld l, a
	rst CallHL
	pop hl
	pop de
	pop bc
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	pop af
	reti

SECTION "Wait VBlank flag", WRAM0
wWaitVBlankFlag: db

SECTION "STAT target", WRAM0
wSTATTarget:: dw

SECTION "Shadow registers", HRAM
hShadowSCX:: db
hShadowSCY:: db
hShadowWX:: db
hShadowWY:: db
hShadowLCDC:: db
hFrameCounter:: db
