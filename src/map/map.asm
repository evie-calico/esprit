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
		alias Name
	end_struct

RSRESET
DEF MAP_NODE_NONE RB     ; No action; the default
DEF MAP_NODE_MOVE RB     ; Move to another node
DEF MAP_NODE_LOCK RB     ; Move to another node if FLAG is set
DEF MAP_NODE_DUNGEON RB  ; Enter a dungeon
DEF MAP_NODE_SCENE RB    ; Enter a town
DEF MAP_NODE_AUTOMOVE RB ; Automatically progress to the next node; do not draw name.

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
	; For MOVE, the bank is redundant.
	; Because of this it is repurposed for LOCK to be a flag ID.
	IF !STRCMP("LOCK", "\2")
		REDEF _NODE_\1_ARG0 EQUS "FLAG_\4"
	ELSE
		REDEF _NODE_\1_ARG0 EQUS "BANK(\3)"
	ENDC
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
	{_NODE_IDENTIFIER}:
		_node_define UP
		_node_define RIGHT
		_node_define DOWN
		_node_define LEFT
		_node_define PRESS
		db _NODE_X, _NODE_Y, "{_NODE_NAME}", 0
ENDM

DEF NB_DROPLETS EQU 16
DEF NB_EFFECTS EQU NB_DROPLETS + 3

SECTION "World map nodes", ROMX
	node xBeginningHouse, "----'s House", 76, 88
		left MOVE, xVillageNode
	end_node
	EXPORT xBeginningHouse

	node xVillageNode, "Crater Village", 48, 88
		left MOVE, xForestNode
		right MOVE, xBeginningHouse
		press SCENE, xVillageScene
	end_node

	node xForestNode, "Crater Forest", 12, 88
		right MOVE, xVillageNode
		up LOCK, xFieldsNode, FOREST_COMPLETE
		press DUNGEON, xForestDungeon
	end_node

	node xFieldsNode, "Crater Fields", 12, 32
		press DUNGEON, xFieldDungeon
		down MOVE, xForestNode
		up LOCK, xRemoteHouse, FIELDS_COMPLETE
		right LOCK, xLakeNode, FIELDS_COMPLETE
	end_node

	node xRemoteHouse, "Remote house", 12, 16
		down MOVE, xFieldsNode
	end_node

	node xLakeNode, "Crystal Lake", 45, 32
		press DUNGEON, xLakeDungeon
		left MOVE, xFieldsNode
		right LOCK, xTurn0, LAKE_COMPLETE
	end_node

	node xTurn0, "", 69, 32
		press AUTOMOVE, null
		down MOVE, xTurn1
		left MOVE, xLakeNode
	end_node

	node xTurn1, "", 69, 56
		press AUTOMOVE, null
		right MOVE, xBlazingPlains
		up MOVE, xTurn0
	end_node

	node xBlazingPlains, "Blazing Plains", 101, 56
		press DUNGEON, xPlainsDungeon
		left MOVE, xTurn1
		up LOCK, xTurn2, PLAINS_COMPLETE
		down LOCK, xGemstoneWoodsNode, CAVES_COMPLETE
	end_node

	node xTurn2, "", 101, 24
		press AUTOMOVE, null
		down MOVE, xBlazingPlains
		left MOVE, xTurn3
	end_node

	node xTurn3, "", 85, 24
		press AUTOMOVE, null
		right MOVE, xTurn2
		up MOVE, xTurn4
	end_node

	node xTurn4, "", 85, 8
		press AUTOMOVE, null
		down MOVE, xTurn3
		right MOVE, xCraterCaverns
	end_node

	node xCraterCaverns, "Crater Caverns", 101, 8
		press DUNGEON, xCavesDungeon
		left MOVE, xTurn4
	end_node

	node xGemstoneWoodsNode, "Gemstone Woods", 101, 80
		press DUNGEON, xGemstoneWoodsDungeon
		up MOVE, xBlazingPlains
	end_node

SECTION "World Map", ROMX
xWorldMap:
.tiles INCBIN "res/worldmap/crater.2bpp"
.map INCBIN "res/worldmap/crater.map"
.colors INCBIN "res/worldmap/crater.pal8"
.colormap INCBIN "res/worldmap/crater.pmap"
.dmgtiles INCBIN "res/worldmap/crater-dmg.2bpp"
.dmgmap INCBIN "res/worldmap/crater-dmg.map"
.duck INCBIN "res/worldmap/duck.2bpp"
.droplet INCBIN "res/worldmap/droplet.2bpp"
.hoof INCBIN "res/worldmap/hoofprint.2bpp"
.haze INCBIN "res/worldmap/haze1.2bpp"
      INCBIN "res/worldmap/haze2.2bpp"
.dropletPalette INCBIN "res/worldmap/droplet.pal8", 3
.duckPalette INCBIN "res/worldmap/duck.pal8", 3
.hoofPalette INCBIN "res/worldmap/hoofprint.pal8", 3
.hazePalette INCBIN "res/worldmap/haze1.pal8", 3

