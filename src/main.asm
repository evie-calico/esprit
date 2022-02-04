INCLUDE "bank.inc"

SECTION "Main", ROM0
Main::
    ; Poll player input and move as needed.
    call UpdateInput
    call ProcessEntities
    bankcall xMoveEntities

    ; Scroll the map after moving entities.
    bankcall xHandleMapScroll
    bankcall xFocusCamera

    ld a, [wDungeonCameraX + 1]
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

    ; Render entities after scrolling.
    call ResetShadowOAM
    bankcall xRenderEntities
    call UpdateEntityGraphics

    ; Print any pending text.
    call PrintVWFChar
    call DrawVWFChars

    ; Wait for the next frame.
    call WaitVBlank
    jr Main
