INCLUDE "defines.inc"
INCLUDE "dungeon.inc"
INCLUDE "entity.inc"

SECTION "evscript Driver", ROM0
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
	add a, LOW(EvscriptBytecodeTable >> 1)
	ld l, a
	adc a, HIGH(EvscriptBytecodeTable >> 1)
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

SECTION "evscript Bytecode table", ROM0, ALIGN[1]
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
	dw ScriptIsCgb
	dw ScriptPrint
	dw ScriptSay
	dw ScriptPrintWait
	dw ScriptGetFlag
	; Mapgen Utilities
	dw ScriptMapPutTile
	dw ScriptMapGetTile
	dw ScriptMapStepDir
	; Sprite drawing
	dw ScriptDrawSprite
	; NPC commands
	dw ScriptNPCWalk
	dw ScriptNPCSetFrame
	dw ScriptNPCSetDirection
	dw ScriptNPCLockPlayer
	dw ScriptNPCFacePlayer

SECTION "evscript Return", ROM0
StdReturn:
	ld hl, 0
StdYield:
	pop de ; pop return address
	pop de ; pop pool pointer
	ret

SECTION "evscript Goto", ROM0
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

SECTION "evscript Put", ROM0
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

SECTION "evscript Mov", ROM0
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

SECTION "evscript 8-bit Operations", ROM0
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

SECTION "evscript ScriptRand", ROM0
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

SECTION "evscript ScriptIsCgb", ROM0
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

SECTION "evscript ScriptPrint", ROM0
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

SECTION "evscript ScriptPrintWait", ROM0
ScriptPrintWait:
	ld a, [wTextSrcPtr + 1]
	inc a
	ret z
	dec hl
	jp StdYield

SECTION "evscript ScriptGetFlag", ROM0
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

SECTION "Map Get/Put Prologue", ROM0
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
		ASSERT DUNGEON_WIDTH * 4 == 256
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
		ld c, a
		adc a, h
		sub a, c
		ld b, a
	pop hl
	pop de
	ret

SECTION "evscript ScriptMapPutTile", ROM0
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

SECTION "evscript ScriptMapGetTile", ROM0
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

SECTION "evscript ScriptMapStepDir", ROM0
ScriptMapStepDir:
	ld a, [hli]
	push hl
		ld l, a
		ld h, 0
		add hl, de
		ld a, [hl]
	pop hl
	add a, a
	add a, LOW(DirectionVectors)
	ld c, a
	adc a, HIGH(DirectionVectors)
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

SECTION "evscript ScriptDrawSprite", ROM0
ScriptDrawSprite:
	; TODO: this would be a good application for structs in evscript.
	; We know these 4 variables are always going to exist in a group, so we
	; *should* load them as such. It would be faster and save space.
	; This current solution is fragile compared to proper structure support.
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

SECTION "evscript ScriptNPCWalk", ROM0
ScriptNPCWalk:
	; TODO: Most NPC operations are simply manipulating data in memory. This would be a good application for pointers, arrays, and function support.
	; For now, we use this bytecode instead.
	ld a, [hli]
	add a, HIGH(wEntity0)
	jr nc, :+
	ld a, [wActiveEntity]
:
	ld d, a
	ld e, LOW(wEntity0_SpriteY)
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

SECTION "evscript ScriptNPCSetFrame", ROM0
ScriptNPCSetFrame:
	ld e, LOW(wEntity0_Frame)
	jr ScriptNPCSet

ScriptNPCSetDirection:
	ld e, LOW(wEntity0_Direction)
; @param e: field to set
ScriptNPCSet:
	ld a, [hli]
	add a, HIGH(wEntity0)
	jr nc, :+
	ld a, [wActiveEntity]
:
	ld d, a
	ld a, [hli]
	ld [de], a
	ret

SECTION "evscript ScriptNPCLockPlayer", ROM0
ScriptNPCLockPlayer:
	ld a, [wSceneMovementLocked]
	xor a, 1
	ld [wSceneMovementLocked], a
	ret

SECTION "evscript ScriptNPCFacePlayer", ROM0
ScriptNPCFacePlayer:
	push hl

	ld de, wEntity0_SpriteY
	ld a, [wActiveEntity]
	ld h, a
	ld l, LOW(wEntity0_SpriteY)
	ld a, [de]
	sub a, [hl]
	ld c, a
	inc de ; Use 16-bit incs to preserve carry
	inc hl
	ld a, [de]
	sbc a, [hl]
	ld b, a
	push bc ; Push Y difference
		ASSERT Entity_SpriteY + 2 == Entity_SpriteX
		inc e
		inc l
		ld a, [de]
		sub a, [hl]
		ld c, a
		inc de
		inc hl
		ld a, [de]
		sbc a, [hl]
		ld b, a
		; bc = X difference
	pop de ; de = Y difference
	; Figure out which axis has the greater magnitude, then check its sign.
	; hl = wEntityN_SpriteX + 1
	; l will be used in the following code to track the sign of each axis

	; Find the absolute values so we can compare only the magnitudes.
	ld a, b
	bit 7, a
	jr z, :+
		ld l, %1 ; bit 1 will be the sign of the X direction, after a shift
		cpl
		ld b, a
		ld a, c
		cpl
		ld c, a
		inc bc
:
	xor a, a ; Clear carry; none of the following 3 instructions will modify it
	ld a, d
	bit 7, a
	jr z, :+
		cpl
		ld d, a
		ld a, e
		cpl
		ld e, a
		inc de
		; Set the carry flag so the following rotate will set bit 0
		scf
:
	rl l ; Bit 0: sign of Y, Bit 1: sign of X

	ld a, b
	cp a, d
	jr c, .y
.x
	ld a, RIGHT
	bit 1, l
	jr z, .store
	ld a, LEFT
	jr .store
.y
	ld a, DOWN
	bit 0, l
	jr z, .store
	ASSERT UP == 0
	xor a, a
.store
	ld l, LOW(wEntity0_Direction)
	ld [hl], a

	pop hl
	ret
