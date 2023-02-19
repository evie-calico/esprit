include "config.inc"
include "defines.inc"
include "dungeon.inc"
include "entity.inc"
include "hardware.inc"

; The distance from the player at which followers will give up and chase the player.
def FOLLOWER_RECALL_DISTANCE equ 2
; The distance from an enemy at which the follower will begin pursuing them.
def FOLLOWER_PURSUIT_DISTANCE equ 2

section "Entity Logic", romx
xPlayerLogic::
	ld a, [wActiveEntity]
	ld hl, wSkipAllyTurn
	cp a, [hl]
	jr nz, :+
		ld [hl], -1
		jp EndTurnContinue
:
	; If any movement is queued, the player should refuse to take its turn to
	; allow all sprites to catch up.
	ld a, [wMovementQueued]
	and a, a
	jr z, :+
		xor a, a
		ld [wWindowMode], a
		ret
	:

	ld a, [wActiveEntity]
	ld [wFocusedEntity], a

	ld hl, wHasCheckedForItem
	and a, a
	jr z, :+
		inc hl
	:
	ld a, [hl]
	and a, a
	call z, StandingCheck
PUSHS
section "Standing Check", rom0
StandingCheck:
	inc a
	ld [hl], a
	; First, check if we're standing on an item.
	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_PosX)
	assert Entity_PosX + 1 == Entity_PosY
	ld a, [hli]
	ld b, a
	ld a, [hl]
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
	assert TILE_CLEAR == 0
	push bc
	push hl
		xor a, a
		ld [de], a
		push de
			; Calculate the VRAM destination by (Camera >> 4) / 16 % 16 * 32
			ld a, [wActiveEntity]
			add a, high(wEntity0)
			ld b, a
			ld c, low(wEntity0_PosY)
			ld a, [bc]
			assert Entity_PosX + 1 == Entity_PosY
			dec c
			and a, %00001111
			ld e, 0
			srl a
			rr e
			rra
			rr e
			ld d, a
			; hl = (Camera >> 8) & 15.0
			ld hl, $9800
			add hl, de ; Add to VRAM
			ld a, [bc]
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
	ld [wfmt_xGetItemString_name], a
	ld a, [hli]
	ld [wfmt_xGetItemString_name + 1], a
	ld a, [hli]
	ld [wfmt_xGetItemString_name + 2], a
	ld b, bank(xGetItemString)
	ld hl, xGetItemString
	call PrintHUD
	ld a, bank(xPlayerLogic)
	rst SwapBank
	ret

.full
	ld b, bank(xFullBagString)
	ld hl, xFullBagString
	call PrintHUD
	ld a, bank(xPlayerLogic)
	rst SwapBank
	ret

.nextFloor
	call FloorComplete
	pop af ; super return
	ld a, bank(xPlayerLogic)
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
	jr z, .notUsingMove
	ld a, WINDOW_SHOW_MOVES
	ld [wWindowMode], a
	jr .useMove

.notUsingMove
	ldh a, [hCurrentKeys]
	bit PADB_B, a
	jr z, .movementCheck
	ld a, WINDOW_TURNING
	ld [wWindowMode], a
	jr .turning

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
	; If no input is given, check if the B button is pressed
	jr nc, :+
		ldh a, [hNewKeys]
		cp a, PADF_B
		ret nz
		ld a, [wManualControlMode]
		xor a, 1
		ld [wManualControlMode], a
		jr z, .auto
			ld b, bank(xSwitchedToManual)
			ld hl, xSwitchedToManual
			jp PrintHUD
		.auto
			ld b, bank(xSwitchedToAutomatic)
			ld hl, xSwitchedToAutomatic
			jp PrintHUD
	:
	ld c, a
	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld b, a
	ld a, c
	call UseMove
	ret z
	xor a, a
	ld [wWindowMode], a
	jp EndTurn

.turning
	call PadToDir
	ret c
	ld b, a
	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_Direction)
	ld [hl], b
	ret

.movementCheck
	xor a, a
	ld [wWindowMode], a

	; In manual mode, we need to use `hNewKeys` to make sure the player doesn't skip both character's turns
	ld a, [wManualControlMode]
	and a, a
	ld c, low(hCurrentKeys)
	jr z, :+
		assert hCurrentKeys + 1 == hNewKeys
		inc c
	:
	ldh a, [c]
	cp a, PADF_SELECT
	; By default this ends the turn, but behavior can be configured at build time.
	jp z, D_SA

	cp a, PADF_START
	jr nz, :+
		xor a, a
		ld [wWindowMode], a
		ld a, 1
		ld [wIsDungeonFading], a
		ld a, low(OpenPauseMenu)
		ld [wDungeonFadeCallback], a
		ld a, high(OpenPauseMenu)
		ld [wDungeonFadeCallback + 1], a
		; Set palettes
		ld a, %11111111
		ld [wBGPaletteMask], a
		ld a, %11111111
		ld [wOBJPaletteMask], a
		jp FadeToWhite
