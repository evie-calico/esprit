INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"
INCLUDE "res/charmap.inc"

DEF DUNGEON_WIDTH EQU 64
DEF DUNGEON_HEIGHT EQU 64

; The dungeon renderer is hard-coded to use these 4 metatiles to draw floors and
; walls. Additional tiles should follow these metatiles.
; For example, stairs, which use an ID of 2, should be placed at $90.
RSSET $80
DEF BLANK_METATILE_ID RB 4
DEF STANDALONE_METATILE_ID RB 4
DEF TERMINAL_METATILE_ID RB 4
DEF FULL_METATILE_ID RB 4
DEF EXIT_METATILE_ID RB 4

SECTION "Init dungeon", ROM0
InitDungeon::
	ld a, [hCurrentBank]
	push af

	; Value init
	ld hl, wActiveDungeon
	ld a, BANK(xForestDungeon)
	ld [hli], a
	ld a, LOW(xForestDungeon)
	ld [hli], a
	ld a, HIGH(xForestDungeon)
	ld [hli], a
	ld a, GAMESTATE_DUNGEON
	ld [wGameState], a


	; Null init
	xor a, a
	ASSERT wDungeonMap + DUNGEON_WIDTH * DUNGEON_HEIGHT == wDungeonCameraX
	ASSERT wDungeonCameraX + 2 == wDungeonCameraY
	ASSERT wDungeonCameraY + 2 == wLastDungeonCameraX
	ASSERT wLastDungeonCameraX + 1 == wLastDungeonCameraY
	ld bc, DUNGEON_WIDTH * DUNGEON_HEIGHT + 4 + 2
	ld hl, wDungeonMap
	call MemSet
	ld c, 6
	ld hl, wEntityAnimation
	call MemSetSmall
	ld [wIsDungeonFading], a

	; Draw static debug map
	FOR I, 64
		ld a, 1
		ld [wDungeonMap + I / 4 + I * 64], a
		ld a, 2
		ld [wDungeonMap + 5 + (I & 1) * 2 + 64 * I], a
	ENDR

	; Null out all entities.
	FOR I, NB_ENTITIES
		lb bc, BANK(xLuvui), 5
		ld de, xLuvui
		ld h, HIGH(wEntity{d:I})
		call SpawnEntity
	ENDR
	ld a, BANK(xPounce)
	ld [wEntity0_Moves], a
	ld a, LOW(xPounce)
	ld [wEntity0_Moves + 1], a
	ld a, HIGH(xPounce)
	ld [wEntity0_Moves + 2], a

	; Load the active dungeon.
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	; Deref pointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
		; Deref tileset
		ASSERT Dungeon_Tileset == 0
		ld a, [hli]
		ld h, [hl]
		ld l, a
		ld bc, 20 * 16
		ld de, $8000 + BLANK_METATILE_ID * 16
		call VRAMCopy
	pop hl

	; Deref palette if on CGB
	ldh a, [hSystem]
	and a, a
	jr z, .skipCGB
		; Set palettes
		ld a, %11111111
		ld [wBGPaletteMask], a
		ld a, %11111111
		ld [wOBJPaletteMask], a
		ld a, 20
		ld [wFadeSteps], a
		ld a, $80 + 20 * 4
		ld [wFadeAmount], a
		ld a, -4
		ld [wFadeDelta], a

		ASSERT Dungeon_Palette == 2
		inc hl
		inc hl
		ld a, [hli]
		ld h, [hl]
		ld l, a

		ld bc, 8 * 12
		ld de, wBGPaletteBuffer
		call MemCopy
.skipCGB

	call InitUI
	ld b, BANK(.text)
	ld hl, .text
	call PrintHUD

	bankcall xDrawDungeon

	jp BankReturn
.text db "Hello, world!<END>"

SECTION "Dungeon State", ROM0
DungeonState::

	; If fading out, do nothing but animate entities and wait for the fade to
	; complete.
	ld a, [wIsDungeonFading]
	and a, a
	jr z, .notFading
	ld a, [wFadeSteps]
	and a, a
	jr nz, .dungeonRendering
	ld a, GAMESTATE_MENU
	ld [wGameState], a
	ret
.notFading

	; If only START is pressed, open pause menu.
	ld a, [hCurrentKeys]
	cp a, PADF_START
	jr nz, :+
		ld a, 1
		ld [wIsDungeonFading], a
		xor a, a
		; Set palettes
		ld a, %11111111
		ld [wBGPaletteMask], a
		ld a, %11111111
		ld [wOBJPaletteMask], a
		ld a, 20
		ld [wFadeSteps], a
		ld a, $80
		ld [wFadeAmount], a
		ld a, 4
		ld [wFadeDelta], a
		; Set all colors to white.
		ld a, $FF
		ld bc, 8 * 12
		ld hl, wBGPaletteBuffer
		call MemSet
:

	ld hl, wEntityAnimation.pointer
	ld a, [hli]
	or a, [hl]
	jr nz, .playAnimation
		bankcall xMoveEntities
		call ProcessEntities
		jr :+
