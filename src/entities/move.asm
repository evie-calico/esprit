INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"

RSRESET
DEF SCAN_ENTITY RB
DEF SCAN_WALL RB
DEF SCAN_NONE RB

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

	; Check the move's fatigue cost
	ASSERT Move_Fatigue == 4
	inc de
	inc de
	inc de
	inc de
	ld h, d
	ld l, e
	; hl = Move_Fatigue
	ld c, LOW(wEntity0_Fatigue)
	ld a, [bc]
	sub a, [hl]
	jr c, .tooTired
	ld [bc], a

	; Load up printing variables
	; First the move name
	ASSERT Move_Fatigue + 1 == Move_Name
	inc de
	ld hl, wfmt_xUsedMoveString_move
	ldh a, [hCurrentBank]
	ld [hli], a
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
	; Then the user's name
	ld a, b
	ld [wfmt_xUsedMoveString_user], a

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

	ld b, BANK(xUsedMoveString)
	ld hl, xUsedMoveString
	call PrintHUD

	pop af
	rst SwapBank
	xor a, a
	inc a ; This sets the Z flag.
	ret

.tooTired
	; B must still be the high byte of the entity
	ld a, b
	; If the user is the player, print a message explaining that they are too tired.
	cp a, HIGH(wEntity0) 
	jr nz, .fail

	ld b, BANK(xTooTiredString)
	ld hl, xTooTiredString
	call PrintHUD

	ld hl, wEntityAnimation
	ld a, LOW(EntityDelayAnimation)
	ld [hli], a
	ld a, HIGH(EntityDelayAnimation)
	ld [hli], a
	xor a, a
	ld [hli], a
	ld [hli], a
	ld a, HIGH(wEntity0)
	ld [hl], a

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
	ld [hSaveUserIndex], a
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
	ASSERT MOVE_ACTION_HEAL == 1
	dw MoveActionHeal
	ASSERT MOVE_ACTION_POISON == 2
	dw MoveActionPoison

	ASSERT MOVE_ACTION_COUNT == 3

; Basic attack. Check <range> tiles in front of <entity>, and attack the first
; enemy seen. Deals <power> damage and has a <chance> chance of succeeding.
; @param b: Entity pointer high byte
; @param de: Move pointer
MoveActionAttack:
	call CheckMoveAccuracy
	jp c, PrintMissed
	call ScanForEntities
	ASSERT SCAN_ENTITY == 0
	and a, a
	jp nz, PrintMissed
	rst Rand8
	and a, 3
	ld b, a
	jp DealDamage

; Basic healing move. Check <range> tiles in front of <entity>, and heal the first
; ally seen. Heals <power> health and has a <chance> chance of succeeding.
; @param b: Entity pointer high byte
; @param de: Move pointer
MoveActionHeal:
	call CheckMoveAccuracy
	jp c, PrintMissed
	ldh a, [hMoveUserTeam]
	xor a, 1 ; Flip the team to check around
	ldh [hMoveUserTeam], a
	call ScanForEntities
	ASSERT SCAN_ENTITY == 0
	and a, a
	; If an entity was not found, heal ourself
	jr z, :+
		ldh a, [hSaveUserIndex]
		ld h, a
:
	rst Rand8
	and a, 3
	ld b, a
	jp HealDamage

MoveActionPoison:
	call CheckMoveAccuracy
	jp c, PrintMissed
	call ScanForEntities
	ASSERT SCAN_ENTITY == 0
	and a, a
	jp nz, PrintMissed
	lb bc, BANK(xPoisonStatus), 8 * 8
	ld de, xPoisonStatus
	jp InflictStatus

SECTION "Check move accuracy", ROM0
; Jumps to PrintMissed if the move missed.
; Skips over caller.
; @param de: move pointer
; @return carry: true if missed
; @return de: Move_Chance
; @preserves b, hl
; @clobbers c
CheckMoveAccuracy:
	ASSERT Move_Chance == 1
	inc de
	rst Rand8
	ld c, a
	ld a, [de]
	cp a, c
	ret

