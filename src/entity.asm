INCLUDE "entity.inc"

SECTION "Debug entity", ROM0
DebugEntity::
    db 0

SECTION "Render entities", ROM0
RenderEntities::
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
        ASSERT Entity_Bank + 3 == Entity_YPos
        inc l
        inc l
        ; Read Y position.
        ld a, [hli]
        ; Adjust 12.4 position down to a 12-bit integer.
        REPT 4
            rrc [hl]
            rra
        ENDR
        ld [de], a
        inc e

        ASSERT Entity_YPos + 2 == Entity_XPos
        ; Read X position.
        inc l
        ld a, [hli]
        ; Adjust 12.4 position down to a 12-bit integer.
        REPT 4
            rrc [hl]
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
        dstruct Entity, wEntity{d:I}
ENDR
