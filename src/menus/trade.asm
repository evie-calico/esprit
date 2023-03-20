include "defines.inc"
include "draw_menu.inc"
include "format.inc"
include "hardware.inc"
include "item.inc"
include "menu.inc"
include "structs.inc"

rsreset
def TRADE_FIRST rb
def TRADE_SECOND rb
def TRADE_FINAL rb

def INVENTORY_ITEM_X equ 8
def INVENTORY_ITEM_Y equ 72

def FIRST_ITEM_X equ 8 * 8
def FIRST_ITEM_Y equ 8 * 13

def SECOND_ITEM_X equ 8 * 12
def SECOND_ITEM_Y equ 8 * 11

section fragment "Trade Menu", romx

; A trade is made up of the first item, as a far pointers, followed by a pointer to the list of combinations.
; This list is make up of 3 sets of 2 far pointers. The first is the second item, and the second is the result.
; Both of these pointers should be null if an entry is absent.
; The only reason for the split is to simplify indexing.

macro item
	farptr \1
	dw .\1
endm

macro trade
	farptr \1
	farptr \2
endm

xFoodVendor:
	item xApple
	item xPear
	db 0
	trade null, null
	trade null, null
	trade null, null

.xApple
	trade xPear, xGrapes
	trade xApple, xGrapes
	trade null, null

.xPear
	trade xApple, xGrapes
	trade xPear, xGrapes
	trade null, null

xTradeMenu::
	db bank(@)
	dw xTradeMenuInit
	; Used Buttons
	db 0
	; Auto-repeat
	db 1
	; Button functions
	; A, B, Sel, Start, Right, Left, Up, Down
	dw null, null, null, null, null, null, null, null
	db 0 ; Last selected item
	; Allow wrapping
	db 0
	; Default selected item
	db 0
	; Number of items in the menu
	db 0
	; Redraw
	dw xTradeMenuRedraw
	; Private Items Pointer
	dw null
	; Close Function
	dw xTradeMenuClose

; Place this first to define certain constants.
xDrawTradeMenu:
	set_region 0, 0, SCRN_VX_B, SCRN_VY_B, idof_vBlankTile
	load_tiles .frame, 9, vFrame
	load_tiles .plus, 4, vPlus
	load_tiles .arrow, 4, vArrow
	load_tiles .noArrow, 4, vNoArrow
	def idof_vBlankTile equ idof_vFrame + 4

	dregion vInventory, 0, 7, 6, 11
	set_frame vInventory, idof_vFrame
	dregion vTradeInterface, 6, 9, 14, 9
	set_frame vTradeInterface, idof_vFrame

	for ico_idx, 6
		set_tile 12 + (ico_idx / 3) * 4, 11 + (ico_idx % 3) * 2, idof_vGreyItemIcon + ico_idx * 4 + 0
		set_tile 13 + (ico_idx / 3) * 4, 11 + (ico_idx % 3) * 2, idof_vGreyItemIcon + ico_idx * 4 + 1
		set_tile 12 + (ico_idx / 3) * 4, 12 + (ico_idx % 3) * 2, idof_vGreyItemIcon + ico_idx * 4 + 2
		set_tile 13 + (ico_idx / 3) * 4, 12 + (ico_idx % 3) * 2, idof_vGreyItemIcon + ico_idx * 4 + 3
	endr

	print_text 1, 8, "  Items"
	print_text 8, 10, "1st"
	print_text 12, 10, "2nd"
	print_text 15, 10, "Result"
	end_dmg
	set_region 0, 0, SCRN_VX_B, SCRN_VY_B, 0
	end_cgb

	dtile vGreyItemIcon, 4 * 6

	dtile_section $8000
	dtile vItemIcon, 4 * INVENTORY_SIZE

.frame incbin "res/ui/hud_frame.2bpp"
.plus incbin "res/ui/trade/plus.2bpp"
.arrow incbin "res/ui/trade/arrow.2bpp"
.noArrow incbin "res/ui/trade/no_arrow.2bpp"

