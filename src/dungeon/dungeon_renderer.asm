include "dungeon.inc"
include "hardware.inc"

section "Draw dungeon", romx
xDrawDungeon::
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

xHandleMapScroll::
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
	assert wLastDungeonCameraX + 1 == wLastDungeonCameraY
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
	; hl = (Camera >> 8) & 15.0
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
	inc de
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
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .drawSingle
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
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ld a, b
	ld [hli], a
	inc a
	ld [hli], a
	jr .exit

.wall
	; Wall tiles are given special handling.
	dec de ; Tempoarirly undo the previous inc e
	push de
		call xGetMapAbove
	pop de
	cp a, TILE_WALL
	ld b, 0
	jr nz, :+
	ld b, %10
:
	push de
		call xGetMapBelow
	pop de
	inc de
	cp a, TILE_WALL
	ld a, 1
	jr z, :+
	dec a
:
	or a, b
	; a = %11 where %10 is a tile above and %01 is a tile below.
	; If a is 0, however, this is a static, standalone tile.
	ld b, STANDALONE_METATILE_ID
	jr z, .drawSingle
	ld b, a
	; Now it's time to draw both halves.
	; Start with the top.
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	; The following snippet takes at most 13/17 cycles.
	ld a, TERMINAL_METATILE_ID
	; If above us is a tile, switch from TERMINAL to FULL
	bit 1, b
	jr z, :+
	ld a, FULL_METATILE_ID
:
	ld [hli], a
	inc a
	ld [hli], a
	; Jump to next row
	ld a, b ; make sure to reserve b
	ld bc, $20 - 2
	add hl, bc
	ld b, a
	; Now draw the bottom.
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	; The following snippet takes at most 13/17 cycles.
	ld a, TERMINAL_METATILE_ID + 2
	; If below us is a tile, switch from TERMINAL to FULL
	bit 0, b
	jr z, :+
	ld a, FULL_METATILE_ID + 2
:
	ld [hli], a
	inc a
	ld [hli], a
.exit
	ldh a, [hSystem]
	and a, a
	ret z

	; If on CGB, repeat for colors.
	pop hl
	; Switch bank
	ld bc, $20 - 2

	call GetTileColor
	ld [hli], a
	call GetTileColor
	ld [hli], a
	add hl, bc
	call GetTileColor
	ld [hli], a
	call GetTileColor
	ld [hli], a

	xor a, a
	ldh [rVBK], a
	ret

; Returns the colors of a given tile.
; This is usually straightforward, but levels like the lake interpret
; terminals differently and need to adjust their palettes.
; The code is kinda messy but for such a simple case it doesn't matter much.
; Returns with VRAM accessible
GetTileColor:
	ld a, [wDungeonAlternateColorTerminals]
	and a, a
	jr z, .normalColor
	; If the value is 2, only color standalones
	dec a
	jr nz, .standalone

	xor a, a
	ldh [rVBK], a

	; Wait for VRAM.
	; On the CGB, we have twice as much time.
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-

	ld a, [hl]
	cp a, STANDALONE_METATILE_ID
	jr c, .normalColor
	cp a, TERMINAL_METATILE_ID + 4
	jr nc, .normalColor

	ld a, 1
	ldh [rVBK], a
	xor a, a
	ret

; Standalone terminals only
.standalone

	xor a, a
	ldh [rVBK], a
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-

	ld a, [hl]
	cp a, STANDALONE_METATILE_ID
	jr c, .normalColor
	cp a, STANDALONE_METATILE_ID + 4
	jr nc, .normalColor

	ld a, 1
	ldh [rVBK], a
	xor a, a
	ret

.normalColor
	ld a, 1
	ldh [rVBK], a

	dec de ; this is undone after the waitloop

:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-

	ld a, [de]
	inc de ; see above
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
	assert low(wDungeonMap) == 0
	cp a, high(wDungeonMap)
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
	assert low(wDungeonMap + 64 * 64) == 0
	cp a, high(wDungeonMap + 64 * 64)
	jr nc, .forceTrue
	ld a, [de]
	ret
.forceTrue
	ld a, 1
	ret

section "Map drawing counters", hram
hMapDrawX: db
hMapDrawY: db

section "wDungeonAlternateColorTerminals", wram0
wDungeonAlternateColorTerminals:: db
