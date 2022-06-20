INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"
INCLUDE "text.inc"

DEF FOLLOWER_DISTANCE EQU 4

SECTION "Entity Logic", ROMX
xPlayerLogic::
	; If any movement is queued, the player should refuse to take its turn to
	; allow all sprites to catch up.
	ld a, [wMovementQueued]
	and a, a
	jr z, .noHide
	xor a, a
	ld [wWindowMode], a
	ret

.noHide
	ld a, [wHasCheckedForItem]
	and a, a
	call z, StandingCheck
PUSHS
SECTION "Standing Check", ROM0
StandingCheck:
	inc a
	ld [wHasCheckedForItem], a
	; First, check if we're standing on an item.
	ld a, [wEntity0_PosX]
	ld b, a
	ld a, [wEntity0_PosY]
	ld c, a
	bankcall xGetMapPosition
	ld a, [de]
	cp a, TILE_EXIT
	jr z, .nextFloor
	sub a, TILE_ITEMS
	ret c
	ld b, a
	push de ; This address is needed in case the pickup succeeds.
		call PickupItem
	pop de
	jr z, .full
	ASSERT TILE_CLEAR == 0
	push bc
	push hl
		xor a, a
		ld [de], a
		push de
			; Calculate the VRAM destination by (Camera >> 4) / 16 % 16 * 32
			ld a, [wEntity0_PosY]
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
			ld a, [wEntity0_PosX]
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
	pop hl
	pop bc
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

.full
	ld b, BANK(FullBagString)
	ld hl, FullBagString
	call PrintHUD
	ld a, BANK(xPlayerLogic)
	rst SwapBank
	ret

.nextFloor
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, Dungeon_FloorCount
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	ld hl, wDungeonCurrentFloor
	inc [hl]
	cp a, [hl]
	jp z, Initialize
	ld a, 1
	ld [wIsDungeonFading], a
	ld a, LOW(.generateFloor)
	ld [wDungeonFadeCallback], a
	ld a, HIGH(.generateFloor)
	ld [wDungeonFadeCallback + 1], a
	; Set palettes
	ld a, %11111111
	ld [wBGPaletteMask], a
	ld a, %11111111
	ld [wOBJPaletteMask], a
	ld a, 20
	ld [wFadeSteps], a
	ld a, $80
	ld [wFadeAmount], a
	ld a, 4
	ld [wFadeDelta], a

	pop af ; super return
	ld a, BANK(xPlayerLogic)
	rst SwapBank
	ret

.generateFloor
	ld b, BANK(FoundExit)
	ld hl, FoundExit
	call PrintHUD

	ASSERT DUNGEON_HEIGHT / 2 == DUNGEON_WIDTH / 2
	ld a, DUNGEON_WIDTH / 2
	ld hl, wEntity0_SpriteY + 1
	ld [hli], a
	inc l
	ld [hli], a
	ld [hli], a
	ld [hl], a
	inc h
	ld [hld], a
	ld [hld], a
	ld [hld], a
	dec l
	ld [hl], a
	inc h
	ld [hli], a
	inc l
	ld [hli], a
	ld [hli], a
	ld [hl], a

	call DungeonGenerateFloor
	jp SwitchToDungeonState

POPS
.noPickup
	; Then open the move window
	ld a, [wWindowSticky]
	and a, a
	jr nz, .sticky
.loose
	; First, check for buttons to see if the player is selecting a move.
	ldh a, [hCurrentKeys]
	and a, PADF_A | PADF_B
	cp a, PADF_A | PADF_B
	jr nz, .notTurning
	ld a, WINDOW_TURNING
	ld [wWindowMode], a
	jr .turning

.notTurning
	ldh a, [hCurrentKeys]
	bit PADB_A, a
	jr z, .movementCheck
	ld a, WINDOW_SHOW_MOVES
	ld [wWindowMode], a
	jr .useMove

.sticky
	ldh a, [hCurrentKeys]
	bit PADB_A, a
	jr z, :+
	ld a, WINDOW_SHOW_MOVES
	ld [wWindowMode], a
	ldh a, [hCurrentKeys]
:
	bit PADB_B, a
	jr z, :+
	xor a, a
	ld [wWindowMode], a
	jr .movementCheck
:
.useMove
	; Before attempting to use a move, set the move user's team.
	xor a, a
	ldh [hMoveUserTeam], a
	ld a, [wWindowMode]
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
	ld [wWindowMode], a
	; End the player's turn.
	ld a, 1
	ld [wActiveEntity], a
	ret

.turning
	call PadToDir
	ret c
	ld [wEntity0_Direction], a
	ret

.movementCheck
	xor a, a
	ld [wWindowMode], a
	ld [wWindowMode], a

	ld a, [hCurrentKeys]
	cp a, PADF_SELECT
	ld a, 1
	jp nz, :+
	; End the player's turn.
	ld a, 1
	ld [wActiveEntity], a
	ret
