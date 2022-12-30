include "defines.inc"
include "dungeon.inc"
include "entity.inc"
include "hardware.inc"

; How fast the entity should move during animations. Should be a power of two.
def MOVEMENT_SPEED equ 16
def RUNNING_SPEED equ 64

; Determines whether health should be restored on a given turn.
def HEALING_TURN_MASK equ 3 ; every 4th turn.

section "Process entities", rom0
; Iterate through the entities.
; The individual logic functions can choose to return on their own to end logic
; processing. This is used to queue up movements to occur simultaneuously.
ProcessEntities::
	ld a, [wMoveEntityCounter]
	and a, a
	ret nz
.loop
	; Beginning-of-turn bookkeeping
	ld a, bank("Entity Logic")
	rst SwapBank

	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_Bank)
	ld a, [hl]
	and a, a
	jr nz, :+
		call EndTurn.skip
		jr .loop
:
	ld a, [wActiveEntity]
	cp a, NB_ALLIES
	jp nc, xEnemyLogic
	ld b, a
	ld a, [wTrackedEntity]
	cp a, b
	jp z, xPlayerLogic
	jp xAllyLogic

; All entity logic jumps here to end their turn.
.next::
	call EndTurn
	jr .loop

EndTurn::
	; End-of-turn bookkeeping
	; Handle status effect updates which happen at the end of each turn.
	ld a, [wActiveEntity]
	ld b, a
	add a, high(wEntity0)
	ld h, a

	ld a, [wManualControlMode]
	and a, a
	jr z, :+
		ld a, [wTrackedEntity]
		cp a, b
		jr nz, :+
		xor a, 1
		ld [wTrackedEntity], a
	:

	; Check for poison
	ld l, low(wEntity0_PoisonTurns)
	ld a, [hl]
	and a, a
	jr z, .noPoison
	todo
	dec [hl]
	jr nz, :+
		ld a, 1
		ld [wForceHudUpdate], a
		jr .noPoison
	:
	; Only deal damage every 4th turn
	and a, 3
	ret nz
	; Deal 1-4 damage
	rst Rand8
	and a, 3
	inc a
	ld e, a
	call DamageEntity
.noPoison

/* The following code *would* regenerate health, but is currently disabled for the sake of balance
	; Restore 1hp every few turns
	ld a, [wActiveEntity]
	cp a, NB_ALLIES
	jr nc, .skipHealing
		ld a, [wTurnCounter]
		and a, HEALING_TURN_MASK
		jr nz, .skipHealing
			ld a, [wActiveEntity]
			add a, high(wEntity0)
			ld b, a
			ld e, 1
			call HealEntity
.skipHealing
*/
	; Restore 1% fatigue
	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_Fatigue)
	ld a, [hl]
	inc a
	cp a, 101
	jr nc, .skipFatigue
		ld [hl], a
.skipFatigue
.skip::
	; Move on to the next entity
	ld a, [wActiveEntity]
	inc a
	cp a, NB_ENTITIES
	jr nz, :+
		ld hl, wTurnCounter
		inc [hl]
		xor a, a
	:
	ld [wActiveEntity], a
	ret

section "Move entities", romx
xMoveEntities::
	xor a, a
	ld [wMoveEntityCounter], a
	ld b, MOVEMENT_SPEED
	ld h, high(wEntity0)