.playAnimation
		bankcall xUpdateAnimation
:

.dungeonRendering
	; Scroll the map after moving entities.
	bankcall xHandleMapScroll
	bankcall xFocusCamera

	ld a, [wDungeonCameraX + 1]
	ld b, a
	ld a, [wDungeonCameraX]
	REPT 4
		srl b
		rra
	ENDR
	ldh [hShadowSCX], a
	ld a, [wDungeonCameraY + 1]
	ld b, a
	ld a, [wDungeonCameraY]
	REPT 4
		srl b
		rra
	ENDR
	ldh [hShadowSCY], a

	; Render entities after scrolling.
	call ResetShadowOAM
	bankcall xRenderEntities
	call UpdateEntityGraphics

	jp UpdateAttackWindow

SECTION "Draw dungeon", ROMX
xDrawDungeon:
	call xGetCurrentVram
	push hl
	; Now find the top-left corner of the map to begin drawing from.
	call xGetCurrentMap
	pop hl

	; Now copy the Dungeon map into VRAM
	; Initialize counters.
	ld a, 10
	ldh [hMapDrawY], a
.drawRow
	ld a, 11
	ld [hMapDrawX], a
	push hl
.drawTile
		push hl
			call xDrawTile
		pop hl
		ld c, 2
		call xVramWrapRight
		ld a, [hMapDrawX]
		dec a
		ld [hMapDrawX], a
		jr nz, .drawTile
	pop hl
	; Go to the next line of the map.
	ld a, 64 - 11
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, 2 * 32
	call xVramWrapDown
	ld a, [hMapDrawY]
	dec a
	ld [hMapDrawY], a
	jr nz, .drawRow
	ret

xHandleMapScroll:
	ld a, [wDungeonCameraX + 1]
	ld hl, wLastDungeonCameraX
	cp a, [hl]
	jr z, .checkY
	ld [hl], a
	jr nc, .drawRight
	; Draw a column on the left side
	call xGetCurrentVram
	push hl
	call xGetCurrentMap
	pop hl
	jr .drawColumn
.drawRight
	call xGetCurrentVram
	ld c, 20
	call xVramWrapRight
	push hl
	call xGetCurrentMap
	pop hl
	ld a, 10
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
.drawColumn
	ld a, 10
	ldh [hMapDrawY], a
.drawColumnLoop
	push hl
	call xDrawTile
	; While xDrawTile usually increments DE for horizontal drawing, we need to
	; add an offset to move vertically.
	ld a, 63
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	pop hl
	ld a, $40
	call xVramWrapDown
	ld a, [hMapDrawY]
	dec a
	ld [hMapDrawY], a
	jr nz, .drawColumnLoop
	ret
.checkY
	ld a, [wDungeonCameraY + 1]
	ASSERT wLastDungeonCameraX + 1 == wLastDungeonCameraY
	inc hl
	cp a, [hl]
	ret z
	ld [hl], a
	jr nc, .drawDown
	; Draw a column on the left side
	call xGetCurrentVram
	push hl
	call xGetCurrentMap
	pop hl
	jr .drawRow
.drawDown
	call xGetCurrentVram
	ld bc, $20 * 18
	add hl, bc
	ld a, h
	; If the address is still below $9C00, we do not yet need to wrap.
	cp a, $9C
	jr c, :+
	; Otherwise, wrap the address around to the top.
	sub a, $9C - $98
	ld h, a
:   push hl
	ld a, [wDungeonCameraX + 1]
	ld b, a
	ld a, [wDungeonCameraY + 1]
	add a, 9
	ld c, a
	call xGetMapPosition
	pop hl
.drawRow
	ld a, 11
	ldh [hMapDrawY], a
.drawRowLoop
	push hl
	call xDrawTile
	pop hl
	ld c, 2
	call xVramWrapRight
	ld a, [hMapDrawY]
	dec a
	ld [hMapDrawY], a
	jr nz, .drawRowLoop
	ret

; Get the current tilemap address according to the camera positions.
; @clobbers all
xGetCurrentVram:
	; Calculate the VRAM destination by (Camera >> 4) / 16 % 16 * 32
	ld a, [wDungeonCameraY + 1]
	and a, %00001111
	ld e, 0
	srl a
	rr e
	rra
	rr e
	ld d, a
	; hl = (Camera >> 8) & 15 << 4
	ld hl, $9800
	add hl, de ; Add to VRAM
	ld a, [wDungeonCameraX + 1]
	and a, %00001111
	add a, a
	; Now we have the neccessary X index on the tilemap.
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ret

; @return de: Current map postion
; @clobbers: all
xGetCurrentMap:
	ld a, [wDungeonCameraX + 1]
	ld b, a
	ld a, [wDungeonCameraY + 1]
	ld c, a
