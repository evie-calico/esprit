INCLUDE "bank.inc"
INCLUDE "hardware.inc"
INCLUDE "optimize.inc"
INCLUDE "text.inc"

SECTION "Initialize user interface", ROM0
InitUI::
    ; Draw vwf text
    ld a, BANK(xTextInit)
    rst SwapBank
    ld a, 18 * 8
    lb bc, $01, 73
    lb de, 3, $90
    call xTextInit

    ld b, BANK(xDebugText)
    ld hl, xDebugText
    ld a, 1
    call PrintVWFText

    lb de, 18, 3
    ld hl, $9FA1
    bankcall xTextDefineBox

    ld a, 1
    ld [wTextLetterDelay], a

    ld a, LOW(ShowTextBox)
    ld [wSTATTarget], a
    ld a, HIGH(ShowTextBox)
    ld [wSTATTarget + 1], a

    ld a, 144 - 32 - 1
    ldh [rLYC], a

    ret

SECTION "Show text box", ROM0
ShowTextBox:
:   ld a, [rSTAT]
    and a, STATF_BUSY
    jr nz, :-
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG9C00 | LCDCF_OBJ16
    ldh [rLCDC], a
    xor a, a
    ldh [rSCX], a
    ld a, 256 - 144
    ldh [rSCY], a
    ret

SECTION "Debug Text", ROMX
xDebugText: db "Eievui used scratch!<DELAY>",60,"\n"
            db "Dealt 255 damage.<DELAY>",60,"<END>"
