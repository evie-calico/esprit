INCLUDE "defines.inc"
INCLUDE "hardware.inc"

INCLUDE "res/music/dungeon.asm"

SECTION "Main", ROM0
Main::
    ; Poll player input and move as needed.
    call UpdateInput

    ; Soft reset if A B START SELECT is held.
    ld a, [hCurrentKeys]
    cp a, PADF_A | PADF_B | PADF_SELECT | PADF_START
    jp z, Initialize

    ; State-specific logic.
    ld a, [wGameState]
    add a, a
    add a, LOW(.stateTable)
    ld l, a
    adc a, HIGH(.stateTable)
    sub a, l
    ld h, a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    rst CallHL
:

    ; Fading
    ldh a, [hSystem]
    and a, a
    jr z, .noFade
    ld a, [wFadeSteps]
    and a, a
    jr z, .noFade
    call nz, FadePaletteBuffers
.noFade
    ; Wait for the next frame.
    call WaitVBlank
    jp Main

.stateTable
    dw DungeonState
    dw MenuState

SECTION "Menu State", ROM0
; When switching into the menu state from the game state, first fade out the
; palettes while continuing to animate entities. Once fading is complete, the
; pause menu can be drawn and faded in.
MenuState:
    ld a, BANK(xDrawPauseMenu)
    rst SwapBank
    ld hl, xDrawPauseMenu
    call DrawMenu
    ret

SECTION "Game State", WRAM0
; The current process to run within the main loop.
wGameState:: db
