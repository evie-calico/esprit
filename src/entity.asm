INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"
INCLUDE "text.inc"

; How fast the entity should move during animations. Should be a power of two.
DEF MOVEMENT_SPEED EQU 16
DEF RUNNING_SPEED EQU 64

SECTION "Process entities", ROM0
; Iterate through the entities.
; The individual logic functions can choose to return on their own to end logic
; processing. This is used to queue up movements to occur simultaneuously.
ProcessEntities::
	ld a, BANK("Entity Logic")
	rst SwapBank
	ld a, [wMoveEntityCounter]
	and a, a
	ret nz
	ld a, [wActiveEntity]
.loop
	add a, HIGH(wEntity0)
	ld h, a
	ld l, LOW(wEntity0_Bank)
	ld a, [hl]
	and a, a
	jr z, .next
	ld a, [wActiveEntity]
	and a, a
	jp z, xPlayerLogic
	cp a, NB_ALLIES
	jp c, xAllyLogic
	jp xEnemyLogic
; All entity logic jumps here to end their turn.
.next::
	ld a, [wActiveEntity]
	inc a
	cp a, NB_ENTITIES
	jr nz, :+
	xor a, a
:   ld [wActiveEntity], a
	jr .loop

SECTION "Move entities", ROMX
xMoveEntities::
	xor a, a
	ld [wMoveEntityCounter], a
	ld b, MOVEMENT_SPEED
	ld h, HIGH(wEntity0)
.loop
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .skip
.yCheck
	ld l, LOW(wEntity0_PosY)
	ld d, [hl]
	; DE: Target position in 12.4
	; [HL]: Sprite position
	; Compare the positions to check if they need to be interpolated.
	ld l, LOW(wEntity0_SpriteY + 1)
	ld a, [hld]
	cp a, d
	jr z, .yCheckLow
	jr c, .yGreater
	; Fallthrough to yLesser.
.yLesser
	ld l, LOW(wEntity0_SpriteY)
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
	ld l, LOW(wEntity0_SpriteY)
	ld a, [hl]
	add a, b
	ld [hli], a
	jr nc, .next
	inc [hl]
	jr .next

.xCheck
	ld l, LOW(wEntity0_PosX)
	ld d, [hl]
	; DE: Target position in 12.4
	; [HL]: Sprite position
	; Compare the positions to check if they need to be interpolated.
	ld l, LOW(wEntity0_SpriteX + 1)
	ld a, [hld]
	cp a, d
	jr z, .xCheckLow
	jr c, .xGreater
	; Fallthrough to xLesser.
.xLesser
	ld l, LOW(wEntity0_SpriteX)
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
	ld l, LOW(wEntity0_SpriteX)
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
:   ld l, LOW(wEntity0_Frame)
	ld [hl], a
	inc h
	ld a, h
	cp a, HIGH(wEntity0) + NB_ENTITIES
	jr nz, .loop
	ld a, [wMoveEntityCounter]
	ld [wMovementQueued], a
	ret

SECTION "Step in direction", ROM0
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

SECTION "Joypad to direction", ROM0
; Reads hCurrentKeys and returns the currently selected pad direction in A.
; If no direction is selected, sets the carry flag.
PadToDir::
	xor a, a ; Clear carry flag
	ldh a, [hCurrentKeys]
	bit PADB_UP, a
	jr z, :+
	ASSERT UP == 0
	xor a, a
	ret
:	bit PADB_RIGHT, a
	jr z, :+
	ld a, 1
	ret
:	bit PADB_DOWN, a
	jr z, :+
	ld a, 2
	ret
:	bit PADB_LEFT, a
	jr z, :+
	ld a, 3
	ret
:	scf
	ret

SECTION "Check for entity", ROMX
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
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .next
	ld l, LOW(wEntity0_PosX)
	ld a, b
	cp a, [hl]
	jr nz, .next
	ASSERT Entity_PosX + 1 == Entity_PosY
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

SECTION "Direction vectors", ROM0
; An array of vectors used to offset positions using a direction.
DirectionVectors::
	db 0, -1
	db 1, 0
	db 0, 1
	db -1, 0

SECTION "Spawn entity", ROM0
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
		ld l, LOW(wEntity0)
		ld c, sizeof_Entity
		call MemSetSmall
		dec h ; correct high byte (MemSet causes it to overflow)
		ASSERT DUNGEON_HEIGHT / 2 == DUNGEON_WIDTH / 2
		ld a, DUNGEON_WIDTH / 2
		ld l, LOW(wEntity0_SpriteY + 1)
		ld [hli], a
		inc l
		ld [hli], a
		ld [hli], a
		ld [hli], a
		ld a, b
		rst SwapBank
		ld l, LOW(wEntity0_Bank)
		ld [hli], a
		ASSERT Entity_Bank + 1 == Entity_Data
		ld a, e
		ld [hli], a
		ld a, d
		ld [hli], a
	pop bc

	; Set level
	ld l, LOW(wEntity0_Level)
	ld a, c
	ld [hli], a

	; Use level to determine health.
	ASSERT Entity_Level + 1 == Entity_Health
	push hl
		call GetMaxHealth
		ld a, l
		ld b, h
	pop hl
	ld [hli], a
	ld [hl], b

	push hl
		call UpdateMoves
	pop hl

	jp BankReturn

