INCLUDE "bank.inc"
INCLUDE "hardware.inc"

INCLUDE "res/music/dungeon.asm"

SECTION "Main", ROM0
Main::
    ; Poll player input and move as needed.
    call UpdateInput
    ld a, [hCurrentKeys]
    cp a, PADF_A | PADF_B | PADF_SELECT | PADF_START
    jp z, Initialize

    bankcall xMoveEntities
    call ProcessEntities

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

    call UpdateAttackWindow

    ldh a, [hSystem]
    and a, a
    jr z, .noFade
    ld a, [wFadeSteps]
    and a, a
    jr z, .noFade
    call nz, FadePaletteBuffers
.noFade

    ; Print any pending text.
    ld a, [wTextSrcPtr + 1]
    inc a ; cp a, $FF
    jr z, :+
    call PrintVWFChar
    call DrawVWFChars
:
    ; Wait for the next frame.
    call WaitVBlank
    jp Main