:
	; if the player is able to move, and presses select, skip their turn.
	; Read the joypad to see if the player is attempting to move.
	call PadToDir
	; If no input is given, the player waits a frame to take its turn
	ret c

	; Turn the player according to the given direction.
	ld b, a
	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_Direction)
	ld [hl], b
	; Force the player to show the walking frame.
	ld l, low(wEntity0_Frame)
	ld a, 1
	ld [hl], a
	; Attempt to move the player.
	ld l, low(wEntity0_Direction)
	ld a, [hl]
	call MoveEntity
	assert NB_ALLIES - 1 == 2
	cp a, high(wEntity0)
	jr z, .swapWithAlly
	cp a, high(wEntity1)
	jr z, .swapWithAlly
	cp a, high(wEntity2)
	jr z, .swapWithAlly
	ld a, [wMovementQueued]
	and a, a
	ret z
.endSwap
	; If movement was successful, end the player's turn and process the next
	; entity.
	; Signal that an item should be checked at the next opportunity.
	ld hl, wHasCheckedForItem
	ld a, [wActiveEntity]
	and a, a
	jr z, :+
		inc hl
		xor a, a
	:
	ld [hl], a
	jp EndTurnContinue

.swapWithAlly
	ld h, a
	sub a, high(wEntity0)
	ld [wSkipAllyTurn], a
	ld l, low(wEntity0_PosX)
	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld d, a
	ld e, low(wEntity0_PosX)
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
	ld l, low(wEntity0_Direction)
	ld e, l
	ld a, [de]
	add a, 2
	and a, 3
	ld [hl], a
	ld a, 1
	ld [wMovementQueued], a
	jr .endSwap

; TODO: Pathfinding should consider walls; we can afford the CPU time to make
; allies smarter. (And possibly for all enemies)
xAllyLogic::
	ld a, [wActiveEntity]
	ld hl, wSkipAllyTurn
	cp a, [hl]
	jr nz, :+
		ld [hl], -1
		jp EndTurnContinue
:
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_PosX)
	ld a, [hli]
	ld c, [hl]
	ld b, a

	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	inc a
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
	cp a, FOLLOWER_RECALL_DISTANCE
	jr nc, .followLeader

	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_PosX)
	ld a, [hli]
	ld c, [hl]
	ld b, a
	ld h, high(wEntity0) + NB_ALLIES
	ld a, high(wEntity0) + NB_ENTITIES
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
	cp a, FOLLOWER_PURSUIT_DISTANCE
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
	jp nz, EndTurn
.chaseEnemy
	call xChaseTarget
	jp c, EndTurnContinue
.followLeader
	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_PosX)
	ld a, [hli]
	ld d, a
	ld e, [hl]
	ld a, [wActiveEntity]
	xor a, 1
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_PosX)
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
	jp z, EndTurnContinue

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
	add a, high(wEntity0)
	ld h, a
	ld a, [wBestDir]
	; Try to move
	ld l, low(wEntity0_Direction)
	ld [hl], a
	call MoveEntity
	and a, a
	jp z, EndTurnContinue
	ld a, [wNextBestDir]
	; Try to move
	ld l, low(wEntity0_Direction)
	ld [hl], a
	call MoveEntity
	jp EndTurnContinue

; @param a: Contains the value of wActiveEntity
xEnemyLogic::
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_PosX)
	ld a, [hli]
	ld c, [hl]
	ld b, a
	ld h, high(wEntity0)
	ld a, high(wEntity0) + NB_ALLIES
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
	jp EndTurnContinue
	; Enemies take some extra steps.
	jp c, EndTurnContinue
	ld a, [wBestDir]
	add a, 2
	and a, %11
	ld d, a
	call xTryStep
	jp c, EndTurnContinue
	ld a, [wNextBestDir]
	add a, 2
	and a, %11
	ld d, a
	call xTryStep
	jp EndTurnContinue

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
	add a, high(wEntity0)
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
	ld l, low(wEntity0_Bank)
	ld a, [hli]
	and a, a
	jr z, .next
	ld l, low(wEntity0_PosX)
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
	ld l, low(wEntity0_PosX)
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
	ld l, low(wEntity0_Direction)
	ld a, d
	add a, 2
	and a, %11
	cp a, [hl]
	jr z, .fail

	; Try to move
	ld l, low(wEntity0_Direction)
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

section "Try Move", rom0
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

	xor a, a
	ld [hCurrentMoveCounter], a
	ld a, [wActiveEntity]
	add a, high(wEntity0)
	ld h, a
	ld l, low(wEntity0_Moves)
	; b = valid move queue (4 bits, 1 = available)
	; c = valid move count (used by rand range to select move)
	ld bc, 0
