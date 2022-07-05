INCLUDE "defines.inc"
INCLUDE "hardware.inc"
INCLUDE "structs.inc"

	struct MapNode
		bytes 4, Up
		bytes 4, Right
		bytes 4, Down
		bytes 4, Left
		bytes 4, Select
		bytes 1, X
		bytes 1, Y
		bytes 0, Name
	end_struct

RSRESET
DEF MAP_NODE_NONE RB 1
DEF MAP_NODE_MOVE RB 1
DEF MAP_NODE_DUNGEON RB 1
DEF MAP_NODE_TOWN RB 1

MACRO _node_entry ; type, value
	db MAP_NODE_\1
	IF STRCMP("\1", "NONE") == 0
		ds 3, 0
	ELSE
		db BANK(\2)
		dw \2
	ENDC
ENDM

MACRO node ; identifier, up, right, down, left, A
	SECTION "\1", ROMX
	\1:
	SHIFT 1
	db MAP_NODE_\1
	IF STRCMP("\1", "NONE") == 0
		ds 3, 0
		SHIFT 1
	ELSE
		db BANK(\2)
		dw \2
		SHIFT 2
	ENDC
	IF STRCMP("\1", "NONE") == 0
		ds 3, 0
		SHIFT 1
	ELSE
		db BANK(\2)
		dw \2
		SHIFT 2
	ENDC
	IF STRCMP("\1", "NONE") == 0
		ds 3, 0
		SHIFT 1
	ELSE
		db BANK(\2)
		dw \2
		SHIFT 2
	ENDC
	IF STRCMP("\1", "NONE") == 0
		ds 3, 0
		SHIFT 1
	ELSE
		db BANK(\2)
		dw \2
		SHIFT 2
	ENDC
	IF STRCMP("\1", "NONE") == 0
		ds 3, 0
		SHIFT 1
	ELSE
		db BANK(\2)
		dw \2
		SHIFT 2
	ENDC
ENDM

	node xCenterNode, NONE, NONE, NONE, MOVE, xLeftNode, DUNGEON, xForest 
	node xLeftNode, NONE, MOVE, xCenterNode, NONE, NONE, NONE

SECTION "Map State Init", ROM0
InitMap::
	ld hl, wActiveMapNode
	ld a, BANK(xCenterNode)
	ld [hli], a
	ld a, LOW(xCenterNode)
	ld [hli], a
	ld a, HIGH(xCenterNode)
	ld [hli], a
	ld a, GAMESTATE_MAP
	ld [wGameState], a
	ret

SECTION "Map State", ROM0
MapState::
	ld a, [wEntity0_Direction]
	inc a
	and a, 3
	ld [wEntity0_Direction], a
	call UpdateMapNode
	; The player and partner entities are always accessible, as entities are not
	; within the state union. This means the entity struct and entity renderer
	; can be reused for the map and town states.
	call UpdateEntityGraphics
	ret

SECTION "Update Map Node", ROM0
UpdateMapNode:
	ld hl, wActiveMapNode
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hCurrentKeys]
	and a, PADF_A | PADF_UP | PADF_RIGHT | PADF_DOWN | PADF_LEFT
	ret z ; If no keys are pressed, no action is neccessary!
	call PadToDir
	; If PadToDir fails, that means A is the only key which is pressed.
	; A corresponds to an index of 4
	jr nc, .notA
	ld a, 4
.notA
	; Preserve the direction in B, so that it may be referenced by the target
	ld b, a
	add a, a ; a * 2
	add a, a ; a * 4
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	; Now we have a pointer to one of the five map node actions.
	; An action is followed by 3 bytes, generally a far pointer to a level,
	; town, or another map node.
	ld a, [hli]
	; Of course, a value of zero means no action should be taken.
	ASSERT MAP_NODE_NONE == 0
	and a, a
	ret z
	ASSERT MAP_NODE_MOVE == 1
	dec a
	jr z, MapNodeMove
	ASSERT MAP_NODE_DUNGEON == 2
	dec a
	jr z, MapNodeDungeon
	ASSERT MAP_NODE_TOWN == 3
	jr MapNodeTown

MapNodeMove:
	ld de, wActiveMapNode
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	; The direction pressed is passed in `b` as a parameter.
	; This means move will ONLY work for directions, NOT A.
	ld a, b
	ld [wEntity0_Direction], a
	ld [wEntity1_Direction], a
	ret

MapNodeDungeon:
	ld de, wActiveDungeon
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	ret

MapNodeTown:
	ret

SECTION "map globals", WRAM0
wActiveMapNode:: ds 3
