include "hardware.inc"

section "Wait for VBlank", rom0
WaitVBlank::
	xor a, a
	ld [wWaitVBlankFlag], a
:   halt
	ld a, [wWaitVBlankFlag]
	and a, a
	jr z, :-
	ret

section "VBlank Interrupt", rom0[$0040]
	push af
	push bc
	push de
	push hl
	jp VBlank

section "STAT Interrupt", rom0[$0048]
	push af
	push bc
	push de
	push hl
	jp STAT

section "VBlank Handler", rom0
VBlank:
	ld a, [hCurrentBank]
	push af

	ld a, high(wShadowOAM)
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
	and a, a
	jr z, .noMusic
	rst SwapBank
	call TickMusic
.noMusic

	ld a, bank("Sound Effects")
	rst SwapBank
	call audio_update

	pop af
	rst SwapBank

	pop hl
	pop de
	pop bc
	pop af
	ret

section "STAT Handler", rom0
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

section "Wait VBlank flag", wram0
wWaitVBlankFlag: db

section "STAT target", wram0
wSTATTarget:: dw

section "Shadow registers", hram
hShadowSCX:: db
hShadowSCY:: db
hShadowWX:: db
hShadowWY:: db
hShadowLCDC:: db
hFrameCounter:: db