:

	ld a, [hCurrentKeys]
	cp a, PADF_START
	jr nz, :+
		xor a, a
		ld [wWindowMode], a
		ld a, 1
		ld [wIsDungeonFading], a
		ld a, LOW(OpenPauseMenu)
		ld [wDungeonFadeCallback], a
		ld a, HIGH(OpenPauseMenu)
		ld [wDungeonFadeCallback + 1], a
		; Set palettes
		ld a, %11111111
		ld [wBGPaletteMask], a
		ld a, %11111111
		ld [wOBJPaletteMask], a
		ld a, 20
		ld [wFadeSteps], a
		ld a, $80
		ld [wFadeAmount], a
		ld a, 4
		ld [wFadeDelta], a
		ret
:
	; if the player is able to move, and presses select, skip their turn.
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
	ASSERT NB_ALLIES - 1 == 2
	cp a, HIGH(wEntity1)
	jr z, .swapWithAlly
	cp a, HIGH(wEntity2)
	jr z, .swapWithAlly
	ld a, [wMovementQueued]
	and a, a
	ret z
.endSwap
	; If movement was successful, end the player's turn and process the next
	; entity.
	; Signal that an item should be checked at the next opportunity.
	xor a, a
	ld [wHasCheckedForItem], a
	jp ProcessEntities.next

.swapWithAlly
	ld h, a
	sub a, HIGH(wEntity0)
	ld [wSkipAllyTurn], a
	ld l, LOW(wEntity0_PosX)
	ld de, wEntity0_PosX
	ld b, [hl]
	ld a, [de]
	ld [hli], a
	ld a, b
	ld [de], a
	inc e
	ld b, [hl]
	ld a, [de]
	ld [hli], a
	ld a, b
	ld [de], a
	ld l, LOW(wEntity0_Direction)
	ld e, l
	ld a, [de]
	add a, 2
	and a, 3
	ld [hl], a
	ld a, 1
	ld [wMovementQueued], a
	jr .endSwap

; @param a: Contains the value of wActiveEntity
; TODO: Pathfinding should consider walls; we can afford the CPU time to make
; allies smarter. (And possibly for all enemies)
xAllyLogic::
	ld hl, wSkipAllyTurn
	cp a, [hl]
	jr nz, :+
		ld [hl], 0
		jp ProcessEntities.next
:
	add a, HIGH(wEntity0)
	ld h, a
	ld l, LOW(wEntity0_PosX)
	ld a, [hli]
	ld c, [hl]
	ld b, a
	ld h, HIGH(wEntity0) + NB_ALLIES
	ld a, HIGH(wEntity0) + NB_ENTITIES
	call xGetClosestOfEntities
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
	add a, b
	cp a, FOLLOWER_DISTANCE
	jr nc, .followLeader
	push hl
	xor a, a
	ldh [hMoveUserTeam], a
	call TryMove
	pop hl
	ld a, b
	cp a, 2
	ret z
	and a, a
	jr z, .chaseEnemy
	ld a, [wActiveEntity]
	inc a
	cp a, NB_ENTITIES
	jr nz, :+
	xor a, a
:   ld [wActiveEntity], a
	ret

.chaseEnemy
	call xChaseTarget
	jp c, ProcessEntities.next
.followLeader
	ld a, [wActiveEntity]
	add a, HIGH(wEntity0)
	ld h, a
	ld l, LOW(wEntity0_PosX)
	ld a, [hli]
	ld d, a
	ld e, [hl]
	ld hl, wEntity0_PosX ; Follow the player.
	ld a, [hli]
	sub a, d
	ld d, a
	ld a, [hl]
	sub a, e
	ld e, a
	; If we are on our target, stop moving.
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	ld b, a
	ld a, d
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	add a, b
	dec a
	jp z, ProcessEntities.next

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
	; Try to move
	ld l, LOW(wEntity0_Direction)
	ld [hl], a
	call MoveEntity
	and a, a
	jp z, ProcessEntities.next
	ld a, [wNextBestDir]
	; Try to move
	ld l, LOW(wEntity0_Direction)
	ld [hl], a
	call MoveEntity
	jp ProcessEntities.next

; @param a: Contains the value of wActiveEntity
xEnemyLogic::
	add a, HIGH(wEntity0)
	ld h, a
	ld l, LOW(wEntity0_PosX)
	ld a, [hli]
	ld c, [hl]
	ld b, a
	ld h, HIGH(wEntity0)
	ld a, HIGH(wEntity0) + NB_ALLIES
	call xGetClosestOfEntities
	push hl
	ld a, 1
	ldh [hMoveUserTeam], a
	call TryMove
	pop hl
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
	call xChaseTarget
	jp ProcessEntities.next
	; Enemies take some extra steps.
	jp c, ProcessEntities.next
	ld a, [wBestDir]
	add a, 2
	and a, %11
	ld d, a
	call xTryStep
	jp c, ProcessEntities.next
	ld a, [wNextBestDir]
	add a, 2
	and a, %11
	ld d, a
	call xTryStep
	jp ProcessEntities.next

