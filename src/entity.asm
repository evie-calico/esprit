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
.next
	ld a, [wActiveEntity]
	inc a
	cp a, NB_ENTITIES
	jr nz, :+
	xor a, a
:   ld [wActiveEntity], a
	jr .loop

SECTION "Entity Logic", ROMX
xPlayerLogic:
	; If any movement is queued, the player should refuse to take its turn to
	; allow all sprites to catch up.
	ld a, [wMovementQueued]
	and a, a
	jr z, .noHide
	xor a, a
	ld [wShowMoves], a
	ret

.noHide
	call ItemCheck
PUSHS
SECTION "Item Check", ROM0
ItemCheck:
	; First, check if we're standing on an item.
	ld a, [wEntity0_PosX]
	ld b, a
	ld a, [wEntity0_PosY]
	ld c, a
	bankcall xGetMapPosition
	ld a, [de]
	sub a, TILE_ITEMS
	ret c
	ASSERT TILE_CLEAR == 0
	push af
		xor a, a
		ld [de], a
		push de
			; Calculate the VRAM destination by (Camera >> 4) / 16 % 16 * 32
			ld a, c
			and a, %00001111
			ld e, 0
			srl a
			rr e
			rra
			rr e
			ld d, a
			; hl = (Camera >> 8) & 15 << 4
			ld hl, $9800
			add hl, de ; Add to VRAM
			ld a, b
			and a, %00001111
			add a, a
			; Now we have the neccessary X index on the tilemap.
			add a, l
			ld l, a
			adc a, h
			sub a, l
			ld h, a
		pop de
		bankcall xDrawTile
	pop bc
	call GetDungeonItem
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, b
	rst SwapBank
	ld [wGetItemFmt], a
	ld a, [hli]
	ld [wGetItemFmt + 1], a
	ld a, [hli]
	ld [wGetItemFmt + 2], a
	ld b, BANK(GetItemString)
	ld hl, GetItemString
	call PrintHUD
	ld a, BANK(xPlayerLogic)
	rst SwapBank
	ret
POPS
.noPickup
	; Then open the move window
	ld a, [wWindowSticky]
	and a, a
	jr nz, .sticky
.loose
	; First, check for buttons to see if the player is selecting a move.
	ldh a, [hCurrentKeys]
	bit PADB_A, a
	jr z, .movementCheck
	ld a, 1
	ld [wShowMoves], a
	jr .useMove

.sticky
	ldh a, [hCurrentKeys]
	bit PADB_A, a
	jr z, :+
	ld a, 1
	ld [wShowMoves], a
	ldh a, [hCurrentKeys]
:
	bit PADB_B, a
	jr z, :+
	xor a, a
	ld [wShowMoves], a
	jr .movementCheck
:
.useMove
	ld a, [wShowMoves]
	and a, a
	jr z, .movementCheck
	; Read the joypad to see if the player is attempting to use a move.
	call PadToDir
	; If no input is given, the player waits a frame to take its turn
	ret c
	ld b, HIGH(wEntity0)
	call UseMove
	ret z
	xor a, a
	ld [wShowMoves], a
	; End the player's turn.
	ld a, 1
	ld [wActiveEntity], a
	ret

.movementCheck
	xor a, a
	ld [wShowMoves], a
	; Read the joypad to see if the player is attempting to move.
	call PadToDir
	; If no input is given, the player waits a frame to take its turn
	ret c
	; Turn the player according to the given direction.
	ld [wEntity0_Direction], a
	; Force the player to show the walking frame.
	ld a, 1
	ld [wEntity0_Frame], a
	; Attempt to move the player.
	ld a, [wEntity0_Direction]
	ld h, HIGH(wEntity0)
	call MoveEntity
	ld a, [wMovementQueued]
	and a, a
	ret z
	; If movement was successful, end the player's turn and process the next
	; entity.
	jp ProcessEntities.next

; @param a: Contains the value of wActiveEntity
xAllyLogic:
	; Stub to immediately spend turn.
	jp ProcessEntities.next

; @param a: Contains the value of wActiveEntity
xEnemyLogic:
	add a, HIGH(wEntity0)
	ld h, a
	call TryMove
	ld a, b
	cp a, 2
	ret z
	and a, a
	jr z, .fail
	ld a, [wActiveEntity]
	inc a
	cp a, NB_ENTITIES
	jr nz, :+
	xor a, a
:   ld [wActiveEntity], a
	ret
.fail

	ld l, LOW(wEntity0_PosX)
	ld a, [hli]
	ld b, a
	ld c, [hl]
	; Determine the distance to the target and two best directions to move in.
	call GetClosestAlly
	; Determine best directions
	ld a, d
	; abs a
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	ld b, a

	ld a, e
	; abs a
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	cp a, b
	jr c, .xCloser
.yCloser
	bit 7, e
	jr z, :+
	xor a, a
	jr .storeBestY
