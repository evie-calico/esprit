include "defines.inc"
include "dungeon.inc"
include "entity.inc"

section "evscript Driver", rom0
; @param de: Variable pool
; @param hl: Script pointer
; @param bank: Script bank
; @return hl: New script pointer. 0 after a return.
; @return bank: New script bank.
; @preserves de
ExecuteScript::
	ld a, h
	or a, l
	ret z
.next
	ld a, [hli]
	push hl
	add a, low(EvscriptBytecodeTable >> 1)
	ld l, a
	adc a, high(EvscriptBytecodeTable >> 1)
	sub a, l
	ld h, a
	add hl, hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld b, h
	ld c, l
	pop hl
	push de
	call .callBC
	pop de
	jr ExecuteScript.next

.callBC
	push bc
	ret

section "evscript Bytecode table", rom0, ALIGN[1]
EvscriptBytecodeTable:
	; Control
	dw StdReturn
	dw StdYield
	; goto
	dw StdJump
	dw StdJumpIfTrue
	dw StdJumpIfFalse
	; Moves
	dw StdPut
	dw StdMove
	; 8-bit ops
	dw StdAdd
	dw StdSub
	dw StdBinaryAnd
	dw StdEqu
	dw StdNotEqu
	dw StdLessThan
	dw StdGreaterThan
	dw StdLessThanEqu
	dw StdGreaterThanEqu
	dw StdLogicalAnd
	dw StdLogicalOr

	; Engine extensions
	dw ScriptRand
	dw ScriptRandRange
	dw ScriptIsCgb
	dw ScriptPrint
	dw ScriptPlayMusic
	dw ScriptSay
	dw ScriptPrintWait
	dw ScriptGetFlag
	; Mapgen Utilities
	dw ScriptMapPutTile
	dw ScriptMapGetTile
	dw ScriptMapStepDir
	dw ScriptMap3x3isEmpty
	; Sprite drawing
	dw ScriptDrawSprite
	; NPC commands
	dw ScriptNPCWalk
	dw ScriptNPCSetFrame
	dw ScriptNPCSetDirection
	dw ScriptNPCLockPlayer
	dw ScriptNPCFacePlayer
	dw ScriptEnterDungeon

section "evscript Return", rom0
StdReturn:
	ld hl, 0
StdYield:
	pop de ; pop return address
	pop de ; pop pool pointer
	ret

section "evscript Goto", rom0
StdJump:
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

StdJumpIfTrue:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [bc]
	and a, a
	jr nz, StdJump
.fail
	inc hl
	inc hl
	ret

StdJumpIfFalse:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [bc]
	and a, a
	jr z, StdJump
.fail
	inc hl
	inc hl
	ret

section "evscript Put", rom0
StdPut:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [hli]
	ld [bc], a
	ret

section "evscript Mov", rom0
StdMove:
	; Load dest
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	; Load source
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	; Move
	ld a, [de]
	ld [bc], a
	ret

section "evscript 8-bit Operations", rom0
; @param de: pool
; @param hl: script pointer
; @return a: lhs
; @return b: rhs
OperandPrologue:
	ld a, [hli] ; lhs offset
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	; de is preserved & variable is pointed to by bc
	ld a, [hli]
	push hl
		ld l, a
		ld h, 0
		add hl, de
		ld a, [bc]
		ld b, [hl]
	pop hl
	ret

StdAdd:
	call OperandPrologue
	add a, b ; Here is the actual operation
	jr StoreEpilogue

StdSub:
	call OperandPrologue
	sub a, b ; Here is the actual operation
	jr StoreEpilogue

StdBinaryAnd:
	call OperandPrologue
	and a, b
	jr StoreEpilogue

StdEqu:
	call OperandPrologue
	cp a, b
	ld a, 0
	jr nz, StoreEpilogue
	inc a
	jr StoreEpilogue

StdNotEqu:
	call OperandPrologue
	cp a, b
	ld a, 0
	jr z, StoreEpilogue
	inc a
	jr StoreEpilogue

StdLessThan:
	call OperandPrologue
	cp a, b
	ld a, 0
	jr nc, StoreEpilogue
	inc a
	jr StoreEpilogue

StdGreaterThan:
	call OperandPrologue
	cp a, b
	jr z, .zero
	jr nc, .zero
	ld a, 1
	jr StoreEpilogue
.zero
	xor a, a
	jr StoreEpilogue

StdLessThanEqu:
	call OperandPrologue
	cp a, b
	jr z, .one
	jr c, .one
	xor a, a
	jr StoreEpilogue
