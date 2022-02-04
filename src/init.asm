INCLUDE "bank.inc"
INCLUDE "engine.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"
INCLUDE "optimize.inc"
INCLUDE "textfmt.inc"
INCLUDE "res/charmap.inc"

SECTION "Header", ROM0[$100]
    di
    jp InitializeSystem
    ds $150 - $104, 0

SECTION "Initialize", ROM0
; Inits system value based off `a` and `b`. Do not jump to this!
InitializeSystem:
    cp a, $11 ; The CGB boot rom sets `a` to $11
    jr nz, .dmg
    bit 0, b ; The AGB boot rom sets bit 0 of `b`
    jr z, .cgb
.agb
    ld a, SYSTEM_AGB
    jr .store
.dmg
    ASSERT SYSTEM_DMG == 0
    xor a, a ; ld a, SYSTEM_DMG
    jr .store
.cgb
    ld a, SYSTEM_CGB
.store
    ldh [hSystem], a

    ; Overclock the CGB
    and a, a
    jr z, Initialize

    ; Do lotsa stuff to be very safe.
:   ldh a, [rLY]
    cp a, 144
    jr c, :-
    xor a, a
    ldh [rLCDC], a
    ldh [rIE], a
    ld a, $30
    ldh [rP1], a
    di

    ld a, 1
    ldh [rKEY1], a
    stop
    jr Initialize.waitSkip

Initialize::
.waitVBlank
    ldh a, [rLY]
    cp a, 144
    jr c, .waitVBlank
    xor a, a
    ldh [rLCDC], a
.waitSkip

    ; Reset Stack to WRAMX
    ld sp, wStack.top

    ; Clear OAM.
    xor a, a
    ld bc, 160
    ld hl, wShadowOAM
    call MemSet
    ldh [hOAMIndex], a

    ; Initialize VWF.
	ld [wTextCurPixel], a
	ld [wTextCharset], a
	ld c, $10 * 2
	ld hl, wTextTileBuffer
	rst MemSetSmall
    ldh [hShadowSCX], a
    ldh [hShadowSCY], a

    ldh [hCurrentBank], a
    ldh [hCurrentKeys], a
    ldh [rIF], a
    ld bc, $2000
    ld d, a
    ld hl, _VRAM
    call VRAMSet

    bankcall xInitDungeon
    bankcall xDrawDungeon

    ; Initiallize OAM
    call InitSprObjLib

    ; Enable interrupts
    ld a, IEF_VBLANK
    ldh [rIE], a

    ld a, %11100100
    ldh [rBGP], a
    ldh [rOBP1], a
    ld a, %11010000
    ldh [rOBP0], a

    ; Draw vwf text
    ld a, BANK(xTextInit)
    rst SwapBank
    ld a, 18 * 8
    lb bc, $01, 73
    lb de, 4, $90
    call xTextInit

    ld b, BANK(xDebugText)
    ld hl, xDebugText
    ld a, 1
    call PrintVWFText

    lb de, 18, 4
    ld hl, $9DC1
    bankcall xTextDefineBox

    ld a, 6
    ld [wTextLetterDelay], a

    ; Turn on the screen.
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
    ldh [rLCDC], a

    ei
    jp Main

SECTION "Debug Text", ROMX
xDebugText:
    db "Player is facing "
    db TEXT_FMT, BANK(xDebugTable)
    dw wEntity0_Direction, xDebugTable
    db " -- "
    db TEXT_JUMP, BANK(xDebugText)
    dw xDebugText

xDebugTable: fmttable "up", "right", "down", "left"

SECTION "Stack", WRAM0
wStack:
    ds 32 * 2
.top

SECTION "System type", HRAM
; The type of system the program is running on.
; Nonzero values indicate CGB features.
; @ 0: DMG
; @ 1: CGB
; @ 2: AGB
hSystem:: db