; @param b: X position
; @param c: Y position
; @return de: Current map postion
; @clobbers: a, hl
; @preserves: bc
xGetMapPosition::
	; Begin with Y
	ld a, c
	ld l, a
	ld h, 0
	ld de, wDungeonMap
	add hl, hl ; Camera Y * 2
	add hl, hl ; Camera Y * 4
	add hl, hl ; Camera Y * 8
	add hl, hl ; Camera Y * 16
	add hl, hl ; Camera Y * 32
	add hl, hl ; Camera Y * 64
	add hl, de ; wDungeonMap + CameraY * 64
	; Now X
	ld a, b
	; Use this add to move the value to de
	add a, l
	ld e, a
	adc a, h
	sub a, e
	ld d, a
	ret

; Draw a tile pointed to by HL to VRAM at DE. The user is expected to reserve
; HL, but can rely on DE being incremented.
xDrawTile:
	ld a, [de]
	inc e
	cp a, 1
	jr z, .wall
	and a, a
	ld b, BLANK_METATILE_ID
	jr z, .drawSingle
	; Multiply index by 4 and then offset a bit to accomodate the wall tiles.
	add a, a
	add a, a
	add a, BLANK_METATILE_ID + 8
	ld b, a
.drawSingle
:   ld a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	; After a STAT check, we have 17.75 safe cycles. The following code takes
	; 17 to write a metatile.
	ld a, b
	ld [hli], a
	inc a
	ld [hli], a
	inc a
	ld bc, $20 - 2
	add hl, bc
	ld b, a
:   ld a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, b
	ld [hli], a
	inc a
	ld [hli], a
	ret
.wall
	; Wall tiles are given special handling.
	dec e ; Tempoarirly undo the previous inc e
	push de
		call xGetMapAbove
	pop de
	and a, 1
	rlca
	ld b, a ; Store the 'above' bit in B
	push de
		call xGetMapBelow
	pop de
	inc e
	and a, 1
	or a, b
	; a = %11 where %10 is a tile above and %01 is a tile below.
	; If a is 0, however, this is a static, standalone tile.
	ld b, STANDALONE_METATILE_ID
	jr z, .drawSingle
	ld b, a
	; Now it's time to draw both halves.
	; Start with the top.
:   ld a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	; The following snippet takes at most 13/17 cycles.
	ld a, TERMINAL_METATILE_ID
	; If above us is a tile, switch from TERMINAL to FULL
	bit 1, b
	jr z, :+
	ld a, FULL_METATILE_ID
:   ld [hli], a
	inc a
	ld [hli], a
	; Jump to next row
	ld a, b ; make sure to reserve b
	ld bc, $20 - 2
	add hl, bc
	ld b, a
	; Now draw the bottom.
:   ld a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	; The following snippet takes at most 13/17 cycles.
	ld a, TERMINAL_METATILE_ID + 2
	; If below us is a tile, switch from TERMINAL to FULL
	bit 0, b
	jr z, :+
	ld a, FULL_METATILE_ID + 2
:   ld [hli], a
	inc a
	ld [hli], a
	ret

; Move the VRAM pointer to the right by 16 pixels, wrapping around to the left
; if needed.
; @param  c: Amount to add.
; @param hl: VRAM pointer
; @clobbers: a, b
xVramWrapRight:
	ld a, l
	and a, %11100000 ; Grab the upper bits, which should stay constant.
	ld b, a
	ld a, l
	add a, c
	and a, %00011111
	or a, b
	ld l, a
	ret

; Move the VRAM pointer down by 16 pixels, wrapping around to the top if needed.
; @param  a: Amount to add.
; @param hl: VRAM pointer
; @clobbers: a
xVramWrapDown:
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	; If the address is still below $9C00, we do not yet need to wrap.
	cp a, $9C
	ret c
	; Otherwise, wrap the address around to the top.
	ld h, $98
	ret

xGetMapAbove:
	ld a, e
	sub a, 64
	ld e, a
	jr nc, :+
	dec d
:   ld a, d
	ASSERT LOW(wDungeonMap) == 0
	cp a, HIGH(wDungeonMap)
	jr c, .forceTrue
	ld a, [de]
	ret
.forceTrue
	ld a, 1
	ret

xGetMapBelow:
	ld a, e
	add a, 64
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ASSERT LOW(wDungeonMap + 64 * 64) == 0
	cp a, HIGH(wDungeonMap + 64 * 64)
	jr nc, .forceTrue
	ld a, [de]
	ret
.forceTrue
	ld a, 1
	ret

SECTION UNION "State variables", WRAM0, ALIGN[8]
; This map uses 4096 bytes of WRAM, but is only ever used in dungeons.
; If more RAM is needed for other game states, it should be unionized with this
; map.
wDungeonMap: ds DUNGEON_WIDTH * DUNGEON_HEIGHT
wDungeonCameraX:: dw
wDungeonCameraY:: dw
; Only the neccessarily info is saved; the high byte.
wLastDungeonCameraX: db
wLastDungeonCameraY: db
; A far pointer to the current dungeon. Bank, Low, High.
wActiveDungeon: ds 3
wIsDungeonFading: db

SECTION "Map drawing counters", HRAM
hMapDrawX: db
hMapDrawY: db