.one
	ld a, 1
	jr StoreEpilogue

StdGreaterThanEqu:
	call OperandPrologue
	cp a, b
	ld a, 0
	jr c, StoreEpilogue
	inc a
	jr StoreEpilogue

StdLogicalAnd:
	call OperandPrologue
	and a, a
	jr z, StoreEpilogue
	ld a, b
	and a, a
	jr z, StoreEpilogue
	ld a, 1
	jr StoreEpilogue

StdLogicalOr:
	call OperandPrologue
	and a, a
	jr nz, .true
	ld a, b
	and a, a
	jr z, StoreEpilogue
.true
	ld a, 1
	; fallthrough
; This is stored in the middle so both variable and constant operations can
; reach it.
StoreEpilogue:
	ld b, a
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, b
	ld [de], a
	ret

section "evscript ScriptRand", rom0
ScriptRand:
	rst Rand8
	ld b, a
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, b
	ld [de], a
	ret

section "evscript ScriptIsCgb", rom0
ScriptIsCgb:
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a

	ldh a, [hSystem]
	and a, a
	ld a, 0
	jr z, :+
	inc a
:
	ld [de], a
	ret

section "evscript ScriptPrint", rom0
ScriptSay:
	ld a, 2
	ld [wTextLetterDelay], a
ScriptPrint:
	ld de, wPrintString
	ldh a, [hCurrentBank]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	jp StdYield

section "evscript ScriptPrintWait", rom0
ScriptPrintWait:
	ld a, [wTextSrcPtr + 1]
	inc a
	ret z
	dec hl
	jp StdYield

section "evscript ScriptGetFlag", rom0
ScriptGetFlag:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [bc]
	ld c, a

	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	push hl
		call GetFlag
		and a, [hl]
	pop hl
	ld a, 0
	jr z, :+
	inc a
:
	ld [de], a
	ret

section "Map Get/Put Prologue", rom0
MapGetPutPrologue:
	push de
	ld a, [hli]
	push hl
		ld l, a
		ld h, 0
		add hl, de
		ld a, [hl]
		and a, a
		jr z, .oneX
		bit 7, a
		jr nz, .oneX
		cp a, DUNGEON_WIDTH - 1
		jr c, .nothingX
	.farX
		ld a, DUNGEON_WIDTH - 2
		jr .storeX
	.oneX
		ld a, 1
	.storeX
		ld [hl], a
	.nothingX
	pop hl
	ld a, [hld]
	push hl
		ld l, a
		ld h, 0
		add hl, de
		ld a, [hl]
		and a, a
		jr z, .oneY
		bit 7, a
		jr nz, .oneY
		cp a, DUNGEON_HEIGHT - 3
		jr c, .nothingY
	.farY
		ld a, DUNGEON_HEIGHT - 4
		jr .storeY
	.oneY
		ld a, 1
	.storeY
		ld [hl], a
	.nothingY
	pop hl
	ld a, [hli]
	push hl
	ld h, d
	ld l, e
	ld c, a
	ld b, 0
	add hl, bc
	ld b, [hl]
	pop hl
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, [de]
	push hl
		assert DUNGEON_WIDTH * 4 == 256
		add a, a ; a * 2
		add a, a ; a * 4
		ld l, a
		ld h, 0
		add hl, hl ; a * 8
		add hl, hl ; a * 16
		add hl, hl ; a * 32
		add hl, hl ; a * 64
		assert DUNGEON_WIDTH == 64
		ld de, wDungeonMap
		add hl, de
		ld a, b
		add a, l
		ld c, a
		adc a, h
		sub a, c
		ld b, a
	pop hl
	pop de
	ret

section "evscript ScriptMapPutTile", rom0
ScriptMapPutTile:
	call MapGetPutPrologue
	; get return register
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	; and copy it into the tile
	ld a, [de]
	ld [bc], a
	ret

section "evscript ScriptMapGetTile", rom0
ScriptMapGetTile:
	call MapGetPutPrologue
	; get return register
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	; and copy the tile into it
	ld a, [bc]
	ld [de], a
	ret

section "evscript ScriptMapStepDir", rom0
ScriptMapStepDir:
	ld a, [hli]
	push hl
		ld l, a
		ld h, 0
		add hl, de
		ld a, [hl]
	pop hl
	add a, a
	add a, low(DirectionVectors)
	ld c, a
	adc a, high(DirectionVectors)
	sub a, c
	ld b, a
	ld a, [hli]
	push hl
		ld l, a
		ld h, 0
		add hl, de
		ld a, [bc]
		inc bc
		add a, [hl]
		ld [hl], a
	pop hl
	ld a, [hli]
	push hl
		ld l, a
		ld h, 0
		add hl, de
		ld a, [bc]
		add a, [hl]
		ld [hl], a
	pop hl
	ret

