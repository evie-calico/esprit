INCLUDE "defines.inc"
INCLUDE "hardware.inc"
INCLUDE "scene.inc"

SECTION "Debug Scene", ROMX
	scene_background Grass, "res/scenes/grass_bkg.2bpp"
	scene_detail Bush, "res/scenes/bush_detail.2bpp", "res/scenes/bush_detail.map", 3, 2, 1

	xDebugScene:: scene 64, 64, 64, 64, 64, 64, 64, 64, \
			256, 256, \ ; width and height
			$EA751B27, \ ; Seed
			null ; Initial script
		load_background_palette GrassGreen, "res/scenes/grass_bkg.pal8"
		load_tiles Grass, GrassGreen
		load_tiles Bush, GrassGreen
		draw_bkg Grass
		scatter_details_row 0, 0, SCENE_WIDTH - 3, 3, 4, 8, Bush
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
	add a, Scene_Seed
	ld l, a
	adc a, h
	sub a, l
	ld h, a
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

	jp RenderScene

SECTION "Scene State", ROM0
SceneState::
	ret

SECTION "Render scene", ROM0
RenderScene:
	ld hl, wSceneMap
	ld de, $9800
	ld b, SCRN_VY_B
:
	ld c, SCRN_VX_B
	call VRAMCopySmall
	dec b
	jr z, .attributes
	ld a, SCENE_WIDTH - SCRN_VX_B
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	jr :-

.attributes
	ldh a, [hSystem]
	and a, a
	ret z
	ld a, 1
	ldh [rVBK], a
	ld hl, wSceneMap
	ld de, $9800
	ld b, SCRN_VY_B
:
	ld c, SCRN_VX_B
.copy
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .copy
	ld a, [hli]
	push de
	ld d, HIGH(wSceneTileAttributes)
	sub a, $80
	ld e, a
	ld a, [de]
	pop de
	ld [de], a
	inc de
	dec c
	jr nz, .copy
	dec b
	jr z, .done
	ld a, SCENE_WIDTH - SCRN_VX_B
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	jr :-

.done
	xor a, a
	ldh [rVBK], a
	ret

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
	inc hl
	inc hl
	inc hl
	inc hl
	inc hl
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

SECTION "Scene Loop counter", HRAM
hSceneLoopCounter: db
hSceneTileOffset: db
