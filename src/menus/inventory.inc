INCLUDE "item.inc"

DEF INVENTORY_CURSOR_X EQU SCRN_VX - SCRN_X + 69
DEF INVENTORY_CURSOR_Y EQU 20

xInventoryMenu::
	db BANK(@)
	dw xInventoryMenuInit
	; Used Buttons
	db PADF_A | PADF_B | PADF_UP | PADF_DOWN
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw xInventoryA, null, null, null, null, null, xInventoryMove, xInventoryMove
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	; This is overwritten each frame to match the size of the inventory.
	db INVENTORY_SIZE
	; Redraw
	dw xInventoryMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xInventoryMenuClose

xDrawInventoryMenu:
	set_region 20, 0, SCRN_VX_B - 20, SCRN_Y_B, idof_vBlankTile
	dtile_section vScratchRegion
	dregion vInventoryMenu, 20, 0, 12, 4 + INVENTORY_SIZE
	print_text 23, 1, "Inventory"
	set_frame vInventoryMenu, idof_vFrame
	dregion vInventoryDescription, 20, 4 + INVENTORY_SIZE, 12, 6
	set_frame vInventoryDescription, idof_vFrame
	dtile vItemNames, 6 * INVENTORY_SIZE
	dtile vItemDesc
	end_menu

xInventoryMenuInit:
	ld a, SCRN_VX - SCRN_X
	ld [wScrollInterp.x], a
	xor a, a
	ld [wScrollInterp.y], a

	ld hl, wSubMenuCursor
	ld a, INVENTORY_CURSOR_X
	ld [hli], a
	ld a, INVENTORY_CURSOR_Y
	ld [hli], a
	ld a, idof_vItemCursor
	ld [hli], a
	ld [hl], OAMF_PAL1 | 1

	ld hl, wUseItemMenuCursor
	ld a, SCRN_VX - SCRN_X + 4
	ld [hli], a
	ld a, SCRN_Y + 4
	ld [hli], a
	ld a, idof_vItemCursor
	ld [hli], a
	ld [hl], OAMF_PAL1 | 1

	ld a, 1
	ld [wInventoryRedrawDesc], a
	ld hl, xDrawInventoryMenu
	call DrawMenu
	call xInventoryDrawItemNames
	ret

xInventoryDrawItemNames:
	xor a, a
	ld [wInventoryIsEmpty], a
	; Text is already mostly initialized by the menu renderer.
	xor a, a
	ld [wTextLetterDelay], a
	ld a, idof_vItemNames
	ld [wTextCurTile], a
	ld [wWrapTileID], a
	ld a, $FF
	ld [wLastTextTile], a

	; Print item names
	ld hl, wInventoryDrawPosition
	ld a, LOW($9800 + 23 + 3 * 32 - 32)
	ld [hli], a
	ld [hl], HIGH($9800 + 23 + 3 * 32 - 32)
	ld hl, wInventory
	ld a, [hl]
	and a, a
	jr nz, .next
		ld a, 1
		ld [wInventoryIsEmpty], a
		ld b, BANK(.emptyString)
		ld hl, .emptyString
		call PrintVWFText
		lb de, 8, 1
		ld hl, $9800 + 23 + 3 * 32
		call TextDefineBox
		call PrintVWFChar
		jp DrawVWFChars
.next
	ld a, [hli]
	and a, a
	jr z, .skip
	push hl
		call GetNextItemName
	PUSHS
	SECTION "Get Next Item Name", ROM0
	GetNextItemName:
		rst SwapBank
		ld b, a
		ld a, [hli]
		ld h, [hl]
		ld l, a
		inc hl
		inc hl
		inc hl
		inc hl
		ASSERT Item_Name == 4
		ld a, [hli]
		ld h, [hl]
		ld l, a
		ld a, 1
		call PrintVWFText
		ld a, BANK(xInventoryDrawItemNames)
		rst SwapBank
		ret
	POPS
		lb de, 8, 1
		ld hl, wInventoryDrawPosition
		ld a, [hli]
		ld h, [hl]
		add a, 32
		ld l, a
		ld [wInventoryDrawPosition], a
		adc a, h
		sub a, l
		ld h, a
		ld [wInventoryDrawPosition + 1], a
		call TextDefineBox
		call PrintVWFChar
		call DrawVWFChars
	pop hl
