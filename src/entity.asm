INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"

SECTION "Process entities", ROM0
; Iterate through the entities.
; The individual logic functions can choose to return on their own to end logic
; processing. This is used to queue up movements to occur simultaneuously.
ProcessEntities::
	ld a, [wMoveEntityCounter]
	and a, a
	ret nz
	ld a, [wActiveEntity]
.loop
	and a, a
	jp z, PlayerLogic
	cp a, NB_ALLIES
	jp c, AllyLogic
	jp EnemyLogic
.next
	ld a, [wActiveEntity]
	inc a
	cp a, NB_ENTITIES
	jr nz, :+
	xor a, a
:   ld [wActiveEntity], a
	jr .loop

SECTION "Player logic", ROM0
PlayerLogic:
	xor a, a
	ld [wShowMoves], a
	; If any movement is queued, the player should refuse to take its turn to
	; allow all sprites to catch up.
	ld a, [wMovementQueued]
	and a, a
	ret nz

	; First, check for buttons to see if the player is selecting a move.
	ldh a, [hCurrentKeys]
	bit PADB_A, a
	jr z, .movementCheck
	ld a, 1
	ld [wShowMoves], a
	; Read the joypad to see if the player is attempting to use a move.
	call PadToDir
	; If no input is given, the player waits a frame to take its turn
	ret c
	ld b, HIGH(wEntity0)
	call UseMove

	ret

.movementCheck
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
	; If movement was successful, end the player's turn and process the next
	; entity.
	ld a, [wMovementQueued]
	and a, a
	ret z
	jp ProcessEntities.next

SECTION "Ally logic", ROM0
; @param a: Contains the value of wActiveEntity
AllyLogic:
	; Stub to immediately spend turn.
	jp ProcessEntities.next

SECTION "Enemy logic", ROM0
; @param a: Contains the value of wActiveEntity
EnemyLogic:
	add a, HIGH(wEntity0)
	ld h, a
	ld l, LOW(wEntity0_Direction)
	ld a, 1
	ld [hl], a
	ld l, LOW(wEntity0_Frame)
	ld [hl], a
	call MoveEntity
	jp ProcessEntities.next

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
:   bit PADB_RIGHT, a
	jr z, :+
	ld a, 1
	ret
:   bit PADB_DOWN, a
	jr z, :+
	ld a, 2
	ret
:   bit PADB_LEFT, a
	jr z, :+
	ld a, 3
	ret
:   scf
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

SECTION "Load Entity Graphics", ROM0
; @param h: high byte of entity pointer
; @clobbers bank
LoadEntityGraphics::
	; Forcefully load entity graphics.
	ld l, LOW(wEntity0_LastDirection)
	ld [hl], -1

	ldh a, [hSystem]
	and a, a
	ret z

	push hl

	ld a, h
	sub a, HIGH(wEntity0)
	ld b, a
	ld l, LOW(wEntity0_Bank)

	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ASSERT EntityData_Palette == 2
	inc hl
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a

	ld a, b
	; An entire palette is 9 bytes
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, b ; a * 9
	add a, LOW(wOBJPaletteBuffer)
	ld e, a
	adc a, HIGH(wOBJPaletteBuffer)
	sub a, e
	ld d, a
	ld c, 9
	call MemCopySmall

	pop hl
	ret

SECTION "GetMaxHealth", ROM0
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

FOR I, NB_ENTITIES
	SECTION "Entity {I}", WRAM0[$C100 - sizeof_Entity + I * $100]
	IF I == 0
wAllies::
	ELIF I == 3
wEnemies::
	ENDC
		dstruct Entity, wEntity{d:I}
ENDR

SECTION "Active entity", WRAM0
; The next entity to be processed.
wActiveEntity:: db

SECTION "Movement Queued", WRAM0
; nonzero if any entity is ready to move.
wMovementQueued:: db

SECTION "Show Moves", WRAM0
wShowMoves:: db