.loop
	ld l, low(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .null
.yCheck
	ld l, low(wEntity0_PosY)
	ld d, [hl]
	; DE: Target position in 12.4
	; [HL]: Sprite position
	; Compare the positions to check if they need to be interpolated.
	ld l, low(wEntity0_SpriteY + 1)
	ld a, [hld]
	cp a, d
	jr z, .yCheckLow
	jr c, .yGreater
	; Fallthrough to yLesser.
.yLesser
	ld l, low(wEntity0_SpriteY)
	ld a, [hl]
	sub a, b
	ld [hli], a
	jr nc, .next
	dec [hl]
	jr .next
.yCheckLow
	ld a, [hl]
	cp a, 0
	jr z, .xCheck
	jr nc, .yLesser
	; Fallthrough to yGreater.
.yGreater
	ld l, low(wEntity0_SpriteY)
	ld a, [hl]
	add a, b
	ld [hli], a
	jr nc, .next
	inc [hl]
	jr .next

.xCheck
	ld l, low(wEntity0_PosX)
	ld d, [hl]
	; DE: Target position in 12.4
	; [HL]: Sprite position
	; Compare the positions to check if they need to be interpolated.
	ld l, low(wEntity0_SpriteX + 1)
	ld a, [hld]
	cp a, d
	jr z, .xCheckLow
	jr c, .xGreater
	; Fallthrough to xLesser.
.xLesser
	ld l, low(wEntity0_SpriteX)
	ld a, [hl]
	sub a, b
	ld [hli], a
	jr nc, .next
	dec [hl]
	jr .next
.xCheckLow
	ld a, [hl]
	cp a, 0
	jr z, .skip
	jr nc, .xLesser
	; Fallthrough to xGreater.
.xGreater
	ld l, low(wEntity0_SpriteX)
	ld a, [hl]
	add a, b
	ld [hli], a
	jr nc, .next
	inc [hl]

.next
	ld a, [wMoveEntityCounter]
	inc a
	ld [wMoveEntityCounter], a
	ld a, 1
	jr :+
.skip
	xor a, a
:   ld l, low(wEntity0_Frame)
	ld [hl], a
.null
	inc h
	ld a, h
	cp a, high(wEntity0) + NB_ENTITIES
	jr nz, .loop
	ld a, [wMoveEntityCounter]
	ld [wMovementQueued], a
	ret

section "Step in direction", rom0
; @param a: direction
; @param b: X
; @param c: Y
StepDir:
	and a, a
	jr z, .up
	dec a
	jr z, .right
	dec a
	jr z, .down
.left
	dec b
	jr .correctX
.down
	inc c
	jr .correctY
.right
	inc b
	jr .correctX
.up
	dec c
.correctY
	ld a, c
	cp a, $FF
	jr nz, :+
	inc c
:	cp a, DUNGEON_WIDTH
	ret nz
	dec c
	ret

.correctX
	ld a, b
	cp a, $FF
	jr nz, :+
	inc b
:	cp a, DUNGEON_HEIGHT
	ret nz
	dec b
	ret

section "Joypad to direction", rom0
; Reads hCurrentKeys and returns the currently selected pad direction in A.
; If no direction is selected, sets the carry flag.
PadToDir::
	xor a, a ; Clear carry flag
	ldh a, [hCurrentKeys]
	bit PADB_LEFT, a
	jr z, :+
	ld a, LEFT
	ret
:	bit PADB_RIGHT, a
	jr z, :+
	ld a, RIGHT
	ret
:	bit PADB_DOWN, a
	jr z, :+
	ld a, DOWN
	ret
:	bit PADB_UP, a
	jr z, :+
	assert UP == 0
	xor a, a
	ret
:	scf
	ret

section "Check for entity", romx
; Checks for an entity at a given position, returning its index if found.
; Otherwise, returns 0.
; @param a: High byte of last entity
; @param b: X position
; @param c: Y position
; @param h: High byte of first entity
; @return h: index, or 0 upon failure.
; @preserves b, c, d, e
xCheckForEntity::
	ldh [hClosestEntityFinal], a
	xor a, a
	ld [wMoveEntityCounter], a
.loop
	ld l, low(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .next
	ld l, low(wEntity0_PosX)
	ld a, b
	cp a, [hl]
	jr nz, .next
	assert Entity_PosX + 1 == Entity_PosY
	inc l
	ld a, c
	cp a, [hl]
	ret z
.next
	inc h
	ldh a, [hClosestEntityFinal]
	cp a, h
	jp nz, .loop
	ld h, 0
	ret

section "Direction vectors", rom0
; An array of vectors used to offset positions using a direction.
DirectionVectors::
	db 0, -1
	db 1, 0
	db 0, 1
	db -1, 0

section "Spawn entity", rom0
; @param b: Entity data bank.
; @param c: Entity level.
; @param de: Entity data pointer.
; @param h: High byte of entity struct.
; @preserves: h, bank
SpawnEntity::
	ld a, [hCurrentBank]
	push af

	push bc
		; Clear out entity struct
		xor a, a
		ld l, low(wEntity0)
		ld c, sizeof_Entity
		call MemSetSmall
		dec h ; correct high byte (MemSet causes it to overflow)
		assert DUNGEON_HEIGHT / 2 == DUNGEON_WIDTH / 2
		ld a, DUNGEON_WIDTH / 2
		ld l, low(wEntity0_SpriteY + 1)
		ld [hli], a
		inc l
		ld [hli], a
		ld [hli], a
		ld [hli], a
		ld a, b
		rst SwapBank
		ld l, low(wEntity0_Bank)
		ld [hli], a
		assert Entity_Bank + 1 == Entity_Data
		ld a, e
		ld [hli], a
		ld a, d
		ld [hli], a
	pop bc

	; Set level
	ld l, low(wEntity0_Level)
	ld a, c
	ld [hl], a

	ld l, low(wEntity0_AnimationDesync)
	rst Rand8
	ld [hl], a

	call RestoreEntity

	push hl
		call UpdateMoves
	pop hl

	jp BankReturn

section "Restore entity", rom0
RestoreEntity::
	; Start with 100% fatigue
	ld l, low(wEntity0_Fatigue)
	ld [hl], 100

	; Get level
	ld l, low(wEntity0_Level)
	ld a, [hli]

	; Use level to determine health.
	assert Entity_Level + 1 == Entity_Health
	push hl
		call GetMaxHealth
		ld a, l
		ld b, h
	pop hl
	ld [hli], a
	ld [hl], b
	ret

section "Spawn Enemy", rom0
SpawnEnemy::
	call Rand
	and a, 63
	ld b, a
	ld a, e
	and a, 63
	ld c, a
	assert DUNGEON_WIDTH * 4 == 256
	add a, a ; a * 2
	add a, a ; a * 4
	ld l, a
	ld h, 0
	add hl, hl ; a * 8
	add hl, hl ; a * 16
	add hl, hl ; a * 32
	add hl, hl ; a * 64
	assert DUNGEON_WIDTH == 64
	ld de, wDungeonMap
	add hl, de
	ld a, b
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	assert TILE_CLEAR == 0
	and a, a
	jr nz, SpawnEnemy
	; b = X
	; c = Y

	push bc
		call Rand
		and a, 7
		assert sizeof_SpawnEntityInfo == 4
		add a, a
		add a, a
		add a, Dungeon_Entities
		assert sizeof_Dungeon < 256
		ld b, a
		ld hl, wActiveDungeon
		ld a, [hli]
		rst SwapBank
		ld a, [hli]
		ld h, [hl]
		add a, b
		ld l, a
		adc a, h
		sub a, l
		ld h, a
		ld a, [hli]
		ld c, a
		ld a, [hli]
		ld b, a
		ld a, [hli]
		ld d, [hl]
		ld e, a
		; de = ptr
		; b = bank
		; c = level
		ld h, high(wEntity0) + NB_ALLIES
	.loop
		ld l, low(wEntity0_Bank)
		ld a, [hli]
		and a, a
		jr z, .spawn
		inc h
		ld a, h
		cp a, high(wEntity0) + NB_ENTITIES
		jr nz, .loop
		pop bc
		ret

	.spawn
		call SpawnEntity
	pop bc
	ld l, low(wEntity0_SpriteY + 1)
	ld [hl], c
	inc hl
	inc hl
	ld a, b
	ld [hli], a
	ld [hli], a
	ld [hl], c
	ret

section "Get Max Health", rom0
; This function encapsulates the maximum level formula, allowing it to
; be easily changed in the future.
; @param a: Level
; @return hl: Max Health
GetMaxHealth::
	; The current formula is 16 + level * 4
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	ld a, 16
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ret

section "Get Experience Target", rom0
; This function encapsulates the experience target formula, allowing it to
; be easily changed in the future.
; @param a: Level
; @return hl: Max Health
; @clobbers bc
GetXpTarget::
	; The current formula is 12 * level * level
	ld b, 0
	ld c, a
	ld hl, 0
.square
	add hl, bc
	dec a
	jr nz, .square
	ld b, h
	ld c, l
	add hl, hl ; hl * 2
	add hl, bc ; hl * 3
	add hl, hl ; hl * 6
	add hl, hl ; hl * 12
	ret

section "Get Experience Reward", rom0
; This function encapsulates the experience reward formula, allowing it to
; be easily changed in the future.
; @param a: Level
; @return a: Reward
GetXpReward::
	ld b, a
	; The current formula is 15 + 8 * level
	add a, a ; a * 2
	add a, a ; a * 4
	add a, b ; a * 5
	add a, a ; a * 10
	add a, 15
	ret

section "Check for Level Up", romx
; @param h: Entity high byte
; @param c: Set if check succeeded
xCheckForLevelUp::
	ld l, low(wEntity0_Level)
	ld a, [hl]
	push hl
		call GetXpTarget
		ld d, h
		ld e, l
	pop hl
	ld c, 0
	ld l, low(wEntity0_Experience + 1)
	ld a, d
	cp a, [hl]
	jr c, .levelUp
	ret nz
	dec hl
	ld a, e
	cp a, [hl]
	ret nc
.levelUp
	ld l, low(wEntity0_Experience)
	xor a, a
	ld [hli], a
	ld [hl], a
	ld l, low(wEntity0_Level)
	ld a, [hl]
	cp a, ENTITY_MAXIMUM_LEVEL
	ret z
	inc c ; ld c, 1
	inc [hl]
	ld a, h
	ld [wfmt_xLeveledUpString_target], a
	ld a, [hl]
	ld [wfmt_xLeveledUpString_level], a
	push bc
		call UpdateMoves
		ld a, c
	pop bc

	and a, a
	jr z, .noNewMoves
	dec e
	dec e
	dec e
	ld a, e
	cp a, low(wEntity0_Moves) - 3
	jr nz, :+
	ld e, low(wEntity0_Moves) + (ENTITY_MOVE_COUNT - 1) * 3
:
	ld hl, wfmt_xLeveledUpString_moveName
	ld a, [de]
	ld [hli], a
	inc e
	ld a, [de]
	ld b, a
	inc e
	ld a, [de]
	ld d, a
	ld a, b
	add a, Move_Name
	ld [hli], a
	ld e, a
	adc a, d
	sub a, e
	ld [hli], a

	ld a, 1
.noNewMoves
	ld [wfmt_xLeveledUpString_newMove], a
	ld b, bank(xLeveledUpString)
	ld hl, xLeveledUpString
	call PrintHUD
	ld a, SFX_COMPLETE
	jp audio_play_fx

section "Entity take damage", rom0
; @param e: Damage
; @param h: entity index
; @clobbers: b, l
DamageEntity::
	ld l, low(wEntity0_Health)
	ld a, [hl]
	sub a, e
	ld [hli], a
	ld a, [hl]
	sbc a, 0
	ld [hl], a

	ld b, h
	ld hl, wEntityAnimation
	ld a, low(EntityHurtAnimation)
	ld [hli], a
	ld a, high(EntityHurtAnimation)
	ld [hli], a
	ld a, low(DefeatCheck)
	ld [hli], a
	ld a, high(DefeatCheck)
	ld [hli], a
	ld [hl], b
	ld a, b
	ld [wDefeatCheckTarget], a
	ret

section "Check for new moves", rom0
; @param h: Entity high byte
; @return c: Set if any moves were new to the current level.
; @return de: pointer to last move slot, subtract 4 and account for wrapping to get the new move.
; @clobbers b, de, hl
; @preserves bank
UpdateMoves::
	ldh a, [hCurrentBank]
	push af

	; Iterate through each of the entity's moves and learn every move up to the
	; current level.
	ld d, h
	ld l, low(wEntity0_Level)
	ld b, [hl]
	inc b
	ld l, low(wEntity0_Bank)
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, EntityData_MoveTable
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld e, low(wEntity0_Moves)
	ld c, 0
.loop
	ld a, [hli]
	and a, a 
	jp z, BankReturn
	cp a, b
	jp nc, BankReturn
	inc a
	cp a, b
	jr nz, :+
	ld c, 1
:
	ld a, [hli]
	ld [de], a
	inc e
	ld a, [hli]
	ld [de], a
	inc e
	ld a, [hli]
	ld [de], a
	inc e
	ld a, low(wEntity0_Moves) + ENTITY_MOVE_COUNT * 3
	cp a, e
	jr nz, .loop
	ld e, low(wEntity0_Moves)
	jp .loop

section "Heal Entity", rom0
; @param b: entity high byte
; @param e: Heal amount
HealEntity::
	ld c, low(wEntity0_Level)
	ld a, [bc]
	call GetMaxHealth
	assert Entity_Level + 1 == Entity_Health
	inc c
	ld a, [bc]
	inc c
	add a, e
	ld e, a
	ld a, [bc]
	adc a, 0
	ld d, a
	cp a, h
	jr z, :+
	jr nc, .hitMax
:
	ld a, e
	cp a, l
	jr z, .heal
	jr nc, .hitMax
.heal
	ld a, d
	ld [bc], a
	dec c
	ld a, e
	ld [bc], a
	ret
.hitMax
	ld d, h
	ld e, l
	jr .heal

; This loop creates page-aligned entity structures. This is a huge benefit to
; the engine as it allows very quick structure seeking and access.
for I, NB_ENTITIES
	section "Entity {I}", wram0[$C100 - sizeof_Entity + I * $100]
	if I == 0
wAllies::
	elif I == 3
wEnemies::
	endc
		dstruct Entity, wEntity{d:I}
endr

; This "BSS" section is used to 0-init private vars from another TU.
section FRAGMENT "dungeon BSS", wram0
; The next entity to be processed.
wActiveEntity:: db
wMoveEntityCounter: db
