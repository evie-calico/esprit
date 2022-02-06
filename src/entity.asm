INCLUDE "bank.inc"
INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"

DEF MOVEMENT_SPEED EQU 16
DEF SPRITE_DIRECTION_SIZE EQU 128 * 3

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
; @param a: Contains the value of wActiveEntity
PlayerLogic:
    ; If any movement is queued, the player should refuse to take its turn to
    ; allow all sprites to catch up.
    ld a, [wMovementQueued]
    and a, a
    ret nz
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
    add a, LOW(.directionVectors)
    ld e, a
    adc a, HIGH(.directionVectors)
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

.directionVectors
    db 0, -1
    db 1, 0
    db 0, 1
    db -1, 0

SECTION "Spawn entity", ROM0
; @param b: Entity data bank.
; @param de: Entity data pointer.
; @param h: High byte of entity struct.
; @preserves: h, bank
SpawnEntity::
    ld a, [hCurrentBank]
    push af

    ; Clear out entity struct
    xor a, a
    ld l, LOW(wEntity0)
    ld c, sizeof_Entity
    call MemSetSmall
    dec h ; correct high byte (MemSet causes it to overflow)
    ld a, b
    rst SwapBank
    ld l, LOW(wEntity0_Bank)
    ld [hli], a
    ASSERT Entity_Bank + 1 == Entity_Data
    ld a, e
    ld [hli], a
    ld a, d
    ld [hli], a
    ; Forcefully load entity graphics.
    ld l, LOW(wEntity0_LastDirection)
    ld [hl], -1

    ; Figure out the entity's index and save it later.
    ld a, h
    sub a, HIGH(wEntity0)
    ld b, a
    ld l, LOW(wEntity0_Data)
    push hl
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

    jp BankReturn

SECTION "Update entity graphics", ROM0
UpdateEntityGraphics::
    ld h, HIGH(wEntity0)
.loop
    ld l, LOW(wEntity0_Bank)
    ld a, [hli]
    and a, a
    jr z, .next
    ld l, LOW(wEntity0_Direction)
    ld a, [hli]
    ASSERT Entity_Direction + Entity_LastDirection
    cp a, [hl]
    jr z, .next
    ld [hl], a
    ld c, a
    ld l, LOW(wEntity0_Bank)
    ld a, [hli]
    ASSERT Entity_Bank + 1 == Entity_Data
    rst SwapBank
    push hl
        ; Save the index in B for later
        ld a, h
        sub a, HIGH(wEntity0)
        ld b, a
        ; Dereference data and graphics.
        ld a, [hli]
        ld h, [hl]
        ld l, a
        ASSERT EntityData_Graphics == 0
        ld a, [hli]
        ld h, [hl]
        ld l, a
        ; Offset graphics by direction
        ASSERT SPRITE_DIRECTION_SIZE == 384
        ; Begin by adding (Direction * 256)
        ld a, h
        add a, c
        ld h, a
        ; Add the remaining (Direction * 128)
        bit 0, c
        jr z, :+
        ld a, l
        add a, 128
        ld l, a
        adc a, h
        sub a, l
        ld h, a
:       bit 1, c
        jr z, :+
        inc h
:       ; Now offset the destination by Index * 128 and copy 256 bytes.
        ld a, b
        add a, $80
        ld d, a
        ld e, 0
        ld c, 0
        call VRAMCopySmall
    pop hl
.next
    inc h
    ld a, h
    cp a, HIGH(wEntity0) + NB_ENTITIES
    jr nz, .loop
    ret

SECTION "Move entities", ROMX
xMoveEntities::
    xor a, a
    ld [wMoveEntityCounter], a
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
    sub a, MOVEMENT_SPEED
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
    add a, MOVEMENT_SPEED
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
    sub a, MOVEMENT_SPEED
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
    add a, MOVEMENT_SPEED
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

SECTION "Render entities", ROMX
xRenderEntities::
    ; Load OAM pointer.
    ld d, HIGH(wShadowOAM)
    ldh a, [hOAMIndex]
    ld e, a
    ; Initialize entity index.
    ld h, HIGH(wEntity0)
