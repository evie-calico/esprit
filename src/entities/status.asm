include "entity.inc"

macro status
	if !def(STATUS_COUNT)
		def STATUS_COUNT = 0
	endc

	def STATUS_COUNT += 1

	def \1 equ STATUS_COUNT
	export \1

	def STATUS{d:STATUS_COUNT}_NAME equs "\2"
endm

macro turns
	def STATUS{d:STATUS_COUNT}_TURNS equ (\1) + 1
endm

	def STATUS_OK equ 0
	export STATUS_OK

	status STATUS_POISON, "Poison"
		turns 16

; Export this at the end of the defintions to ensure that the latest value is what is exported
def STATUS_COUNT += 1
export STATUS_COUNT

section "Inflict status", rom0
; @param h: Entity index
; @param b: Status effect
InflictStatus::
	ldh a, [hCurrentBank]
	push af

	ld l, low(wEntity0_StatusEffect)
	ld [hl], b
	inc l

	ld a, bank(xStatusGetTurnCount)
	rst SwapBank
	ld a, b
	call xStatusGetTurnCount
	ld [hl], a

	ld a, 1
	ld [wForceHudUpdate], a

	jp BankReturn

section "Pre-Turn Status Update", romx
; Update any status effects which occur after the entity's turn.
; Eahc handler recieves Entity_StatusEffect in HL.
; @param h: Entity index
; @clobbers all
xStatusPostTurnUpdate::
	ld l, low(wEntity0_StatusTurns)
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
	assert Entity_StatusTurns - 1 == Entity_StatusEffect
	dec l

	; As more effects are added, this may constitute a more efficient check.
	; For now, a small number of compares isn't an issue.
	ld a, [hl]
	cp a, STATUS_POISON
	ret nz
; Deal 1-4 damage to an entity every 8 turns.
xPoisonPostTurnUpdate:
	assert Entity_StatusEffect + 1 == Entity_StatusTurns
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

section "Get Status Turn Count", romx
; @param a: Status ID
; @return a: Status Turns
; @clobbers: de
xStatusGetTurnCount:
	assert STATUS_COUNT <= 128
	add a, low(.table - 1)
	ld e, a
	adc a, high(.table - 1)
	sub a, e
	ld d, a
	ld a, [de]
	ret

.table
	for i, 1, STATUS_COUNT
		db STATUS{d:i}_TURNS
	endr

section "Status Names", rom0
; @param a: Status ID
xStatusGetName::
	assert STATUS_COUNT <= 128
	add a, a
	add a, low(.names - 2)
	ld l, a
	adc a, high(.names - 2)
	sub a, l
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

.names
	for i, 1, STATUS_COUNT
		dw .status{d:i}
	endr

	for i, 1, STATUS_COUNT
		.status{d:i} db STATUS{d:i}_NAME, 0
	endr

section "wInflictStatusTarget", wram0
wInflictStatusTarget: db
