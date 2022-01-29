INCLUDE "bank.inc"

SECTION "Main", ROM0
Main::
    call UpdateInput
    call PrintVWFChar
    call DrawVWFChars
    call ResetShadowOAM
    call ProcessEntities
    call UpdateEntityGraphics
    bankcall xMoveEntities
    bankcall xRenderEntities
    call WaitVBlank
    jr Main