.loop
	ld a, [hli]
	and a, a
	jr nz, :+
		inc hl
		inc hl
		; and a, a luckily clears carry.
		jr .next
:
	rst SwapBank
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	assert Move_Range == 2
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
	; The value of `nc` at this point is *very important*!!!!!!!
	jr nc, .popNext
.found
	; This move is valid.
	inc c ; increment move count
	scf ; Add it to the queue by setting move bit
.popNext
	pop hl
	inc hl
.next
	; shift the carry bit in.
	; Only two paths can reach this code, passing either `c` (valid) or `nc`.
	rl b
	ldh a, [hCurrentMoveCounter]
	inc a
	ldh [hCurrentMoveCounter], a
	cp a, ENTITY_MOVE_COUNT
	jr nz, .loop
.done
	ld a, b
	ldh [hMoveQueue], a
	ld a, c
	and a, a
	ld b, a ; ld b, 0 (if a is zero, since the value of b only matters in that case)
	jp z, BankReturn

	; After doing all this work to find out if we can use a move in the first place...
	; ...fail if there is a pending movement.
	ld a, [wMovementQueued]
	and a, a
	ld b, 2
	jp nz, BankReturn

	; Now convert b and c into a move selection
	push hl
	push de
	ld h, 0
	ld a, c
	; adjust the move count to be within rand range's bounds.
	; if the index is 0 then we need to skip the call entirely.
	dec a
	ld l, a ; the number of moves - 1; the upper bound.
	call nz, RandRange
	; adjust up so `dec b` sets `z`
	inc a
	; b = random move index
	ld b, a
	; a = move queue
	ldh a, [hMoveQueue]
	; c = current move
	ld c, 4
.moveQueue
	; count the move we're on; important for skipping gaps.
	; since we're going through the queue backwards, we start at the last move.
	dec c 
	; loop through move queue to resolve gaps.
	rra
	jr nc, .moveQueue ; If the move is invalid, just skip this bit.
	; if it is valid, decrement the selected move.
	dec b
	jr nz, .moveQueue
	; At this point, `c` is our chosen move.
	; it's not clobbered in the following code, so leave it where it is.

	pop de
	pop hl

	ld l, low(wEntity0_Direction)
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
	; finally load the chosen move
	ld a, c
	ld b, h
	call UseMove
	ld b, 1
	jp BankReturn

section "Move entity", rom0
; @param a: Direction to move in.
; @param h: High byte of entity.
; @returns a: 0 upon success, 1 if blocked by wall, otherwise the entity blocking movement
; @clobbers: bc, de, l
; @preserves: h
MoveEntity:
	add a, a
	add a, low(DirectionVectors)
	ld e, a
	adc a, high(DirectionVectors)
	sub a, e
	ld d, a
	ld l, low(wEntity0_PosX)
	ld a, [de]
	add a, [hl]
	ld b, a
	inc de
	inc l
	assert Entity_PosX + 1 == Entity_PosY
	ld a, [de]
	add a, [hl]
	ld c, a
	; bc now equals the target position. Let's check if it's valid!
	ldh a, [hCurrentBank]
	push af
		push hl
			ld a, bank(xGetMapPosition)
			rst SwapBank
			call xGetMapPosition
		pop hl
		ld a, [de]
		cp a, TILE_WALL
		jr z, .fail
		push hl
			ld a, bank(xCheckForEntity)
			rst SwapBank
			ld h, high(wEntity0)
			ld a, high(wEntity0) + NB_ENTITIES
			call xCheckForEntity
			ld a, h
			and a, a
			jr nz, .failEntity
		pop hl
		; Move!
		ld a, c
		ld [hld], a
		assert Entity_PosY - 1 == Entity_PosX
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

section "Movement Queued", wram0
; nonzero if any entity is ready to move.
wMovementQueued:: db

section "Pathfinding vars", wram0
wClosestAllyTemp: db
wBestDir: db
wNextBestDir: db
wChosenMove: db

section "Get closest entity hram", hram
hClosestEntityTarget: db
hClosestEntityFinal:: db

section "Volatile", hram
; this is a union
hMoveQueue:
hCurrentMoveCounter:
	db

section fragment "dungeon BSS", wram0
wMovementToggleWatch: db
wManualControlMode:: db
; Who is controlled in automatic mode?
; By switching to manual when the ally is selected, the user can switch who they play as.
; TODO: When exiting a level, reorder the party to put the tracked entity first.
wTrackedEntity:: db
; Who is the camera pointed at?
wFocusedEntity:: db
; True if the player has already checked for an item on this tile.
wHasCheckedForItem:: ds 2 ; one for each character
