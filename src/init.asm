INCLUDE "defines.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"

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
	ld [wActiveEntity], a
	ld [wMoveEntityCounter], a
	ld [wSTATTarget], a
	ld [wSTATTarget + 1], a
	ld [wTextCharset], a
	ld [wTextCurPixel], a
	ld [randstate], a
	ld [randstate + 1], a
	ld [randstate + 2], a
	ld [randstate + 3], a
	ld [wNbMenus], a
	ld [wFadeCallback], a
	ld [wFadeCallback + 1], a
	ldh [hCurrentBank], a
	ldh [hCurrentKeys], a
	ldh [hFrameCounter], a
	ldh [hShadowSCX], a
	ldh [hShadowSCY], a
	ldh [rIF], a
	ld bc, $2000
	ld d, a
	ld hl, _VRAM
	call VRAMSet
	ld c, $10 * 2
	ld hl, wTextTileBuffer
	rst MemSetSmall

	ld a, $FF
	ld [wTextSrcPtr + 1], a
	; Set a default theme.
	; TODO add a theme selection to the options menu.
	ld a, LOW(PinkMenuPalette)
	ld [wActiveMenuPalette], a
	ld a, HIGH(PinkMenuPalette)
	ld [wActiveMenuPalette + 1], a
	ld a, LOW(PawprintMenuTheme)
	ld [wActiveMenuTheme], a
	ld a, HIGH(PawprintMenuTheme)
	ld [wActiveMenuTheme + 1], a

	call InitDungeon

	; Initiallize OAM
	call InitSprObjLib

	ld c, BANK(dungeon_data)
	ld de, dungeon_data
	ld a, 0
	call gbt_play

	; Enable interrupts
	ld a, IEF_VBLANK | IEF_STAT
	ldh [rIE], a

	ld a, STATF_LYC
	ldh [rSTAT], a

	ld a, %11100100
	ldh [rBGP], a
	ldh [rOBP1], a
	ld a, %11010000
	ldh [rOBP0], a

	; Turn on the screen.
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
	ldh [rLCDC], a
	ld a, SCRN_X
	ldh [rWX], a
	ldh [hShadowWX], a
	ld a, SCRN_Y
	ldh [rWY], a
	ldh [hShadowWY], a

	ei
	jp Main

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