section "evscript ScriptMapIsStandalone", rom0
ScriptMap3x3isEmpty:
	call MapGetPutPrologue
	; get return register
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a

	; Start from the top left
	rept 3
		call .checkRow
		jr nz, .fail
	endr

	db LD_A_PREFIX
.fail
	xor a, a
	ld [de], a
	ret

; Check three tiles from left to right
; nz == fail
; adds 2 to BC
.checkRow
	ld a, [bc]
	and a, a
	ret nz
	inc bc
	ld a, [bc]
	and a, a
	ret nz
	inc bc
	ld a, [bc]
	and a, a
	ret nz
	ld a, c
	add a, DUNGEON_WIDTH - 2
	ld c, a
	adc a, b
	sub a, c
	ld b, a
	xor a, a
	ret

section "evscript ScriptDrawSprite", rom0
ScriptDrawSprite:
	ld a, [hli]
	push hl
		ld l, a
		ld h, 0
		add hl, de
		ld a, [hli]
		ld c, a
		ld a, [hli]
		ld b, a
		ld a, [hli]
		ld d, a
		ld a, [hli]
		ld e, a
		call RenderSimpleSprite
	pop hl
	ret

section "evscript ScriptNPCWalk", rom0
ScriptNPCWalk:
	; TODO: Most NPC operations are simply manipulating data in memory. This would be a good application for pointers, arrays, and function support.
	; For now, we use this bytecode instead.
	ld a, [hli]
	add a, high(wEntity0)
	jr nc, :+
	ld a, [wActiveEntity]
:
	ld d, a
	ld e, low(wEntity0_SpriteY)
	ld a, [de]
	ld c, a
	inc e
	ld a, [de]
	ld b, a
	ld a, [hli]
	add a, c
	ld c, a
	ld a, [hli]
	adc a, b
	ld [de], a
	dec e
	ld a, c
	ld [de], a
	inc e
	inc e
	ld a, [de]
	ld c, a
	inc e
	ld a, [de]
	ld b, a
	ld a, [hli]
	add a, c
	ld c, a
	ld a, [hli]
	adc a, b
	ld [de], a
	dec e
	ld a, c
	ld [de], a
	ret

section "evscript ScriptNPCSetFrame", rom0
ScriptNPCSetFrame:
	ld e, low(wEntity0_Frame)
	jr ScriptNPCSet

ScriptNPCSetDirection:
	ld e, low(wEntity0_Direction)
; @param e: field to set
ScriptNPCSet:
	ld a, [hli]
	add a, high(wEntity0)
	jr nc, :+
	ld a, [wActiveEntity]
:
	ld d, a
	ld a, [hli]
	ld [de], a
	ret

section "evscript ScriptNPCLockPlayer", rom0
ScriptNPCLockPlayer:
	ld a, [wSceneMovementLocked]
	xor a, 1
	ld [wSceneMovementLocked], a
	ret

section "evscript ScriptNPCFacePlayer", rom0
ScriptNPCFacePlayer:
	push hl

	ld de, wEntity0_Direction
	ld a, [wActiveEntity]
	ld h, a
	ld l, low(wEntity0_Direction)
	ld a, [de]
	add a, 2
	and a, 3
	ld [hl], a

	pop hl
	ret

section "evscript ScriptPlayMusic", rom0
ScriptPlayMusic:
	ldh a, [hCurrentBank]
	push af
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	push hl
	call StartSong
	pop hl
	jp BankReturn

section "evscript ScriptEnterDungeon", rom0
ScriptEnterDungeon:
	ld bc, wActiveDungeon
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hli]
	ld [bc], a
	inc bc
	ld a, [hli]
	ld [bc], a

	call FadeToBlack

	ld bc, wFadeCallback
	ld a, low(EnterNewFloor)
	ld [bc], a
	inc bc
	ld a, high(EnterNewFloor)
	ld [bc], a
	ret

section "evscript ScriptRandRange", rom0
ScriptRandRange:
	ld a, [hli]
	ld b, a
	ld a, [hli]
	push hl
	ld h, b
	ld l, a
	ld a, l
	sub a, h
	ld l, a
	push de
	call RandRange
	pop de
	pop hl
	; Time to set the return value.
	; The random number is currently stored in `a`
	ld b, a
	ld a, [hli]
	; add de, a
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	; Now store the result!
	ld a, b
	ld [de], a
	ret