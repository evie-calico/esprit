INCLUDE "defines.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"

DEF MOVEMENT_SPEED EQU 1 << 4

SECTION "Debug entity", ROMX
xDebugEntity::
    db 0

SECTION "Process entities", ROM0
ProcessEntities::
    call PadToDir
    ret c
    add a, a
    add a, LOW(.directionVectors)
    ld l, a
    adc a, HIGH(.directionVectors)
    sub a, l
    ld h, a
    ld de, wEntity0_PosX
    ld a, [de]
    add a, [hl]
    ld [de], a
    inc hl
    inc e
    ASSERT Entity_PosX + 1 == Entity_PosY
    ld a, [de]
    add a, [hl]
    ld [de], a
    ret

.directionVectors
    db 0, -1
    db 1, 0
    db 0, 1
    db -1, 0

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
    push hl
        ASSERT Entity_Bank + 3 == Entity_SpriteY
        inc l
        inc l
        ; Read Y position.
        ld a, [hli]
        ld b, [hl]
        ; Adjust 12.4 position down to a 12-bit integer.
        REPT 4
            rrc b
            rra
        ENDR
        ld [de], a
        inc e

        ASSERT Entity_SpriteY + 2 == Entity_SpriteX
        ; Read X position.
        inc l
        ld a, [hli]
        ld b, [hl]
        ; Adjust 12.4 position down to a 12-bit integer.
        REPT 4
            rrc b
            rra
        ENDR
        ld [de], a
        inc e

        ; Determine entity index and render.
        ld a, h
        sub a, HIGH(wEntity0)
        swap a ; a * 16
        ld [de], a
        inc e

        ld a, h
        sub a, HIGH(wEntity0)
        ld [de], a
        inc e
    pop hl
.next
    inc h
    ld a, h
    cp a, HIGH(wEntity0) + NB_ENTITIES
    jr nz, .loop
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
