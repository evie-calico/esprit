INCLUDE "engine.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"
INCLUDE "optimize.inc"
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

    ; Wait to turn off the screen, because speed switch can be finicky.
    .waitVBlank
    ldh a, [rLY]
    cp a, 144
    jr c, .waitVBlank
    xor a, a
    ldh [rLCDC], a

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

    ; Null out all entities.
    xor a, a
    FOR I, NB_ENTITIES
        ld bc, sizeof_Entity
        ld hl, wEntity{d:I}
        call MemSet
    ENDR

    ; Clear OAM.
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

    ldh [hCurrentBank], a
    ldh [hCurrentKeys], a
    ldh [rIF], a
    ld bc, $2000
    ld d, a
    ld hl, _VRAM
    call VRAMSet

    ; Initialize an entity for debugging.
    ld a, BANK(xDebugEntity)
    ld [wEntity0_Bank], a
    ld a, LOW(xDebugEntity)
    ld [wEntity0_Data], a
    ld a, HIGH(xDebugEntity)
    ld [wEntity0_Data + 1], a

    ; Initiallize OAM
    call InitSprObjLib

    ; Enable interrupts
    ld a, IEF_VBLANK
    ldh [rIE], a

    ; Draw vwf text
    ld a, 18 * 8
    lb bc, $01, 73
    lb de, 4, $90
    call TextInit

    ld b, BANK(xDebugText)
    ld hl, xDebugText
    ld a, 1
    call PrintVWFText

    lb de, 18, 4
    ld hl, $99C1
    call TextDefineBox

    ld a, 1
    ld [wTextLetterDelay], a

    ; Turn on the screen.
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
    ldh [rLCDC], a

    ei
    jp Main

SECTION "Debug Text", ROMX
xDebugText: db "<CLEAR>Eievui used Scratch!<DELAY>",60,"<NEWLINE>Enemy took 255 damage and was defeated.<DELAY>",120,"<CLEAR>", \
               "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. ", \
               "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ", \
               "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. ", \
               "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.<END>"

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
