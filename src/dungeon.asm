INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"
INCLUDE "item.inc"

; The dungeon renderer is hard-coded to use these 4 metatiles to draw floors and
; walls. Additional tiles should follow these metatiles.
; For example, stairs, which use an ID of 2, should be placed at $90.
RSSET $80
DEF BLANK_METATILE_ID RB 4
DEF STANDALONE_METATILE_ID RB 4
DEF TERMINAL_METATILE_ID RB 4
DEF FULL_METATILE_ID RB 4
DEF EXIT_METATILE_ID RB 4
DEF ITEM_METATILE_ID RB 4 * 4

SECTION "Init dungeon", ROM0
; Switch to the dungeon state.
; @clobbers: bank
InitDungeon::
	; Value init
	ld hl, wActiveDungeon
	ld a, BANK(xForestDungeon)
	ld [hli], a
	ld a, LOW(xForestDungeon)
	ld [hli], a
	ld a, HIGH(xForestDungeon)
	ld [hli], a

	; Null init
	xor a, a
	ld c, 6
	ld hl, wEntityAnimation
	call MemSetSmall
	ld c, SIZEOF("entity.asm BSS")
	ld hl, STARTOF("entity.asm BSS")
	call MemSetSmall

	; Draw debug map
	bankcall xGenerateScraper
	ld a, 3 ; Item0
	ld [wDungeonMap + 30 + 30 * 64], a
	ld a, 4 ; Item1
	ld [wDungeonMap + 31 + 30 * 64], a
	ld a, 5 ; Item2
	ld [wDungeonMap + 32 + 30 * 64], a
	ld a, 6 ; Item3
	ld [wDungeonMap + 33 + 30 * 64], a

	; Null out all entities.
	FOR I, NB_ENTITIES
		lb bc, BANK(xLuvui), 5
		ld de, xLuvui
		ld h, HIGH(wEntity{d:I})
		call SpawnEntity
	ENDR
	ld hl, wEntity0_Moves
	ld a, BANK(xPounce)
	ld [hli], a
	ld a, LOW(xPounce)
	ld [hli], a
	ld a, HIGH(xPounce)
	ld [hli], a
	ld a, BANK(xBite)
	ld [hli], a
	ld a, LOW(xBite)
	ld [hli], a
	ld a, HIGH(xBite)
	ld [hli], a
	ld a, BANK(xScratch)
	ld [hli], a
	ld a, LOW(xScratch)
	ld [hli], a
	ld a, HIGH(xScratch)
	ld [hli], a
	ld a, BANK(xPounce)
	ld [hli], a
	ld a, LOW(xPounce)
	ld [hli], a
	ld a, HIGH(xPounce)
	ld [hli], a
; Re-initializes some aspects of the dungeon, such as rendering the map.
; @clobbers: bank
SwitchToDungeonState::
	ld a, GAMESTATE_DUNGEON
	ld [wGameState], a
	xor a, a
	ld [wIsDungeonFading], a

	call InitUI

	ld h, HIGH(wEntity0)
.loop
	ld l, LOW(wEntity0_Bank)
	ld a, [hli]
	and a, a
	call nz, LoadEntityGraphics
.next
	inc h
	ld a, h
	cp a, HIGH(wEntity0) + NB_ENTITIES
	jp nz, .loop

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

	ld a, 20
	ld [wFadeSteps], a
	ld a, $80 + 20 * 4
	ld [wFadeAmount], a
	ld a, -4
	ld [wFadeDelta], a

	; Deref palette if on CGB
	ldh a, [hSystem]
	and a, a
	jp z, .skipCGB
		; Set palettes
		ld a, %11111111
		ld [wBGPaletteMask], a
		ld a, %11111111
		ld [wOBJPaletteMask], a

		ASSERT Dungeon_Palette == 2
		inc hl
		inc hl
		ld a, [hli]
		ld h, [hl]
		ld l, a

		push hl
		ld c, 3
		ld de, wBGPaletteBuffer + 3 * 12
		call MemCopySmall
		pop hl

		push hl
		ld c, 3
		ld de, wBGPaletteBuffer + 4 * 12
		call MemCopySmall
		pop hl

		push hl
		ld c, 3
		ld de, wBGPaletteBuffer + 5 * 12
		call MemCopySmall
		pop hl

		push hl
		ld c, 3
		ld de, wBGPaletteBuffer + 6 * 12
		call MemCopySmall
		pop hl

		; Load first 3 palettes
		ld c, 3 * 12
		ld de, wBGPaletteBuffer
		call MemCopySmall

		ld hl, wActiveDungeon + 1
		ld a, [hli]
		ld h, [hl]
		ld l, a
		inc hl
		inc hl
		inc hl
		inc hl
		ASSERT Dungeon_Items == 4
		; Push each item onto the stack :)
		ld b, DUNGEON_ITEM_COUNT
	.pushItems
		ld a, [hli]
		push af
		ld a, [hli]
		ld e, a
		ld a, [hli]
		ld d, a
		push de
		dec b
		jr nz, .pushItems

	.color
		; Now pop each in order and load their palettes and graphics
		ld b, DUNGEON_ITEM_COUNT
		ld de, wBGPaletteBuffer + 6 * 12 + 3
	.copyItemColor
		pop hl
		pop af
		rst SwapBank
		ASSERT Item_Palette == 0
		ld a, [hli]
		ld h, [hl]
		ld l, a
		ld c, 9
		call MemCopySmall
		ld a, e
		sub a, 21
		ld e, a
		ld a, d
		sbc a, 0
		ld d, a
		dec b
		jr nz, .copyItemColor