xTradeMenuInit:
	; Set scroll
	xor a, a
	ldh [hShadowSCX], a
	ldh [hShadowSCY], a
	ld [wInventoryCursor], a
	ld [wBlinkItem], a

	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
	ldh [hShadowLCDC], a

	ld hl, xDrawTradeMenu
	call DrawMenu
	; Load palette
	ldh a, [hSystem]
	and a, a
	call nz, LoadPalettes

	ld a, TRADE_FIRST
	call xSwitchTradeState

	ld a, low(xFoodVendor)
	ld [wCurrentVendor + 0], a
	ld a, high(xFoodVendor)
	ld [wCurrentVendor + 1], a

	; Set palettes
	ld a, $FF
	ld [wBGPaletteMask], a
	ld [wOBJPaletteMask], a
	call FadeIn
	ret

xTradeMenuRedraw:
	ld a, -1
	ld [wBlinkItem], a

	ld a, [wTradeState]
	add a, a ; a * 2
	add a, low(.stateTable)
	ld l, a
	adc a, high(.stateTable)
	sub a, l
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	rst CallHL

	call xRenderIcons
	ret

.stateTable
	dw xTradeMenuFirst
	dw xTradeMenuSecond

xTradeMenuFirst:
	ldh a, [hNewKeys]
	bit PADB_UP, a
	call nz, xMoveItemCursor.up
	ldh a, [hNewKeys]
	bit PADB_DOWN, a
	call nz, xMoveItemCursor.down
	ldh a, [hNewKeys]
	bit PADB_LEFT, a
	call nz, xMoveItemCursor.left
	ldh a, [hNewKeys]
	bit PADB_RIGHT, a
	call nz, xMoveItemCursor.right

	ldh a, [hNewKeys]
	bit PADB_A, a
	jr z, :+
		ld a, TRADE_SECOND
		call xSwitchTradeState
	:

	ldh a, [hNewKeys]
	bit PADB_B, a
	jr z, :+
		ld a, MENU_CANCELLED
		ld [wMenuClosingReason], a
	:
	jp xBlinkSelection

xTradeMenuSecond:
	ldh a, [hNewKeys]
	bit PADB_UP, a
	jr z, :+
		ld a, [wTradeCursor]
		sub a, 1
		jr c, :+
		ld [wTradeCursor], a
	:

	ldh a, [hNewKeys]
	bit PADB_DOWN, a
	jr z, :+
		ld a, [wTradeCursor]
		inc a
		cp a, 3
		jr nc, :+
		ld [wTradeCursor], a
	:

	ld a, [wInventoryCursor]
	add a, a ; a * 2
	add a, a ; a * 4
	add a, low(wInventoryItemPositions)
	ld l, a
	adc a, high(wInventoryItemPositions)
	sub a, l
	ld h, a
	ld a, FIRST_ITEM_X
	ld [hli], a
	ld a, [wTradeCursor]
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, a ; a * 16
	add a, FIRST_ITEM_Y - 16
	ld [hli], a

	ldh a, [hNewKeys]
	bit PADB_B, a
	jr z, :+
		assert TRADE_FIRST == 0
		xor a, a
		call xSwitchTradeState
	:

	ldh a, [hNewKeys]
	bit PADB_A, a
	jr z, :+
		ld a, [wTradeCursor]
		call xIsSelectionValid
		jr z, :+

		ld a, [wTradeCursor]
		ld l, a
		add a, a ; a * 2
		add a, l ; a * 3
		add a, a ; a * 6
		add a, 3
		push af
		call xGetCurrentTradelist
		pop af
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
		push bc
		push hl

			ld a, [wInventoryCursor]
			call InventoryRemoveItem

			ld a, [wTradeCursor]
			add a, low(wTradeSecondaries)
			ld l, a
			adc a, high(wTradeSecondaries)
			sub a, l
			ld h, a
			ld a, [wInventoryCursor]
			ld b, [hl]
			cp a, b
			jr nc, .noDec
				dec b
			.noDec
			ld a, b
			call InventoryRemoveItem

		pop hl
		pop bc

		call InventoryAddItem
		assert TRADE_FIRST == 0
		xor a, a
		ld [wInventoryCursor], a
		call xSwitchTradeState
		call ReloadPalettes
	:

	jp xBlinkSelection

