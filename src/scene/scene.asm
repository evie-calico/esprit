INCLUDE "defines.inc"
INCLUDE "hardware.inc"
INCLUDE "scene.inc"

DEF SCROLL_PADDING_TOP EQU 40
DEF SCROLL_PADDING_BOTTOM EQU SCRN_Y - 40 - 40
DEF SCROLL_PADDING_LEFT EQU 40
DEF SCROLL_PADDING_RIGHT EQU SCRN_X - 56

SECTION "Debug Scene", ROMX
	scene_background Grass, "res/scenes/grass_bkg.2bpp"
	scene_detail Bush, "res/scenes/bush_detail.2bpp", "res/scenes/bush_detail.map", 3, 2, SCENETILE_WALL

	xDebugScene:: scene 64, 64, 64, 64, 64, 64, 64, 64, \
			512, 256, \ ; width and height
			$EA751B27, \ ; Seed
			null ; Initial script
		load_background_palette GrassGreen, "res/scenes/grass_bkg.pal8"
		load_tiles Grass, GrassGreen
		load_tiles Bush, GrassGreen
		fill_collision SCENETILE_CLEAR, 0, 0, SCENE_WIDTH, SCENE_HEIGHT
		draw_bkg Grass
		scatter_details_row 0, 3, SCENE_WIDTH - 3, 6, 4, 8, Bush
		scatter_details_row 0, 10, SCENE_WIDTH - 3, 13, 4, 8, Bush
	end_scene

SECTION "Scene State Init", ROM0
InitScene::
	ld hl, wActiveScene
	ld a, BANK(xDebugScene)
	ld [hli], a
	ld a, LOW(xDebugScene)
	ld [hli], a
	ld a, HIGH(xDebugScene)
	ld [hli], a

	ld hl, wSceneCamera
	xor a, a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld hl, wEntity0_SpriteY
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a

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
	ld [wSceneBoundary.x], a
	ld a, [hli]
	ld [wSceneBoundary.y], a
	ASSERT Scene_Width + 2 == Scene_Seed
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

	call FadeIn

	ld a, GAMESTATE_SCENE
	ld [wGameState], a

	call DrawScene
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

	ld a, BANK(xRenderScene)
	rst SwapBank
	jp xRenderScene

SECTION "Scene State", ROM0
SceneState::
	ld a, BANK(xHandleSceneMovement)
	rst SwapBank
	call xHandleSceneMovement
	
	ld a, BANK(xHandleSceneCamera)
	rst SwapBank
	call xHandleSceneCamera

	ld hl, wSceneCamera.x
	ld a, [hli]
	ld d, a
	ld a, [hli]
	REPT 4
		rra
		rr d
	ENDR
	ld a, [hli]
	ld e, a
	ld a, [hli]
	REPT 4
		rra
		rr e
	ENDR
	ld hl, wEntity0_SpriteY
	ld a, [hli]
	ld b, [hl]
	REPT 4
		rr b
		rra
	ENDR
	add a, 16
	sub a, e
	ldh [hRenderTempByte], a
	inc l
	ld a, [hli]
	ld b, [hl]
	REPT 4
		rr b
		rra
	ENDR
	add a, 8
	sub a, d
	ld b, a
	ldh a, [hOAMIndex]
	ld e, a
	ld d, HIGH(wShadowOAM)
; @param b: X
; @param de: OAM pointer
; @param h: Entity pointer high byte
; @param hRenderTempByte: Y
	ld a, BANK(xRenderEntity)
	rst SwapBank
	call xRenderEntity.customArgs
	jp UpdateEntityGraphics

SECTION "Scene Movement", ROMX
xHandleSceneMovement:
	xor a, a
	ld [wEntity0_Frame], a
	call PadToDir
	ret c
	ld [wEntity0_Direction], a
	call .y
.x
	ldh a, [hCurrentKeys]
	bit PADB_RIGHT, a
	jr nz, .right
	bit PADB_LEFT, a
	jr nz, .left
	ret
.y
	ldh a, [hCurrentKeys]
	bit PADB_DOWN, a
	jr nz, .down
	bit PADB_UP, a
	ret z
.up
	lb bc, 0, -1 << 4
	jr .finish

.left
	lb bc, -1 << 4, 0
	jr .finish

.right
	lb bc, 1 << 4, 0
	jr .finish

.down
	lb bc, 0, 1 << 4
.finish
	; b = X offset
	; c = Y offset
	ld hl, wEntity0_SpriteX
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld e, b
	ld d, 0
	bit 7, e
	jr z, :+
	dec d
:
	add hl, de
	ld d, h
	ld e, l
	; de = target X
	ld hl, wEntity0_SpriteY
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld b, 0
	bit 7, c
	jr z, :+
	dec b
