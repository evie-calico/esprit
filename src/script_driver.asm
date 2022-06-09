INCLUDE "dungeon.inc"

SECTION "EVScript Driver", ROM0
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
	add a, LOW(EVScriptBytecodeTable >> 1)
	ld l, a
	adc a, HIGH(EVScriptBytecodeTable >> 1)
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

SECTION "EVScript Bytecode table", ROM0, ALIGN[1]
EVScriptBytecodeTable:
	; Control
	dw StdReturn
	dw StdYield
	dw StdGoto
	dw StdGotoFar
	dw StdGotoConditional
	dw StdGotoConditionalNot
	dw StdGotoConditionalFar
	dw StdGotoConditionalNotFar
	dw StdCallAsm
	dw StdCallAsmFar
	; 8-bit ops
	dw StdAdd
	dw StdSub
	dw StdMul
	dw StdDiv
	dw StdBinaryAnd
	dw StdBinaryOr
	dw StdEqu
	dw StdNot
	dw StdLessThan
	dw StdGreaterThanEqu
	dw StdLogicalAnd
	dw StdLogicalOr
	; Constant 8-bit ops
	dw StdAddConst
	dw StdSubConst
	dw StdMulConst
	dw StdDivConst
	dw StdBinaryAndConst
	dw StdBinaryOrConst
	dw StdEquConst
	dw StdNotConst
	dw StdLessThanConst
	dw StdGreaterThanEquConst
	; Copy
	dw StdCopy
	dw StdLoad
	dw StdStore
	dw StdCopyConst
	dw StdLoadConst
	dw StdStoreConst
	;
	dw ScriptMemset
	dw ScriptRand
	; Mapgen Utilities
	dw ScriptMapPutTile
	dw ScriptMapGetTile
	dw ScriptMapStepDir

SECTION "EVScript Return", ROM0
StdReturn:
	ld hl, 0
StdYield:
	pop de ; pop return address
	pop de ; pop pool pointer
	ret

SECTION "EVScript Goto", ROM0
StdGoto:
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

StdGotoConditional:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [bc]
	and a, a
	jr nz, StdGoto
.fail
	inc hl
	inc hl
	ret

StdGotoConditionalNot:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [bc]
	and a, a
	jr z, StdGoto
.fail
	inc hl
	inc hl
	ret

SECTION "EVScript GotoFar", ROM0
StdGotoFar:
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hl]
	rst SwapBank
	ld l, c
	ld h, b
	ret

StdGotoConditionalFar:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [bc]
	and a, a
	jr nz, StdGotoFar
.fail
	inc hl
	inc hl
	ret

StdGotoConditionalNotFar:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [bc]
	and a, a
	jr z, StdGotoFar
.fail
	inc hl
	inc hl
	ret

SECTION "EVScript CallAsm", ROM0
StdCallAsm:
	push hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call .hl
	pop hl
	ret
.hl
	jp hl

SECTION "EVScript CallAsmFar", ROM0
StdCallAsmFar:
	push hl
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	rst SwapBank
	ld h, b
	ld l, c
	call .hl
	pop hl
	ret
.hl
	jp hl

SECTION "EVScript 8-bit Operations", ROM0
; @param de: pool
; @param hl: script pointer
; @return a: lhs
; @return b: rhs
ConstantOperandPrologue:
	ld a, [hli] ; lhs offset
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	; de is preserved & variable is pointed to by bc
	ld a, [bc]
	ld b, [hl]
	inc hl
	ret

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

; This is a VERY simple multiply routine. It is meant to be compact, not
; fast. Rewrite if speed is needed.
StdMul:
	call OperandPrologue
	ld c, a
	xor a, a
	inc b
:
	dec b
	jr z, StoreEpilogue
	add a, c
	jr :-

; This is a VERY simple divide routine. It is meant to be compact, not
; fast. Rewrite if speed is needed.
StdDiv:
	call OperandPrologue
	ld c, 0
:
	sub a, b
	jr c, StoreEpilogue
	inc c
	jr :-

StdBinaryAnd:
	call OperandPrologue
	and a, b
	jr StoreEpilogue