:	ld a, DOWN
.storeBestY
	ld [wBestDir], a
	; Now check X, but store it as the second best.
	bit 7, d
	jr z, :+
	ld a, LEFT
	jr .store2ndBest
:	ld a, RIGHT
	jr .store2ndBest

.xCloser
	bit 7, d
	jr z, :+
	ld a, LEFT
	jr .storeBestX
:	ld a, RIGHT
.storeBestX
	ld [wBestDir], a
	; Now check X, but store it as the second best.
	bit 7, e
	jr z, :+
	xor a, a
	jr .store2ndBest
:	ld a, DOWN
	jr .store2ndBest

.store2ndBest
	ld [wNextBestDir], a

	; Now it's time to attempt movement.
	ld a, [wActiveEntity]
	add a, HIGH(wEntity0)
	ld h, a
	ld a, [wBestDir]
	ld d, a
	call TryStep
	jp c, ProcessEntities.next
	ld a, [wNextBestDir]
	ld d, a
	call TryStep
	jp c, ProcessEntities.next
	ld a, [wBestDir]
	add a, 2
	and a, %11
	ld d, a
	call TryStep
	jp c, ProcessEntities.next
	ld a, [wNextBestDir]
	add a, 2
	and a, %11
	ld d, a
	call TryStep
	jp ProcessEntities.next

SECTION "Try Move", ROM0
; @param h: high byte of entity pointer
; @return b: 0 if failed, 1 if success, 2 if waiting
; @preserves h
TryMove:
	ldh a, [hCurrentBank]
	push af

	ld l, LOW(wEntity0_PosX)
	ld a, [hli]
	ld b, a
	ld c, [hl]

	; Determine the distance to the target.
	push hl
	call GetClosestAlly
	pop hl

	; We can't be close enough for a move unless one of the distances is a 0
	ld a, d
	and a, a
	jr z, :+
	ld a, e
	and a, a
	ld b, 0
	jp nz, BankReturn
:

	ld a, -1
	ld [wStrongestValidMove], a
	xor a, a
	ld [wStrongestValidMove.strength], a
	ld [hCurrentMoveCounter], a
	ld l, LOW(wEntity0_Moves)
.loop
	ld a, [hli]
	and a, a
	jr nz, :+
		inc hl
		inc hl
		jr .next
:
	rst SwapBank
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ASSERT Move_Range == 4
	inc hl
	inc hl
	inc hl
	inc hl
	; When comparing distances, use the absolute value.
	ld a, d
	bit 7, a
	jr z, :+
	cpl
	inc a
:	dec a
	cp a, [hl]
	jr c, .found
	ld a, d
	bit 7, a
	jr z, :+
	cpl
	inc a
:	dec a
	cp a, [hl]
	jr nc, .popNext
.found
	ld a, [wStrongestValidMove]
	cp a, -1
	jr z, .strongest
	ld a, [wStrongestValidMove.strength]
	inc hl
	ASSERT Move_Range + 1 == Move_Power
	cp a, [hl]
	jr nc, .popNext ; If the move's power is greater, set it as the strongest move.
.strongest
	ldh a, [hCurrentMoveCounter]
	ld [wStrongestValidMove], a
	ld a, [hl]
	ld [wStrongestValidMove.strength], a
.popNext
	pop hl
	inc hl
.next
	ldh a, [hCurrentMoveCounter]
	inc a
	ldh [hCurrentMoveCounter], a
	cp a, ENTITY_MOVE_COUNT
	jr nz, .loop
.done
	ld a, [wStrongestValidMove]
	inc a ; cp a, -1
	ld b, a ; ld b, 0 (if a is zero, since the value of b only matters in that case)
	jp z, BankReturn

	; After doing all this work to find out if we can use a move in the first place...
	; ...fail if there is a pending movement.
	ld a, [wMovementQueued]
	and a, a
	ld b, 2
	jp nz, BankReturn

	ld l, LOW(wEntity0_Direction)
	; Determine best directions
	ld a, d
	; abs a
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	ld b, a
	ld a, e
	; abs a
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	cp a, b
	jr c, .xCloser
.yCloser
	bit 7, e
	jr z, :+
	xor a, a
	jr .storeBestY
:	ld a, DOWN
.storeBestY
	ld [hl], a
	jr .useMove
.xCloser
	bit 7, d
	jr z, :+
	ld a, LEFT
	jr .storeBestX
:	ld a, RIGHT
.storeBestX
	ld [hl], a

.useMove
	ld a, [wStrongestValidMove]
	ld b, h
	call UseMove
	ld b, 1
	jp BankReturn

SECTION "Get item String", ROMX
GetItemString:
	db "Picked up "
	textcallptr wGetItemFmt
	db ".", 0

SECTION "Get Item fmt", WRAM0
wGetItemFmt: ds 3

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

