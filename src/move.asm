INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"
INCLUDE "text.inc"

SECTION "Use Move", ROM0
; @param a: Move index
; @param b: Entity pointer high byte
; @param hMoveUserTeam: must be configured immediently before or after this call.
; @return z: set if failed
UseMove::
	; Each move pointer is 3 bytes.
	ld c, a
	add a, a ; a * 2
	add a, c ; a * 3
	add a, LOW(wEntity0_Moves)
	ld c, a

	; Deref move into de.
	ldh a, [hCurrentBank]
	push af ; don't forget to save the current bank.

	ld a, [bc]
	and a, a
	jr z, .fail ; Exit if the move's bank is 0.
	inc bc
	rst SwapBank
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	ld d, a
	; Save parameters to be used by animation callbacks.
	ld hl, wMoveState
	ASSERT wMoveState.userIndex + 1 == wMoveState.moveBank
	ld a, b
	ld [hli], a
	ldh a, [hCurrentBank]
	ld [hli], a
	ld a, e
	ld [hli], a
	ld [hl], d

	; Load up printing variables
	; First the move name
	ASSERT Move_Name == 1
	inc de
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld d, a
	ld e, l
	ld hl, wUsedMove.move
	ldh a, [hCurrentBank]
	ld [hli], a
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
	; Then the user's name
	ld c, LOW(wEntity0_Bank)
	ld a, [bc]
	ld [hli], a
	rst SwapBank
	inc c
	ld a, [bc]
	ld l, a
	inc c
	ld a, [bc]
	ld h, a
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, l
	ld [wUsedMove.user + 1], a
	ld a, h
	ld [wUsedMove.user + 2], a

	ld hl, wEntityAnimation
	ld a, LOW(EntityAttackAnimation)
	ld [hli], a
	ld a, HIGH(EntityAttackAnimation)
	ld [hli], a
	ld a, LOW(.dispatchMoveAction)
	ld [hli], a
	ld a, HIGH(.dispatchMoveAction)
	ld [hli], a
	ld [hl], b

	ld b, BANK(xUsedText)
	ld hl, xUsedText
	call PrintHUD

	pop af
	rst SwapBank
	xor a, a
	inc a ; This sets the Z flag.
	ret

.fail
	pop af
	rst SwapBank
	xor a, a
	ret

.dispatchMoveAction
	ldh a, [hCurrentBank]
	push af

	ld hl, wMoveState
	ASSERT wMoveState.userIndex + 1 == wMoveState.moveBank
	ld a, [hli]
	ld b, a
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld e, a
	ld d, [hl]
	; Check move action and execute.
	ASSERT Move_Action == 0
	ld a, [de]
	ld hl, .moveActions
	call HandleJumpTable

	pop af
	rst SwapBank
	ret

; Functions to handle move behaviors.
; @param b: Entity pointer high byte
; @param de: Move pointer
.moveActions
	ASSERT MOVE_ACTION_ATTACK == 0
	dw MoveActionAttack

; Basic attack. Check <range> tiles in front of <entity>, and attack the first
; entity seen. Deals <power> damage and has a <chance> chance of succeeding.
; @param b: Entity pointer high byte
; @param de: Move pointer
MoveActionAttack:
	ld h, b ; Move the index to h; a more useful register.
	ld a, b
	ldh [hSaveUserIndex], a

	ASSERT Move_Chance == 3
	inc de
	inc de
	inc de
	push de
	push hl
	call Rand
	pop hl
	pop de
	ld c, a
	ld a, [de]
	cp a, c
	jp c, .miss

	ASSERT Move_Chance + 1 == Move_Range
	inc de
	ld a, [de] ; Load range and store for later.
	ldh [hRangeCounter], a

	ld l, LOW(wEntity0_PosX)
	ld a, [hli]
	ld b, a
	ld c, [hl]
.offsetDirection
	ldh a, [hSaveUserIndex]
	ld h, a
	push de
		ld l, LOW(wEntity0_Direction)
		ld a, [hl]
		add a, a
		add a, LOW(DirectionVectors)
		ld e, a
		adc a, HIGH(DirectionVectors)
		sub a, e
		ld d, a
		ld a, [de]
		add a, b
		ld b, a
		inc de
		inc l
		ASSERT Entity_PosX + 1 == Entity_PosY
		ld a, [de]
		add a, c
		ld c, a
	pop de

	ldh a, [hCurrentBank]
	push af
		; Check for a wall; basic attacks shouldn't go through them
		push de
			ld a, BANK(xGetMapPosition)
			rst SwapBank
			call xGetMapPosition
			ld a, [de]
		pop de
		cp a, TILE_WALL
		jr nz, :+
		pop af
		rst SwapBank
		jr .miss
:
		ld a, BANK(xCheckForEntity)
		rst SwapBank
		ldh a, [hMoveUserTeam]
		and a, a
		jr nz, .enemyTeam
		ld h, HIGH(wEntity0) + NB_ALLIES
		ld a, HIGH(wEntity0) + NB_ENTITIES
		jr .entityCheck
	.enemyTeam
		ld h, HIGH(wEntity0)
		ld a, HIGH(wEntity0) + NB_ALLIES
	.entityCheck
		call xCheckForEntity
	pop af
	rst SwapBank
	ld a, h
	and a, a
	jr nz, .found
	; if not found, keep searching for each unit of range.
	ldh a, [hRangeCounter]
	dec a
	jr z, .miss
	ldh [hRangeCounter], a
	jr .offsetDirection

