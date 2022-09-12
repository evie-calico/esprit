INCLUDE "entity.inc"

SECTION "Inflict Status", ROM0
; @param b: Bank
; @param c: Turns
; @param de: Status
; @param h: Entity index
; @clobbers all
InflictStatus::
	ldh a, [hCurrentBank]
	push af

	ld l, LOW(wEntity0_Status)
	ld a, [hld]
	and a, a
	ret nz
	ld a, c
	ld [hli], a
	ld a, b
	rst SwapBank
	ld b, h
	ld [hli], a
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
	ld a, [de]
	inc de
	ld l, a
	ld a, [de]
	ld h, a
	rst CallHL

	jp BankReturn

MACRO status ; identifier, name, first, every, last
SECTION "\1 status", ROMX
\1::
	dw \3, \4, \5
	db \2
ENDM

	status xPoisonStatus, "Poison", xPoisonFirstTurn, xPoisonEachTurn, xPoisonFinalTurn

xPoisonFirstTurn:
	ld a, b
	ld [wfmt_xGotPoisonedString_target], a
	ld b, BANK(xGotPoisonedString)
	ld hl, xGotPoisonedString
	jp PrintHUD

xPoisonEachTurn:
	ld a, [wActiveEntity]
	add a, HIGH(wEntity0)
	ld h, a
	;ld l, LOW(wEntity0_StatusTurns)

	;ld a, [hl]
	;dec a
	;and a, 7 ; Every 8th turn
	;ret nz
	;rst Rand8
	;and a, 3 ; 1-4 damage
	;inc a
	ld e, 1
	jp DamageEntity

xPoisonFinalTurn:
	ld a, [wActiveEntity]
	add a, HIGH(wEntity0)
	ld [wfmt_xNotPoisonedString_target], a
	ld b, BANK(xNotPoisonedString)
	ld hl, xNotPoisonedString
	jp PrintHUD