:
	add hl, bc
	; hl = target Y
	; Get the tile this would end up on in bc and check for collision
	ld b, h
	ld a, l
	add a, 15 << 4
	ld c, a
	adc a, b
	sub a, c
	ld b, a
	ld a, c
	and a, $80 ; The tile component is implicitly multiplied by 128
	; and clears carry and upper two bits of b are reset
	rr b ; Y * 64
	rra
	ld c, a
	ASSERT !LOW(wSceneCollision)
	ld a, b
	add a, HIGH(wSceneCollision)
	ld b, a

	; Now adjust and add the X component
	push de
		ld a, e
		add a, 7 << 4
		ld e, a
		adc a, d
		sub a, e
		REPT 7 ; adjust to an integer and then divide by 8
			rra
			rr e
		ENDR
		ld a, e
	pop de
	add a, c
	ld c, a
	adc a, b
	sub a, c
	ld b, a

	; finally, check collision
	ld a, [bc]
	and a, a
	ret nz ; check for special collision here in the future.
	ld a, c
	sub a, SCENE_WIDTH
	ld c, a
	ld a, b
	sbc a, 0
	ld b, a
	ld a, [bc]
	and a, a
	ret nz ; check for special collision here in the future.

	ld bc, wEntity0_SpriteY
	ld a, l
	ld [bc], a
	inc c
	ld a, h
	ld [bc], a
	inc c
	ld a, e
	ld [bc], a
	inc c
	ld a, d
	ld [bc], a
	inc c
	ld a, 1
	ld [wEntity0_Frame], a
	ret

SECTION "Handle scene scrolling", ROMX
xHandleSceneCamera:
	; Loosely follow the player, stopping at the edges of the screen.
	; check if (entity.y <= camera.y + padding)
	ld hl, wEntity0_SpriteY
	; The value of de will be negative, often ending up in the OAM range.
	; Because of this, an inc is not sufficient on DMG; we must manually add 1.
	; Luckily cpl does not touch the carry flag.
	ld a, [hli]
	add a, 1
	cpl
	ld e, a
	ld a, [hl]
	cpl
	ld d, a
	jr nc, :+
	inc d
:
	ld hl, wSceneCamera.y
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, SCROLL_PADDING_TOP << 4
	add hl, bc
	add hl, de
	bit 7, h
	jr nz, .down
	ld hl, wSceneCamera.y
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, -1 << 4
	add hl, bc
	bit 7, h
	jr z, :+
	ld hl, 0
:
	ld a, l
	ld [wSceneCamera.y], a
	ld a, h
	ld [wSceneCamera.y + 1], a
	jr .left

.down
	; check if (entity.y > camera.y + SCRN_Y - 32 - padding)
	ld hl, wEntity0_SpriteY
	; The value of de will be negative, often ending up in the OAM range.
	; Because of this, an inc is not sufficient on DMG; we must manually add 1.
	; Luckily cpl does not touch the carry flag.
	ld a, [hli]
	add a, 1
	cpl
	ld e, a
	ld a, [hl]
	cpl
	ld d, a
	jr nc, :+
	inc d
:
	ld hl, wSceneCamera.y
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, SCROLL_PADDING_BOTTOM << 4
	add hl, bc
	add hl, de
	bit 7, h
	jr z, .left
	ld hl, wSceneCamera.y
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, 1 << 4
	add hl, bc
	ld a, [wSceneBoundary.y]
	cp a, h
	jr nz, :+
	ld h, a
	ld l, 0
:
	ld a, l
	ld [wSceneCamera.y], a
	ld a, h
	ld [wSceneCamera.y + 1], a

.left
	; check if (entity.x <= camera.x + padding)
	ld hl, wEntity0_SpriteX
	; The value of de will be negative, often ending up in the OAM range.
	; Because of this, an inc is not sufficient on DMG; we must manually add 1.
	; Luckily cpl does not touch the carry flag.
	ld a, [hli]
	add a, 1
	cpl
	ld e, a
	ld a, [hl]
	cpl
	ld d, a
	jr nc, :+
	inc d
:
	ld hl, wSceneCamera.x
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, SCROLL_PADDING_LEFT << 4
	add hl, bc
	add hl, de
	bit 7, h
	jr nz, .right
	ld hl, wSceneCamera.x
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, -1 << 4
	add hl, bc
	bit 7, h
	jr z, :+
	ld hl, 0
:
	ld a, l
	ld [wSceneCamera.x], a
	ld a, h
	ld [wSceneCamera.x + 1], a
	jr .done