.skipCGB
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	inc hl
	inc hl
	inc hl
	ASSERT Dungeon_Items == 4
	; Push each item onto the stack :)
	ld b, DUNGEON_ITEM_COUNT
.pushItems2
	ld a, [hli]
	push af
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push de
	dec b
	jr nz, .pushItems2

.items
	; And finally, copy the graphics
	ld b, DUNGEON_ITEM_COUNT
	ld de, $8000 + (ITEM_METATILE_ID + 3 * 4) * 16
.copyItemGfx
	pop hl
	pop af
	rst SwapBank
	inc hl
	inc hl
	ASSERT Item_Graphics == 2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld c, 16 * 4
	call VRAMCopySmall
	ld a, e
	sub a, 128
	ld e, a
	ld a, d
	sbc a, 0
	ld d, a
	dec b
	jr nz, .copyItemGfx

	ld a, BANK(xFocusCamera)
	rst SwapBank
	call xFocusCamera
	ld a, [wDungeonCameraX + 1]
	ld [wLastDungeonCameraX], a
	ld a, [wDungeonCameraY + 1]
	ld [wLastDungeonCameraY], a
	ld a, BANK(xDrawDungeon)
	rst SwapBank
	jp xDrawDungeon

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
		ld b, BANK(xPauseMenu)
		ld de, xPauseMenu
		call AddMenu
		ld a, GAMESTATE_MENU
		ld [wGameState], a
		xor a, a
		ld [wSTATTarget], a
		ld [wSTATTarget + 1], a
		ret
.notFading

	; If only START is pressed, open pause menu.
	ld a, [hCurrentKeys]
	cp a, PADF_START
	jr nz, :+
		xor a, a
		ld [wShowMoves], a
		ld a, 1
		ld [wIsDungeonFading], a
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
	bankcall xRenderEntities
	call UpdateEntityGraphics

	ld a, [wPrintString]
	and a, a
	call nz, DrawPrintString

	jp UpdateAttackWindow

SECTION "Get Item", ROM0
; Get a dungeon item given an index in b
; @param b: Item ID
; @return b: Item bank
; @return hl: Item pointer
GetDungeonItem::
	ld hl, wActiveDungeon
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ASSERT Dungeon_Items == 4
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, b
	add a, b
	add a, b
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

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
xDrawTile::
	ldh a, [hSystem]
	and a, a
	jr z, :+
	push hl
:
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
	jr .exit

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
.exit
	ldh a, [hSystem]
	and a, a
	ret z
	; If on CGB, repeat for colors.
	pop hl
	; Switch bank
	ld a, 1
	ldh [rVBK], a
	ld bc, $20 - 2
	; Wait for VRAM.
	; On the CGB, we have twice as much time.
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-

	dec e
	ld a, [de]
	inc e
	ld [hli], a
	ld [hli], a
	add hl, bc
	ld [hli], a
	ld [hli], a
	xor a, a
	ldh [rVBK], a
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

; A simple dungeon generator that works by randomly stepping around and clearing
; tiles.
xGenerateScraper::
	ld a, TILE_WALL
	ld bc, DUNGEON_WIDTH * DUNGEON_HEIGHT
	ld hl, wDungeonMap
	call MemSet

	xor a, a
	ld [wMapgenLoopCounter], a
	; Get a pointer to the center tile of the map.
	lb bc, DUNGEON_WIDTH / 2, DUNGEON_HEIGHT / 2
	ld hl, wDungeonMap + DUNGEON_WIDTH / 2 + DUNGEON_WIDTH * (DUNGEON_HEIGHT / 2)
.loop
	push bc
	call Rand
	pop bc
	and a, %11
	ASSERT UP == 0
	jr z, .up
	ASSERT RIGHT == 1
	dec a
	jr z, .right
	ASSERT DOWN == 2
	dec a
	jr z, .down
	ASSERT LEFT == 3
.left
	dec b
	jr .write
.up
	dec c
	jr .write
.right
	inc b
	jr .write
.down
	inc c
.write
	ld a, b
	cp a, -1
	jr nz, :+
	inc b
:	cp a, DUNGEON_WIDTH
	jr nz, :+
	dec b
:	ld a, c
	cp a, -1
	jr nz, :+
	inc c
:	cp a, DUNGEON_HEIGHT
	jr nz, :+
	dec c
:
	ASSERT DUNGEON_WIDTH * 4 == 256
	ld a, c
	add a, a ; a * 2
	add a, a ; a * 4
	ld l, a
	ld h, 0
	add hl, hl ; a * 8
	add hl, hl ; a * 16
	add hl, hl ; a * 32
	add hl, hl ; a * 64
	ASSERT DUNGEON_WIDTH == 64
	ld de, wDungeonMap
	add hl, de
	ld a, b
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a

	ld [hl], TILE_CLEAR

	ld hl, wMapgenLoopCounter
	dec [hl]
	jr nz, .loop
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

wMapgenLoopCounter: db

SECTION "Map drawing counters", HRAM
hMapDrawX: db
hMapDrawY: db
