INCLUDE "defines.inc"
INCLUDE "entity.inc"
INCLUDE "hardware.inc"
INCLUDE "structs.inc"

	struct MapNode
		bytes 4, Up
		bytes 4, Right
		bytes 4, Down
		bytes 4, Left
		bytes 4, Press
		bytes 1, X
		bytes 1, Y
		bytes 0, Name
	end_struct

RSRESET
DEF MAP_NODE_NONE RB 1
DEF MAP_NODE_MOVE RB 1
DEF MAP_NODE_DUNGEON RB 1
DEF MAP_NODE_TOWN RB 1

MACRO _node_dir
	REDEF _NODE_\1_TYPE     EQU MAP_NODE_NONE
	REDEF _NODE_\1_ARG0     EQUS "0"
	REDEF _NODE_\1_ARG1     EQUS "0"
	REDEF _NODE_\1_ARG2     EQUS "0"
ENDM

MACRO node
	REDEF _NODE_IDENTIFIER EQUS "\1"
	REDEF _NODE_X EQU \3
	REDEF _NODE_Y EQU \4
	REDEF _NODE_NAME EQUS \2
	_node_dir UP
	_node_dir RIGHT
	_node_dir DOWN
	_node_dir LEFT
	_node_dir PRESS
ENDM

MACRO _node_entry
	REDEF _NODE_\1_TYPE EQU MAP_NODE_\2
	REDEF _NODE_\1_ARG0 EQUS "BANK(\3)"
	REDEF _NODE_\1_ARG1 EQUS "LOW(\3)"
	REDEF _NODE_\1_ARG2 EQUS "HIGH(\3)"
ENDM

DEF up    EQUS "_node_entry UP, "
DEF right EQUS "_node_entry RIGHT, "
DEF down  EQUS "_node_entry DOWN, "
DEF left  EQUS "_node_entry LEFT, "
DEF press EQUS "_node_entry PRESS, "

MACRO _node_define
	db _NODE_\1_TYPE, _NODE_\1_ARG0, _NODE_\1_ARG1, _NODE_\1_ARG2
ENDM

MACRO end_node
	SECTION "{_NODE_IDENTIFIER} map node", ROMX
	{_NODE_IDENTIFIER}:
		_node_define UP
		_node_define RIGHT
		_node_define DOWN
		_node_define LEFT
		_node_define PRESS
		db _NODE_X, _NODE_Y, "{_NODE_NAME}", 0
ENDM

	node xCenterNode, "Forest Dungeon", 1, 1
		left MOVE, xLeftNode
		press DUNGEON, xForest
	end_node
	EXPORT xCenterNode

	node xLeftNode, "", 0, 1
		right MOVE, xCenterNode
		press DUNGEON, xForest
	end_node

SECTION "Map State Init", ROM0
InitMap::
	ldh a, [hCurrentBank]
	push af
	ld hl, wActiveMapNode
	ld de, wEntity0_SpriteY
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, MapNode_Y
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	xor a, a
	ld [de], a
	inc e
	ld a, [hld]
	ld [de], a
	inc e
	xor a, a
	ld [de], a
	inc e
	ld a, [hl]
	ld [de], a
	pop af
	rst SwapBank

	ld a, 20
	ld [wFadeSteps], a
	ld a, $80 + 20 * 4
	ld [wFadeAmount], a
	ld a, -4
	ld [wFadeDelta], a

	ld hl, wSTATTarget
	xor a, a
	ld [hli], a
	ld [hli], a

	ld a, GAMESTATE_MAP
	ld [wGameState], a
	ret

SECTION "Map State", ROM0
MapState::
	call UpdateMapNode

	ld hl, wActiveMapNode
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, MapNode_X
	ld l, a
	adc a, h
	sub a, l
	ld h, a

	call MapMovement
	; The player and partner entities are always accessible, as entities are not
	; within the state union. This means the entity struct and entity renderer
	; can be reused for the map and town states.
	call UpdateEntityGraphics
	ld a, BANK(xRenderEntity)
	rst SwapBank
	ld h, HIGH(wEntity0)
	call xRenderEntity
	ret

SECTION "Map Movement", ROM0
MapMovement:
	FOR Y, 2
		IF Y
			.yCheck
		ENDC
		; Compare the active map node's position to the player's.
		ld hl, wActiveMapNode
		ld a, [hli]
		rst SwapBank
		ld a, [hli]
		ld h, [hl]
		add a, MapNode_X + Y
		ld l, a
		adc a, h
		sub a, l
		ld h, a
		ld a, [hli]
		ld b, a
		ld de, wEntity0_SpriteX - Y * 2
		ld a, [de]
		inc e
		and a, a
		jr nz, :+
		ld a, [de]
		cp a, b
		IF Y
			; If Y matches, set the player to face foward and stand still.
			jr z, .noMovement
		ELSE
			; If X matches, check Y
			jr z, .yCheck
		ENDC
	:
		ld a, [de]
		cp a, b
		; If they do not match, animate the player. This does NOT clobber flags!
		ld a, ENTITY_FRAME_STEP
		ld [wEntity0_Frame], a
		; If the target is greater, move right.
		ld a, (RIGHT + Y) & 3
		jr c, :+
		; Otherwise move left.
		ld a, (LEFT + Y) & 3
	:
		ld [wEntity0_Direction], a
		IF Y
			cp a, DOWN
		ELSE
			ASSERT RIGHT == 1
			dec a ; cp a, RIGHT
		ENDC
		ld de, wEntity0_SpriteX - Y * 2 + 1
		ld a, [de]
		ld h, a
		dec de ; 16-bit to preserve Z
		ld a, [de]
		ld l, a
		ld bc, 16
		jr z, :+
		ld bc, -16
	:
		add hl, bc
		ld a, l
		ld [de], a
		inc e
		ld a, h
		ld [de], a
		ret
	ENDR
.noMovement
	ld a, DOWN
	ld [wEntity0_Direction], a
	ld a, ENTITY_FRAME_IDLE
	ld [wEntity0_Frame], a
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

	ld a, 20
	ld [wFadeSteps], a
	ld a, $80
	ld [wFadeAmount], a
	ld a, 4
	ld [wFadeDelta], a

	ld hl, wFadeCallback
	ld a, LOW(InitDungeon)
	ld [hli], a
	ld [hl], HIGH(InitDungeon)

	ret

MapNodeTown:
	ret

SECTION "map globals", WRAM0
wActiveMapNode:: ds 3