.right
	; check if (entity.x <= camera.x + padding)
	ld hl, wEntity0_SpriteX
	; The value of de will be negative, often ending up in the OAM range.
	; Because of this, an inc is not sufficient on DMG; we must manually add 1.
	; Luckily cpl does not touch the carry flag.
	ld a, [hli]
	add a, 1
	cpl
	ld e, a
	ld a, [hl]
	cpl
	ld d, a
	jr nc, :+
	inc d
:
	ld hl, wSceneCamera.x
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, SCROLL_PADDING_RIGHT << 4
	add hl, bc
	add hl, de
	bit 7, h
	jr z, .done
	ld hl, wSceneCamera.x
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld bc, 1 << 4
	add hl, bc
	ld a, [wSceneBoundary.x]
	cp a, h
	jr nz, :+
	ld h, a
	ld l, 0
:
	ld a, l
	ld [wSceneCamera.x], a
	ld a, h
	ld [wSceneCamera.x + 1], a

.done
	ld hl, wSceneCamera.x + 1
	ld a, [hld]
	ld b, a
	ld a, [hli]
	REPT 4
		rr b
		rra
	ENDR
	ldh [hShadowSCX], a
	REPT 3
		rr b
		rra
	ENDR
	ld b, a
	ld a, [wSceneCamera.lastX]
	cp a, b
	ld a, b
	ld [wSceneCamera.lastX], a
	call nz, xRenderColumn
	ld hl, wSceneCamera.y + 1
	ld a, [hld]
	ld b, a
	ld a, [hli]
	REPT 4
		rr b
		rra
	ENDR
	ldh [hShadowSCY], a
	ret

; @input a: column of camera
; @input carry: set if moving right
; @preserves e
xRenderColumn:
	; Depending on the carry input, determine an offset for the column
	jr nc, :+
	add a, SCRN_X_B
:
	and a, 63
	ASSERT LOW(wSceneMap) == 0
	ld c, a
	ld b, HIGH(wSceneMap)
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
	ldh a, [hSystem]
	and a, a
	jr z, .noCgb
	ld a, 1
	ldh [rVBK], a
	ld a, [bc]
	push bc
	sub a, $80
	ld c, a
	ld b, HIGH(wSceneTileAttributes)
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
	REPT 4
		srl h
		rra
	ENDR
	ld e, a
	REPT SCRN_X_B - 1
		xor a, a ; clear carry
		ld a, e
		call xRenderColumn
		inc e
	ENDR
	xor a, a ; clear carry
	ld a, e
	jp xRenderColumn

SECTION "Draw scene", ROM0
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
	add a, LOW(.jumpTable)
	ld e, a
	adc a, HIGH(.jumpTable)
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
	ASSERT DRAWSCENE_END == 0
	dw DrawSceneExit
	ASSERT DRAWSCENE_VRAMCOPY == 1
	dw DrawSceneVramCopy
	ASSERT DRAWSCENE_BKG == 2
	dw DrawSceneBackground
	ASSERT DRAWSCENE_PLACEDETAIL == 3
	dw DrawScenePlaceDetail
	ASSERT DRAWSCENE_SPAWNEFFECT == 4
	dw DrawSceneSpawnEffect
	ASSERT DRAWSCENE_FILL == 5
	dw DrawSceneFill
	ASSERT DRAWSCENE_SETDOOR == 6
	dw DrawSceneSetDoor
	ASSERT DRAWSCENE_MEMCOPY == 7
	dw DrawSceneMemcopy
	ASSERT DRAWSCENE_SETCOLOR == 8
	dw DrawSceneSetColor

DrawSceneExit:
	pop af
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
	call VRAMCopy
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
		push de
		push hl
		call Rand
		pop hl
		pop de
		pop bc
		and a, 15 ; 1/16 chance
		jr z, .four
		dec a ; 1/16 chance
		jr z, .three
		cp a, 6 ; 7/16 chance
		ld a, 0
		jr nc, .two
		; 7/16 chance
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

DrawSceneSpawnEffect:
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
	ld d, HIGH(wSceneTileAttributes)
	ld a, [hli]
	ld c, [hl]
	inc hl
.loop
	ld [de], a
	inc e
	dec c
	jr nz, .loop
	ret

SECTION "Scene variables", WRAM0
wActiveScene:: ds 3

SECTION UNION "State variables", WRAM0, ALIGN[8]
wSceneMap:: ds SCENE_WIDTH * SCENE_HEIGHT
wSceneCollision:: ds SCENE_WIDTH * SCENE_HEIGHT
ASSERT !LOW(@)
wSceneTileAttributes:: ds 128

wSceneCamera::
.x dw
.y dw
.lastX db
wSceneBoundary::
.x db
.y db

SECTION "Scene Loop counter", HRAM
hSceneLoopCounter: db
hSceneTileOffset: db