SECTION "Map State Init", ROM0
InitMap::
	ldh a, [hCurrentBank]
	push af

	xor a, a
	ld [wMapLockInput], a

	ld a, BANK(xWorldMap)
	rst SwapBank

	ldh a, [hSystem]
	and a, a
	jr z, .dmg
.cgb
	ld de, wBGPaletteBuffer
	ld hl, xWorldMap.colors
	ld c, 7 * 3 * 4
	call MemCopySmall

	ld de, wOBJPaletteBuffer + 3 * 3
	ld hl, xWorldMap.dropletPalette
	ld c, 3 * 3 * 4
	call MemCopySmall

	ld a, 1
	ldh [rVBK], a
	lb bc, SCRN_X_B, SCRN_Y_B
	ld de, $9800
	ld hl, xWorldMap.colormap
	call MapRegion
	xor a, a
	ldh [rVBK], a

	ld hl, xWorldMap.tiles
	ld de, $8800
	ld bc, xWorldMap.map - xWorldMap.tiles
	call VRAMCopy

	lb bc, SCRN_X_B, SCRN_Y_B
	ld de, $9800
	ld hl, xWorldMap.map
	call MapRegion
	jr .noDmg

.dmg
	ld hl, xWorldMap.dmgtiles
	ld de, $8800
	ld bc, xWorldMap.map - xWorldMap.tiles
	call VRAMCopy

	lb bc, SCRN_X_B, SCRN_Y_B
	ld de, $9800
	ld hl, xWorldMap.dmgmap
	call MapRegion

.noDmg

	ld hl, xWorldMap.droplet
	ld de, $8000 + $7E * 16
	ld c, 16
	call VRAMCopySmall
	lb bc, 0, 16
	ld h, d
	ld l, e
	call VRAMSetSmall

	ld hl, xWorldMap.duck
	ld de, $8000 + $7C * 16
	ld c, 16
	call VRAMCopySmall
	lb bc, 0, 16
	ld h, d
	ld l, e
	call VRAMSetSmall

	ld hl, xWorldMap.hoof
	ld de, $8000 + $7A * 16
	ld c, 16
	call VRAMCopySmall
	lb bc, 0, 16
	ld h, d
	ld l, e
	call VRAMSetSmall

	ld hl, xWorldMap.haze
	ld de, $8000 + $6E * 16
	ld c, 16 * 12
	call VRAMCopySmall

	ld b, NB_DROPLETS
	ld hl, wEffects
.initDroplets
	ld a, BANK(xDropletEffect)
	ld [hli], a
	ld a, LOW(xDropletEffect)
	ld [hli], a
	ld a, HIGH(xDropletEffect)
	ld [hli], a
	ld a, l
	add a, 16
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	dec b
	jr nz, .initDroplets

	ld hl, wEffects + 19 * NB_DROPLETS
	ld a, BANK(xDuckEffect)
	ld [hli], a
	ld a, LOW(xDuckEffect)
	ld [hli], a
	ld a, HIGH(xDuckEffect)
	ld [hli], a

	ld hl, wEffects + 19 * (NB_DROPLETS + 1)
	ld a, BANK(xHoofprintsEffect)
	ld [hli], a
	ld a, LOW(xHoofprintsEffect)
	ld [hli], a
	ld a, HIGH(xHoofprintsEffect)
	ld [hli], a

	ld hl, wEffects + 19 * (NB_DROPLETS + 2)
	ld a, BANK(xHazeEffect)
	ld [hli], a
	ld a, LOW(xHazeEffect)
	ld [hli], a
	ld a, HIGH(xHazeEffect)
	ld [hli], a

	call InitUI

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
	ld b, a ; clear flags and set b
	ld a, [hld]
	REPT 4
		rla
		rl b
	ENDR
	ld [de], a
	inc e
	ld a, b
	ld [de], a
	inc e
	ASSERT Entity_SpriteY + 2 == Entity_SpriteX
	ASSERT MapNode_Y - 1 == MapNode_X
	xor a, a
	ld b, a ; clear flags and set b
	ld a, [hli]
	REPT 4
		rla
		rl b
	ENDR
	ld [de], a
	inc e
	ld a, b
	ld [de], a
	inc l
	ASSERT MapNode_Y + 1 == MapNode_Name
	ldh a, [hCurrentBank]
	ld b, a
	call PrintHUD
	call DrawPrintString

	call FadeIn

	ld hl, wSTATTarget
	ld a, LOW(ShowOnlyTextBox)
	ld [hli], a
	ld a, HIGH(ShowOnlyTextBox)
	ld [hli], a
	xor a, a
	ldh [hShadowSCX], a
	ldh [hShadowSCY], a

	ld a, GAMESTATE_MAP
	ld [wGameState], a
	jp BankReturn

