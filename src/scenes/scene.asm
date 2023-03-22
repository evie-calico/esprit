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
	ld [wSceneOverrideColor], a
	; TODO: we'll need to load the player and ally from the save file here.

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

	;call DrawScene
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

	ld a, bank(xRenderScene)
	rst SwapBank
	jp xRenderScene

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

section "render scene column", romx

; @input a: column of camera
; @input carry: set if moving right
; @preserves e
xRenderColumn:
	; Depending on the carry input, determine an offset for the column
	jr nc, :+
	add a, SCRN_X_B
:
	and a, 63
	assert low(wSceneMap) == 0
	ld c, a
	ld b, high(wSceneMap)
	and a, 31
	ld l, a
	ld h, $98
	ld d, SCRN_VY_B
.loop
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .loop
	ld a, [bc]
	ld [hl], a
	ld a, [wSceneOverrideColor]
	and a, a
	jr nz, .noCgb
	ldh a, [hSystem]
	and a, a
	jr z, .noCgb
	ld a, 1
	ldh [rVBK], a
	ld a, [bc]
	push bc
	sub a, $80
	ld c, a
	ld b, high(wSceneTileAttributes)
	ld a, [bc]
	pop bc
	ld [hl], a
	xor a, a
	ldh [rVBK], a
.noCgb
	ld a, SCRN_VX_B
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, SCENE_WIDTH
	add a, c
	ld c, a
	adc a, b
	sub a, c
	ld b, a
	dec d
	jr nz, .loop
	ret

xRenderScene:
	ld hl, wSceneCamera.x
	ld a, [hli]
	ld h, [hl]
	rept 7
		srl h
		rra
	endr
	ld e, a
	rept SCRN_X_B
		xor a, a ; clear carry
		ld a, e
		call xRenderColumn
		inc e
	endr
	xor a, a ; clear carry
	ld a, e
	jp xRenderColumn

section "Draw scene", rom0
DrawScene:
	ld hl, wActiveScene
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, Scene_DrawInfo
	ld l, a
	adc a, h
	sub a, l
	ld h, a
.loop
	ld de, .loop
	push de
	ld a, [hli]
	add a, a
	add a, low(.jumpTable)
	ld e, a
	adc a, high(.jumpTable)
	sub a, e
	ld d, a
	ld a, [de]
	inc de
	ld b, a
	ld a, [de]
	ld d, a
	ld e, b
	push de
	ret

.jumpTable
	assert DRAWSCENE_END == 0
	dw DrawSceneExit
	assert DRAWSCENE_VRAMCOPY == 1
	dw DrawSceneVramCopy
	assert DRAWSCENE_BKG == 2
	dw DrawSceneBackground
	assert DRAWSCENE_PLACEDETAIL == 3
	dw DrawScenePlaceDetail
	assert DRAWSCENE_SPAWNNPC == 4
	dw DrawSceneSpawnNpc
	assert DRAWSCENE_FILL == 5
	dw DrawSceneFill
	assert DRAWSCENE_SETDOOR == 6
	dw DrawSceneSetDoor
	assert DRAWSCENE_MEMCOPY == 7
	dw DrawSceneMemcopy
	assert DRAWSCENE_SETCOLOR == 8
	dw DrawSceneSetColor
	assert DRAWSCENE_TOGGLE_VRAM == 9
	dw DrawSceneToggleVram
	assert DRAWSCENE_FORCE_COLOR == 10
	dw DrawSceneForceColor

DrawSceneExit:
	pop af
	ret

DrawSceneToggleVram:
	ldh a, [rVBK]
	xor a, 1
	ldh [rVBK], a
	ret

DrawSceneForceColor:
	ldh a, [hCurrentBank]
	push af
	ld a, [hli]
	ld b, a
	ld de, $9840
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ld a, b
	rst SwapBank
	lb bc, 20, 12
	call MapRegion
	pop hl
	inc hl
	pop af
	rst SwapBank
	ret

DrawSceneVramCopy:
	ldh a, [hCurrentBank]
	push af
	push hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	push af
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	rst SwapBank
	call VramCopy
	pop hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	pop af
	rst SwapBank
	ret