xTradeMenuClose:
	ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16 | LCDCF_WINON | LCDCF_WIN9C00
	ldh [hShadowLCDC], a
	ret

xBlinkSelection:
	; Handle blinking
	ldh a, [hFrameCounter]
	bit 3, a
	ld a, -1
	jr z, :+
		ld a, [wInventoryCursor]
	:
	ld [wBlinkItem], a
	ret

xMoveItemCursor:
.up
	ld a, [wInventoryCursor]
	sub a, 2
	ret c
	ld [wInventoryCursor], a
	ret

.down
	ld a, [wTradeMenuInventoryLength]
	ld b, a
	ld a, [wInventoryCursor]
	add a, 2
	cp a, b
	ret nc
	ld [wInventoryCursor], a
	ret

.left
	ld a, [wInventoryCursor]
	sub a, 1
	ret c
	ld [wInventoryCursor], a
	ret

.right
	ld a, [wTradeMenuInventoryLength]
	ld b, a
	ld a, [wInventoryCursor]
	add a, 1
	cp a, b
	ret nc
	ld [wInventoryCursor], a
	ret

xSwitchTradeState:
	ld [wTradeState], a
	add a, a ; a * 2
	add a, low(.stateTable)
	ld l, a
	adc a, high(.stateTable)
	sub a, l
	ld h, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.stateTable
	dw xSwitchToFirstState
	dw xSwitchToSecondState

xSwitchToFirstState:
	call TradeLoadItemIcons
	call xMoveIconsToInventory

	ld d, 0
	ld bc, 16 * 4 * 6
	ld hl, vGreyItemIcon
	call VramSet
	call xClearHintIcons
	ret

xSwitchToSecondState:
	ld a, 1
	ld [wTradeCursor], a
	call xClearHintIcons

	ld a, -1
	ld [wTradeSecondaries + 0], a
	ld [wTradeSecondaries + 1], a
	ld [wTradeSecondaries + 2], a

	call xGetCurrentTradelist
	for i, 3
		ld a, [hli]
		ld b, a
		ld a, [hli]
		ld e, a
		ld a, [hli]
		ld d, a
		ld a, i
		ldh [hTradeIndex], a
		push hl
		call xRenderSecondItem
		pop hl
		ld a, [hli]
		ld b, a
		ld a, [hli]
		ld e, a
		ld a, [hli]
		ld d, a
		push hl
		call xRenderResultItem
		pop hl
	endr
	ret

xRenderSecondItem:
	ld a, b
	and a, a
	ret z
	call xFindItem
	jr z, .greyItem
	ld a, c
	add a, a ; a * 2
	add a, a ; a * 4
	add a, low(wInventoryItemPositions)
	ld l, a
	adc a, high(wInventoryItemPositions)
	sub a, l
	ld h, a
	ld a, SECOND_ITEM_X
	ld [hli], a
	ldh a, [hTradeIndex]
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, a ; a * 16
	add a, SECOND_ITEM_Y
	ld [hli], a
	ldh a, [hTradeIndex]
	add a, low(wTradeSecondaries)
	ld l, a
	adc a, high(wTradeSecondaries)
	sub a, l
	ld h, a
	ld [hl], c
	ld a, idof_vArrow
	ldh [hArrowIcon], a
	jr .showPlus

.greyItem
	ldh a, [hTradeIndex]
	ld c, a
	call DrawGreyIcon
	ld a, idof_vNoArrow
	ldh [hArrowIcon], a
