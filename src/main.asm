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

	; Clear last frame's shadow OAM.
	call ResetShadowOAM

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
	ld a, [wFadeSteps]
	and a, a
	jr z, .noFade
	call nz, FadePaletteBuffers
	jr .noCallback
.noFade
	ld hl, wFadeCallback
	ld a, [hli]
	or a, [hl]
	jr z, .noCallback
	dec hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	rst CallHL
	xor a, a
	ld hl, wFadeCallback
	ld [hli], a
	ld [hl], a
.noCallback

	; Wait for the next frame.
	call WaitVBlank
	jp Main

.stateTable
	dw DungeonState
	dw ProcessMenus

SECTION "Game State", WRAM0
; The current process to run within the main loop.
wGameState:: db

SECTION "Fade callback", WRAM0
wFadeCallback:: dw

SECTION "General Script Pool", WRAM0
wScriptPool:: ds 16