SECTION "Spawn Enemy", ROM0
SpawnEnemy::
	call Rand
	and a, 63
	ld b, a
	ld a, e
	and a, 63
	ld c, a
	ASSERT DUNGEON_WIDTH * 4 == 256
	add a, a ; a * 2
	add a, a ; a * 4
	ld l, a
	ld h, 0
	add hl, hl ; a * 8
	add hl, hl ; a * 16
	add hl, hl ; a * 32
	add hl, hl ; a * 64
	ASSERT DUNGEON_WIDTH == 64
	ld de, wDungeonMap
	add hl, de
	ld a, b
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	ASSERT TILE_CLEAR == 0
	and a, a
	jr nz, SpawnEnemy
	; b = X
	; c = Y

	push bc
		call Rand
		and a, 7
		ASSERT sizeof_SpawnEntityInfo == 4
		add a, a
		add a, a
		add a, Dungeon_Entities
		ASSERT sizeof_Dungeon < 256
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
		ld h, HIGH(wEntity0) + NB_ALLIES
	.loop
		ld l, LOW(wEntity0_Bank)
		ld a, [hli]
		and a, a
		jr z, .spawn
		inc h
		ld a, h
		cp a, HIGH(wEntity0) + NB_ENTITIES
		jr nz, .loop
		pop bc
		ret

	.spawn
		call SpawnEntity
	pop bc
	ld l, LOW(wEntity0_SpriteY + 1)
	ld [hl], c
	inc hl
	inc hl
	ld a, b
	ld [hli], a
	ld [hli], a
	ld [hl], c
	ret

SECTION "Get Max Health", ROM0
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

SECTION "Get Experience Target", ROM0
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

SECTION "Get Experience Reward", ROM0
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

SECTION "Check for Level Up", ROMX
; @param h: Entity high byte
; @param c: Set if check succeeded
xCheckForLevelUp::
	ld l, LOW(wEntity0_Level)
	ld a, [hl]
	push hl
		call GetXpTarget
		ld d, h
		ld e, l
	pop hl
	ld c, 0
	ld l, LOW(wEntity0_Experience + 1)
	ld a, d
	cp a, [hl]
	jr c, .levelUp
	ret nz
	dec hl
	ld a, e
	cp a, [hl]
	ret nc
.levelUp
	ld l, LOW(wEntity0_Experience)
	xor a, a
	ld [hli], a
	ld [hl], a
	ld l, LOW(wEntity0_Level)
	ld a, [hl]
	cp a, ENTITY_MAXIMUM_LEVEL
	ret z
	inc c ; ld c, 1
	inc [hl]
	ld a, h
	ld [wLevelUpText.target], a
	ld a, [hl]
	ld [wLevelUpText.level], a
	push bc
		call UpdateMoves
	pop bc

	ld a, c
	and a, a
	jr z, .noNewMoves
	dec e
	dec e
	dec e
	ld a, e
	cp a, LOW(wEntity0_Moves) - 3
	jr nz, :+
	ld e, LOW(wEntity0_Moves) + (ENTITY_MOVE_COUNT - 1) * 3
:
	ld hl, wLevelUpText.moveName
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
	ld [wLevelUpText.newMove], a
	ld b, BANK(xLeveledUpText)
	ld hl, xLeveledUpText
	jp PrintHUD

SECTION "Check for new moves", ROM0
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
	ld l, LOW(wEntity0_Level)
	ld b, [hl]
	inc b
	ld l, LOW(wEntity0_Bank)
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
	ld e, LOW(wEntity0_Moves)
	ld c, 0
.loop
	ld a, [hli]
	and a, a 
	jp z, BankReturn
	cp a, b
	jp nc, BankReturn
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
	ld a, LOW(wEntity0_Moves) + ENTITY_MOVE_COUNT * 3
	cp a, e
	jr nz, .loop
	ld e, LOW(wEntity0_Moves)
	jp .loop

SECTION "Heal Entity", ROM0
; @param b: entity high byte
; @param e: Heal amount
HealEntity::
	ld c, LOW(wEntity0_Level)
	ld a, [bc]
	call GetMaxHealth
	ASSERT Entity_Level + 1 == Entity_Health
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

SECTION "Leveled up", ROMX
xLeveledUpText:
	print_entity wLevelUpText.target
	db "'s level increased to "
	print_u8 wLevelUpText.level
	db "!"
	textcondition wLevelUpText.newMove
.newMove
	db " "
	print_entity wLevelUpText.target
	db " learned "
	textcallptr wLevelUpText.moveName
	db ".", 0

SECTION "Leveled up fmt", WRAM0
wLevelUpText:
.target db
.level db
.newMove db
.moveName ds 3

; This loop creates page-aligned entity structures. This is a huge benefit to
; the engine as it allows very quick structure seeking and access.
FOR I, NB_ENTITIES
	SECTION "Entity {I}", WRAM0[$C100 - sizeof_Entity + I * $100]
	IF I == 0
wAllies::
	ELIF I == 3
wEnemies::
	ENDC
		dstruct Entity, wEntity{d:I}
ENDR

; This "BSS" section is used to 0-init private vars from another TU.
SECTION FRAGMENT "dungeon BSS", WRAM0
; The next entity to be processed.
wActiveEntity:: db
wMoveEntityCounter: db
; True if the player has already checked for an item on this tile.
wHasCheckedForItem:: db