.showPlus
	ldh a, [hTradeIndex]
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, a ; a * 16
	add a, a ; a * 32 (screen width)
	add a, a ; a * 64 (screen width * 2) (64 * 3 < 256)
	add a, low($996A)
	ld l, a
	adc a, high($996A)
	sub a, l
	ld h, a
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-

	ld a, idof_vPlus
	and a, a
	ld [hli], a
	inc a
	ld [hli], a
	inc hl
	inc hl
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ldh a, [hArrowIcon]
	ld [hli], a
	inc a
	ld [hli], a
	ld a, 32 - 6
	add a, l
	ld l, a
	adc a , h
	sub a, l
	ld h, a
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-

	ld a, idof_vPlus + 2
	ld [hli], a
	inc a
	ld [hli], a
	inc hl
	inc hl
:
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, :-
	ldh a, [hArrowIcon]
	add a, 2
	ld [hli], a
	inc a
	ld [hli], a
	ret

xRenderResultItem:
	ld a, b
	and a, a
	ret z
	ldh a, [hTradeIndex]
	add a, 3
	ld c, a
	jp DrawGreyIcon

xClearHintIcons:
	for y, 0, 6, 2
		for x, 0, 8, 4
		:
			ldh a, [rSTAT]
			and a, STATF_BUSY
			jr nz, :-
			ld a, idof_vBlankTile
			ld [$996A + (0 + x) + (0 + y) * 32], a
			ld [$996A + (1 + x) + (0 + y) * 32], a
			ld [$996A + (0 + x) + (1 + y) * 32], a
			ld [$996A + (1 + x) + (1 + y) * 32], a
		endr
	endr
	ret

; @param: bde: item farptr
; @return c: index
; @return nz if found
xFindItem:
	ld c, 0
.find
	ld a, [wInventoryCursor]
	cp a, c
	jr z, .next
	ld a, c
	add a, c ; a * 2
	add a, c ; a * 3
	add a, low(wInventory)
	ld l, a
	adc a, high(wInventory)
	sub a, l
	ld h, a

	ld a, [hli]
	and a, a
	ret z
	cp a, b
	jr nz, .next
	ld a, [hli]
	cp a, e
	jr nz, .next
	ld a, [hli]
	cp a, d
	jr nz, .next

	ld a, 1
	and a, a
	ret nz

.next
	inc c
	cp a, 8
	ret z
	jr .find

; @param a trade selection to verify
; @return nz if valid.
xIsSelectionValid:
	ld l, a
	add a, a ; a * 2
	add a, l ; a * 3
	add a, a ; a * 6
	push af
	call xGetCurrentTradelist
	pop af
	add a, l
	ld l, a
	adc a, h
	sub a, l
	ld h, a
	ld a, [hli]
	and a, a
	ret z
	ld b, a
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	call xFindItem
	ret

; @return z: set if no list.
; @return hl: list.
xGetCurrentTradelist:
	ld hl, wCurrentVendor
	ld a, [hli]
	ld h, [hl]
	ld l, a

	ld a, [wInventoryCursor]
	ld c, a
	add a, a ; a * 2
	add a, c ; a * 3
	; do this backwards so we can overwrite b last.
	add a, low(wInventory + 2)
	ld c, a
	adc a, high(wInventory + 2)
	sub a, c
	ld b, a
	ld a, [bc]
	dec bc
	ld d, a ; high
	ld a, [bc]
	dec bc
	ld e, a ; low
	ld a, [bc]
	dec bc
	ld b, a; bank
	; time to search
.loop
	; compare bank
	ld a, [hli]
	and a, a
	ret z
	cp a, b
	jr nz, .next2
	ld a, [hli]
	cp a, e
	jr nz, .next1
	ld a, [hli]
	cp a, d
	jr nz, .next
	; found!
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, h ; h is gauranteed to be nonzero because it's banked.
	and a, a
	ret nz
