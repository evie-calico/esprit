INCLUDE "hardware.inc"

SECTION "Wait for VBlank", ROM0
WaitVBlank::
    xor a, a
    ld [wWaitVBlankFlag], a
:   halt
    ld a, [wWaitVBlankFlag]
    and a, a
    jr z, :-
    ret

SECTION "VBlank Interrupt", ROM0[$0040]
    push af
    push bc
    push de
    push hl
    jp VBlank

SECTION "STAT Interrupt", ROM0[$0048]
    push af
    push bc
    push de
    push hl
    jp STAT

SECTION "VBlank Handler", ROM0
VBlank:
    ld a, [hCurrentBank]
    push af

    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
    ldh [rLCDC], a

    ld a, HIGH(wShadowOAM)
    call hOAMDMA

    ldh a, [hShadowSCX]
    ldh [rSCX], a
    ldh a, [hShadowSCY]
    ldh [rSCY], a

    call gbt_update

    ldh a, [hFrameCounter]
    inc a
    ldh [hFrameCounter], a

    ld a, 1
    ld [wWaitVBlankFlag], a

    pop af
    rst SwapBank

    pop hl
    pop de
    pop bc
    pop af
    reti

SECTION "STAT Handler", ROM0
STAT:
    ld hl, wSTATTarget
    ld a, [hli]
    or a, [hl]
    jr z, :+
    dec hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    rst CallHL
:   pop hl
    pop de
    pop bc
    pop af
    reti

SECTION "Wait VBlank flag", WRAM0
wWaitVBlankFlag: db

SECTION "STAT target", WRAM0
wSTATTarget:: dw

SECTION "Shadow scroll registers", HRAM
hShadowSCX:: db
hShadowSCY:: db
hFrameCounter:: db