.skip
	inc hl
	inc hl
	ld a, l
	cp a, LOW(wInventory.end)
	jr nz, .next
	ld a, h
	cp a, HIGH(wInventory.end)
	jr nz, .next

	ret

.emptyString db "It's empty!", 0

xInventoryMenuRedraw:
	; Calculate the number of items in the inventory.
	ld hl, wInventory - 2
	ld b, INVENTORY_SIZE
.countItems
	inc hl
	inc hl
	ld a, [hli]
	and a, a
	jr z, .end
	dec b
	jr nz, .countItems
.end
	ld a, INVENTORY_SIZE
	sub a, b
	ld b, a

	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	dec hl
	dec hl ; Size
	; Set the size of the menu to match the number of entries in the inventory
	ld [hl], b
	dec hl ; Selection
	ld a, [wInventoryRedrawDesc]
	and a, a
	ld a, [hl]
	jr z, :+
	push af
	call xInventoryLoadItemSelection
	xor a, a
	ld [wInventoryRedrawDesc], a
	pop af
:
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, INVENTORY_CURSOR_Y
	ld b, a
	ld c, INVENTORY_CURSOR_X
	ld hl, wSubMenuCursor
	call DrawCursor
	
	ld hl, wPauseMenuCursor
	call DrawCursorStatic

	ld hl, wUseItemMenuCursor
	call DrawCursorStatic
	jp xScrollInterp

xInventoryMenuClose:
	xor a, a
	ld [wScrollInterp.x], a
	ld [wScrollInterp.y], a
	ret

xInventoryA:
	ld a, [wInventoryIsEmpty]
	and a, a
	ret nz
	ld hl, sp+2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	inc hl
	ld a, [hl]
	ld [wInventorySelection], a
	xor a, a
	ld [hl], a
	ld [wMenuAction], a
	ld de, xUseItemMenu
	ld b, BANK(xUseItemMenu)
	jp AddMenu

xInventoryMove:
	ld a, 1
	ld [wInventoryRedrawDesc], a
	ret

xInventoryLoadItemSelection:
	push af
	ld a, [wInventoryIsEmpty]
	and a, a
	jr nz, .noCursor
	lb bc, 10, 4
	ld d, idof_vBlankTile
	ld hl, $9800 + 21 + 13 * 32
	call FillRegion
	pop af
	ld b, a
	add a, b ; a * 2
	add a, b ; a * 3
	add a, LOW(wInventory)
	ld l, a
	adc a, HIGH(wInventory)
	sub a, l
	ld h, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp InventoryLoadItemSelection
.noCursor
	pop af
	xor a, a
	ld hl, vItemCursor
	lb c, 0, 64
	jp VRAMSetSmall

PUSHS
SECTION "Load Inventory Item Graphic", ROM0
InventoryLoadItemSelection:
	ld a, b
	rst SwapBank
	push bc
		ldh a, [hSystem]
		and a, a
		jr z, .skipColor
		push hl
			ld a, [hli]
			ld h, [hl]
			ld l, a
			ld de, wOBJPaletteBuffer + 3 * 3 ; Set second palette
			ld c, 3 * 3
			call MemCopySmall
			call ReloadColor
		pop hl
	.skipColor
		ASSERT Item_Graphics == 2
		inc hl
		inc hl
		ld a, [hli]
		push hl
			ld h, [hl]
			ld l, a
			ld de, vItemCursor
			ld c, 16
			call VRAMCopySmall
			ld de, vItemCursor + 32
			ld c, 16
			call VRAMCopySmall
			ld de, vItemCursor + 16
			ld c, 16
			call VRAMCopySmall
			ld de, vItemCursor + 48
			ld c, 16
			call VRAMCopySmall
		pop hl
		ASSERT Item_Graphics + 4 == Item_Description
		inc hl
		inc hl
		inc hl
		ld a, [hli]
		ld h, [hl]
		ld l, a
		lb bc, idof_vItemDesc, $FF
		lb de, SCRN_Y_B, $80
		ld a, 10 * 8
		call TextInit
	pop bc
	ld a, 1
	call PrintVWFText
	lb de, 10, 3
	ld hl, $9800 + 21 + 13 * 32
	call TextDefineBox
	call PrintVWFChar
	call DrawVWFChars
	ld a, BANK("Pause Menu")
	rst SwapBank
	ret

SECTION "Inventory Draw Position", WRAM0
wInventoryDrawPosition: dw
wInventoryRedrawDesc: db
wInventorySelection: db
wInventoryIsEmpty: db
POPS