.next2
	inc hl
.next1
	inc hl
.next
	; skip the list pointer too.
	inc hl
	inc hl
	jr .loop

xMoveIconsToInventory:
	ld hl, wInventoryItemPositions
	for y, 4
		for x, 2
			ld a, INVENTORY_ITEM_X + x * 16
			ld [hli], a
			ld a, INVENTORY_ITEM_Y + y * 16
			ld [hli], a
			inc hl
			inc hl
		endr
	endr
	; fallthrough
xCountInventory:
	ld hl, wInventory
	ld b, 0
.loop
	ld a, [hli]
	inc hl
	inc hl
	and a, a
	jr z, .end
	inc b
	ld a, b
	cp a, 8
	jr nz, .loop
.end
	ld a, b
	ld [wTradeMenuInventoryLength], a
	ret

xResetIcons:
	ld hl, wInventoryItemPositions + 4 * 8 - 1
	rept 8
		ld a, [hld]
		ld b, a
		ld a, [hld]
		ld [hl], b
		dec hl
		ld [hld], a
	endr

xLerpIcons:
	ld b, 8
	ld hl, wInventoryItemPositions
.loop
	ld a, [hli] ; cur x
	ld e, a
	srl a
	srl a
	srl a
	ld d, a
	inc hl ; skip cur y
	ld a, [hl] ; target x
	srl a
	srl a
	srl a
	cp a, d
	jr nz, :+
		ld a, [hl]
		ld e, a
		jr :++
	:
	jr c, .curXIsGreater
	.curXIsLesser
		ld a, e
		add a, 8
		ld e, a
		jr :+
	.curXIsGreater
		ld a, e
		sub a, 8
		ld e, a
:
	dec hl
	dec hl
	ld a, e
	ld [hli], a ; set cur x

	ld a, [hli] ; cur y
	ld e, a
	srl a
	srl a
	srl a
	ld d, a
	inc hl ; skip target x
	ld a, [hl] ; target y
	srl a
	srl a
	srl a
	cp a, d
	jr nz, :+
		ld a, [hl]
		ld e, a
		jr :++
	:
	jr c, .curYIsGreater
	.curYIsLesser
		ld a, e
		add a, 8
		ld e, a
		jr :+
	.curYIsGreater
		ld a, e
		sub a, 8
		ld e, a
:
	dec hl ; undo target y
	dec hl ; undo target x
	ld a, e
	ld [hli], a ; set cur y
	inc hl ; skip targets
	inc hl
	dec b
	jr nz, .loop
	ret

xRenderIcons:
	ld hl, wInventoryItemPositions
	xor a, a
	ldh [hTradeIndex], a
.loop
	; Palette
	ld e, a

	ld a, [wBlinkItem]
	cp a, e
	jr nz, :+
		inc hl
		inc hl
		inc hl
		inc hl
		jr .next
	:

	ld a, e
	add a, a ; a * 2
	add a, e ; a * 3
	add a, low(wInventory)
	ld c, a
	adc a, high(wInventory)
	sub a, c
	ld b, a
	ld a, [bc]
	and a, a
	ret z

	; Tile ID - 4 each
	ld a, e
	add a, a ; a * 2
	add a, a ; a * 4
	ld d, a
	; Now position
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	inc hl
	inc hl
	push hl
		call RenderSimpleSprite
		ld a, c
		add a, 8
		ld c, a
		inc d
		call RenderSimpleSprite
		ld a, c
		sub a, 8
		ld c, a
		ld a, b
		add a, 8
		ld b, a
		inc d
		call RenderSimpleSprite
		ld a, c
		add a, 8
		ld c, a
		inc d
		call RenderSimpleSprite
	pop hl
.next
	ldh a, [hTradeIndex]
	inc a
	ldh [hTradeIndex], a
	cp a, 8
	jr nz, .loop
	ret