.loop
    ld l, LOW(wEntity0_Bank)
    ld a, [hli]
    and a, a
    jp z, .next
    ASSERT Entity_Bank + 4 == Entity_SpriteY + 1
    inc l
    inc l
    inc l
    ; Now check if the entity is within the camera bounds
    ld a, [wDungeonCameraY + 1]
    cp a, [hl] ; possibly need to inc/dec here?
    jr z, :+
    jp nc, .next
:   add a, 9
    cp a, [hl]
    jp c, .next
    ASSERT Entity_SpriteY + 3 == Entity_SpriteX + 1
    inc l
    inc l
    ld a, [wDungeonCameraX + 1]
    cp a, [hl] ; possibly need to inc/dec here?
    jr z, :+
    jp nc, .next
:   add a, 11
    cp a, [hl]
    jr c, .next
    ASSERT Entity_SpriteX - 2 == Entity_SpriteY
    dec l
    dec l
    ; Read Y position.
    ldh a, [hShadowSCY]
    ld c, a
    ld a, [hld]
    ld b, a
    ld a, [hli]
    ; Adjust 12.4 position down to a 12-bit integer.
    REPT 4
        srl b
        rra
    ENDR
    add a, 16
    sub a, c
    ldh [hRenderTempByte], a

    ASSERT Entity_SpriteY + 2 == Entity_SpriteX
    inc l
    inc l
    ; Read X position.
    ldh a, [hShadowSCX]
    ld c, a
    ld a, [hld]
    ld b, a
    ld a, [hli]
    ; Adjust 12.4 position down to a 12-bit integer.
    REPT 4
        srl b
        rra
    ENDR
    add a, 8
    sub a, c
    ld b, a

    FOR I, 2
        ; The following is an unrolled loop which writes both halves of the sprite.
        ldh a, [hRenderTempByte]
        ld [de], a
        inc e
        ld a, b
        IF I
            add a, 8
        ENDC
        ld [de], a
        inc e
        ; Determine entity index and render.
        ld a, h
        sub a, HIGH(wEntity0)
        swap a ; a * 16
        ld c, a
        ldh a, [hFrameCounter]
        and a, %00010000
        rra
        rra
        IF I
            add a, 2
        ENDC
        add a, c
        ld c, a
        IF !I
            ld l, LOW(wEntity0_Frame)
        ENDC
        ld a, [hl]
        and a, a
        jr z, :+
        ld a, 8
:       add a, c
        ld [de], a
        inc e
        ; Use the index and use it as the color palette.
        ld a, h
        sub a, HIGH(wEntity0)
        ld [de], a
        inc e
    ENDR
.next
    inc h
    ld a, h
    cp a, HIGH(wEntity0) + NB_ENTITIES
    jp nz, .loop
    ; Store final OAM index.
    ld a, e
    ldh [hOAMIndex], a
    ret

SECTION "Focus Camera", ROMX
xFocusCamera::
    ld bc, wEntity0_SpriteY
    ld a, [bc]
    inc c
    ld l, a
    ld a, [bc]
    inc c
    ld h, a
    ld de, (SCRN_Y - 50) / -2 << 4
    add hl, de
    bit 7, h
    jr nz, :+
    ld a, h
    cp a, 64 - 9
    jr nc, :+
    ld a, l
    ld [wDungeonCameraY], a
    ld a, h
    ld [wDungeonCameraY + 1], a
:   ld a, [bc]
    inc c
    ld l, a
    ld a, [bc]
    inc c
    ld h, a
    ld de, (SCRN_X - 24) / -2 << 4
    add hl, de
    bit 7, h
    ret nz
    ld a, h
    cp a, 64 - 10
    ret nc
    ld a, l
    ld [wDungeonCameraX], a
    ld a, h
    ld [wDungeonCameraX + 1], a
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

SECTION "Movement return", WRAM0
; Set to 0 if all entities are done moving.
wMoveEntityCounter:: db

SECTION "Active entity", WRAM0
; The next entity to be processed.
wActiveEntity:: db

SECTION "Movement Queued", WRAM0
; nonzero if any entity is ready to move.
wMovementQueued: db

SECTION "Render Temp", HRAM
hRenderTempByte: db