StdBinaryOr:
	call OperandPrologue
	or a, b
	jr StoreEpilogue

StdEqu:
	call OperandPrologue
	cp a, b
	ld a, 0
	jr nz, StoreEpilogue
	inc a
	jr StoreEpilogue

StdNot:
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

StdAddConst:
	call ConstantOperandPrologue
	add a, b ; Here is the actual operation
	jr StoreEpilogue

StdSubConst:
	call ConstantOperandPrologue
	sub a, b ; Here is the actual operation
	jr StoreEpilogue

; This is a VERY simple multiply routine. It is meant to be compact, not
; fast. Rewrite if speed is needed.
StdMulConst:
	call ConstantOperandPrologue
	ld c, a
	xor a, a
	inc b
:
	dec b
	jr z, StoreEpilogue
	add a, c
	jr :-

; This is a VERY simple divide routine. It is meant to be compact, not
; fast. Rewrite if speed is needed.
StdDivConst:
	call ConstantOperandPrologue
	ld c, 0
:
	sub a, b
	jr c, StoreEpilogue
	inc c
	jr :-

StdBinaryAndConst:
	call ConstantOperandPrologue
	and a, b ; Here is the actual operation
	jr StoreEpilogue

StdBinaryOrConst:
	call ConstantOperandPrologue
	or a, b ; Here is the actual operation
	jr StoreEpilogue

StdEquConst:
	call ConstantOperandPrologue
	cp a, b
	ld a, 0
	jr nz, StoreEpilogue
	inc a
	jr StoreEpilogue

StdNotConst:
	call ConstantOperandPrologue
	cp a, b
	ld a, 0
	jr z, StoreEpilogue
	inc a
	jr StoreEpilogue

StdLessThanConst:
	call ConstantOperandPrologue
	cp a, b
	ld a, 0
	jr nc, StoreEpilogue
	inc a
	jr StoreEpilogue

StdGreaterThanEquConst:
	call ConstantOperandPrologue
	cp a, b
	ld a, 0
	jr c, StoreEpilogue
	inc a
	jr StoreEpilogue

SECTION "EVScript Copy", ROM0
StdCopy:
	push de
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, [de]
	ld [bc], a
	pop de
	ret

SECTION "EVScript Load", ROM0
StdLoad:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [hli]
	push hl
	add a, e
	ld l, a
	adc a, d
	sub a, l
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hl]
	ld [bc], a
	pop hl
	ret

SECTION "EVScript Store", ROM0
StdStore:
	push de
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [bc]
	inc bc
	ld d, a
	ld a, [bc]
	ld b, a
	ld c, d
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, [de]
	ld [bc], a
	pop de
	ret

SECTION "EVScript CopyConst", ROM0
StdCopyConst:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [hli]
	ld [bc], a
	ret

SECTION "EVScript LoadConst", ROM0
StdLoadConst:
	ld a, [hli]
	add a, e
	ld c, a
	adc a, d
	sub a, c
	ld b, a
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	ld a, [hl]
	ld [bc], a
	pop hl
	inc hl
	ret

SECTION "EVScript StoreConst", ROM0
StdStoreConst:
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	add a, e
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	ld a, [de]
	ld [bc], a
	ret

SECTION "EVScript ScriptMemset", ROM0
ScriptMemset:
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, [hl]
	inc hl
	ld b, [hl]
	inc hl
	push hl
		ld h, d
		ld l, e
		call MemSet
	pop hl
	ret

SECTION "EVScript ScriptRand", ROM0
ScriptRand:
	push de
	push hl
	call Rand
	pop hl
	pop de
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

SECTION "Map Get/Put Prologue", ROM0
MapGetPutPrologue:
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
		ld e, a
		adc a, h
		sub a, e
		ld d, a
	pop hl
	ret

SECTION "EVScript ScriptMapPutTile", ROM0
ScriptMapPutTile:
	call MapGetPutPrologue
	ld a, [hli]
	ld [de], a
	ret

SECTION "EVScript ScriptMapGetTile", ROM0
ScriptMapGetTile:
	push de
	call MapGetPutPrologue
	ld a, [de]
	pop de
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

SECTION "EVScript ScriptMapStepDir", ROM0
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