SECTION "Try Step", ROM0
; @param d: direction
; @param h: entity high byte
; @clobbers: a, bc, de, l
; @return carry: set upon success.
TryStep:
	ld l, LOW(wEntity0_Direction)
	ld a, d
	add a, 2
	and a, %11
	cp a, [hl]
	jr z, .fail

	; Try to move
	ld l, LOW(wEntity0_Direction)
	ld [hl], d
	ld a, d
	call MoveEntity
	and a, a
	jr nz, .fail
	scf
	ret

.fail
	xor a, a
	ret

SECTION "Get Closest Ally", ROM0
; @param b: X position
; @param c: Y position
; @clobbers l
; @returns d: X distance
; @returns e: Y distance
; @returns h: Target high byte
GetClosestAlly:
	xor a, a
	ld [wClosestAllyTemp], a
	ld h, HIGH(wEntity0)
	lb de, 64, 64 ; An impossible distance, but not too high.
.loop
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .next
	ld l, LOW(wEntity0_PosX)
	; Compare total distances first.
	ld a, [hli]
	add a, [hl]
	sub a, b
	sub a, c
	; abs a
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	; a = abs((X + Y) - (TX - TY))
	; Use l as a scratch register
	ld l, a
	ld a, d
	add a, e
	; abs a
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	; a = abs(total distance)
	cp a, l
	jr c, .next ; If the new position is more steps away, don't switch to it.

	; Set new distance
	ld l, LOW(wEntity0_PosX)
	ld a, [hli]
	sub a, b
	ld d, a
	ld a, [hl]
	sub a, c
	ld e, a
	ld a, h
	ld [wClosestAllyTemp], a

.next
	inc h
	ld a, h
	cp a, HIGH(wEntity0) + NB_ALLIES
	jp nz, .loop
	ld a, [wClosestAllyTemp]
	ld h, a
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

SECTION "Move entity", ROM0
; @param a: Direction to move in.
; @param h: High byte of entity.
; @returns a: Nonzero if the movement failed.
; @clobbers: bc, de, l
; @preserves: h
MoveEntity:
	add a, a
	add a, LOW(DirectionVectors)
	ld e, a
	adc a, HIGH(DirectionVectors)
	sub a, e
	ld d, a
	ld l, LOW(wEntity0_PosX)
	ld a, [de]
	add a, [hl]
	ld b, a
	inc de
	inc l
	ASSERT Entity_PosX + 1 == Entity_PosY
	ld a, [de]
	add a, [hl]
	ld c, a
	; bc now equals the target position. Let's check if it's valid!
	push hl
	bankcall xGetMapPosition
	pop hl
	ld a, [de]
	cp a, TILE_WALL
	jr z, .fail
	push hl
	bankcall xCheckForEntity
	ld a, h
	and a, a
	pop hl
	jr nz, .fail
	; Move!
	ld a, c
	ld [hld], a
	ASSERT Entity_PosY - 1 == Entity_PosX
	ld a, b
	ld [hl], a
	ld a, 1
	ld [wMovementQueued], a
	xor a, a
	ret
.fail
	ld a, 1
	ret

SECTION "Check for entity", ROMX
; Checks for an entity at a given position, returning its index if found.
; Otherwise, returns 0.
; @param b: X position
; @param c: Y position
; @return h: index, or 0 upon failure.
; @preserves b, c, d, e
xCheckForEntity::
	xor a, a
	ld [wMoveEntityCounter], a
	ld h, HIGH(wEntity0)
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
	ld a, h
	cp a, HIGH(wEntity0) + NB_ENTITIES
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
		ld l, LOW(wEntity0_SpriteY + 1)
		ld [hl], DUNGEON_HEIGHT / 2
		inc l
		inc l
		ld [hl], DUNGEON_WIDTH / 2
		inc l
		ld [hl], DUNGEON_WIDTH / 2
		inc l
		ld [hl], DUNGEON_HEIGHT / 2
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
	ld a, b
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

	jp BankReturn

SECTION "Get Max Health", ROM0
; This function encapsulates the maximum level formula, allowing it to
; be easily changed in the future.
; @param a: Level
; @return hl: Max Health
GetMaxHealth::
	; The current formula is 10 + level * 4
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	ld a, 10
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ret

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
SECTION "entity.asm BSS", WRAM0
; The next entity to be processed.
wActiveEntity: db
wMoveEntityCounter: db

SECTION "Movement Queued", WRAM0
; nonzero if any entity is ready to move.
wMovementQueued: db

SECTION "Show Moves", WRAM0
wShowMoves:: db

SECTION "Pathfinding vars", WRAM0
wClosestAllyTemp: db
wBestDir: db
wNextBestDir: db
wStrongestValidMove: db
.strength: db

SECTION "Volatile", HRAM
hCurrentMoveCounter: db
