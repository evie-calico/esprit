INCLUDE "entity.inc"

MACRO status
	IF !DEF(STATUS_COUNT)
		DEF STATUS_COUNT = 0
	ENDC

	DEF STATUS_COUNT += 1

	DEF \1 EQU STATUS_COUNT
	EXPORT \1

	DEF STATUS{d:STATUS_COUNT}_NAME EQUS "\2"
ENDM

MACRO turns
	DEF STATUS{d:STATUS_COUNT}_TURNS EQU (\1) + 1
ENDM

	DEF STATUS_OK EQU 0
	EXPORT STATUS_OK

	status STATUS_POISON, "Poison"
		turns 16

; Export this at the end of the defintions to ensure that the latest value is what is exported
DEF STATUS_COUNT += 1
EXPORT STATUS_COUNT

SECTION "Inflict status", ROM0
; @param h: Entity index
; @param b: Status effect
InflictStatus::
	ldh a, [hCurrentBank]
	push af

	ld l, LOW(wEntity0_StatusEffect)
	ld [hl], b
	inc l

	ld a, BANK(xStatusGetTurnCount)
	rst SwapBank
	ld a, b
	call xStatusGetTurnCount
	ld [hl], a

	ld a, 1
	ld [wForceHudUpdate], a

	jp BankReturn

SECTION "Pre-Turn Status Update", ROMX
; Update any status effects which occur after the entity's turn.
; Eahc handler recieves Entity_StatusEffect in HL.
; @param h: Entity index
; @clobbers all
xStatusPostTurnUpdate::
	ld l, LOW(wEntity0_StatusTurns)
	ld a, [hl]
	and a, a
	ret z
	dec [hl]
	jr nz, .turnsRemaining
		dec l
		xor a, a
		ld [hl], a
		inc a
		ld [wForceHudUpdate], a
		ret
.turnsRemaining
	ASSERT Entity_StatusTurns - 1 == Entity_StatusEffect
	dec l

	; As more effects are added, this may constitute a more efficient check.
	; For now, a small number of compares isn't an issue.
	ld a, [hl]
	cp a, STATUS_POISON
	ret nz
; Deal 1-4 damage to an entity every 8 turns.
xPoisonPostTurnUpdate:
	ASSERT Entity_StatusEffect + 1 == Entity_StatusTurns
	inc l
	ld a, [hl]
	dec a
	; Only deal damage every 4th turn
	and a, 3
	ret nz
	; Deal 1-4 damage
	rst Rand8
	and a, 3
	inc a
	ld e, a
	jp DamageEntity

SECTION "Get Status Turn Count", ROMX
; @param a: Status ID
; @return a: Status Turns
; @clobbers: de
xStatusGetTurnCount:
	ASSERT STATUS_COUNT <= 128
	add a, LOW(.table - 1)
	ld e, a
	adc a, HIGH(.table - 1)
	sub a, e
	ld d, a
	ld a, [de]
	ret

.table
	FOR i, 1, STATUS_COUNT
		db STATUS{d:i}_TURNS
	ENDR

SECTION "Status Names", ROM0
; @param a: Status ID
xStatusGetName::
	ASSERT STATUS_COUNT <= 128
	add a, a
	add a, LOW(.names - 2)
	ld l, a
	adc a, HIGH(.names - 2)
	sub a, l
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

.names
	FOR i, 1, STATUS_COUNT
		dw .status{d:i}
	ENDR

	FOR i, 1, STATUS_COUNT
		.status{d:i} db STATUS{d:i}_NAME, 0
	ENDR

SECTION "wInflictStatusTarget", WRAM0
wInflictStatusTarget: db