; @param d: X distance
; @param e: Y distance
xChaseTarget:
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
	call xTryStep
	ret c
	ld a, [wNextBestDir]
	ld d, a
	call xTryStep
	ret

; @param a: High byte of final entity
; @param b: X position
; @param c: Y position
; @param h: High byte of starting entity
; @clobbers l
; @returns d: X distance
; @returns e: Y distance
; @returns h: Target high byte
xGetClosestOfEntities:
	ldh [hClosestEntityFinal], a
	xor a, a
	ldh [hClosestEntityTarget], a
	lb de, 64, 64 ; An impossible distance, but not too high.
.loop
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .next
	ld l, LOW(wEntity0_PosX)
	; Compare total distances first.
	; Calculate abs(TX - X) + abs(TY - Y)
	ld a, [hli]
	sub a, b ; TX - X
	; abs a
	bit 7, a
	jr z, :+
	cpl
	inc a
:
	push af
		ld a, [hl]
		sub a, c ; TY - T
		; abs a
		bit 7, a
		jr z, :+
		cpl
		inc a
:
		ld l, a
	pop af
	add a, l ; (TX - X) + (TY - Y)

	; Use l as a scratch register
	ld l, a
	push hl
		; Calculate abs(DX) + abs(DY)
		ld a, d
		; abs a
		bit 7, a
		jr z, :+
		cpl
		inc a
:
		ld l, a
		ld a, e
		; abs a
		bit 7, a
		jr z, :+
		cpl
		inc a
:
		add a, l
	pop hl
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
	ldh [hClosestEntityTarget], a
.next
	inc h
	ldh a, [hClosestEntityFinal]
	cp a, h
	jp nz, .loop
	ldh a, [hClosestEntityTarget]
	ld h, a
	ret

; @param d: direction
; @param h: entity high byte
; @clobbers: a, bc, de, l
; @return carry: set upon success.
xTryStep:
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

SECTION "Try Move", ROM0
; @param d: X distance
; @param e: Y distance
; @param hMoveUserTeam: must be configured immediently before or after this call.
; @return b: 0 if failed, 1 if success, 2 if waiting
; @clobbers h
; @preserves de unless b==1
TryMove:
	; We can't be close enough for a move unless one of the distances is a 0
	ld a, d
	and a, a
	jr z, :+
	ld a, e
	and a, a
	ld b, 0
	ret nz
:

	ldh a, [hCurrentBank]
	push af

	ld a, -1
	ld [wStrongestValidMove], a
	xor a, a
	ld [wStrongestValidMove.strength], a
	ld [hCurrentMoveCounter], a
	ld a, [wActiveEntity]
	add a, HIGH(wEntity0)
	ld h, a
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
	ASSERT Move_Range == 2
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
	ld a, e
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

SECTION "Move entity", ROM0
; @param a: Direction to move in.
; @param h: High byte of entity.
; @returns a: 0 upon success, 1 if blocked by wall, otherwise the entity blocking movement
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
	ldh a, [hCurrentBank]
	push af
		push hl
			ld a, BANK(xGetMapPosition)
			rst SwapBank
			call xGetMapPosition
		pop hl
		ld a, [de]
		cp a, TILE_WALL
		jr z, .fail
		push hl
			ld a, BANK(xCheckForEntity)
			rst SwapBank
			ld h, HIGH(wEntity0)
			ld a, HIGH(wEntity0) + NB_ENTITIES
			call xCheckForEntity
			ld a, h
			and a, a
			jr nz, .failEntity
		pop hl
		; Move!
		ld a, c
		ld [hld], a
		ASSERT Entity_PosY - 1 == Entity_PosX
		ld a, b
		ld [hl], a
		ld a, 1
		ld [wMovementQueued], a
	pop af
	rst SwapBank
	xor a, a
	ret
.fail
	pop af
	rst SwapBank
	ld a, 1
	ret

.failEntity
	pop bc ; undo previous push hl
	pop af
	rst SwapBank
	ld a, h
	ld h, b
	ret

SECTION "Get item String", ROMX
GetItemString:
	db "Picked up "
	textcallptr wGetItemFmt
	db ".", 0

SECTION "Get Item fmt", WRAM0
wGetItemFmt: ds 3

SECTION "Full Bag", ROMX
FullBagString: db "Your bag is full.", 0

SECTION "Found exit", ROMX
FoundExit:
	db "Entered floor "
	print_u8 wDungeonCurrentFloor
	db ".", 0

SECTION "Movement Queued", WRAM0
; nonzero if any entity is ready to move.
wMovementQueued:: db

SECTION "Pathfinding vars", WRAM0
wClosestAllyTemp: db
wBestDir: db
wNextBestDir: db
wStrongestValidMove: db
.strength: db

SECTION "Get closest entity HRAM", HRAM
hClosestEntityTarget: db
hClosestEntityFinal:: db

SECTION "Volatile", HRAM
hCurrentMoveCounter: db