SECTION "Map State", ROM0
MapState::
	; The player and partner entities are always accessible, as entities are not
	; within the state union. This means the entity struct and entity renderer
	; can be reused for the map and town states.
	call UpdateEntityGraphics

	ld a, BANK(xRenderEntity)
	rst SwapBank
	ld h, HIGH(wEntity0)
	call xRenderEntity

	ld de, wEffects
	ld a, NB_EFFECTS
.runEffects
	push af
	ld a, [de]
	inc de
	rst SwapBank
	ld a, [de]
	inc de
	ld l, a
	ld a, [de]
	inc de
	ld h, a
	call ExecuteScript
	dec de
	ld a, h
	ld [de], a
	dec de
	ld a, l
	ld [de], a
	ld a, e
	add a, 18
	ld e, a
	adc a, d
	sub a, e
	ld d, a
	pop af
	dec a
	jr nz, .runEffects

	call MapMovement
	call c, UpdateMapNode

	ret

SECTION "Map Movement", ROM0
; @return carry: Set if not moving
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
		ld c, a
		inc e
		ld a, [de]
		REPT 4
			rra
			rr c
		ENDR
		ld a, c
		cp a, b
		IF Y
			; If Y matches, set the player to face foward and stand still.
			jr z, .noMovement
		ELSE
			; If X matches, check Y
			jr z, .yCheck
		ENDC
	:
		ld a, c
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
		xor a, a
		ret
	ENDR
.noMovement
	ld a, DOWN
	ld [wEntity0_Direction], a
	ld a, ENTITY_FRAME_IDLE
	ld [wEntity0_Frame], a
	scf
	ret

SECTION "Update Map Node", ROM0
UpdateMapNode:
	ld hl, wActiveMapNode
	ld a, [hli]
	rst SwapBank
	ld a, [hli]
	ld h, [hl]
	add a, MapNode_Press
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hl]
	cp a, MAP_NODE_AUTOMOVE
	jr nz, .noAutomove

	; Find the first direction containing MOVE that is not equal to the current direction.
	ld a, [wEntity0_LastDirection]
	ld b, a
	ASSERT MapNode_Press - 4 == MapNode_Left
	dec hl
	dec hl
	dec hl
	dec hl
	ld a, [hli]
	dec a
	jr nz, :+
	ld a, RIGHT
	cp a, b
	jp nz, MapNodeMove
:
	ASSERT MapNode_Left - 4 == MapNode_Down
	dec hl
	dec hl
	dec hl
	dec hl
	dec hl
	ld a, [hli]
	dec a
	jr nz, :+
	ld a, UP
	cp a, b
	jp nz, MapNodeMove
:
	ASSERT MapNode_Down - 4 == MapNode_Right
	dec hl
	dec hl
	dec hl
	dec hl
	dec hl
	ld a, [hli]
	dec a
	jr nz, :+
	ld a, LEFT
	cp a, b
	jp nz, MapNodeMove
:
	ASSERT MapNode_Right - 4 == MapNode_Up
	dec hl
	dec hl
	dec hl
	dec hl
	dec hl
	ld a, [hli]
	dec a
	jr nz, :+
	ld a, DOWN
	cp a, b
	jp nz, MapNodeMove
:

.noAutomove

	ld a, [wPrintString]
	and a, a
	call nz, DrawPrintString

	ld a, [wMapLockInput]
	and a, a
	ret nz

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
	ASSERT MAP_NODE_LOCK == 2
	dec a
	jr z, MapNodeLock
	ASSERT MAP_NODE_DUNGEON == 3
	dec a
	jr z, MapNodeDungeon
	ASSERT MAP_NODE_SCENE == 4
	jr MapNodeScene

MapNodeMove:
	inc hl
.noInc
	ld a, b
	ld [wMapLastDirectionMoved], a
	ld de, wActiveMapNode + 1
	ld a, [hli]
	ld [de], a
	ld c, a
	inc de
	ld a, [hli]
	ld [de], a
	ld b, a
	ld a, c
	add a, MapNode_Name
	ld l, a
	adc a, b
	sub a, l
	ld h, a
	ldh a, [hCurrentBank]
	ld b, a
	jp PrintHUD

MapNodeLock:
	ld a, [hli]
	push hl
	ld c, a
	call GetFlag
	and a, [hl]
	pop hl
	ret z
	jr MapNodeMove.noInc

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

	ld a, 1
	ld [wMapLockInput], a

	call FadeToBlack

	ld hl, wFadeCallback
	ld a, LOW(InitDungeon)
	ld [hli], a
	ld [hl], HIGH(InitDungeon)

	ret

MapNodeScene:
	ld de, wActiveScene
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a

	call FadeToBlack

	ld hl, wFadeCallback
	ld a, LOW(InitScene)
	ld [hli], a
	ld [hl], HIGH(InitScene)
	ret

SECTION "map globals", WRAM0
wActiveMapNode:: ds 3
; Used for determining what side of a scene the player should start out on.
wMapLastDirectionMoved:: db

SECTION UNION "State variables", WRAM0
wEffects: ds (3 + 16) * NB_EFFECTS

wMapLockInput: db