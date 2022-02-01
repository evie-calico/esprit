INCLUDE "bank.inc"
INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"

DEF MOVEMENT_SPEED EQU 16
DEF SPRITE_DIRECTION_SIZE EQU 128 * 3

SECTION "Luvui data", ROMX
xLuvui::
    dw .graphics
.graphics::
    INCBIN "res/sprites/luvui.2bpp"

SECTION "Process entities", ROM0
ProcessEntities::
    call PadToDir
    ret c
    ld [wEntity0_Direction], a
    ld h, HIGH(wEntity0)
    jp MoveEntity

; Reads hCurrentKeys and returns the currently selected pad direction in A.
; If no direction is selected, sets the carry flag.
PadToDir::
    xor a, a ; Clear carry flag
    ldh a, [hNewKeys]
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
    ld h, HIGH(wEntity0)
.loop
    ld l, LOW(wEntity0_Bank)
    ld a, [hli]
    and a, a
    jr z, .next
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
    jr z, .next
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
    inc h
    ld a, h
    cp a, HIGH(wEntity0) + NB_ENTITIES
    jr nz, .loop
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
    jr z, .next
    ASSERT Entity_Bank + 4 == Entity_SpriteY + 1
    inc l
    inc l
    inc l
    ; Now check if the entity is within the camera bounds
    ld a, [wDungeonCameraY + 1]
    cp a, [hl] ; possibly need to inc/dec here?
    jr z, :+
    jr nc, .next
:   add a, 9
    cp a, [hl]
    jr c, .next
    dec l
    ; Read Y position.
    ld a, [wDungeonCameraY]
    ld c, a
    ld a, [hli]
    sub a, c
    ld c, a
    ld a, [wDungeonCameraY + 1]
    ld b, a
    ld a, [hli]
    sbc a, b
    ld b, a
    ld a, c
    ; Adjust 12.4 position down to a 12-bit integer.
    REPT 4
        srl b
        rra
    ENDR
    add a, 16
    ldh [hRenderTempByte], a

    ASSERT Entity_SpriteY + 2 == Entity_SpriteX
    ; Read X position.
    ld a, [wDungeonCameraX]
    ld c, a
    ld a, [hli]
    sub a, c
    ld c, a
    ld a, [wDungeonCameraX + 1]
    ld b, a
    ld a, [hli]
    sbc a, b
    ld b, a
    ld a, c
    ; Adjust 12.4 position down to a 12-bit integer.
    REPT 4
        srl b
        rra
    ENDR
    add a, 8
    ld b, a

    ; The following is an unrolled loop which writes both halves of the sprite.
    ldh a, [hRenderTempByte]
    ld [de], a
    inc e
    ld a, b
    ld [de], a
    inc e
    ; Determine entity index and render.
    ld a, h
    sub a, HIGH(wEntity0)
    swap a ; a * 16
    ld [de], a
    inc e
    ; Revert the index and use it as the color palette.
    swap a
    ld [de], a
    inc e

    ldh a, [hRenderTempByte]
    ld [de], a
    inc e
    ld a, b
    add a, 8
    ld [de], a
    inc e
    ; Determine entity index and render.
    ld a, h
    sub a, HIGH(wEntity0)
    swap a ; a * 16
    add a, 2
    ld [de], a
    inc e
    sub a, 2
    ; Revert the index and use it as the color palette.
    swap a
    ld [de], a
    inc e
.next
    inc h
    ld a, h
    cp a, HIGH(wEntity0) + NB_ENTITIES
    jp nz, .loop
    ; Store final OAM index.
    ld a, e
    ldh [hOAMIndex], a
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

SECTION "Render Temp", HRAM
hRenderTempByte: db
