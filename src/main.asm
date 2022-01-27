SECTION "Main", ROM0
Main::
    call UpdateInput
    call PrintVWFChar
    call DrawVWFChars
    call ResetShadowOAM
    call RenderEntities
    call WaitVBlank
    jr Main
