include "defines.inc"
include "entity.inc"
include "hardware.inc"
include "scene.inc"

def SCROLL_PADDING_TOP equ 40
def SCROLL_PADDING_BOTTOM equ SCRN_Y - 40 - 40
def SCROLL_PADDING_LEFT equ 40
def SCROLL_PADDING_RIGHT equ SCRN_X - 56

def NB_NPCS equ 6

def vAPrompt equ $8FE0
def idof_vAPrompt equ $FE
def vAPromptLocation equ $9C00 + 19 + 31 * 32

section "A Prompt", romx
APrompt: incbin "res/ui/a_prompt.2bpp"

section "Scene State Init", rom0
InitScene::
	; Reset all NPC banks
	xor a, a
	ld hl, wEntity2_Bank
	rept NB_ENTITIES - 2
		ld [hl], a
		inc h
	endr
	ld c, SIZEOF("scene BSS")
	ld hl, STARTOF("scene BSS")
	call MemSetSmall

	; Push the RNG state onto the stack and restore it later.
	; This ensures that the static seed of the scene doesn't create a
	; predictable RNG state that players can abuse.
	ld de, randstate
	ld a, [de]
	inc de
	ld c, a
	ld a, [de]
	inc de
	ld b, a
	push bc
	ld a, [de]
	inc de
	ld c, a
	ld a, [de]
	ld b, a
	push bc

	ld a, bank(APrompt)
	rst SwapBank
	ld de, vAPrompt
	ld hl, APrompt
	ld c, 32
	call VramCopySmall

	ld hl, wActiveScene
	ld de, randstate
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, Scene_Width
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hli]
	ld a, [hli]
	assert Scene_Width + 2 == Scene_Seed
	ld de, randstate
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	assert Scene_Seed + 4 == Scene_IntroScript
	ld de, wScenePrimaryScript.pointer
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	; load initial position based on the direction we came from on the map.
	ld hl, wActiveScene + 1
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wMapLastDirectionMoved]
	ld [wEntity0_Direction], a
	add a, a
	add a, a
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld de, wEntity0_SpriteY
	ld a, [hli]
	ld [de], a
	inc e
	ld a, [hli]
	ld [de], a
	inc e
	ld a, [hli]
	ld [de], a
	inc e
	ld a, [hli]
	ld [de], a

	xor a, a
	ld c, 4
	ld hl, wSceneCamera
	rst MemSetSmall
	ld [hShadowSCX], a
	ld [hShadowSCY], a

	call FadeIn

	ld a, GAMESTATE_SCENE
	ld [wGameState], a

	; After drawing the scene the seed may be restored.
	ld de, randstate
	pop bc
	ld a, c
	ld [de], a
	inc de
	ld a, b
	ld [de], a
	inc de
	pop bc
	ld a, c
	ld [de], a
	inc de
	ld a, b
	ld [de], a

	xor a, a
	ld [wSceneMovementLocked], a
	ret

section "Scene State", rom0
SceneState::
	ld hl, wScenePrimaryScript.pointer
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wScenePrimaryScript.scriptVariables
	call ExecuteScript
	ld de, wScenePrimaryScript.pointer
	ldh a, [hCurrentBank]
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	inc de
	ld a, h
	ld [de], a

	ld a, bank(xRenderNPCs)
	rst SwapBank
	call xRenderNPCs
	call UpdateEntityGraphics

	; Check the function for null, not the bank.
	ld hl, wSceneTickFunction + 1
	ld a, [hli]
	or a, [hl]
	jr z, .noTick
	; Go back and switch the bank
	ld a, [wSceneTickFunction]
	rst SwapBank
	; This is a sort of backwards deref
	ld a, [hld]
	ld l, [hl]
	ld h, a
	rst CallHL
.noTick

	ld a, [wPrintString]
	and a, a
	call nz, DrawPrintString.customDelay
	call PrintVWFChar
	call DrawVWFChars

	ld a, [wTextSrcPtr + 1]
	inc a
	jr z, .noAPrompt
	ld a, [wTextFlags]
	bit 6, a
	jr z, .noAPrompt
	ldh a, [hFrameCounter]
	and a, 32
	jr z, .noAPrompt
	ld b, idof_vAPrompt
	jr .drawAPrompt
.noAPrompt
	ld b, idof_vUIFrameRight
.drawAPrompt
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .drawAPrompt

	ld a, b
	ld [vAPromptLocation], a

	ret

section "Scene variables", wram0
wActiveScene:: ds 3

section UNION "State variables", wram0, ALIGN[8]
wSceneMap:: ds SCENE_WIDTH * SCENE_HEIGHT
wSceneCollision:: ds SCENE_WIDTH * SCENE_HEIGHT
assert !low(@)
wSceneTileAttributes:: ds 128

wSceneCamera::
.x:: dw
.y:: dw

wSceneMovementLocked:: db

section fragment "scene BSS", wram0
; Called once per frame, can be configured via evscript
wSceneTickFunction:: ds 3

wSceneOverrideColor:: db

wScenePrimaryScript:
	.pointer ds 3
	.scriptVariables:: ds evscript_npc_pool_size
	.threads::
	for i, 1, 8
		.thread{d:i}:: ds 3
		.thread{d:i}Pool ds evscript_npc_pool_size
	endr

section "Scene Loop counter", hram
hSceneLoopCounter: db
hSceneTileOffset: db