DrawSceneBackground:
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	push hl
		ld l, a
		ld h, b
	.nextTile
		; b, c = width, height
		; de = destination
		; l = base tile
		; h = width counter
		push bc
		rst Rand8
		pop bc
		and a, 3
		jr z, .four
		dec a
		jr z, .three
		dec a
		jr z, .two
		dec a
		jr .one
	.four
		inc a
	.three
		inc a
	.two
		inc a
	.one
		add a, l
		ld [de], a
		inc de
		dec h
		jr nz, .nextTile
		dec c
		jr z, .done
		ld a, SCENE_WIDTH
		sub a, b
		add a, e
		ld e, a
		adc a, d
		sub a, e
		ld d, a
		ld h, b
		jr nz, .nextTile
	.done
	pop hl
	ret

DrawScenePlaceDetail:
	ldh a, [hCurrentBank]
	push af
		ld a, [hli]
		ld b, a
		ldh [hSceneLoopCounter], a
		ld a, [hli]
		ld c, a
		push hl ;  Preserve script pointer
			push bc ; b = Width, c = Height
				ld a, [hli]
				ldh [hSceneTileOffset], a
				ld a, [hli]
				ld b, a
				; b = Bank
				ld a, [hli]
				ld e, a
				ld a, [hli]
				ld d, a
				; de = destination
				ld a, [hli]
				ld h, [hl]
				ld l, a
				; hl = source map (for add a, [hl])
				ld a, b
				rst SwapBank
				ld a, c
			pop bc
		.loop
			ldh a, [hSceneTileOffset]
			add a, [hl]
			inc hl
			ld [de], a
			inc de
			dec b
			jr nz, .loop
			ldh a, [hSceneLoopCounter]
			ld b, a
			ld a, SCENE_WIDTH
			sub a, b
			add a, e
			ld e, a
			adc a, d
			sub a, e
			ld d, a
			dec c
			jr nz, .loop
		pop hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
	pop af
	rst SwapBank
	ret

DrawSceneSpawnNpc:
	ld a, [hli]
	ld d, a
	; Copy data pointer
	ld e, low(wEntity0_Bank)
	ld c, 3
	rst MemCopySmall
	xor a, a
	ld e, low(wEntity0_WasMovingLastFrame)
	ld [de], a
	ld e, low(wEntity0_AnimationDesync)
	ld [de], a

	; Copy initial position
	ld e, low(wEntity0_SpriteY)
	ld c, 4
	rst MemCopySmall
	; Force-load graphics
	ld e, low(wEntity0_Direction)
	ld a, [hli]
	ld [de], a
	inc e
	ld a, -1
	ld [de], a
	inc e
	xor a, a
	ld [de], a
	; Copy Scripts
	ld e, low(wEntity0_IdleScript)
	ld c, 6
	rst MemCopySmall
	ret

DrawSceneFill:
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	push hl
	ld h, d
	ld l, e
	ld d, a
	ld a, b
	push af
.copy
	ld a, d
	ld [hli], a
	dec b
	jr nz, .copy
	pop af
	dec c
	jr z, .done
	push af
	ld b, a
	ld a, SCENE_WIDTH
	sub a, b
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	jr .copy
.done
	pop hl
	ret

DrawSceneSetDoor:
	ret

DrawSceneMemcopy:
	ldh a, [hCurrentBank]
	push af
	push hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	push af
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop af
	rst SwapBank
	call MemCopy
	pop hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
	pop af
	rst SwapBank
	ret

DrawSceneSetColor:
	ld a, [hli]
	sub a, $80
	ld e, a
	ld d, high(wSceneTileAttributes)
	ld a, [hli]
	ld c, [hl]
	inc hl
.loop
	ld [de], a
	inc e
	dec c
	jr nz, .loop
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

wSceneNPCIdleScriptVariables:: ds evscript_npc_pool_size * NB_NPCS

wScenePrimaryScript:
.pointer ds 3
.scriptVariables:: ds evscript_npc_pool_size * 2

wSceneOverrideColor:: db

section "Scene Loop counter", hram
hSceneLoopCounter: db
hSceneTileOffset: db