section "Trade menu rom0", rom0
TradeLoadItemIcons:
	ldh a, [hCurrentBank]
	push af

	ld hl, wInventory
	xor a, a
	ldh [hTradeIndex], a
.loop
	ld a, [hli]
	and a, a
	jr z, .exit

	rst SwapBank
	push hl

		ld a, [hli]
		ld h, [hl]
		ld l, a

		; Copy palette
		assert Item_Palette == 0
		ld a, [hli]
		ld e, a
		ld a, [hli]
		ld d, a

		ldh a, [hTradeIndex]
		ld c, a
		add a, a ; a * 2
		add a, a ; a * 4
		add a, a ; a * 8
		add a, c ; a * 9
		; bc = wOBJPaletteBuffer + a * 3 * 3
		add a, low(wOBJPaletteBuffer)
		ld c, a
		adc a, high(wOBJPaletteBuffer)
		sub a, c
		ld b, a

		rept 3 * 3
			ld a, [de]
			inc de
			ld [bc], a
			inc bc
		endr

		; Copy Graphics
		assert Item_Graphics == 2
		ld a, [hli]
		ld e, a
		ld a, [hli]
		ld d, a

		; 4 tiles is 16 * 4 == 64 bytes.
		; 64 * 8 == 512 > 256, but luckily we can clobber hl
		ldh a, [hTradeIndex]
		add a, a ; a * 2
		add a, a ; a * 4 (64 * 4 == 256, so we have to promote)
		assert low(vItemIcon) == 0
		ld l, a
		assert high(vItemIcon) & %1111 == 0
		ld h, high(vItemIcon) / 16
		add hl, hl ; a * 8
		add hl, hl ; a * 16
		add hl, hl ; a * 32
		add hl, hl ; a * 64

		ld b, 64
		.copy
			ldh a, [rSTAT]
			and a, STATF_BUSY
			jr nz, .copy
			ld a, [de]
			inc de
			ld [hli], a
			dec b
		jr nz, .copy

	pop hl
	inc hl
	inc hl

	ldh a, [hTradeIndex]
	inc a
	ldh [hTradeIndex], a
	cp a, INVENTORY_SIZE
	jr nz, .loop

.exit
	jp BankReturn

; @param b: bank of item
; @param de: item
; @param c: grey location
DrawGreyIcon:
	ldh a, [hCurrentBank]
	push af
	ld a, b
	rst SwapBank
	inc de
	inc de
	ld a, [de]
	inc de
	ld b, a
	ld a, [de]
	ld d, a
	ld e, b
	; de = item graphics pointer
	ld a, c ; 64 * 6 == 
	add a, a ; a * 2
	add a, a ; a * 4
	add a, a ; a * 8
	add a, a ; a * 16
	add a, a ; a * 32 (192, any more and we overflow)
	add a, low(vGreyItemIcon / 2)
	ld l, a
	adc a, high(vGreyItemIcon / 2)
	sub a, l
	ld h, a
	add hl, hl ; a * 64
	; hl = item destination
	inc de
	ld b, 4 * 8
.copy
	ldh a, [rSTAT]
	and a, STATF_BUSY
	jr nz, .copy
	ld a, [de]
	inc de
	ld [hli], a
	xor a, a
	inc de
	ld [hli], a
	dec b
	jr nz, .copy
	jp BankReturn

section "Trade State", wram0
wTradeState: db
wInventoryCursor: db
wTradeCursor: db
wTradeMenuInventoryLength: db
; inventory index -1 for none
wTradeSecondaries: ds 3

; Index. >= 8 is None
wBlinkItem: db

wCurrentVendor: dw

; Where to render each of the inventory's items.
; 8 sets of 2 u8 vectors that determine the current and target position.
wInventoryItemPositions:
	; Current
	; Target
	ds 4 * INVENTORY_SIZE

section "trade temp", hram
hTradeIndex: db
hArrowIcon: db
