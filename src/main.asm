INCLUDE "bank.inc"

SECTION "Main", ROM0
Main::
    call UpdateInput
    call ProcessEntities
    bankcall xMoveEntities
    call ResetShadowOAM
    bankcall xRenderEntities
    call UpdateEntityGraphics
    bankcall xHandleMapScroll
    ld a, [wDungeonCameraX]
    add a, 1
    ld [wDungeonCameraX], a
    jr nc, :+
    ld a, [wDungeonCameraX + 1]
    inc a
    ld [wDungeonCameraX + 1], a
:   ld a, [wDungeonCameraX + 1]
    ld b, a
    ld a, [wDungeonCameraX]
    REPT 4
        srl b
        rra
    ENDR
    ldh [hShadowSCX], a
    ld a, [wDungeonCameraY + 1]
    ld b, a
    ld a, [wDungeonCameraY]
    REPT 4
        srl b
        rra
    ENDR
    ldh [hShadowSCY], a
    ;call PrintVWFChar
    ;call DrawVWFChars
    call WaitVBlank
    jr Main