SECTION "Scan for entities", ROM0
; Jumps to PrintMissed if no entity is found or a wall is hit.
; @param de: Move_Chance
; @param hSaveUserIndex: User index
; @return a: SCAN_ENTITY, SCAN_WALL, SCAN_NONE
; @return de: Move_Chance
; @preserves de
ScanForEntities:
	inc de
	ld a, [de] ; Load range and store for later.
	ldh [hRangeCounter], a

	ldh a, [hSaveUserIndex]
	ld h, a
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
		ld a, SCAN_WALL
		ret
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
	ld a, SCAN_ENTITY
	ret nz
	; if not found, keep searching for each unit of range.
	ldh a, [hRangeCounter]
	dec a
	jr nz, :+
		ld a, SCAN_NONE
		ret
:
	ldh [hRangeCounter], a
	jr .offsetDirection

SECTION "Deal damage", ROM0
; @param b: damage offset
; @param de: Move_Range
; @param h: target entity
DealDamage:
	ASSERT Move_Range + 1 == Move_Power
	inc de
	; Damage target with move power.
	ld a, [de]
	add a, b
	ld [wfmt_xDealtDamageString_value], a
	ld e, a ; Save the move power in e. We don't need de anymore.
	call DamageEntity
	; Prepare for printing.
	ld a, h
	ld [wfmt_xDealtDamageString_target], a

	ld b, BANK(xDealtDamageString)
	ld hl, xDealtDamageString
	jp PrintHUD

SECTION "Heal damage", ROM0
; @param b: damage offset
; @param de: Move_Range
; @param h: target entity
HealDamage:
	ASSERT Move_Range + 1 == Move_Power
	inc de
	; Damage target with move power.
	ld a, [de]
	add a, b
	ld [wfmt_xHealedDamageString_value], a
	ld e, a ; Save the move power in e. We don't need de anymore.
	ld b, h
	call HealEntity

	; Prepare for printing.
	ld a, b
	ld [wfmt_xHealedDamageString_target], a
	ld b, BANK(xHealedDamageString)
	ld hl, xHealedDamageString
	call PrintHUD

	ld hl, wEntityAnimation
	ld a, LOW(EntityDelayAnimation)
	ld [hli], a
	ld a, HIGH(EntityDelayAnimation)
	ld [hli], a
	xor a, a
	ld [hli], a
	ld [hli], a
	ld a, [wfmt_xHealedDamageString_target]
	ld [hl], a
	ret

SECTION "Print missed text", ROM0
; @hSaveUserIndex: user index
PrintMissed:
	ldh a, [hSaveUserIndex]
	ld h, a
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	ld [wfmt_xMissedString_user], a
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
	ld [wfmt_xMissedString_user + 1], a
	ld a, [hl]
	ld [wfmt_xMissedString_user + 2], a

	ld b, BANK(xMissedString)
	ld hl, xMissedString
	call PrintHUD

	ld hl, wEntityAnimation
	ld a, LOW(EntityDelayAnimation)
	ld [hli], a
	ld a, HIGH(EntityDelayAnimation)
	ld [hli], a
	xor a, a
	ld [hli], a
	ld [hli], a
	ld a, [wfmt_xMissedString_user + 2]
	ld [hl], a
	ret

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
	ld [wfmt_xDefeatedString_reward], a
	ld a, h
	ld [wfmt_xDefeatedString_target], a

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

	ld b, BANK(xDefeatedString)
	ld hl, xDefeatedString
	jp PrintHUD

.final
	ld a, [wDefeatCheckTarget]
	ld h, a
	ld l, LOW(wEntity0_Bank)
	xor a, a
	ld [hli], a
	ret

; User to save the parameters of UseMove for animation callbacks.
SECTION "Move state", WRAM0
wMoveState:
.userIndex db
.moveBank db
.movePointer dw

SECTION "Defeat check target", WRAM0
; High byte of the entity for the coming defeat check to target.
wDefeatCheckTarget:: db

SECTION "Attack range counter", HRAM
hRangeCounter: db
hSaveUserIndex: db

SECTION "User Team", HRAM
; 0 if current move is being used by allies, 1 if used by enemies
hMoveUserTeam:: db