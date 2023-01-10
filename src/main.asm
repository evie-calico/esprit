include "defines.inc"
include "hardware.inc"

section "Main", rom0
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
	add a, low(.stateTable)
	ld l, a
	adc a, high(.stateTable)
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
	; Only fade out music when fading to black
	ld a, [wFadeMusic]
	and a, a
	jr z, .notSound
	ldh a, [rNR50]
	sub a, $11
	jr z, .notSound
	ldh [rNR50], a
.notSound
	call FadePaletteBuffers
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
	dw MapState
	dw SceneState

; Fade to white is used when transitioning between menus, like when pausing.
FadeToWhite::
	ld a, $10
	ld [wFadeSteps], a
	ld a, $80
	ld [wFadeAmount], a
	ld a, 8
	ld [wFadeDelta], a
	ret

; Fade to black is used when transitioning between areas, such as entering or
; leaving a dungeon or scene.
FadeToBlack::
	ld a, $10
	ld [wFadeSteps], a
	ld a, $80
	ld [wFadeAmount], a
	ld a, -8
	ld [wFadeDelta], a
	ld a, 1
	ld [wFadeMusic], a
	ret

FadeIn::
	xor a, a
	ld [wFadeMusic], a
	ld a, $0F
	ld [wFadeSteps], a
	ld a, [wFadeDelta]
	bit 7, a
	jr z, .down
	ld a, 8
	ld [wFadeDelta], a
	ld a, $80 - $0F * 8
	ld [wFadeAmount], a
	ret

.down
	ld a, -8
	ld [wFadeDelta], a
	ld a, $80 + $0F * 8
	ld [wFadeAmount], a
	ret

ReloadPalettes::
	ld a, 1
	ld [wFadeSteps], a
	ld a, $80 + 1
	ld [wFadeAmount], a
	ld a, -1
	ld [wFadeDelta], a
	ret

section "Game State", wram0
; The current process to run within the main loop.
wGameState:: db

section "Fade callback", wram0
wFadeCallback:: dw
wFadeMusic:: db

section "General Script Pool", wram0
wScriptPool:: ds evscript_script_pool_size