.found
	push hl
	ASSERT Move_Range + 1 == Move_Power
	inc de
	; Damage target with move power.
	ld a, [de]
	ld [wDealtDamage.value], a
	ld e, a ; Save the move power in e. We don't need de anymore.
	ld l, LOW(wEntity0_Health)
	ld a, [hl]
	sub a, e
	ld [hli], a
	ld a, [hl]
	sbc a, 0
	ld [hl], a
	; Prepare for printing.
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	ld [wDealtDamage.target], a
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hli]
	ld [wDealtDamage.target + 1], a
	ld a, [hl]
	ld [wDealtDamage.target + 2], a

	ld b, BANK(xDealtText)
	ld hl, xDealtText
	call PrintHUD
	pop hl

	; Finally, play the damage animation.
	ld b, h
	ld hl, wEntityAnimation
	ld a, LOW(EntityHurtAnimation)
	ld [hli], a
	ld a, HIGH(EntityHurtAnimation)
	ld [hli], a
	ld a, LOW(DefeatCheck)
	ld [hli], a
	ld a, HIGH(DefeatCheck)
	ld [hli], a
	ld [hl], b
	ld a, b
	ld [wDefeatCheckTarget], a
	ret

.miss
	ldh a, [hSaveUserIndex]
	ld h, a
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	ld [wMissedMove.user], a
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ASSERT EntityData_Name == 4
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hli]
	ld [wMissedMove.user + 1], a
	ld a, [hl]
	ld [wMissedMove.user + 2], a

	ld b, BANK(xMissedText)
	ld hl, xMissedText
	jp PrintHUD

SECTION "Defeat check", ROM0
DefeatCheck::
	ld a, [wDefeatCheckTarget]
	ld h, a
	ld l, LOW(wEntity0_Health)
	ld a, [hli]
	or a, [hl]
	jr z, .defeat
	bit 7, [hl]
	ret z
.defeat
	ld b, h
	ld hl, wEntityAnimation
	ld a, LOW(EntityDefeatAnimation)
	ld [hli], a
	ld a, HIGH(EntityDefeatAnimation)
	ld [hli], a
	ld a, LOW(.final)
	ld [hli], a
	ld a, HIGH(.final)
	ld [hli], a
	ld [hl], b
	ldh a, [hSaveUserIndex]
	cp a, HIGH(wEntity0) + NB_ALLIES
	ret nc
	; Now reward XP to the party and print message
	ld h, b
	ld l, LOW(wEntity0_Level)
	ld a, [hl]
	call GetXpReward
	ld b, a
	ld [wDefeatText.reward], a
	ldh a, [hCurrentBank]
	push af
		ld l, LOW(wEntity0_Bank)
		ld a, [hli]
		ld [wDefeatText.target], a
		rst SwapBank
		ld a, [hli]
		ld h, [hl]
		ld l, a
		ASSERT EntityData_Name == 4
		inc hl
		inc hl
		inc hl
		inc hl
		ld a, [hli]
		ld [wDefeatText.target + 1], a
		ld a, [hli]
		ld [wDefeatText.target + 2], a
	pop af

	ld hl, wEntity0
.rewardParty
	ld l, LOW(wEntity0_Bank)
	ld a, [hl]
	and a, a
	jr z, .next
	ld l, LOW(wEntity0_Experience)
	ld a, [hli]
	add a, b
	ld c, a
	adc a, [hl]
	sub a, c
	ld [hld], a
	ld [hl], c
.next
	inc h
	ld a, h
	cp a, HIGH(wEntity0) + NB_ALLIES
	jr nz, .rewardParty

	ld b, BANK(xDefeatText)
	ld hl, xDefeatText
	jp PrintHUD

.final
	ld a, [wDefeatCheckTarget]
	ld h, a
	ld l, LOW(wEntity0_Bank)
	xor a, a
	ld [hli], a
	ret

SECTION "Used move text", ROMX
xUsedText:
	textcallptr wUsedMove.user
	db " used "
	textcallptr wUsedMove.move
	db "!<END>"

SECTION "Dealt damage text", ROMX
xDealtText:
	db "Dealt "
	print_u8 wDealtDamage.value
	db " damage to "
	textcallptr wDealtDamage.target
	db "!<END>"

SECTION "Defeated enemy text", ROMX
xDefeatText:
	db "Defeated "
	textcallptr wDefeatText.target
	db ". Gained "
	print_u8 wDefeatText.reward
	db " xp.", 0

SECTION "Missed move text", ROMX
xMissedText:
	textcallptr wMissedMove.user
	db " missed!<END>"

SECTION UNION "Move text variables", WRAM0
wUsedMove:
.move ds 3
.user ds 3

SECTION UNION "Move text variables", WRAM0
wMissedMove:
.user ds 3

SECTION UNION "Move text variables", WRAM0
wDealtDamage:
.value db
.target ds 3

SECTION UNION "Move text variables", WRAM0
wDefeatText:
.target ds 3
.reward db

; User to save the parameters of UseMove for animation callbacks.
SECTION "Move state", WRAM0
wMoveState:
.userIndex db
.moveBank db
.movePointer dw

SECTION "Defeat check target", WRAM0
; High byte of the entity for the coming defeat check to target.
wDefeatCheckTarget: db

SECTION "Attack range counter", HRAM
hRangeCounter: db
hSaveUserIndex: db

SECTION "User Team", HRAM
; 0 if current move is being used by allies, 1 if used by enemies
hMoveUserTeam:: db