INCLUDE "bank.inc"

SECTION "Main", ROM0
Main::
    call UpdateInput
    call ProcessEntities
    bankcall xMoveEntities
    call ResetShadowOAM
    bankcall xRenderEntities
    call UpdateEntityGraphics
    ;call PrintVWFChar
    ;call DrawVWFChars
    call WaitVBlank
    jr Main
